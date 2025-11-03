# 🚨 Quick Fix: Notifications Not Working

## Immediate Steps to Try

### 1. Run the App and Check Console
```bash
flutter run
```

Look for these messages:
```
✅ User granted notification permission
🔑 FCM Token: [long token string]
📋 Authorization Status: AuthorizationStatus.authorized
✅ Notification setup test completed
```

**If you DON'T see the token:**
- Permission was denied → Check device settings
- Firebase not configured → Verify `google-services.json`

---

### 2. Verify Notification Permission (Android 13+)

**On your device:**
1. Settings → Apps → Sieves Mob → Notifications
2. Enable "All Sieves Mob notifications"

**Or grant when prompted in app**

---

### 3. Copy Your FCM Token

From the console output, copy the FULL token:
```
🔑 Current FCM Token: eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Important:** Copy the ENTIRE token (usually 150+ characters)

---

### 4. Send Test from Firebase Console

1. Go to: https://console.firebase.google.com
2. Select your project
3. Cloud Messaging → "Send test message"
4. Paste your FCM token
5. Click "Test"

**Expected Result:**
- App in background/terminated → Notification appears in status bar
- App in foreground → Console shows "📨 Foreground message received"

---

### 5. Common Issues & Quick Fixes

#### ❌ "Invalid registration token"
**Fix:** Get a fresh token
```bash
# Uninstall and reinstall the app
flutter clean
flutter run
```

#### ❌ No notification on device
**Fix:** Check these settings on device:
- Battery optimization → OFF for your app
- Data saver → Allow background data
- Do Not Disturb → OFF

#### ❌ Works in foreground but not background
**Fix:** Ensure background handler is set
- Already done in `main.dart` ✅
- Check battery optimization is OFF

#### ❌ "MissingPluginException"
**Fix:** Clean and rebuild
```bash
flutter clean
flutter pub get
flutter run
```

---

### 6. Test with curl (Advanced)

Get your Server Key from Firebase Console → Project Settings → Cloud Messaging

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "YOUR_FCM_TOKEN_HERE",
    "priority": "high",
    "notification": {
      "title": "Test",
      "body": "This is a test"
    }
  }'
```

**Success Response:**
```json
{"success": 1, "failure": 0}
```

**Error Response:**
```json
{"error": "InvalidRegistration"}  → Token is wrong
{"error": "NotRegistered"}        → App uninstalled or token expired
```

---

## Still Not Working?

### Check Android Logcat
```bash
adb logcat | findstr /i "firebase fcm notification"
```

### Verify Package Name
In `android/app/build.gradle.kts`:
```kotlin
applicationId = "com.sieves.v1.sieves_mob"
```

Must match Firebase Console → Project Settings → Your apps

### Rebuild from Scratch
```bash
flutter clean
cd android
./gradlew clean
cd ..
flutter pub get
flutter run
```

---

## Debug Checklist

- [ ] App shows FCM token in console
- [ ] Token is 150+ characters long
- [ ] Notification permission granted
- [ ] Battery optimization disabled
- [ ] Tested with Firebase Console "Send test message"
- [ ] Package name matches Firebase project
- [ ] `google-services.json` in `android/app/`
- [ ] App rebuilt after adding FCM

---

## Need More Help?

See detailed guide: `NOTIFICATION_TROUBLESHOOTING.md`
