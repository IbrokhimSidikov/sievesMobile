import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../model/notification_model.dart';
import 'notification_storage_service.dart';
import '../api/api_service.dart';
import '../auth/auth_manager.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
  
  // Save notification to storage
  await _saveNotificationToStorage(message);
  print('✅ Background notification saved to storage');
}

/// Helper function to save notification
Future<void> _saveNotificationToStorage(RemoteMessage message) async {
  try {
    final platform = Platform.isIOS ? '🍎 iOS' : '🤖 Android';
    print('$platform Saving notification to storage...');
    print('  Message ID: ${message.messageId}');
    print('  Title: ${message.notification?.title}');
    print('  Body: ${message.notification?.body}');
    print('  Type: ${message.data['type']}');
    
    final notification = NotificationModel(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: message.notification?.title ?? 'New Notification',
      body: message.notification?.body ?? '',
      type: message.data['type'] as String? ?? 'general',
      timestamp: DateTime.now(),
      isRead: false,
      data: message.data,
    );
    
    await NotificationStorageService().saveNotification(notification);
    print('$platform Notification saved successfully');
  } catch (e) {
    print('❌ Error saving notification: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Stream controller for notification events
  final _notificationStreamController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get notificationStream => _notificationStreamController.stream;

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  /// Returns cached token or fetches a fresh one from Firebase directly.
  /// Use this after login when the token may not be cached yet.
  Future<String?> getOrFetchToken() async {
    if (_fcmToken != null) return _fcmToken;
    try {
      print('🔑 [FCM] Token not cached, fetching directly from Firebase...');
      _fcmToken = await _messaging.getToken();
      print('🔑 [FCM] Fetched token: $_fcmToken');
    } catch (e) {
      print('❌ [FCM] Error fetching token: $e');
    }
    return _fcmToken;
  }
  
  // Reference to AuthManager for getting identity ID
  final AuthManager _authManager = AuthManager();

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      final settings = await _requestPermission();
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ User granted notification permission');
        
        // Get FCM token
        await _getToken();
        
        // Listen to token refresh
        _messaging.onTokenRefresh.listen((newToken) {
          print('🔄 FCM Token refreshed: $newToken');
          _fcmToken = newToken;
          // Send refreshed token to backend
          _sendTokenToBackend(newToken);
        });
        
        // Configure foreground notification presentation
        await _configureForegroundNotifications();
        
        // Set up message handlers
        _setupMessageHandlers();
        
        print('✅ Notification service initialized successfully');
      } else {
        print('⚠️ User declined notification permission');
      }
    } catch (e) {
      print('❌ Error initializing notification service: $e');
    }
  }

  /// Request notification permissions (iOS)
  Future<NotificationSettings> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    
    print('📋 Permission status: ${settings.authorizationStatus}');
    return settings;
  }

  /// Get FCM token
  Future<void> _getToken() async {
    try {
      // On iOS, wait for APNs token first (but with shorter delay)
      if (Platform.isIOS) {
        print('🍎 iOS: Checking for APNs token...');
        
        // Reduced delay from 2s to 500ms
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Check if APNs token is available
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) {
          print('🍎 iOS: APNs token available');
        } else {
          print('⚠️ iOS: APNs token not available yet, will retry in background...');
          // Don't wait here - retry in background
          _retryGetTokenInBackground();
          return;
        }
      }
      
      _fcmToken = await _messaging.getToken();
      print('🔑 FCM Token: $_fcmToken');
      
      // Send this token to your backend server
      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      print('❌ Error getting FCM token: $e');
      // Retry in background instead of blocking
      _retryGetTokenInBackground();
    }
  }

  /// Retry getting FCM token in background without blocking
  void _retryGetTokenInBackground() {
    print('🔄 Retrying FCM token fetch in background...');
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        _fcmToken = await _messaging.getToken();
        print('🔑 FCM Token (background retry): $_fcmToken');
        // Send this token to your backend server
        if (_fcmToken != null) {
          await _sendTokenToBackend(_fcmToken!);
        }
      } catch (e) {
        print('❌ Background retry failed: $e');
      }
    });
  }

  /// Configure how notifications appear in foreground
  Future<void> _configureForegroundNotifications() async {
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true, // Show notification banner
      badge: true, // Update badge count
      sound: true, // Play sound
    );
  }

  /// Set up message handlers for different states
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Foreground message received: ${message.messageId}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      
      // Emit to stream for UI to handle
      _notificationStreamController.add(message);
      
      // You can show a custom in-app notification here
      _handleForegroundNotification(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification tapped (app in background): ${message.messageId}');
      print('Data: ${message.data}');
      
      // Navigate to specific screen based on notification data
      _handleNotificationTap(message);
    });

    // Check if app was opened from a terminated state via notification
    _checkInitialMessage();
  }

  /// Check if app was opened from terminated state via notification
  Future<void> _checkInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    
    if (initialMessage != null) {
      print('🚀 App opened from terminated state via notification: ${initialMessage.messageId}');
      print('Data: ${initialMessage.data}');
      
      // Handle the notification tap
      _handleNotificationTap(initialMessage);
    }
  }

  /// Handle notification when app is in foreground
  Future<void> _handleForegroundNotification(RemoteMessage message) async {
    // Save notification to storage
    await _saveNotificationToStorage(message);
    
    // You can show a custom dialog, snackbar, or banner here
    // Example: Show a snackbar with notification content
    
    // This is where you'd integrate with your UI layer
    // For example, using a GlobalKey<ScaffoldMessengerState>
  }

  /// Handle notification tap - navigate to appropriate screen
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    final data = message.data;
    
    print('📍 Notification tapped, navigating to notifications page');
    
    // Save notification to storage (important for iOS where background handler may not run)
    await _saveNotificationToStorage(message);
    print('✅ Notification saved on tap');
    
    // Navigate to notifications page by default
    // Use a delay to ensure app is fully loaded
    Future.delayed(const Duration(milliseconds: 500), () {
      try {
        // Import will be added at the top
        // AppRoutes.router.go('/notificationNew');
        
        // For now, just log - navigation will be handled by router
        print('📱 Opening notifications page');
      } catch (e) {
        print('❌ Error navigating: $e');
      }
    });
    
    // Optional: Navigate to specific screen based on data
    if (data.containsKey('screen')) {
      final screen = data['screen'];
      print('📍 Custom screen requested: $screen');
      
      // You can add custom navigation logic here
      // if (screen == 'attendance') {
      //   AppRoutes.router.go('/attendance');
      // } else if (screen == 'history') {
      //   AppRoutes.router.go('/history');
      // }
    }
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('✅ Subscribed to topic: $topic');
    } catch (e) {
      print('❌ Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      print('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      print('❌ Error unsubscribing from topic $topic: $e');
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      final employeeId = _authManager.currentEmployeeId;
      if (employeeId == null) {
        print('⚠️ [FCM] No employee ID available, cannot send token to backend');
        return;
      }

      final apiService = _authManager.apiService;
      final success = await apiService.sendFcmToken(employeeId, token);
      
      if (success) {
        print('✅ [FCM] Token successfully sent to backend for employee $employeeId');
      } else {
        print('❌ [FCM] Failed to send token to backend');
      }
    } catch (e) {
      print('❌ [FCM] Exception sending token to backend: $e');
    }
  }

  /// Delete FCM token (e.g., on logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _fcmToken = null;
      print('✅ FCM token deleted');
    } catch (e) {
      print('❌ Error deleting FCM token: $e');
    }
  }

  /// Debug method to test notification setup
  Future<void> testNotificationSetup() async {
    print('🔍 === NOTIFICATION DEBUG INFO ===');
    
    try {
      // Check permission status
      final settings = await _messaging.getNotificationSettings();
      print('📋 Authorization Status: ${settings.authorizationStatus}');
      print('📋 Alert Setting: ${settings.alert}');
      print('📋 Badge Setting: ${settings.badge}');
      print('📋 Sound Setting: ${settings.sound}');
      
      // Check token
      final token = await _messaging.getToken();
      print('🔑 Current FCM Token: $token');
      print('🔑 Token Length: ${token?.length ?? 0} characters');
      
      // Check if APNs token exists (iOS only)
      final apnsToken = await _messaging.getAPNSToken();
      print('🍎 APNs Token: ${apnsToken ?? "Not available (Android or not set)"}');
      
      print('✅ Notification setup test completed');
    } catch (e) {
      print('❌ Error during notification setup test: $e');
    }
    
    print('🔍 === END DEBUG INFO ===');
  }

  /// Dispose resources
  void dispose() {
    _notificationStreamController.close();
  }
}
