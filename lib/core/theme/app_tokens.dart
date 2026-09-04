import 'package:flutter/material.dart';

/// Semantic color tokens for both modes. See design.md §2–§3.
///
/// Feature code reads these through `context.tokens` and never branches on
/// brightness or hard-codes a hex value.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.primary,
    required this.primaryContainer,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.surfaceTint,
    required this.outline,
    required this.outlineStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.shadow,
  });

  final Color primary;
  final Color primaryContainer;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceTint;
  final Color outline;
  final Color outlineStrong;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color shadow;

  /// Text and icons placed on [primary], a feature accent or a hero gradient.
  Color get textOnAccent => const Color(0xFFFFFFFF);

  static const AppTokens light = AppTokens(
    primary: Color(0xFF4F46E5),
    primaryContainer: Color(0xFFEEF2FF),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    error: Color(0xFFDC2626),
    info: Color(0xFF2563EB),
    background: Color(0xFFF5F5F7),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF),
    surfaceTint: Color(0xFFF3F4F6),
    outline: Color(0xFFE5E7EB),
    outlineStrong: Color(0xFFD1D5DB),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    shadow: Color(0x0F0F172A),
  );

  static const AppTokens dark = AppTokens(
    primary: Color(0xFF6366F1),
    primaryContainer: Color(0xFF312E81),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    error: Color(0xFFEF4444),
    info: Color(0xFF60A5FA),
    background: Color(0xFF0F0F14),
    surface: Color(0xFF1A1A24),
    surfaceElevated: Color(0xFF252532),
    surfaceTint: Color(0xFF20202B),
    outline: Color(0xFF2E2E3D),
    outlineStrong: Color(0xFF374151),
    textPrimary: Color(0xFFE8E8F0),
    textSecondary: Color(0xFF9CA3AF),
    textTertiary: Color(0xFF6B7280),
    shadow: Color(0x59000000),
  );

  @override
  AppTokens copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? success,
    Color? warning,
    Color? error,
    Color? info,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? surfaceTint,
    Color? outline,
    Color? outlineStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? shadow,
  }) {
    return AppTokens(
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      error: error ?? this.error,
      info: info ?? this.info,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      surfaceTint: surfaceTint ?? this.surfaceTint,
      outline: outline ?? this.outline,
      outlineStrong: outlineStrong ?? this.outlineStrong,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppTokens(
      primary: l(primary, other.primary),
      primaryContainer: l(primaryContainer, other.primaryContainer),
      success: l(success, other.success),
      warning: l(warning, other.warning),
      error: l(error, other.error),
      info: l(info, other.info),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceElevated: l(surfaceElevated, other.surfaceElevated),
      surfaceTint: l(surfaceTint, other.surfaceTint),
      outline: l(outline, other.outline),
      outlineStrong: l(outlineStrong, other.outlineStrong),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textTertiary: l(textTertiary, other.textTertiary),
      shadow: l(shadow, other.shadow),
    );
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppTokens.dark
          : AppTokens.light);
}
