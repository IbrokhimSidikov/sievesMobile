import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Auth0Service {
  final FlutterAppAuth appAuth = FlutterAppAuth();
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  // Auth0 configuration
  final String domain = 'exodelicainc.eu.auth0.com';
  final String clientId = 'HzIOKK7VlhRTVJxLVdL0djqCWwuGK5wH';
  final String audience = 'https://exodelicainc.eu.auth0.com/api/v2/';
  final String redirectUrl = 'sievesmob://callback'; // Match your Auth0 config
  final String issuer = 'https://exodelicainc.eu.auth0.com';

  // Storage keys
  final String accessTokenKey = 'access_token';
  final String refreshTokenKey = 'refresh_token';
  final String idTokenKey = 'id_token';
  final String expiresAtKey = 'expires_at';

  // Login with Auth0
  Future<bool> login() async {
    try {
      print('🚀 Starting Auth0 login...');
      print('Client ID: $clientId');
      print('Redirect URL: $redirectUrl');
      print('Issuer: $issuer');
      
      final AuthorizationTokenResponse? result = await appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          clientId,
          redirectUrl,
          issuer: issuer,
          scopes: ['openid', 'profile', 'email', 'offline_access'],
          promptValues: ['login'],
          additionalParameters: {'audience': audience},
        ),
      );

      print('🔍 Auth result: ${result != null ? 'Success' : 'Null'}');
      
      if (result != null) {
        print('✅ Tokens received, storing...');
        await _storeTokens(result);
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
    await secureStorage.write(key: accessTokenKey, value: response.accessToken);
    await secureStorage.write(key: refreshTokenKey, value: response.refreshToken);
    await secureStorage.write(key: idTokenKey, value: response.idToken);

    // Fix: Use the actual expiration time, not just the seconds
    if (response.accessTokenExpirationDateTime != null) {
      final expiresAt = response.accessTokenExpirationDateTime!
          .millisecondsSinceEpoch
          .toString();
      await secureStorage.write(key: expiresAtKey, value: expiresAt);
      print('📅 Token expires at: ${response.accessTokenExpirationDateTime}');
    }
    print('✅ Tokens stored successfully');
  }

  // Get access token (with auto-refresh if expired)
  Future<String?> getAccessToken() async {
    final expiresAt = await secureStorage.read(key: expiresAtKey);
    final currentTime = DateTime.now().millisecondsSinceEpoch.toString();

    if (expiresAt != null && int.parse(expiresAt) < int.parse(currentTime)) {
      await refreshToken();
    }

    return await secureStorage.read(key: accessTokenKey);
  }

  // Refresh the access token
  Future<bool> refreshToken() async {
    try {
      final refreshToken = await secureStorage.read(key: refreshTokenKey);

      if (refreshToken == null) {
        return false;
      }

      final TokenResponse? result = await appAuth.token(
        TokenRequest(
          clientId,
          redirectUrl,
          issuer: issuer,
          refreshToken: refreshToken,
          scopes: ['openid', 'profile', 'email', 'offline_access'],
          additionalParameters: {'audience': audience},
        ),
      );

      if (result != null) {
        await secureStorage.write(key: accessTokenKey, value: result.accessToken);

        if (result.refreshToken != null) {
          await secureStorage.write(key: refreshTokenKey, value: result.refreshToken);
        }

        final expiresAt = DateTime.now()
            .add(Duration(seconds: result.accessTokenExpirationDateTime!.second))
            .millisecondsSinceEpoch
            .toString();
        await secureStorage.write(key: expiresAtKey, value: expiresAt);

        return true;
      }
      return false;
    } catch (e) {
      print('Error refreshing token: $e');
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
      Uri.parse('https://$domain/userinfo'),
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
    await secureStorage.delete(key: accessTokenKey);
    await secureStorage.delete(key: refreshTokenKey);
    await secureStorage.delete(key: idTokenKey);
    await secureStorage.delete(key: expiresAtKey);
  }
}