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

  // Dark Theme - Professional & Modern
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF6366F1), // Modern indigo
    scaffoldBackgroundColor: const Color(0xFF0F0F14), // Deep dark background
    
    // AppBar styling
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A24), // Elevated dark surface
      foregroundColor: Color(0xFFE8E8F0),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE8E8F0),
        letterSpacing: 0.15,
      ),
    ),
    
    // Color scheme
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6366F1), // Indigo
      primaryContainer: Color(0xFF4F46E5),
      secondary: Color(0xFF34D399), // Emerald
      secondaryContainer: Color(0xFF10B981),
      tertiary: Color(0xFFA78BFA), // Purple
      surface: Color(0xFF1A1A24), // Card/surface background
      surfaceContainerHighest: Color(0xFF252532), // Elevated surface
      error: Color(0xFFEF4444), // Modern red
      onPrimary: Color(0xFFFFFFFF),
      onSecondary: Color(0xFF000000),
      onSurface: Color(0xFFE8E8F0), // Primary text
      onSurfaceVariant: Color(0xFF9CA3AF), // Secondary text
      onError: Color(0xFFFFFFFF),
      outline: Color(0xFF374151), // Borders
      shadow: Color(0xFF000000),
      surfaceTint: Color(0xFF6366F1),
    ),
    
    // Card styling
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1A24),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // Divider styling
    dividerTheme: const DividerThemeData(
      color: Color(0xFF252532),
      thickness: 1,
      space: 1,
    ),
    
    // Input decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A24),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF374151)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF374151)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
    ),
    
    // Text theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE8E8F0),
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE8E8F0),
        letterSpacing: -0.25,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE8E8F0),
      ),
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE8E8F0),
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE8E8F0),
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE8E8F0),
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE8E8F0),
        letterSpacing: 0.15,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFFE8E8F0),
        letterSpacing: 0.15,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Color(0xFFD1D5DB),
        letterSpacing: 0.1,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: Color(0xFFD1D5DB),
        letterSpacing: 0.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.25,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: Color(0xFF6B7280),
        letterSpacing: 0.4,
      ),
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFFE8E8F0),
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Color(0xFF9CA3AF),
        letterSpacing: 0.5,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B7280),
        letterSpacing: 0.5,
      ),
    ),
    
    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF6366F1),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.25,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6366F1),
        side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Icon theme
    iconTheme: const IconThemeData(
      color: Color(0xFF9CA3AF),
      size: 24,
    ),
    
    // Bottom navigation bar
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A24),
      selectedItemColor: Color(0xFF6366F1),
      unselectedItemColor: Color(0xFF6B7280),
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ),
    ),
    
    // Floating action button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF6366F1),
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    
    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF252532),
      selectedColor: const Color(0xFF6366F1).withOpacity(0.2),
      labelStyle: const TextStyle(color: Color(0xFFE8E8F0)),
      secondaryLabelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    
    // Dialog theme
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1A1A24),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFFE8E8F0),
      ),
      contentTextStyle: const TextStyle(
        fontSize: 16,
        color: Color(0xFF9CA3AF),
      ),
    ),
    
    // Snackbar theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF252532),
      contentTextStyle: const TextStyle(color: Color(0xFFE8E8F0)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
    ),
    
    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFFFFFFFF);
        }
        return const Color(0xFF6B7280);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF6366F1);
        }
        return const Color(0xFF374151);
      }),
    ),
    
    // Progress indicator theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF6366F1),
      circularTrackColor: Color(0xFF252532),
    ),
  );
}