import 'dart:convert';

import '../../model/identity_model.dart';
import '../api/api_service.dart';
import 'auth_service.dart';
import 'login_exception.dart';
import '../notification/notification_service.dart';

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

  // Get the branch the current employee belongs to
  int? get currentBranchId => _currentIdentity?.employee?.branchId;
  
  // Get current employee status (online/offline)
  String? get currentEmployeeStatus => _currentIdentity?.employee?.status;
  
  // Check if employee is online
  bool get isEmployeeOnline => currentEmployeeStatus?.toLowerCase() == 'online';
  
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

  // Roles allowed to mark intro-training checklist items done for an employee.
  bool get canManageIntroTrainings {
    if (_currentIdentity == null) return false;
    final role = _currentIdentity!.role.toLowerCase();
    return role == 'admin' ||
        role == 'manager' ||
        role == 'teamleader' ||
        role == 'trainer' ||
        role == 'superadmin';
  }

  bool get hasCancelAccess {
    if (_currentIdentity == null) return false;
    final role = _currentIdentity!.role.toLowerCase();
    return role == 'admin' ||
           role == 'manager' ||
           role == 'teamleader' ||
           role == 'trainer' ||
           role == 'superadmin' ||
           role == 'cashier';
  }
  
  // Branches whose managers order break for their OWN branch: unlimited orders,
  // no lunch-time window, and the order is routed to their own branch_id.
  static const List<int> breakOwnBranchIds = [3, 4, 5, 11, 14, 25];

  // Check if user has access to break order.
  // Branch 2 or 6 keep their existing access (any role); managers of the
  // own-branch list can also order.
  bool get hasBreakAccess {
    if (_currentIdentity == null) return false;
    final branchId = _currentIdentity!.employee?.branchId;
    if (branchId == 2 || branchId == 6) return true;
    final role = _currentIdentity!.role.toLowerCase();
    return role == 'manager' && breakOwnBranchIds.contains(branchId);
  }

  // True when the current employee belongs to an own-branch break branch
  // (unlimited orders, no time window, order routed to their own branch).
  bool get isBreakOwnBranchUser {
    final branchId = _currentIdentity?.employee?.branchId;
    return branchId != null && breakOwnBranchIds.contains(branchId);
  }

  // Work-entry (face verification) for own-branch managers is geofenced to
  // their branch location. Break orders are NOT geofenced.
  bool get requiresBranchGeofence => isBreakOwnBranchUser;

  // Destination branch for a break order. Own-branch users route to their own
  // branch; everyone else (branch 2, 6, office) routes to Boulevard (14).
  int? get breakOrderBranchId {
    final branchId = _currentIdentity?.employee?.branchId;
    if (branchId == null) return null;
    if (breakOwnBranchIds.contains(branchId)) return branchId;
    return 14;
  }
  
  // Check if user has access to checklists (admin, manager, teamleader, trainer, superadmin)
  bool get hasChecklistAccess {
    if (_currentIdentity == null) return false;
    final role = _currentIdentity!.role.toLowerCase();
    return role == 'admin' || 
           role == 'manager' || 
           role == 'teamleader' || 
           role == 'trainer' || 
           role == 'superadmin';
  }

  //planshet uchun, break and face verification work entry ga
  bool get hasFaceIdAccess {
    if(_currentIdentity == null) return false;
    final role = _currentIdentity!.role.toLowerCase();

    return role == 'faceId';

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

  /// Signs in with username / password, then loads the backend identity.
  ///
  /// Throws [LoginException]; never returns false silently, so the UI can
  /// show a specific message.
  Future<Identity> loginWithPassword({
    required String username,
    required String password,
  }) async {
    print('🔄 Starting password login flow...');

    // 1. Auth0 password grant → tokens stored, subject returned.
    final authId = await authService.loginWithPassword(
      username: username,
      password: password,
    );

    // 2. Backend identity for that subject.
    final Identity? identity;
    try {
      identity = await apiService.getIdentityByAuthId(authId);
    } catch (e) {
      print('❌ Backend identity error: $e');
      throw LoginException(LoginErrorType.network, e.toString());
    }
    if (identity == null) {
      // Tokens are useless without an identity; do not leave a half session.
      await authService.logout();
      throw const LoginException(LoginErrorType.identityNotFound);
    }

    print('✅ Identity received: id=${identity.id} role=${identity.role}');
    _currentIdentity = identity;
    await _saveIdentity(identity);
    await _sendFcmTokenToBackend();
    return identity;
  }

  // Send FCM token to backend after login
  Future<void> _sendFcmTokenToBackend() async {
    try {
      print('📲 [AuthManager] Sending FCM token to backend...');
      
      final employeeId = currentEmployeeId;
      if (employeeId == null) {
        print('⚠️ [AuthManager] No employee ID available, cannot send FCM token');
        return;
      }
      
      // Get FCM token - fetches from Firebase directly if not cached yet
      final notificationService = NotificationService();
      final fcmToken = await notificationService.getOrFetchToken();
      
      if (fcmToken == null) {
        print('⚠️ [AuthManager] FCM token unavailable even after fetch, skipping');
        return;
      }
      
      // POST token to backend
      final success = await apiService.sendFcmToken(employeeId, fcmToken);
      
      if (success) {
        print('✅ [AuthManager] FCM token sent successfully for employee $employeeId');
      } else {
        print('❌ [AuthManager] Failed to send FCM token');
      }
    } catch (e) {
      print('❌ [AuthManager] Exception sending FCM token: $e');
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
    
    print('   → Deleting FCM token from backend and device...');
    try {
      final employeeId = currentEmployeeId;
      if (employeeId != null) {
        await apiService.deleteFcmToken(employeeId);
      }
      final notificationService = NotificationService();
      await notificationService.deleteToken();
      print('   ✅ FCM token deleted');
    } catch (e) {
      print('   ⚠️ Error deleting FCM token: $e');
    }
    
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