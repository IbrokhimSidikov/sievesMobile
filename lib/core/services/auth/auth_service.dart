import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'login_exception.dart';

class AuthService {
  late final Auth0 _auth0;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Expose secure storage for use by AuthManager
  FlutterSecureStorage get secureStorage => _secureStorage;
  
  // Background timer for proactive token refresh
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  
  // Callback for when refresh token fails and user needs to be logged out
  Function? onRefreshTokenExpired;
  
  // TEST MODE: Set to true to test proactive refresh quickly
  // When true: checks every 30 seconds, refreshes if < 1500 minutes remaining
  // When false: checks every 4 minutes, refreshes if < 5 minutes remaining
  static const bool _testMode = false;

  // Auth0 configuration
  static const String _domain = 'exodelicainc.eu.auth0.com';
  static const String _clientId = 'HzIOKK7VlhRTVJxLVdL0djqCWwuGK5wH';
  static const String _audience = 'localhost:8080/loook-api/web';

  /// Auth0 database connection the backend creates employees in
  /// (see sieves-api `Identity::createAuthUser`).
  static const String _realm = 'Username-Password-Authentication';

  // Storage keys
  final String _accessTokenKey = 'access_token';
  final String _refreshTokenKey = 'refresh_token';
  final String _idTokenKey = 'id_token';
  final String _expiresAtKey = 'expires_at';

  // Initialize Auth0
  AuthService() {
    _auth0 = Auth0(_domain, _clientId);
  }

  /// Signs in with a username (or email) and password through Auth0's
  /// resource-owner password grant against the database connection the
  /// backend creates users in.
  ///
  /// Returns the Auth0 subject (`sub`) of the signed-in user, which the
  /// backend uses as `auth_id`. Throws [LoginException] on failure.
  ///
  /// Requires the "Password" grant to be enabled on the Auth0 application
  /// (Dashboard > Applications > Advanced Settings > Grant Types).
  Future<String> loginWithPassword({
    required String username,
    required String password,
  }) async {
    final Credentials credentials;
    try {
      print('🔐 Signing in with password for "$username"...');
      credentials = await _auth0.api.login(
        usernameOrEmail: username.trim(),
        password: password,
        connectionOrRealm: _realm,
        audience: _audience,
        scopes: {'openid', 'profile', 'email', 'offline_access'},
      );
    } on ApiException catch (e) {
      print('❌ Auth0 password login failed: ${e.code} — ${e.message}');
      throw LoginException(_mapApiError(e), '${e.code}: ${e.message}');
    } on SocketException catch (e) {
      throw LoginException(LoginErrorType.network, e.message);
    } on TimeoutException catch (e) {
      throw LoginException(LoginErrorType.network, e.message);
    } catch (e) {
      final text = e.toString().toLowerCase();
      if (text.contains('network') ||
          text.contains('socket') ||
          text.contains('timed out') ||
          text.contains('host lookup')) {
        throw LoginException(LoginErrorType.network, e.toString());
      }
      throw LoginException(LoginErrorType.unknown, e.toString());
    }

    print('✅ Credentials received (refresh token: ${credentials.refreshToken != null})');
    await _storeCredentials(credentials);

    final sub = credentials.user.sub;
    // Same post-login step the web app performs: mirror the token onto the
    // backend identity row.
    await _getBackendIdentity(sub, credentials.accessToken);
    return sub;
  }

  LoginErrorType _mapApiError(ApiException e) {
    if (e.isMultifactorRequired || e.isMultifactorEnrollRequired) {
      return LoginErrorType.mfaRequired;
    }
    final code = e.code.toLowerCase();
    final message = e.message.toLowerCase();
    if (code == 'too_many_attempts' || message.contains('too many attempts')) {
      return LoginErrorType.tooManyAttempts;
    }
    if (code == 'invalid_grant' ||
        code == 'invalid_user_password' ||
        code == 'access_denied' ||
        message.contains('wrong email or password') ||
        message.contains('wrong username or password')) {
      return LoginErrorType.invalidCredentials;
    }
    if (code == 'unauthorized_client' ||
        code == 'invalid_request' ||
        message.contains('grant type') ||
        message.contains('realm') ||
        message.contains('connection')) {
      return LoginErrorType.notConfigured;
    }
    if (code.contains('network') || message.contains('network')) {
      return LoginErrorType.network;
    }
    return LoginErrorType.unknown;
  }

  // Store credentials securely
  Future<void> _storeCredentials(Credentials credentials) async {
    print('📝 Storing credentials...');
    
    await _secureStorage.write(key: _accessTokenKey, value: credentials.accessToken);
    
    if (credentials.refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: credentials.refreshToken);
      print('✅ Refresh token stored successfully');
    } else {
      print('⚠️  WARNING: No refresh token received from Auth0!');
      print('   This means token refresh will NOT work.');
      print('   Check Auth0 Dashboard > Application > Settings > Advanced Settings > Grant Types');
      print('   Ensure "Refresh Token" grant type is enabled.');
    }
    
