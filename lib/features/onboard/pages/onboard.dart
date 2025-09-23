import 'package:flutter/cupertino.dart';
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
      backgroundColor: AppColors.cxWhite,
      appBar: AppBar(
        backgroundColor: AppColors.cxWhite,
      ),
      body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Image.asset(AppImages.sievesGradient3D),
              11.verticalSpace,
              Text(
                'Xush kelibsiz!',
                style: TextStyle(
                  fontSize: 24.sp,
                )
              ),
              11.verticalSpace,
              CupertinoButton(
                  child: Icon(Icons.arrow_forward, color: AppColors.cxBlack, size: 30.sp,),
                  onPressed: () {
                      context.push(AppRoutes.login);
                  },
              )
            ],
          ),
      ),
    );
  }
}
