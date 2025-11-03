# 🔧 FCM Notification Troubleshooting Guide

## Common Issues & Solutions

### 1. ⚠️ Not Receiving Notifications on Physical Device

#### Check #1: Verify FCM Token is Valid
Run your app and check the console output:
```
🔑 FCM Token: [should see a long token here]
✅ User granted notification permission
✅ Notification service initialized successfully
```

**If you don't see the token:**
- The token might not be generated
- Check if Firebase is initialized properly
- Verify `google-services.json` is in `android/app/`

#### Check #2: Notification Permission Granted
On Android 13+ (API 33+), you MUST explicitly grant notification permission:
1. Go to device Settings → Apps → Sieves Mob → Notifications
2. Ensure notifications are enabled
3. Or check in-app when the permission dialog appears

#### Check #3: Test Message Format
When sending from Firebase Console, use this format:

**Correct Format:**
```json
{
  "to": "YOUR_FCM_TOKEN_HERE",
  "notification": {
    "title": "Test Title",
    "body": "Test Body"
  },
  "priority": "high",
  "data": {
    "click_action": "FLUTTER_NOTIFICATION_CLICK"
  }
}
```

**Important:** 
- Use `"to"` (not `"registration_ids"`)
- Include `"priority": "high"` for immediate delivery
- Token should be the FULL token from console logs

#### Check #4: Google Services Configuration
Verify your `google-services.json`:
1. Check it's in `android/app/google-services.json`
2. Verify package name matches: `com.sieves.v1.sieves_mob`
3. Re-download from Firebase Console if unsure

#### Check #5: App State
Test notifications in different states:
- **Foreground**: App is open and active
- **Background**: App is minimized but running
- **Terminated**: App is completely closed

Different states may behave differently!

---

## 🧪 Testing Steps

### Step 1: Verify Token Generation
```bash
# Run the app and check logs
flutter run --verbose
```

Look for these logs:
```
✅ User granted notification permission
🔑 FCM Token: [your-token]
✅ Notification service initialized successfully
```

### Step 2: Test with curl
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_DEVICE_FCM_TOKEN",
    "priority": "high",
    "notification": {
      "title": "Test Notification",
      "body": "If you see this, FCM is working!"
    }
  }'
```

**Expected Response:**
```json
{
  "multicast_id": 123456789,
  "success": 1,
  "failure": 0,
  "canonical_ids": 0,
  "results": [{"message_id": "0:1234567890"}]
}
```

**If you get an error:**
- `"error": "InvalidRegistration"` → Token is invalid/expired
- `"error": "NotRegistered"` → App was uninstalled or token deleted
- `"error": "Unauthorized"` → Wrong server key

### Step 3: Check Device Settings
1. **Battery Optimization**: Disable for your app
   - Settings → Battery → Battery Optimization → Sieves Mob → Don't optimize
2. **Data Saver**: Disable or allow background data for your app
3. **Do Not Disturb**: Temporarily disable
4. **App Notifications**: Ensure enabled in system settings

---

## 🐛 Debug Mode

### Enable Verbose Logging

Add this to your notification service to see more details:

```dart
// In notification_service.dart, add after initialization
Future<void> testNotificationSetup() async {
  print('🔍 === NOTIFICATION DEBUG INFO ===');
  
  // Check permission status
  final settings = await _messaging.getNotificationSettings();
  print('📋 Authorization Status: ${settings.authorizationStatus}');
  print('📋 Alert Setting: ${settings.alert}');
  print('📋 Badge Setting: ${settings.badge}');
  print('📋 Sound Setting: ${settings.sound}');
  
  // Check token
  final token = await _messaging.getToken();
  print('🔑 Current FCM Token: $token');
  
  // Check if APNs token exists (iOS only)
  final apnsToken = await _messaging.getAPNSToken();
  print('🍎 APNs Token: $apnsToken');
  
  print('🔍 === END DEBUG INFO ===');
}
```

Call it after initialization:
```dart
await NotificationService().initialize();
await NotificationService().testNotificationSetup();
```

---

## 📱 Platform-Specific Issues

### Android Issues

#### Issue: "POST_NOTIFICATIONS permission not granted"
**Solution:** On Android 13+, request permission explicitly:
```dart
// Already handled in NotificationService.initialize()
// But you can check manually:
final settings = await FirebaseMessaging.instance.requestPermission();
print('Permission status: ${settings.authorizationStatus}');
```

#### Issue: Notifications work in debug but not release
**Solution:** 
1. Check ProGuard rules aren't stripping FCM classes
2. Verify release build has correct `google-services.json`
3. Test with a signed release build

#### Issue: Background notifications not working
**Solution:**
1. Ensure background handler is registered BEFORE `runApp()`
2. Check battery optimization settings
3. Verify app has background data access

### iOS Issues

#### Issue: No token received on iOS
**Solution:**
1. Add `GoogleService-Info.plist` to Xcode project
2. Enable Push Notifications capability
3. Configure APNs in Firebase Console
4. Test on physical device (not simulator)

---

## ✅ Checklist

Use this checklist to verify your setup:

- [ ] `firebase_messaging` package added to `pubspec.yaml`
- [ ] `flutter pub get` executed
- [ ] `google-services.json` in `android/app/`
- [ ] Google Services plugin applied in `build.gradle.kts`
- [ ] Notification permissions in `AndroidManifest.xml`
- [ ] FCM initialized in `main.dart`
- [ ] Background handler registered
- [ ] App rebuilt after changes (`flutter clean && flutter run`)
- [ ] Notification permission granted on device
- [ ] Battery optimization disabled for app
- [ ] FCM token printed in console
- [ ] Server key correct in Firebase Console
- [ ] Package name matches Firebase project

---

## 🎯 Quick Test

Run this test to verify everything:

1. **Start the app** and look for:
   ```
   ✅ User granted notification permission
   🔑 FCM Token: eyJhbGc...
   ```

2. **Copy the FCM token** from console

3. **Send test from Firebase Console:**
   - Go to Firebase Console → Cloud Messaging
   - Click "Send test message"
   - Paste your FCM token
   - Click "Test"

4. **Expected behavior:**
   - **App in foreground**: See console log "📨 Foreground message received"
   - **App in background**: See notification in status bar
   - **App terminated**: See notification in status bar

---

## 🔍 Common Error Messages

### "MissingPluginException"
**Cause:** Flutter plugins not registered
**Solution:** 
```bash
flutter clean
flutter pub get
flutter run
```

### "INVALID_ARGUMENT: Invalid registration token"
**Cause:** Token format is wrong or expired
**Solution:** 
- Get fresh token from app logs
- Ensure you're copying the FULL token
- Token might expire if app is reinstalled

### "Sender ID mismatch"
**Cause:** `google-services.json` doesn't match Firebase project
**Solution:**
- Re-download `google-services.json` from Firebase Console
- Verify package name matches

---

## 📞 Still Not Working?

If notifications still don't work after trying everything:

1. **Enable Flutter verbose logging:**
   ```bash
   flutter run --verbose
   ```

2. **Check Android logcat:**
   ```bash
   adb logcat | grep -i "firebase\|fcm\|notification"
   ```

3. **Verify in Firebase Console:**
   - Go to Cloud Messaging → Send test message
   - Check "Campaign analytics" for delivery status

4. **Test with a different device** to rule out device-specific issues

5. **Check Firebase project settings:**
   - Verify app is added to project
   - Check SHA-1 fingerprint (if using Firebase Auth)
   - Ensure Cloud Messaging API is enabled
