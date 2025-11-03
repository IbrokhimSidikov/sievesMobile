import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📱 Background message received: ${message.messageId}');
  print('Title: ${message.notification?.title}');
  print('Body: ${message.notification?.body}');
  print('Data: ${message.data}');
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
          // TODO: Send new token to your backend
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
      _fcmToken = await _messaging.getToken();
      print('🔑 FCM Token: $_fcmToken');
      
      // TODO: Send this token to your backend server
      // await _sendTokenToBackend(_fcmToken);
    } catch (e) {
      print('❌ Error getting FCM token: $e');
    }
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
  void _handleForegroundNotification(RemoteMessage message) {
    // You can show a custom dialog, snackbar, or banner here
    // Example: Show a snackbar with notification content
    
    // This is where you'd integrate with your UI layer
    // For example, using a GlobalKey<ScaffoldMessengerState>
  }

  /// Handle notification tap - navigate to appropriate screen
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    
    // Example: Navigate based on notification data
    if (data.containsKey('screen')) {
      final screen = data['screen'];
      print('📍 Navigating to screen: $screen');
      
      // TODO: Implement navigation logic
      // Example:
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
