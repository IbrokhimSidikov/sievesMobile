import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../models/career_roadmap.dart';
import 'career_format.dart';

/// Progress toward the next work anniversary.
class CareerMilestoneCard extends StatelessWidget {
  final NextMilestone milestone;

  const CareerMilestoneCard({super.key, required this.milestone});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: t.outline),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: t.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: t.warning.withValues(alpha: 0.20)),
                ),
                child: Icon(
                  Icons.workspace_premium_rounded,
                  size: 24.sp,
                  color: t.warning,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.careerNextMilestone,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: t.textSecondary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      formatMilestone(l, milestone.months),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: t.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '${(milestone.progress * 100).round()}%',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: t.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: milestone.progress),
            duration: MediaQuery.of(context).disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8.h,
                backgroundColor: t.surfaceTint,
                valueColor: AlwaysStoppedAnimation(t.primary),
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.careerDaysLeft.replaceAll('{n}', '${milestone.daysLeft}'),
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: t.textSecondary,
                  ),
                ),
              ),
              Text(
                formatCareerDate(context, milestone.date),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: t.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
