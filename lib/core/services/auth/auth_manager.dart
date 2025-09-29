import 'package:flutter/material.dart';
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
    final auth0Service = Auth0Service();
    final apiService = ApiService(auth0Service);
    authService = auth0Service;
    this.apiService = apiService;
  }

  late final Auth0Service authService;
  late final ApiService apiService;

  Identity? _currentIdentity;
  Identity? get currentIdentity => _currentIdentity;
  
  // Get employee ID from current identity
  int? get currentEmployeeId => _currentIdentity?.employee?.id;

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

  // Logout
  Future<void> logout() async {
    await authService.logout();
    _currentIdentity = null;
  }
}