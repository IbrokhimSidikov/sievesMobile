import 'package:flutter/material.dart';
import 'dart:convert';
import '../../model/employee_model.dart';
import '../../model/identity_model.dart';
import '../api/api_service.dart';
import 'auth_service.dart';

class AuthManager {
  // Singleton pattern to share the same instance across the app
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  
  AuthManager._internal() {
    // Initialize services in the singleton
    final authService = AuthService();
    final apiService = ApiService(authService);
    this.authService = authService;
    this.apiService = apiService;
    
    // Set up callback for when token refresh fails in API calls
    apiService.onTokenRefreshFailed = () {
      print('🚨 Token refresh failed in API call - logging out user');
      _handleTokenExpired();
    };
    
    // Set up callback for when refresh token expires in background refresh
    authService.onRefreshTokenExpired = () {
      print('🚨 Refresh token expired in background - logging out user');
      _handleTokenExpired();
    };
  }

  late final AuthService authService;
  late final ApiService apiService;

  Identity? _currentIdentity;
  Identity? get currentIdentity => _currentIdentity;
  
  // Get employee ID from current identity
  int? get currentEmployeeId => _currentIdentity?.employee?.id;
  
  // Get current user role
  String? get currentUserRole => _currentIdentity?.role;
  
  // Check if user has required role for stopwatch access
  bool get hasStopwatchAccess {
    if (_currentIdentity == null) return false;
    final role = _currentIdentity!.role.toLowerCase();
    return role == 'admin' || 
           role == 'manager' || 
           role == 'teamleader' || 
           role == 'trainer' || 
           role == 'superadmin';
  }
  
  // Check if user has access to break order (branch == 2)
  bool get hasBreakAccess {
    if (_currentIdentity == null) return false;
    return _currentIdentity!.employee?.branchId == 2 || _currentIdentity!.employee?.branchId == 6;
  }
  
  // Callback for when session expires (refresh token failed)
  Function()? onSessionExpired;

  // Storage key for identity
  static const String _identityKey = 'user_identity';

  /// Save identity to secure storage for persistent login
  Future<void> _saveIdentity(Identity identity) async {
    try {
      final identityJson = json.encode(identity.toJson());
      await authService.secureStorage.write(key: _identityKey, value: identityJson);
      print('💾 Identity saved to secure storage');
    } catch (e) {
      print('❌ Error saving identity: $e');
    }
  }

  /// Restore session from secure storage
  Future<bool> restoreSession() async {
    try {
      print('🔄 Attempting to restore session...');
      
      // Check if we have a valid access token
      final accessToken = await authService.getAccessToken();
      
      // If getAccessToken returns null, it means refresh failed (refresh token expired)
      if (accessToken == null) {
        print('ℹ️ Access token is null - refresh token likely expired, clearing session');
        await logout(); // Clear any remaining data
        return false;
      }

      // Try to load saved identity
      final identityJson = await authService.secureStorage.read(key: _identityKey);
      if (identityJson == null) {
        print('ℹ️ No saved identity found');
        return false;
      }

      // Parse the identity
      final identityMap = json.decode(identityJson) as Map<String, dynamic>;
      _currentIdentity = Identity.fromJson(identityMap);
      
      print('✅ Session restored successfully');
      print('   User: ${_currentIdentity!.email}');
      print('   Employee ID: ${currentEmployeeId}');
      
      // Start proactive token refresh timer
      authService.startProactiveRefresh();
      
      return true;
    } catch (e) {
      print('❌ Error restoring session: $e');
      // Clear invalid data
      await authService.secureStorage.delete(key: _identityKey);
      return false;
    }
  }

  /// Refresh identity data from API
  Future<void> refreshIdentity() async {
    if (_currentIdentity == null) return;
    
    try {
      print('🔄 Refreshing identity data...');
      final authId = _currentIdentity!.authId;
      
      final identity = await apiService.getIdentityByAuthId(authId);
      if (identity != null) {
        _currentIdentity = identity;
        await _saveIdentity(identity);
        print('✅ Identity data refreshed');
        print('📸 Photo URL after refresh: ${identity.employee?.individual?.photoUrl}');
      }
    } catch (e) {
      print('❌ Error refreshing identity: $e');
    }
  }

  /// Ensure photo data is loaded for face verification
  Future<String?> getProfilePhotoUrl() async {
    // First check if we already have the photo URL
    if (_currentIdentity?.employee?.individual?.photoUrl != null) {
      print('✅ Photo URL found in current identity: ${_currentIdentity!.employee!.individual!.photoUrl}');
      return _currentIdentity!.employee!.individual!.photoUrl;
    }

    // If not, refresh the identity to get the latest data with photo
    print('⚠️ Photo URL not found in current identity, refreshing...');
    await refreshIdentity();

    // Check again after refresh
    if (_currentIdentity?.employee?.individual?.photoUrl != null) {
      print('✅ Photo URL found after refresh: ${_currentIdentity!.employee!.individual!.photoUrl}');
      return _currentIdentity!.employee!.individual!.photoUrl;
    }

    print('❌ Photo URL still not available after refresh');
    return null;
  }

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
      print('User info:  ${userInfo}');


