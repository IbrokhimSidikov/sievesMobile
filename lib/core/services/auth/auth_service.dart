import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthService {
  final FlutterAppAuth _appAuth = FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  
  // Expose secure storage for use by AuthManager
  FlutterSecureStorage get secureStorage => _secureStorage;

  // Auth0 configuration
  static const String _domain = 'exodelicainc.eu.auth0.com';
  static const String _clientId = 'HzIOKK7VlhRTVJxLVdL0djqCWwuGK5wH';
  static const String _redirectUri = 'sievesmob://callback';
  static const String _audience = 'localhost:8080/loook-api/web'; // Fixed spelling
  static const String _issuer = 'https://$_domain';

  // Storage keys
  final String _accessTokenKey = 'access_token';
  final String _refreshTokenKey = 'refresh_token';
  final String _idTokenKey = 'id_token';
  final String _expiresAtKey = 'expires_at';

  // Login with Auth0
  Future<bool> login() async {
    try {
      print('🚀 Starting Auth0 login...');
      print('Client ID: $_clientId');
      print('Redirect URL: $_redirectUri');
      print('Issuer: $_issuer');
      
      final AuthorizationTokenResponse? result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          issuer: _issuer,
          scopes: ['openid', 'profile', 'email', 'offline_access'],
          promptValues: ['login'],
          additionalParameters: {
            'audience': _audience, // Correct audience
          },
        ),
      );

      print('🔍 Auth result: ${result != null ? 'Success' : 'Null'}');
      
      if (result != null) {
        print('✅ Tokens received, storing...');
        await _storeTokens(result);
        
        // Get user profile
        await _getUserProfile(result.accessToken!);
        
        print('✅ Login completed successfully');
        return true;
      } else {
        print('❌ No result returned from Auth0');
        return false;
      }
    } catch (e) {
      print('❌ Login error: $e');
      print('Error type: ${e.runtimeType}');
      
      // Check for specific error types
      if (e.toString().contains('User cancelled') || 
          e.toString().contains('CANCELED') ||
          e.toString().contains('cancelled')) {
        print('🚫 User cancelled the login');
        return false;
      }
      
      // Re-throw other errors so they can be handled by the UI
      rethrow;
    }
  }

  // Store tokens securely
  Future<void> _storeTokens(AuthorizationTokenResponse response) async {
    print('📝 Storing tokens...');
    await _secureStorage.write(key: _accessTokenKey, value: response.accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: response.refreshToken);
    await _secureStorage.write(key: _idTokenKey, value: response.idToken);

    // Fix: Use the actual expiration time, not just the seconds
    if (response.accessTokenExpirationDateTime != null) {
      final expiresAt = response.accessTokenExpirationDateTime!
          .millisecondsSinceEpoch
          .toString();
      await _secureStorage.write(key: _expiresAtKey, value: expiresAt);
      print('📅 Token expires at: ${response.accessTokenExpirationDateTime}');
    }
    print('✅ Tokens stored successfully');
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
      // Call your backend identity service (same as Angular)
      final response = await http.get(
        Uri.parse('https://app.sievesapp.com/v1/identity/0?auth_id=$authId&expand[]=employee.branch&expand[]=employee.individual&expand[]=employee.reward'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final identityData = json.decode(response.body);
        print('✅ Backend identity: $identityData');
        
        // Update identity with token (same as Angular)
        identityData['token'] = accessToken;
        
        final updateResponse = await http.put(
          Uri.parse('https://app.sievesapp.com/v1/identity/${identityData['id']}'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
          body: json.encode(identityData),
        );

        if (updateResponse.statusCode == 200) {
          print('✅ Identity updated successfully');
        } else {
          print('❌ Identity update failed: ${updateResponse.statusCode}');
        }
      } else {
        print('❌ Backend identity failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Backend identity error: $e');
    }
  }

  // Get access token (with auto-refresh if expired)
  Future<String?> getAccessToken() async {
    final expiresAt = await _secureStorage.read(key: _expiresAtKey);
    final currentTime = DateTime.now().millisecondsSinceEpoch;

    // Check if token is expired or about to expire (within 5 minutes)
    if (expiresAt != null) {
      final expiryTime = int.parse(expiresAt);
      final bufferTime = 5 * 60 * 1000; // 5 minutes in milliseconds
      
      if (expiryTime < currentTime + bufferTime) {
        print('⏰ Token expired or expiring soon, refreshing...');
        final refreshed = await refreshToken();
        if (!refreshed) {
          print('❌ Failed to refresh token');
          return null;
        }
      }
    }

    return await _secureStorage.read(key: _accessTokenKey);
  }

  // Refresh the access token
  Future<bool> refreshToken() async {
    try {
      print('🔄 Refreshing access token...');
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      if (refreshToken == null) {
        print('❌ No refresh token available');
        return false;
      }

      final TokenResponse? result = await _appAuth.token(
        TokenRequest(
          _clientId,
          _redirectUri,
          issuer: _issuer,
          refreshToken: refreshToken,
          scopes: ['openid', 'profile', 'email', 'offline_access'],
          additionalParameters: {'audience': _audience},
        ),
      );

      if (result != null) {
        await _secureStorage.write(key: _accessTokenKey, value: result.accessToken);

        if (result.refreshToken != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: result.refreshToken);
        }

        // Fix: Use the actual expiration time from the token response
        if (result.accessTokenExpirationDateTime != null) {
          final expiresAt = result.accessTokenExpirationDateTime!
              .millisecondsSinceEpoch
              .toString();
          await _secureStorage.write(key: _expiresAtKey, value: expiresAt);
          print('✅ Token refreshed successfully');
          print('📅 New token expires at: ${result.accessTokenExpirationDateTime}');
        }

        return true;
      }
      print('❌ Token refresh returned null result');
      return false;
    } catch (e) {
      print('❌ Error refreshing token: $e');
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
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _secureStorage.delete(key: _idTokenKey);
    await _secureStorage.delete(key: _expiresAtKey);
  }
}