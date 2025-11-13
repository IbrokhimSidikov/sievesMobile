import 'dart:convert';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  late final Auth0 _auth0;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Expose secure storage for use by AuthManager
  FlutterSecureStorage get secureStorage => _secureStorage;

  // Auth0 configuration
  static const String _domain = 'exodelicainc.eu.auth0.com';
  static const String _clientId = 'HzIOKK7VlhRTVJxLVdL0djqCWwuGK5wH';
  static const String _audience = 'localhost:8080/loook-api/web';

  // Storage keys
  final String _accessTokenKey = 'access_token';
  final String _refreshTokenKey = 'refresh_token';
  final String _idTokenKey = 'id_token';
  final String _expiresAtKey = 'expires_at';

  // Initialize Auth0
  AuthService() {
    _auth0 = Auth0(_domain, _clientId);
  }

  // Login with Auth0
  Future<bool> login() async {
    try {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('🚀 Starting Auth0 login with auth0_flutter...');
      print('═══════════════════════════════════════════════════════');
      print('📋 Configuration:');
      print('   Domain: $_domain');
      print('   Client ID: $_clientId');
      print('   Audience: $_audience');
      print('   URL Scheme: sievesmob');
      print('   Callback URL: sievesmob://callback');
      print('');
      print('⏳ Opening Auth0 login page...');
      
      final credentials = await _auth0
          .webAuthentication(scheme: 'sievesmob')
          .login(
            audience: _audience,
            scopes: {'openid', 'profile', 'email', 'offline_access'},
            redirectUrl: 'sievesmob://callback',
            parameters: {
              'max_age': '0', // Force re-authentication every time
            },
          );

      print('');
      print('✅ Credentials received from Auth0!');
      print('   Access Token: ${credentials.accessToken.substring(0, 20)}...');
      print('   ID Token: ${credentials.idToken.substring(0, 20)}...');
      print('   Has Refresh Token: ${credentials.refreshToken != null}');
      print('   Expires At: ${credentials.expiresAt}');
      print('');
      
      await _storeCredentials(credentials);
      
      // Get user profile
      print('📞 Fetching user profile from Auth0...');
      await _getUserProfile(credentials.accessToken);
      
      print('');
      print('✅ Login completed successfully');
      print('═══════════════════════════════════════════════════════');
      print('');
      return true;
    } catch (e, stackTrace) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('❌ LOGIN ERROR OCCURRED');
      print('═══════════════════════════════════════════════════════');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace:');
      print(stackTrace);
      print('═══════════════════════════════════════════════════════');
      print('');
      
      // Check for specific error types
      if (e.toString().contains('User cancelled') || 
          e.toString().contains('CANCELED') ||
          e.toString().contains('cancelled') ||
          e.toString().contains('a0.session.user_cancelled')) {
        print('🚫 User cancelled the login - this is normal behavior');
        return false;
      }
      
      // Check for callback URL mismatch
      if (e.toString().contains('callback') || 
          e.toString().contains('redirect') ||
          e.toString().contains('URL')) {
        print('');
        print('⚠️  POSSIBLE CALLBACK URL ISSUE');
        print('   Check Auth0 Dashboard > Application Settings > Allowed Callback URLs');
        print('   Must include: sievesmob://callback');
        print('');
      }
      
      // Check for audience issues
      if (e.toString().contains('audience')) {
        print('');
        print('⚠️  POSSIBLE AUDIENCE ISSUE');
        print('   Current audience: $_audience');
        print('   Verify this matches your Auth0 API identifier');
        print('');
      }
      
      // Re-throw other errors so they can be handled by the UI
      rethrow;
    }
  }

  // Store credentials securely
  Future<void> _storeCredentials(Credentials credentials) async {
    print('📝 Storing credentials...');
    
    await _secureStorage.write(key: _accessTokenKey, value: credentials.accessToken);
    
    if (credentials.refreshToken != null) {
      await _secureStorage.write(key: _refreshTokenKey, value: credentials.refreshToken);
    }
    
    await _secureStorage.write(key: _idTokenKey, value: credentials.idToken);

    // Store expiration time
    final expiresAt = credentials.expiresAt.millisecondsSinceEpoch.toString();
    await _secureStorage.write(key: _expiresAtKey, value: expiresAt);
    print('📅 Token expires at: ${credentials.expiresAt}');
    
    print('✅ Credentials stored successfully');
  }

  // Get user profile from Auth0
  Future<void> _getUserProfile(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse('https://$_domain/userinfo'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final userProfile = json.decode(response.body);
        print('✅ User profile: $userProfile');
        
        // Now call your backend identity service
        await _getBackendIdentity(userProfile['sub'], accessToken);
      } else {
        print('❌ Get user profile failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Get user profile error: $e');
    }
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
      
      await _storeCredentials(credentials);
      
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
}