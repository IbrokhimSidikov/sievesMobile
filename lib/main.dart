import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/constants/app_colors.dart';
import 'core/router/app_routes.dart';
import 'core/services/auth/auth_cubit.dart';
import 'core/services/auth/auth_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Provide AuthCubit to the entire app
      create: (context) => AuthCubit(AuthManager()),
      child: ScreenUtilInit(
        designSize: const Size(393, 852),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, child) {
          return MaterialApp.router(
            title: 'Sieves Mobile App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme.copyWith(
              textTheme: GoogleFonts.nunitoTextTheme(
                Theme.of(context).textTheme,
              ),
            ),
            darkTheme: AppTheme.darkTheme.copyWith(
                textTheme: GoogleFonts.nunitoTextTheme(
                    Theme.of(context).textTheme,
                )),
            themeMode: ThemeMode.system,
            routerConfig: AppRoutes.router,
          );
        },
      ),
    );
  }
}