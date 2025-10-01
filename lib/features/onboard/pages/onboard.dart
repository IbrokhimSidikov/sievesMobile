import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/auth/auth_cubit.dart';
import '../../../core/services/auth/auth_state.dart';

class Onboard extends StatefulWidget {
  const Onboard({super.key});

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
  void _handleLogin() {
    // Trigger login via AuthCubit
    context.read<AuthCubit>().login(context);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // Handle navigation and notifications based on auth state
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.home);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.cxRoyalBlue,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cxSoftWhite,
                AppColors.cxPlatinumGray.withOpacity(0.3),
                AppColors.cxPureWhite,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cxRoyalBlue.withOpacity(0.15),
                          blurRadius: 30,
                          offset: Offset(0, 15),
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      AppImages.sievesWhite3D,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.cxRoyalBlue,
                          AppColors.cxEmeraldGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cxRoyalBlue.withOpacity(0.3),
                          blurRadius: 30,
                          offset: Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: _handleLogin,
                        child: BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isLoading) ...[
                                    SizedBox(
                                      width: 20.w,
                                      height: 20.h,
                                      child: CircularProgressIndicator(
                                        color: AppColors.cxPureWhite,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Text(
                                      'Logging in...',
                                      style: TextStyle(
                                        color: AppColors.cxPureWhite,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: EdgeInsets.all(8.r),
                                      decoration: BoxDecoration(
                                        color: AppColors.cxPureWhite.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8.r),
                                      ),
                                      child: Icon(
                                        Icons.fingerprint_rounded,
                                        color: AppColors.cxPureWhite,
                                        size: 24.sp,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Text(
                                      'Sign In with Auth0',
                                      style: TextStyle(
                                        color: AppColors.cxPureWhite,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                40.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
