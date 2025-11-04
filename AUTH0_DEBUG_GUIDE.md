# Auth0 Authentication Debugging Guide

## Current Configuration

### Auth0 Settings (from auth_service.dart)
- **Domain**: `exodelicainc.eu.auth0.com`
- **Client ID**: `HzIOKK7VlhRTVJxLVdL0djqCWwuGK5wH`
- **Audience**: `localhost:8080/loook-api/web`
- **URL Scheme**: `sievesmob`
- **Bundle ID**: `com.sieves.v1`

## Required Auth0 Dashboard Configuration

### 1. Application Settings
Go to: https://manage.auth0.com/dashboard/eu/exodelicainc/applications

Find your application with Client ID: `HzIOKK7VlhRTVJxLVdL0djqCWwuGK5wH`

### 2. Add Callback URLs
In the "Allowed Callback URLs" field, add:
```
sievesmob://exodelicainc.eu.auth0.com/ios/com.sieves.v1/callback
```

### 3. Add Logout URLs
In the "Allowed Logout URLs" field, add:
```
sievesmob://exodelicainc.eu.auth0.com/ios/com.sieves.v1/logout
```

### 4. Application Type
- Ensure "Application Type" is set to **Native**

### 5. Grant Types
Ensure these are enabled:
- ✅ Authorization Code
- ✅ Refresh Token
- ✅ Implicit (if needed)

## Common Issues & Solutions

### Issue 1: "Callback URL mismatch"
**Symptom**: Login page opens but fails after authentication
**Solution**: Verify callback URLs in Auth0 dashboard match exactly

### Issue 2: "Invalid audience"
**Symptom**: Login fails immediately with audience error
**Solution**: Check if audience `localhost:8080/loook-api/web` is correct for your API

### Issue 3: "User cancelled"
**Symptom**: Login page closes without completing
**Solution**: This is normal user behavior, not an error

### Issue 4: "Network error"
**Symptom**: Cannot reach Auth0 servers
**Solution**: Check internet connection and firewall settings

### Issue 5: "Backend API fails"
**Symptom**: Auth0 succeeds but app shows error
**Solution**: Check backend API endpoint and token validity

## Testing Steps

### 1. Test Auth0 Login Flow
```bash
# Run app with verbose logging
flutter run --verbose

# Watch for these log messages:
# 🚀 Starting Auth0 login with auth0_flutter...
# ✅ Credentials received!
# ✅ Login completed successfully
```

### 2. Check Console Logs
Look for specific error messages:
- `❌ Login error:` - Auth0 authentication failed
- `❌ Failed to get identity from backend API` - Backend issue
- `❌ Backend API error:` - API communication problem

### 3. Verify Token Storage
After successful login, tokens should be stored in secure storage:
- `access_token`
- `refresh_token`
- `id_token`
- `expires_at`

### 4. Test Backend API
The app calls this endpoint after Auth0 login:
```
GET https://app.sievesapp.com/v1/identity/0?auth_id={authId}&expand[]=employee.branch&expand[]=employee.individual&expand[]=employee.reward
```

## Quick Fixes

### Fix 1: Clean Build
```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

### Fix 2: Clear Secure Storage
Add this temporary code to clear old tokens:
```dart
// In auth_manager.dart login() method, before authService.login()
await authService.secureStorage.deleteAll();
```

### Fix 3: Verify Info.plist
Check `ios/Runner/Info.plist` has:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>None</string>
        <key>CFBundleURLName</key>
        <string>auth0</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>sievesmob</string>
        </array>
    </dict>
</array>
```

## Debug Commands

### View Console Logs
```bash
# iOS Simulator
xcrun simctl spawn booted log stream --predicate 'processImagePath contains "Runner"' --level debug

# Physical Device
idevicesyslog | grep Runner
```

### Check Secure Storage
Add debug code in `auth_service.dart`:
```dart
Future<void> debugPrintAllKeys() async {
  final all = await _secureStorage.readAll();
  print('🔍 Secure Storage Contents:');
  all.forEach((key, value) {
    print('   $key: ${value.substring(0, min(20, value.length))}...');
  });
}
```

## Contact Points

If issue persists, provide:
1. Exact error message from console
2. Screenshot of Auth0 application settings
3. Whether Auth0 login page opens or not
4. Any network errors in console
