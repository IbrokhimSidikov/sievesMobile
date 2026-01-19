import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/auth/auth_cubit.dart';
import '../../../core/services/auth/auth_state.dart';
import '../../../core/utils/responsive_helper.dart';

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
                  padding: ResponsiveHelper.rPadding(
                    context,
                    horizontal: 40,
                    tabletMultiplier: 2.5,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveHelper.isTablet(context) ? 450 : double.infinity,
                    ),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cxRoyalBlue.withOpacity(0.15),
                          blurRadius: ResponsiveHelper.rw(context, 30, 40),
                          offset: Offset(0, ResponsiveHelper.rh(context, 15, 20)),
                          spreadRadius: ResponsiveHelper.rw(context, -5, -8),
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
                  padding: ResponsiveHelper.rPadding(
                    context,
                    horizontal: 40,
                    tabletMultiplier: 2.5,
                  ),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxWidth: ResponsiveHelper.isTablet(context) ? 450 : double.infinity,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.cxRoyalBlue,
                          AppColors.cxEmeraldGreen,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(
                        ResponsiveHelper.rr(context, 30, 36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cxRoyalBlue.withOpacity(0.3),
                          blurRadius: ResponsiveHelper.rw(context, 30, 40),
                          offset: Offset(0, ResponsiveHelper.rh(context, 15, 20)),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          ResponsiveHelper.rr(context, 16, 20),
                        ),
                        onTap: _handleLogin,
                        child: BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            final isLoading = state is AuthLoading;
                            
                            return Padding(
                              padding: ResponsiveHelper.rPadding(
                                context,
                                vertical: 12,
                                tabletMultiplier: 1.3,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isLoading) ...[
                                    SizedBox(
                                      width: ResponsiveHelper.rw(context, 20, 24),
                                      height: ResponsiveHelper.rh(context, 20, 24),
                                      child: CircularProgressIndicator(
                                        color: AppColors.cxPureWhite,
                                        strokeWidth: ResponsiveHelper.isTablet(context) ? 2.5 : 2,
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveHelper.rw(context, 8, 12)),
                                    Flexible(
                                      child: Text(
                                        'Logging in...',
                                        style: TextStyle(
                                          color: AppColors.cxPureWhite,
                                          fontSize: ResponsiveHelper.rsp(context, 18, 22),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ] else ...[
                                    Container(
                                      padding: EdgeInsets.all(
                                        ResponsiveHelper.rr(context, 8, 10),
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.cxPureWhite.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                          ResponsiveHelper.rr(context, 8, 10),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.fingerprint_rounded,
                                        color: AppColors.cxPureWhite,
                                        size: ResponsiveHelper.rsp(context, 24, 28),
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveHelper.rw(context, 12, 16)),
                                    Flexible(
                                      child: Text(
                                        'Sign In with Auth0',
                                        style: TextStyle(
                                          color: AppColors.cxPureWhite,
                                          fontSize: ResponsiveHelper.rsp(context, 18, 22),
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
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
                ResponsiveHelper.rVerticalSpace(context, 40, 60),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
