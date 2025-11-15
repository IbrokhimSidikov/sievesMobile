# Testing Proactive Token Refresh

## Quick Test Mode

The app now has a **TEST MODE** to quickly verify proactive refresh is working.

### Current Configuration (TEST MODE ENABLED)

```dart
static const bool _testMode = true;
```

**Test Mode Settings:**
- ✅ Checks every **30 seconds** (instead of 4 minutes)
- ✅ Refreshes if token expires in < **1360 minutes** (instead of 5 minutes)
- ✅ This will trigger refresh with your current token (1362 minutes)

### Expected Console Output

Within 30 seconds after login, you should see:

```
⏰ Starting proactive token refresh timer (checks every 30 seconds [TEST MODE])
⏰ Proactive refresh check: Token expires in 1362 minutes [TEST MODE: threshold=1360min]
🔄 Token expiring soon (1362 min), proactively refreshing...
🔄 Refreshing access token...
   Refresh token available: true
✅ Token refreshed successfully
   New access token received: true
   New refresh token received: true
📅 New token expires at: 2025-11-15 15:30:00
✅ Proactive token refresh successful
```

Then every 30 seconds, you'll see another check.

### How to Test

1. **Run the app** with test mode enabled (already done)
2. **Login** to your account
3. **Watch the console** - within 30 seconds you should see the refresh happen
4. **Verify** the token was refreshed by checking the new expiration time

### After Testing - Switch to Production Mode

Once you've verified it works, change this line in `auth_service.dart`:

```dart
static const bool _testMode = false;  // ← Change to false
```

**Production Settings:**
- Checks every **4 minutes**
- Refreshes if token expires in < **5 minutes**
- Optimal for battery life and user experience

### Troubleshooting

**If refresh doesn't trigger:**
- Check that your token actually expires in ~1362 minutes
- Verify the timer started (look for "Starting proactive token refresh timer")
- Check for any errors in the console

**If refresh fails:**
- Check your internet connection
- Verify refresh token is valid
- Check Auth0 configuration

### Test Scenarios

1. **Normal refresh**: Leave app running, watch it refresh every 30 seconds
2. **Network failure**: Turn off WiFi during refresh, see how it handles failure
3. **Background/foreground**: Put app in background, bring back, verify timer still works
4. **Logout**: Logout and verify timer stops
