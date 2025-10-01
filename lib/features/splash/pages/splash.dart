import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_cubit.dart';
import '../../../core/services/auth/auth_state.dart';

/// Splash screen that checks authentication status on app startup
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Check authentication status when splash screen loads
    context.read<AuthCubit>().checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // Navigate based on authentication state
        if (state is AuthAuthenticated) {
          // User is logged in, go to home
          context.go('/home');
        } else if (state is AuthUnauthenticated) {
          // User is not logged in, go to onboard
          context.go('/onboard');
        }
        // Stay on splash for AuthInitial and AuthLoading states
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cx43C19F,
                AppColors.cx4AC1A7,
                AppColors.cx3FBDA3,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                Container(
                  width: 120.w,
                  height: 120.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/sieves_gradient_3d.png',
                      width: 80.w,
                      height: 80.h,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.business,
                          size: 60.sp,
                          color: AppColors.cx43C19F,
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 32.h),
                // App Name
                Text(
                  'Sieves',
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Employee Management',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 48.h),
                // Loading indicator
                SizedBox(
                  width: 40.w,
                  height: 40.h,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3.w,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