      // 3. Get access token for API calls
      print('3️⃣ Getting access token...');
      final accessToken = await authService.getAccessToken();
      if (accessToken == null) {
        print('❌ Failed to get access token');
        return false;
      }
      print('✅ Access token received');
      print('   Token: $accessToken');

      // 4. Get identity from backend API
      print('4️⃣ Fetching identity from backend API...');
      final authId = userInfo['sub'] as String;

      print('Auth ID: $authId');
      
      try {
        final identity = await apiService.getIdentityByAuthId(authId);
        if (identity == null) {
          print('❌ Failed to get identity from backend API');
          return true;
        }
        
        print('✅ Identity received from backend API');
        print('   Identity ID: ${identity.id}');
        print('   Email: ${identity.email}');
        print('   Username: ${identity.username}');
        print('   Role: ${identity.role}');
        
        // Store the real identity from backend
        _currentIdentity = identity;
        
        // Save identity to secure storage for persistent login
        await _saveIdentity(identity);
        
        // 🔍 LOG ALL AVAILABLE USER DATA
        print('');
        print('📊 ========== COMPLETE USER DATA AFTER LOGIN ==========');
        print('');
        
        // Core Identity Information
        print('👤 IDENTITY INFORMATION:');
        print('   ID: ${identity.id}');
        print('   Auth ID: ${identity.authId}');
        print('   Email: ${identity.email}');
        print('   Username: ${identity.username}');
        print('   Role: ${identity.role}');
        print('   Phone: ${identity.phone ?? 'Not provided'}');
        print('   Allowance: \$${identity.allowance}');
        print('   Token: ${identity.token?.substring(0, 20)}...');
        print('');
        
        // Employee Information
        if (identity.employee != null) {
          print('👔 EMPLOYEE INFORMATION:');
          print('   Employee ID: ${identity.employee!.id}');
          print('   Status: ${identity.employee!.status}');
          print('   Company ID: ${identity.employee!.companyId ?? 'Not set'}');
          print('   Branch ID: ${identity.employee!.branchId ?? 'Not set'}');
          print('   Department ID: ${identity.employee!.departmentId ?? 'Not set'}');
          print('');
          
          // Personal Information
          if (identity.employee!.individual != null) {
            print('🧑 PERSONAL INFORMATION:');
            print('   First Name: ${identity.employee!.individual!.firstName}');
            print('   Last Name: ${identity.employee!.individual!.lastName}');
            print('   Full Name: ${identity.employee!.individual!.firstName} ${identity.employee!.individual!.lastName}');
            print('   Personal Email: ${identity.employee!.individual!.email}');
            print('   Personal Phone: ${identity.employee!.individual!.phone ?? 'Not provided'}');
            print('');
        }
        
          // Branch Information
          if (identity.employee!.branch != null) {
            print('🏢 BRANCH INFORMATION:');
            print('   Branch Name: ${identity.employee!.branch!.name}');
            print('   Branch Address: ${identity.employee!.branch!.address}');
            print('');
          }
        }
        
        // Raw Auth0 Data
        print('🔐 RAW AUTH0 DATA:');
        userInfo.forEach((key, value) {
          print('   $key: $value');
        });
        print('');
        print('📊 ================================================');
        print('');
        
        print('🎉 Complete login flow successful!');
        return true;
        
      } catch (apiError) {
        print('❌ Backend API error: $apiError');
        print('Error type: ${apiError.runtimeType}');
        return false;
      }
    } catch (e) {
      print('❌ Login flow error: $e');
      print('Error type: ${e.runtimeType}');
      return false;
    }
  }

  // Handle when token refresh fails (refresh token expired)
  Future<void> _handleTokenExpired() async {
    print('⏰ Refresh token expired - clearing session');
    await logout();
    // Notify listeners that session has expired
    onSessionExpired?.call();
  }

  // Logout
  Future<void> logout() async {
    print('📋 [AuthManager] Starting logout...');
    
    print('   → Calling AuthService.logout()...');
    await authService.logout();
    print('   ✅ AuthService.logout() completed');
    
    print('   → Deleting identity from secure storage...');
    await authService.secureStorage.delete(key: _identityKey);
    print('   ✅ Identity deleted from secure storage');
    
    print('   → Clearing current identity in memory...');
    _currentIdentity = null;
    print('   ✅ Current identity cleared');
    
    print('✅ [AuthManager] Logout completed');
  }
}