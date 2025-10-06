# Token Refresh & Auto-Logout Flow

## Overview
The app now automatically handles token expiration and only logs out users when absolutely necessary (refresh token expired).

---

## 🔄 Automatic Token Refresh Flow

### Scenario 1: Access Token Expires (Normal Case)
```
User makes API request
    ↓
Access token expired (401/403 response)
    ↓
HTTP Interceptor catches error
    ↓
Automatically refreshes using refresh token
    ↓
✅ SUCCESS → Retry API request with new token
    ↓
User continues working (NO LOGOUT)
```

**User Experience:** Seamless, no interruption

---

### Scenario 2: Proactive Refresh (Before Expiration)
```
User makes API request
    ↓
System checks: Token expires in < 5 minutes?
    ↓
YES → Automatically refresh token
    ↓
Make API request with fresh token
    ↓
✅ User continues working (NO LOGOUT)
```

**User Experience:** Seamless, prevents 401 errors

---

## 🚪 Automatic Logout Flow

### Scenario 3: Refresh Token Expired (Rare)
```
Access token expired (401/403)
    ↓
Try to refresh using refresh token
    ↓
❌ FAILED (refresh token expired/invalid)
    ↓
AuthManager._handleTokenExpired() called
    ↓
Clear all tokens and session data
    ↓
Notify AuthCubit via callback
    ↓
AuthCubit emits: AuthError("Your session has expired")
    ↓
Wait 3 seconds (show error message)
    ↓
AuthCubit emits: AuthUnauthenticated
    ↓
User redirected to login screen
```

**User Experience:** Graceful logout with explanation

---

## Token Lifetimes (Typical)

| Token Type | Lifetime | Purpose |
|------------|----------|---------|
| **Access Token** | 1-24 hours | API authorization |
| **Refresh Token** | 7-90 days | Get new access tokens |

The app automatically handles access token expiration. Users only need to log in again after the refresh token expires (much less frequent).

---

## Implementation Details

### Key Components

1. **AuthHttpClient** (`http_client.dart`)
   - Intercepts all HTTP requests
   - Detects 401/403 responses
   - Automatically refreshes tokens and retries

2. **AuthService** (`auth_service.dart`)
   - `getAccessToken()`: Proactively refreshes if expiring soon
   - `refreshToken()`: Gets new access token using refresh token

3. **AuthManager** (`auth_manager.dart`)
   - Coordinates authentication flow
   - Handles session expiration callbacks
   - Notifies UI layer when logout needed

4. **AuthCubit** (`auth_cubit.dart`)
   - Manages app-wide authentication state
   - Listens for session expiration
   - Triggers navigation to login screen

---

## Logging & Debugging

Look for these console messages:

### Normal Refresh
```
⏰ Token expired or expiring soon, refreshing...
🔄 Refreshing access token...
✅ Token refreshed successfully
📅 New token expires at: 2025-10-06 15:30:00
```

### Interceptor Retry
```
🔒 Received 401 response, attempting token refresh...
✅ Token refreshed, retrying request...
📡 Retry response status: 200
```

### Session Expired (Logout)
```
❌ Token refresh failed - refresh token likely expired
⚠️ Token refresh failed completely - logout required
🚨 Token refresh failed - logging out user
⏰ Refresh token expired - clearing session
🔔 Session expired notification received
```

---

## FAQ

**Q: Will users have to login frequently?**
A: No! Access tokens refresh automatically. Users only re-login when the refresh token expires (typically 30-90 days).

**Q: What happens if user has no internet during refresh?**
A: The refresh will fail, but the app will retry on the next API call. User stays logged in.

**Q: Can user work offline?**
A: Only if the access token is still valid. Once expired, API calls require network to refresh.

**Q: How is this different from before?**
A: Before: App didn't refresh tokens → API calls failed after token expired
   Now: App auto-refreshes → seamless experience → only logout when refresh token expires

---

## Testing Recommendations

1. **Normal usage:** Leave app running for hours - should stay logged in
2. **Token expiration:** Wait for access token to expire - should refresh automatically
3. **No logout:** User should NOT be logged out during normal usage
4. **Refresh token expiry:** Only logs out after refresh token expires (30+ days)

