import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_tokens.dart';

/// Shimmer over the silhouette of the milestone card and roadmap rows.
class CareerSkeleton extends StatelessWidget {
  const CareerSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget block(double height, {double? width, double radius = 16}) =>
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: t.surfaceTint,
            borderRadius: BorderRadius.circular(radius.r),
          ),
        );

    return Shimmer.fromColors(
      baseColor: t.surfaceTint,
      highlightColor: isDark ? t.surfaceElevated : t.surface,
      period: const Duration(milliseconds: 1500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(118.h),
          SizedBox(height: 24.h),
          block(20.h, width: 110.w, radius: 8),
          SizedBox(height: 16.h),
          for (var i = 0; i < 4; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 32.w,
                  child: Padding(
                    padding: EdgeInsets.only(top: 30.h),
                    child: Center(child: block(12, width: 12, radius: 6)),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(child: block(72.h)),
              ],
            ),
            SizedBox(height: 12.h),
          ],
        ],
      ),
    );
  }
}

/// Error and empty states (design.md §7.13).
class CareerMessageView extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CareerMessageView({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 32.h),
      child: Column(
        children: [
          Icon(icon, size: 64.sp, color: iconColor),
          SizedBox(height: 16.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: t.textSecondary,
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            SizedBox(height: 24.h),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(actionLabel!),
              style: FilledButton.styleFrom(
                backgroundColor: t.primary,
                foregroundColor: Colors.white,
                minimumSize: Size(160.w, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                textStyle: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
