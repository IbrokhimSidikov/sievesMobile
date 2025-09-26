import 'package:flutter/material.dart';
import '../../model/identity_model.dart';
import '../api/api_service.dart';
import 'auth_service.dart';

class AuthManager {
  final Auth0Service authService;
  final ApiService apiService;

  Identity? _currentIdentity;
  Identity? get currentIdentity => _currentIdentity;

  AuthManager({
    required this.authService,
    required this.apiService,
  });

  // Complete login flow
  Future<bool> login(BuildContext context) async {
    try {
      print('🔄 Starting complete login flow...');
      
      // 1. Authenticate with Auth0
      print('1️⃣ Authenticating with Auth0...');
      final loginSuccess = await authService.login();
      if (!loginSuccess) {
        print('❌ Auth0 authentication failed');
        return false;
      }
      print('✅ Auth0 authentication successful');

      // 2. Get user info from Auth0
      print('2️⃣ Getting user info from Auth0...');
      final userInfo = await authService.getUserInfo();
      if (userInfo == null) {
        print('❌ Failed to get user info from Auth0');
        return false;
      }
      print('✅ User info received: ${userInfo['email']}');

      // 3. Get identity from API using Auth0 ID
      print('3️⃣ Getting identity from API...');
      final authId = userInfo['sub'] as String;
      print('Auth ID: $authId');
      final identity = await apiService.getIdentityByAuthId(authId);
      if (identity == null) {
        print('❌ Failed to get identity from API');
        return false;
      }
      print('✅ Identity received: ${identity.username}');

      // 4. Get access token
      print('4️⃣ Getting access token...');
      final accessToken = await authService.getAccessToken();
      if (accessToken == null) {
        print('❌ Failed to get access token');
        return false;
      }
      print('✅ Access token received');

      // 5. Update identity with token
      print('5️⃣ Updating identity with token...');
      identity.token = accessToken;
      final updatedIdentity = await apiService.updateIdentityToken(identity.id!, accessToken);
      if (updatedIdentity == null) {
        print('❌ Failed to update identity with token');
        return false;
      }
      print('✅ Identity updated with token');

      // 6. Store identity
      _currentIdentity = updatedIdentity;
      print('🎉 Complete login flow successful!');

      return true;
    } catch (e) {
      print('❌ Login flow error: $e');
      print('Error type: ${e.runtimeType}');
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await authService.logout();
    _currentIdentity = null;
  }
}