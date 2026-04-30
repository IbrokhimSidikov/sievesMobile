import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

enum SnackbarType { success, error, warning, info }

class SnackbarHelper {
  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return;

    final (bgColor, icon) = switch (type) {
      SnackbarType.success => (AppColors.cxEmeraldGreen, Icons.check_circle_outline),
      SnackbarType.error   => (const Color(0xFFD32F2F), Icons.error_outline),
      SnackbarType.warning => (const Color(0xFFF57C00), Icons.warning_amber_outlined),
      SnackbarType.info    => (AppColors.cxRoyalBlue, Icons.info_outline),
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }

  static void showError(BuildContext context, String message, {String? actionLabel, VoidCallback? onAction}) =>
      show(context, message: message, type: SnackbarType.error, actionLabel: actionLabel, onAction: onAction);

  static void showSuccess(BuildContext context, String message) =>
      show(context, message: message, type: SnackbarType.success);

  static void showWarning(BuildContext context, String message) =>
      show(context, message: message, type: SnackbarType.warning);

  static void showInfo(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) =>
      show(context, message: message, type: SnackbarType.info, duration: duration);
}


