import 'package:flutter/material.dart';

abstract class AppColors{
  static const Color cx43C19F = Color(0xFF43C19F);
  static const Color cx292B2F = Color(0xFF292B2F);
  static const Color cxF5F7F9 = Color(0xFFF5F7F9);
  static const Color cxF5F6F9 = Color(0xFFF5F6F9);
  static const Color cxBlack = Color(0xFF000000);
  static const Color cxWhite = Color(0xFFFFFFFF);
  static const Color cx4AC1A7 = Color(0xFF4AC1A7);
  static const Color cxAFB1B1 = Color(0xFFAFB1B1);
  static const Color cxF7F6F9 = Color(0xFFF7F6F9);
  static const Color cx78D9BF = Color(0xFF78D9BF);
  static const Color cxFEDA84 = Color(0xFFFEDA84);
  static const Color cxFFBCFA = Color(0xFFFFBCFA);
  static const Color cxFF8B92 = Color(0xFFFF8B92);
  static const Color cxFEC700 = Color(0xFFFEC700);
  static const Color cx02D5F5 = Color(0xFF02D5F5);
  static const Color cx3FBDA3 = Color(0xFF3FBDA3);

  static const Color cxDADADA = Color(0xFFDADADA);
  static const Color cxADADAD = Color(0xFFADADAD);
  static const Color cxB0B0B0 = Color(0xFFB0B0B0);
  static const Color cxD9D9D9 = Color(0xFFD9D9D9);

  // Onboard page colors
  static const Color cxDarkCharcoal = Color(0xFF0D0D0D);
  static const Color cxSoftWhite = Color(0xFFF5F5F7);
  static const Color cxGraphiteGray = Color(0xFF1C1C1E);

  // Accent Colors
  static const Color cxRoyalBlue = Color(0xFF0071E3);
  static const Color cxEmeraldGreen = Color(0xFF34C759);
  static const Color cxAmberGold = Color(0xFFFFD60A);
  static const Color cxCrimsonRed = Color(0xFFFF3B30);

  // Supporting Neutrals
  static const Color cxPlatinumGray = Color(0xFFE5E5EA);
  static const Color cxSilverTint = Color(0xFFA1A1A6);
  static const Color cxPureWhite = Color(0xFFFFFFFF);

  // Primary brand color
  static const Color cxPrimary = Color(0xFF4A90E2); // Elegant blue

  // Status colors
  static const Color cxSuccess = Color(0xFF34C759); // Green (attendance, success)
  static const Color cxWarning = Color(0xFFFF9500); // Orange (break records, caution)
  static const Color cxBlue    = Color(0xFF007AFF); // Bright iOS blue (history)
  static const Color cxPurple  = Color(0xFFAF52DE); // Purple (achievements)
}

class AppTheme {
  // Light Theme
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.cxRoyalBlue,
    scaffoldBackgroundColor: AppColors.cxSoftWhite,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cxSoftWhite,
      foregroundColor: AppColors.cxDarkCharcoal,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.light(
      primary: AppColors.cxRoyalBlue,
      secondary: AppColors.cxEmeraldGreen,
      surface: AppColors.cxSoftWhite,
      error: AppColors.cxCrimsonRed,
      onPrimary: AppColors.cxPureWhite,
      onSecondary: AppColors.cxPureWhite,
      onSurface: AppColors.cxDarkCharcoal,
      onError: AppColors.cxPureWhite,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.cxDarkCharcoal,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.cxGraphiteGray,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.cxSilverTint,
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.cxRoyalBlue,
      textTheme: ButtonTextTheme.primary,
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.cxRoyalBlue,
    scaffoldBackgroundColor: AppColors.cxDarkCharcoal,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cxDarkCharcoal,
      foregroundColor: AppColors.cxSoftWhite,
      elevation: 0,
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cxRoyalBlue,
      secondary: AppColors.cxEmeraldGreen,
      surface: AppColors.cxGraphiteGray,
      error: AppColors.cxCrimsonRed,
      onPrimary: AppColors.cxPureWhite,
      onSecondary: AppColors.cxPureWhite,
      onSurface: AppColors.cxSoftWhite,
      onError: AppColors.cxPureWhite,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.cxSoftWhite,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: AppColors.cxPlatinumGray,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.cxSilverTint,
      ),
    ),
    buttonTheme: const ButtonThemeData(
      buttonColor: AppColors.cxRoyalBlue,
      textTheme: ButtonTextTheme.primary,
    ),
  );
}