    await _secureStorage.write(key: _idTokenKey, value: credentials.idToken);

    // Store expiration time
    final expiresAt = credentials.expiresAt.millisecondsSinceEpoch.toString();
    await _secureStorage.write(key: _expiresAtKey, value: expiresAt);
    print('📅 Token expires at: ${credentials.expiresAt}');
    
    print('✅ Credentials stored successfully');
    
    // Start proactive refresh timer after storing credentials
    _startProactiveRefreshTimer();
  }

  // Get backend identity (same flow as Angular app)
  Future<void> _getBackendIdentity(String authId, String accessToken) async {
    try {
      print('');
      print('📡 Calling backend identity API...');
      final url = 'https://app.sievesapp.com/v1/identity/0?auth_id=$authId&expand[]=employee.branch&expand[]=employee.individual&expand[]=employee.reward';
      print('   URL: $url');
      print('   Auth ID: $authId');
      
      // Call your backend identity service (same as Angular)
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('   Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final identityData = json.decode(response.body);
        print('✅ Backend identity retrieved successfully');
        print('   Identity ID: ${identityData['id']}');
        print('   Email: ${identityData['email']}');
        
        // Update identity with token (same as Angular)
        identityData['token'] = accessToken;
        
        print('');
        print('📡 Updating identity with token...');
        final updateResponse = await http.put(
          Uri.parse('https://app.sievesapp.com/v1/identity/${identityData['id']}'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: json.encode(identityData),
        );

        print('   Update Response Status: ${updateResponse.statusCode}');
        
        if (updateResponse.statusCode == 200) {
          print('✅ Identity updated successfully');
        } else {
          print('❌ Identity update failed: ${updateResponse.statusCode}');
          print('   Response: ${updateResponse.body}');
        }
      } else {
        print('❌ Backend identity failed: ${response.statusCode}');
        print('   Response: ${response.body}');
        print('');
        print('⚠️  BACKEND API ERROR');
        print('   This might mean:');
        print('   1. The auth_id does not exist in your backend database');
        print('   2. The access token is not valid for your backend API');
        print('   3. The backend API is not accessible');
        print('');
      }
    } catch (e, stackTrace) {
      print('❌ Backend identity error: $e');
      print('   Stack trace: $stackTrace');
      print('');
      print('⚠️  NETWORK OR API ERROR');
      print('   Check your internet connection and backend API status');
      print('');
    }
  }

  // Get access token (with auto-refresh if expired or expiring soon)
  Future<String?> getAccessToken() async {
    final expiresAt = await _secureStorage.read(key: _expiresAtKey);
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    if (expiresAt != null) {
      final expiresAtTime = int.parse(expiresAt);
      final timeUntilExpiry = expiresAtTime - currentTime;
      final fiveMinutesInMs = 5 * 60 * 1000; // 5 minutes in milliseconds

      // Refresh if expired or expiring within 5 minutes
      if (expiresAtTime < currentTime || timeUntilExpiry < fiveMinutesInMs) {
        print('⏰ Token expired or expiring soon (${timeUntilExpiry ~/ 1000}s remaining), refreshing...');
        final refreshSuccess = await refreshToken();
        
        if (!refreshSuccess) {
          print('❌ Proactive token refresh failed - refresh token likely expired');
          // Clear all tokens since refresh failed
          await _secureStorage.delete(key: _accessTokenKey);
          await _secureStorage.delete(key: _refreshTokenKey);
          await _secureStorage.delete(key: _idTokenKey);
          await _secureStorage.delete(key: _expiresAtKey);
          return null;
        }
      }
    }

    return await _secureStorage.read(key: _accessTokenKey);
  }

  // Refresh the access token
  Future<bool> refreshToken() async {
    // Prevent concurrent refresh attempts
    if (_isRefreshing) {
      print('⏳ Token refresh already in progress, skipping...');
      return false;
    }
    
    _isRefreshing = true;
    
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      if (refreshToken == null) {
        print('❌ No refresh token found - cannot refresh access token');
        return false;
      }

      print('🔄 Refreshing access token...');
      print('   Refresh token available: ${refreshToken.isNotEmpty}');

      final credentials = await _auth0
          .api
          .renewCredentials(refreshToken: refreshToken);

      print('✅ Token refreshed successfully');
      print('   New access token received: ${credentials.accessToken.isNotEmpty}');
      print('   New refresh token received: ${credentials.refreshToken != null}');
      
      // Store credentials without restarting timer (to avoid recursion)
      await _secureStorage.write(key: _accessTokenKey, value: credentials.accessToken);
      
      if (credentials.refreshToken != null) {
        await _secureStorage.write(key: _refreshTokenKey, value: credentials.refreshToken);
      }
      
      await _secureStorage.write(key: _idTokenKey, value: credentials.idToken);
      
      final expiresAt = credentials.expiresAt.millisecondsSinceEpoch.toString();
      await _secureStorage.write(key: _expiresAtKey, value: expiresAt);
      
      final newExpiresAt = credentials.expiresAt;
      print('📅 New token expires at: $newExpiresAt');

      return true;
    } catch (e) {
      print('❌ Error refreshing token: $e');
      print('   Error type: ${e.runtimeType}');
      
      // Check for specific Auth0 errors
      if (e.toString().contains('invalid_grant')) {
        print('   → Refresh token is invalid or expired');
      } else if (e.toString().contains('network')) {
        print('   → Network error during refresh');
      } else if (e.toString().contains('timeout')) {
        print('   → Request timed out');
      }
      
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  // Get user info from Auth0
  Future<Map<String, dynamic>?> getUserInfo() async {
    final accessToken = await getAccessToken();

    if (accessToken == null) {
      return null;
    }

    final response = await http.get(
      Uri.parse('https://$_domain/userinfo'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Error getting user info: ${response.body}');
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      print('🚪 Logging out...');
      
      // Stop proactive refresh timer
      _stopProactiveRefreshTimer();
      
      // Clear local tokens from secure storage
      // We use max_age=0 in login to force re-authentication, so we don't need
      // to call Auth0's web logout which causes the browser popup
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _idTokenKey);
      await _secureStorage.delete(key: _expiresAtKey);
      
      print('✅ Logout completed successfully (tokens cleared)');
    } catch (e) {
      print('❌ Logout error: $e');
      // Ensure tokens are cleared even if there's an error
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _idTokenKey);
      await _secureStorage.delete(key: _expiresAtKey);
    }
  }
  
  /// Start background timer for proactive token refresh
  /// Checks every 4 minutes if token is expiring within 5 minutes
  void _startProactiveRefreshTimer() {
    // Cancel existing timer if any
    _stopProactiveRefreshTimer();
    
    final checkInterval = _testMode ? const Duration(seconds: 30) : const Duration(minutes: 4);
    final intervalText = _testMode ? '30 seconds [TEST MODE]' : '4 minutes';
    
    print('⏰ Starting proactive token refresh timer (checks every $intervalText)');
    
    // Check immediately
    _checkAndRefreshToken();
    
    // Then check periodically
    _refreshTimer = Timer.periodic(checkInterval, (timer) {
      _checkAndRefreshToken();
    });
  }
  
  /// Stop the proactive refresh timer
  void _stopProactiveRefreshTimer() {
    if (_refreshTimer != null) {
      print('⏰ Stopping proactive token refresh timer');
      _refreshTimer?.cancel();
      _refreshTimer = null;
    }
  }
  
  /// Check if token is expiring soon and refresh if needed
  Future<void> _checkAndRefreshToken() async {
    try {
      final expiresAt = await _secureStorage.read(key: _expiresAtKey);
      
      if (expiresAt == null) {
        print('⏰ No expiration time found, skipping proactive refresh');
        return;
      }
      
      final expiresAtTime = int.parse(expiresAt);
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final timeUntilExpiry = expiresAtTime - currentTime;
      
      // TEST MODE: Refresh if < 1500 minutes (to trigger with your current token)
      // PRODUCTION: Refresh if < 5 minutes
      final thresholdInMs = _testMode ? (1500 * 60 * 1000) : (5 * 60 * 1000);
      
      // Calculate time remaining in minutes
      final minutesRemaining = (timeUntilExpiry / 1000 / 60).round();
      
      final modeText = _testMode ? ' [TEST MODE: threshold=${1500}min]' : '';
      print('⏰ Proactive refresh check: Token expires in $minutesRemaining minutes$modeText');
      
      // Refresh if expired or expiring within threshold
      if (timeUntilExpiry < thresholdInMs) {
        print('🔄 Token expiring soon ($minutesRemaining min), proactively refreshing...');
        final success = await refreshToken();
        
        if (success) {
          print('✅ Proactive token refresh successful');
        } else {
          print('❌ Proactive token refresh failed - refresh token expired');
          print('🚪 Triggering automatic logout due to expired refresh token');
          
          // Stop timer if refresh fails (likely refresh token expired)
          _stopProactiveRefreshTimer();
          
          // Clear all tokens
          await _secureStorage.delete(key: _accessTokenKey);
          await _secureStorage.delete(key: _refreshTokenKey);
          await _secureStorage.delete(key: _idTokenKey);
          await _secureStorage.delete(key: _expiresAtKey);
          
          // Notify the app to logout the user
          if (onRefreshTokenExpired != null) {
            print('📢 Calling onRefreshTokenExpired callback');
            onRefreshTokenExpired!();
          } else {
            print('⚠️  No onRefreshTokenExpired callback set');
          }
        }
      } else {
        print('✅ Token still valid for $minutesRemaining minutes');
      }
    } catch (e) {
      print('❌ Error during proactive token check: $e');
    }
  }
  
  /// Manually start the proactive refresh timer (for session restoration)
  void startProactiveRefresh() {
    _startProactiveRefreshTimer();
  }
}