# 🐛 Notification Debugging Guide

## Issue: Notifications Not Appearing in the Page

### Quick Checks

#### 1. **Check if Notification is Being Saved**

Run your app and check the console logs when you receive a notification:

**Expected logs:**
```
📱 Background message received: [message-id]
Title: Your notification title
Body: Your notification body
Data: {type: system}
✅ Notification saved: Your notification title
✅ Background notification saved to storage
```

If you don't see "✅ Notification saved", the notification isn't being stored.

#### 2. **Check if Notification Page is Loading Data**

When you open the notifications page, check console for:
```
Error loading notifications: [error message]
```

#### 3. **Manually Test Storage**

Add this temporary code to your notifications page `initState`:

```dart
@override
void initState() {
  super.initState();
  _loadNotifications();
  
  // DEBUG: Add a test notification
  _addTestNotification();
}

Future<void> _addTestNotification() async {
  final testNotification = NotificationModel(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    title: 'Test Notification',
    body: 'This is a test to verify storage is working',
    type: 'system',
    timestamp: DateTime.now(),
    isRead: false,
  );
  
  await NotificationStorageService().saveNotification(testNotification);
  print('✅ Test notification added');
  await _loadNotifications();
}
```

If you see the test notification appear, storage is working!

---

## Common Issues & Solutions

### Issue 1: Notifications Saved But Not Showing

**Cause:** Filter might be hiding them

**Solution:** 
1. Click "All" filter
2. Pull down to refresh
3. Check console for "Error loading notifications"

### Issue 2: Background Notifications Not Saved

**Cause:** Background handler not registered or Firebase not initialized

**Solution:** Verify in `main.dart`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // THIS IS CRITICAL - Must be before runApp()
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  await NotificationService().initialize();
  await NotificationService().testNotificationSetup();
  
  runApp(const MyApp());
}
```

### Issue 3: Tapping Notification Doesn't Navigate

**Current Status:** Navigation is logged but not implemented yet.

**To Fix:** Update `notification_service.dart`:

```dart
import '../../router/app_routes.dart';

void _handleNotificationTap(RemoteMessage message) {
  print('📍 Notification tapped, navigating to notifications page');
  
  Future.delayed(const Duration(milliseconds: 500), () {
    try {
      AppRoutes.router.go('/notificationNew');
      print('📱 Navigated to notifications page');
    } catch (e) {
      print('❌ Error navigating: $e');
    }
  });
}
```

---

## Testing Steps

### Test 1: Send Notification While App is in Background

1. **Minimize your app** (don't close it)
2. **Send test notification** from Firebase Console
3. **Tap the notification** in system tray
4. **Check console logs:**
   ```
   📱 Background message received: [id]
   ✅ Notification saved: [title]
   📍 Notification tapped, navigating to notifications page
   ```
5. **Open notifications page** from app menu
6. **Pull down to refresh**
7. **You should see the notification**

### Test 2: Send Notification While App is Terminated

1. **Completely close your app** (swipe away)
2. **Send test notification**
3. **Tap notification** to open app
4. **App should open** (might go to home first)
5. **Navigate to notifications page**
6. **You should see the notification**

### Test 3: Send Notification While App is in Foreground

1. **Keep app open**
2. **Send test notification**
3. **Check console:**
   ```
   📨 Foreground message received: [id]
   ✅ Notification saved: [title]
   ```
4. **Go to notifications page**
5. **You should see it immediately**

---

## Verification Commands

### Check Stored Notifications (Add to notifications page temporarily)

```dart
// Add this button to your notifications page for debugging
FloatingActionButton(
  onPressed: () async {
    final notifications = await NotificationStorageService().getNotifications();
    print('📊 Total notifications in storage: ${notifications.length}');
    for (var n in notifications) {
      print('  - ${n.title} (${n.type}) - ${n.timeAgo}');
    }
  },
  child: Icon(Icons.bug_report),
)
```

### Clear All Notifications (For Testing)

```dart
// Add this to test fresh state
await NotificationStorageService().clearAll();
print('🗑️ All notifications cleared');
```

---

## Expected Behavior

### When Notification is Received:

1. **Background/Terminated:**
   - System notification appears in tray
   - Notification is saved to storage
   - Tapping opens app
   - Notification visible in notifications page

2. **Foreground:**
   - No system notification (by design)
   - Notification is saved to storage
   - Console log shows "📨 Foreground message received"
   - Notification visible in notifications page

### When Opening Notifications Page:

1. Loading spinner appears
2. Notifications load from storage
3. List displays with newest first
4. Unread count shows in header
5. Pull-to-refresh works

---

## Still Not Working?

### Enable Verbose Logging

Add this to notification_storage_service.dart:

```dart
Future<void> saveNotification(NotificationModel notification) async {
  try {
    print('💾 Attempting to save notification: ${notification.title}');
    final prefs = await SharedPreferences.getInstance();
    print('✅ SharedPreferences instance obtained');
    
    final notifications = await getNotifications();
    print('📋 Current notifications count: ${notifications.length}');
    
    notifications.insert(0, notification);
    
    if (notifications.length > _maxNotifications) {
      notifications.removeRange(_maxNotifications, notifications.length);
    }
    
    final jsonList = notifications.map((n) => n.toJson()).toList();
    print('📝 Converting ${notifications.length} notifications to JSON');
    
    await prefs.setString(_notificationsKey, jsonEncode(jsonList));
    print('✅ Notification saved successfully: ${notification.title}');
  } catch (e) {
    print('❌ Error saving notification: $e');
    print('Stack trace: ${StackTrace.current}');
  }
}
```

### Check SharedPreferences

Add this debug function:

```dart
Future<void> debugStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final keys = prefs.getKeys();
  print('📦 All SharedPreferences keys: $keys');
  
  final notifData = prefs.getString('app_notifications');
  print('📨 Notification data length: ${notifData?.length ?? 0}');
  
  if (notifData != null) {
    final decoded = jsonDecode(notifData);
    print('📊 Decoded notifications count: ${decoded.length}');
  }
}
```

Run this when the app starts to verify storage is accessible.
