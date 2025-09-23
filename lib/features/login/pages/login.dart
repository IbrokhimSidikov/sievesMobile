import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_routes.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cxWhite,
      appBar: AppBar(
        backgroundColor: AppColors.cxWhite,
        title:  Text('Login', style: TextStyle(
          fontSize: 30.sp,
          fontWeight: FontWeight.bold,
        ),),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            Text('welcome'),
            11.verticalSpace,
            CupertinoButton(
                child: Icon(Icons.home, color: AppColors.cxBlack, size: 30.sp,),
                onPressed: (){
                  context.push(AppRoutes.home);
                }
                )
          ],
        )
      )
    );
  }
}
