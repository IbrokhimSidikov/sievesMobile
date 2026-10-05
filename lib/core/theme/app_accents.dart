import 'package:flutter/material.dart';

/// A feature accent as a light / dark pair (design.md §2.3).
///
/// An accent may tint a module's tile, its header icon tile, its back button
/// and its primary CTA. It never tints page chrome or body text.
@immutable
class AppAccent {
  const AppAccent(this.light, this.dark);

  final Color light;
  final Color dark;

  Color resolve(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

abstract class AppAccents {
  /// Profile, HR, Feedback.
  static const AppAccent indigo = AppAccent(Color(0xFF4F46E5), Color(0xFF6366F1));

  /// Attendance, Face verification.
  static const AppAccent teal = AppAccent(Color(0xFF0D9488), Color(0xFF2DD4BF));

  /// Break records, Break order.
  static const AppAccent orange = AppAccent(Color(0xFFEA580C), Color(0xFFFB923C));

  /// History, Calendar.
  static const AppAccent blue = AppAccent(Color(0xFF2563EB), Color(0xFF60A5FA));

  /// Learning (LMS, exams, trainings).
  static const AppAccent violet = AppAccent(Color(0xFF7C3AED), Color(0xFFA78BFA));

  /// Wallet, Salary.
  static const AppAccent green = AppAccent(Color(0xFF059669), Color(0xFF34D399));

  /// Qualification matrix.
  static const AppAccent purple = AppAccent(Color(0xFF9333EA), Color(0xFFC084FC));

  /// Tasks, Productivity, Checklist.
  static const AppAccent slate = AppAccent(Color(0xFF475569), Color(0xFF94A3B8));

  /// Order cancel.
  static const AppAccent red = AppAccent(Color(0xFFDC2626), Color(0xFFF87171));
}
