import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/api/api_service.dart';

class Onboard extends StatefulWidget {
  const Onboard({super.key});

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
  bool _isLoading = false;
  late AuthManager _authManager;

  @override
  void initState() {
    super.initState();
    // Initialize AuthManager with Auth0Service and ApiService
    final auth0Service = Auth0Service();
    final apiService = ApiService(auth0Service);
    _authManager = AuthManager(
      authService: auth0Service,
      apiService: apiService,
    );
  }


  Future<void> _handleLogin() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the new AuthManager for complete login flow
      final loginSuccess = await _authManager.login(context);

      if (!mounted) return;

      if (loginSuccess) {
        // Login successful - user profile and identity are now stored
        final identity = _authManager.currentIdentity;
        print('Login successful! User: ${identity?.username}');
        
        context.go(AppRoutes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Login canceled or failed. Please try again.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ));
      }
    } catch (e) {
      if (!mounted) return;

      print('Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Authentication error: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 4),
      ));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      onTap: _isLoading ? null : _handleLogin,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isLoading) ...[
                              SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  color: AppColors.cxPureWhite,
                                  strokeWidth: 2,
                                ),
                              ),
                              12.horizontalSpace,
                              Text(
                                'Kirish...',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cxPureWhite,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Davom etish',
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cxPureWhite,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              12.horizontalSpace,
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.cxPureWhite,
                                size: 24.sp,
                              ),
                            ],
                          ],
                        ),
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
    );
  }
}
