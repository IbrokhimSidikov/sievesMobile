import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/router/app_routes.dart';

class Onboard extends StatefulWidget {
  const Onboard({super.key});

  @override
  State<Onboard> createState() => _OnboardState();
}

class _OnboardState extends State<Onboard> {
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
                      onTap: () {
                        context.push(AppRoutes.login);
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
