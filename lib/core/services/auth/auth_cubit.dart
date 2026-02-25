import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_manager.dart';
import 'auth_state.dart';
import '../cache/menu_cache_service.dart';

/// Cubit for managing authentication state throughout the app
class AuthCubit extends Cubit<AuthState> {
  final AuthManager _authManager;
  final MenuCacheService _cacheService = MenuCacheService();

  AuthCubit(this._authManager) : super(const AuthInitial()) {
    // Set up callback for when session expires automatically
    _authManager.onSessionExpired = () {
      print('🔔 Session expired notification received');
      emit(const AuthError('Your session has expired. Please log in again.'));
      // After showing error, return to unauthenticated state
      Future.delayed(const Duration(seconds: 3), () {
        if (!isClosed) {
          emit(const AuthUnauthenticated());
        }
      });
    };
  }

  /// Check if user is already authenticated on app startup
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());
    
    try {
      print('🔍 Checking authentication status...');
      
      // Try to restore session from secure storage
      final isAuthenticated = await _authManager.restoreSession();
      
      if (isAuthenticated && _authManager.currentIdentity != null) {
        print('✅ Session restored successfully');
        emit(AuthAuthenticated(_authManager.currentIdentity!));
        
        // Preload menu data in background after successful authentication
        _preloadMenuData();
      } else {
        print('ℹ️ No valid session found');
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      print('❌ Error checking auth status: $e');
      emit(const AuthUnauthenticated());
    }
  }

  /// Perform login flow
  Future<void> login(BuildContext context) async {
    emit(const AuthLoading());
    
    try {
      print('🔐 Starting login flow...');
      
      final success = await _authManager.login(context);
      
      if (success && _authManager.currentIdentity != null) {
        print('✅ Login successful');
        emit(AuthAuthenticated(_authManager.currentIdentity!));
        
        // Preload menu data in background after successful login
        _preloadMenuData();
      } else {
        print('❌ Login failed');
        emit(const AuthError('Login failed. Please try again.'));
        // Return to unauthenticated after showing error
        await Future.delayed(const Duration(seconds: 2));
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      print('❌ Login error: $e');
      emit(AuthError('Login error: ${e.toString()}'));
      // Return to unauthenticated after showing error
      await Future.delayed(const Duration(seconds: 2));
      emit(const AuthUnauthenticated());
    }
  }

  /// Perform logout
  Future<void> logout() async {
    try {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('🚪 [AuthCubit] Starting logout process...');
      print('═══════════════════════════════════════════════════════');
      
      print('1️⃣ [AuthCubit] Calling AuthManager.logout()...');
      await _authManager.logout();
      print('✅ [AuthCubit] AuthManager.logout() completed');
      
      print('2️⃣ [AuthCubit] Emitting AuthUnauthenticated state...');
      emit(const AuthUnauthenticated());
      print('✅ [AuthCubit] AuthUnauthenticated state emitted');
      
      print('═══════════════════════════════════════════════════════');
      print('✅ [AuthCubit] Logout process completed successfully');
      print('═══════════════════════════════════════════════════════');
      print('');
    } catch (e, stackTrace) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('❌ [AuthCubit] Logout error occurred');
      print('═══════════════════════════════════════════════════════');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('═══════════════════════════════════════════════════════');
      print('');
      emit(AuthError('Logout error: ${e.toString()}'));
    }
  }

  /// Refresh user identity data
  Future<void> refreshIdentity() async {
    if (state is! AuthAuthenticated) return;
    
    try {
      print('🔄 Refreshing identity data...');
      await _authManager.refreshIdentity();
      
      if (_authManager.currentIdentity != null) {
        emit(AuthAuthenticated(_authManager.currentIdentity!));
        print('✅ Identity refreshed');
      }
    } catch (e) {
      print('❌ Error refreshing identity: $e');
      // Keep the current state on error
    }
  }

  /// Preload menu data in background (non-blocking)
  void _preloadMenuData() {
    print('🚀 [AuthCubit] _preloadMenuData() called - starting background preload');
    // Run in background without blocking the UI
    Future.microtask(() async {
      try {
        print('📥 [AuthCubit] Executing preloadMenuData...');
        await _cacheService.preloadMenuData(
          _authManager.apiService.getInventoryMenu,
          _authManager.apiService.getPosCategories,
        );
        print('✅ [AuthCubit] Preload completed successfully');
      } catch (e) {
        print('❌ [AuthCubit] Menu preload error: $e');
        // Silently fail - this is a background optimization
      }
    });
  }
}
