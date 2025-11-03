# Firebase Cloud Messaging (FCM) Setup Guide

## ✅ What's Already Done

### Android Configuration
- ✅ `firebase_messaging` package added to `pubspec.yaml`
- ✅ Google Services plugin configured in `build.gradle.kts`
- ✅ `google-services.json` file present
- ✅ Notification permissions added to `AndroidManifest.xml`
- ✅ `NotificationService` created and initialized
- ✅ Background message handler configured

### Code Implementation
- ✅ `NotificationService` class created at `lib/core/services/notification/notification_service.dart`
- ✅ FCM initialized in `main.dart`
- ✅ Background message handler set up

---

## 📱 iOS Setup (Required for iOS Notifications)

### 1. Add GoogleService-Info.plist
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/` directory
3. Open Xcode and add it to the project (right-click Runner → Add Files to "Runner")

### 2. Update iOS Podfile
Add to `ios/Podfile` (if not already present):
```ruby
# Add this at the top after platform line
platform :ios, '13.0'

# Add Firebase pods (if needed)
pod 'Firebase/Messaging'
```

### 3. Enable Push Notifications in Xcode
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Signing & Capabilities
3. Click "+ Capability" → Add "Push Notifications"
4. Click "+ Capability" → Add "Background Modes"
5. Check "Remote notifications" under Background Modes

### 4. Update AppDelegate.swift
Add to `ios/Runner/AppDelegate.swift`:
```swift
import UIKit
import Flutter
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Firebase configuration
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

### 5. Run Pod Install
```bash
cd ios
pod install
cd ..
```

---

## 🚀 Next Steps

### 1. Run Flutter Pub Get
```bash
flutter pub get
```

### 2. Test the Setup
Run your app and check the console for:
- ✅ "User granted notification permission"
- ✅ "FCM Token: [your-token]"
- ✅ "Notification service initialized successfully"

### 3. Get Your FCM Token
The FCM token will be printed in the console when the app starts. You can also access it programmatically:
```dart
final token = NotificationService().fcmToken;
print('FCM Token: $token');
```

---

## 📤 Sending Test Notifications

### Option 1: Firebase Console
1. Go to Firebase Console → Cloud Messaging
2. Click "Send your first message"
3. Enter notification title and text
4. Select your app
5. Send test message

### Option 2: Using HTTP API
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Test Notification",
      "body": "This is a test message"
    },
    "data": {
      "screen": "attendance",
      "custom_key": "custom_value"
    }
  }'
```

### Option 3: Using Firebase Admin SDK (Node.js)
```javascript
const admin = require('firebase-admin');

admin.messaging().send({
  token: 'DEVICE_FCM_TOKEN',
  notification: {
    title: 'Test Notification',
    body: 'This is a test message'
  },
  data: {
    screen: 'attendance'
  }
});
```

---

## 💡 Usage Examples

### 1. Subscribe to Topics
```dart
// Subscribe to a topic (e.g., all users)
await NotificationService().subscribeToTopic('all_users');

// Subscribe to user-specific topic
await NotificationService().subscribeToTopic('user_${userId}');
```

### 2. Listen to Notifications in Your App
```dart
// In your widget
@override
void initState() {
  super.initState();
  
  // Listen to notification stream
  NotificationService().notificationStream.listen((message) {
    // Handle notification received while app is in foreground
    print('Notification received: ${message.notification?.title}');
    
    // Show custom UI, snackbar, etc.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message.notification?.body ?? '')),
    );
  });
}
```

### 3. Handle Navigation from Notifications
Update the `_handleNotificationTap` method in `notification_service.dart`:
```dart
void _handleNotificationTap(RemoteMessage message) {
  final data = message.data;
  
  if (data.containsKey('screen')) {
    final screen = data['screen'];
    
    // Navigate based on screen parameter
    switch (screen) {
      case 'attendance':
        AppRoutes.router.go('/attendance');
        break;
      case 'history':
        AppRoutes.router.go('/history');
        break;
      case 'profile':
        AppRoutes.router.go('/profile');
        break;
      default:
        AppRoutes.router.go('/home');
    }
  }
}
```

### 4. Send Token to Your Backend
Update the `_getToken` method in `notification_service.dart`:
```dart
Future<void> _getToken() async {
  try {
    _fcmToken = await _messaging.getToken();
    print('🔑 FCM Token: $_fcmToken');
    
    // Send token to your backend
    if (_fcmToken != null) {
      await _sendTokenToBackend(_fcmToken!);
    }
  } catch (e) {
    print('❌ Error getting FCM token: $e');
  }
}

Future<void> _sendTokenToBackend(String token) async {
  try {
    // Replace with your API endpoint
    final response = await http.post(
      Uri.parse('https://your-api.com/api/fcm-token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'fcm_token': token}),
    );
    
    if (response.statusCode == 200) {
      print('✅ Token sent to backend');
    }
  } catch (e) {
    print('❌ Error sending token to backend: $e');
  }
}
```

### 5. Delete Token on Logout
```dart
// In your logout function
await NotificationService().deleteToken();
```

---

## 🎨 Custom Notification UI

To show custom in-app notifications when app is in foreground, update `_handleForegroundNotification`:

```dart
void _handleForegroundNotification(RemoteMessage message) {
  // Access your global scaffold messenger key
  final scaffoldMessenger = GlobalKey<ScaffoldMessengerState>();
  
  scaffoldMessenger.currentState?.showSnackBar(
    SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.notification?.title ?? '',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Text(message.notification?.body ?? ''),
        ],
      ),
      action: SnackBarAction(
        label: 'View',
        onPressed: () => _handleNotificationTap(message),
      ),
      duration: Duration(seconds: 4),
    ),
  );
}
```

---

## 🔧 Notification Payload Structure

### Recommended Format
```json
{
  "notification": {
    "title": "New Message",
    "body": "You have a new message from John"
  },
  "data": {
    "screen": "messages",
    "message_id": "12345",
    "user_id": "67890",
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

### Data-Only Messages (Silent Notifications)
```json
{
  "data": {
    "type": "sync",
    "action": "refresh_data",
    "silent": "true"
  }
}
```

---

## 🐛 Troubleshooting

### Android Issues
1. **No token received**: Check `google-services.json` is in `android/app/`
2. **Build errors**: Run `flutter clean && flutter pub get`
3. **Notifications not showing**: Check notification permissions in device settings

### iOS Issues
1. **No token received**: Ensure `GoogleService-Info.plist` is added to Xcode project
2. **Push capability missing**: Add Push Notifications capability in Xcode
3. **APNs certificate**: Configure APNs in Firebase Console for production

### General
- Check Firebase Console for any configuration errors
- Verify app package name matches Firebase project
- Test on physical device (notifications may not work on emulators)

---

## 📚 Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Messaging Package](https://firebase.flutter.dev/docs/messaging/overview)
- [Firebase Console](https://console.firebase.google.com/)

---

## ✨ Features Implemented

- ✅ Foreground notifications
- ✅ Background notifications
- ✅ Notification tap handling
- ✅ Topic subscription/unsubscription
- ✅ Token management
- ✅ Custom notification data handling
- ✅ Stream-based notification events
- ✅ iOS & Android support
