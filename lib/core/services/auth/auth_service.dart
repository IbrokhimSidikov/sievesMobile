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
      print('🚀 Starting Auth0 login with auth0_flutter...');
      print('Domain: $_domain');
      print('Client ID: $_clientId');
      print('Audience: $_audience');
      
      final credentials = await _auth0
          .webAuthentication(scheme: 'sievesmob')
          .login(
            audience: _audience,
            scopes: {'openid', 'profile', 'email', 'offline_access'},
          );

      print('✅ Credentials received!');
      print('Access Token: ${credentials.accessToken.substring(0, 20)}...');
      print('Has Refresh Token: ${credentials.refreshToken != null}');
      
      await _storeCredentials(credentials);
      
      // Get user profile
      await _getUserProfile(credentials.accessToken);
      
      print('✅ Login completed successfully');
      return true;
    } catch (e) {
      print('❌ Login error: $e');
      print('Error type: ${e.runtimeType}');
      
      // Check for specific error types
      if (e.toString().contains('User cancelled') || 
          e.toString().contains('CANCELED') ||
          e.toString().contains('cancelled') ||
          e.toString().contains('a0.session.user_cancelled')) {
        print('🚫 User cancelled the login');
        return false;
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
    final currentTime = DateTime.now().millisecondsSinceEpoch.toString();

    if (expiresAt != null && int.parse(expiresAt) < int.parse(currentTime)) {
      await refreshToken();
    }

    return await _secureStorage.read(key: _accessTokenKey);
  }

  // Refresh the access token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      if (refreshToken == null) {
        print('❌ No refresh token found');
        return false;
      }

      print('🔄 Refreshing access token...');

      final credentials = await _auth0
          .api
          .renewCredentials(refreshToken: refreshToken);

      print('✅ Token refreshed successfully');
      await _storeCredentials(credentials);

      return true;
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
    try {
      print('🚪 Logging out...');
      
      // Logout from Auth0
      await _auth0
          .webAuthentication(scheme: 'sievesmob')
          .logout();
      
      // Clear stored tokens
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _idTokenKey);
      await _secureStorage.delete(key: _expiresAtKey);
      
      print('✅ Logged out successfully');
    } catch (e) {
      print('❌ Logout error: $e');
      // Still clear local tokens even if Auth0 logout fails
      await _secureStorage.delete(key: _accessTokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _idTokenKey);
      await _secureStorage.delete(key: _expiresAtKey);
    }
  }
}