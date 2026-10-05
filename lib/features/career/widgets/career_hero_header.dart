import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';
import '../models/career_roadmap.dart';
import '../models/career_timeline_model.dart';
import 'career_format.dart';

/// Indigo hero header (design.md §7.2): back tile, title, and — once loaded —
/// the employee's name, position, current step, tenure and key counts.
class CareerHeroHeader extends StatelessWidget {
  final CareerTimeline? timeline;

  /// Days on the current salary step, shown in the step pill.
  final int? currentStepDays;

  const CareerHeroHeader({super.key, this.timeline, this.currentStepDays});

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    final profile = timeline?.profile;
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20.w, topInset + 8.h, 20.w, 24.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [t.primary, t.primary.withValues(alpha: 0.80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
        boxShadow: [
          BoxShadow(
            color: t.primary.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _GlassTile(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () =>
                    context.canPop() ? context.pop() : context.go('/home'),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.careerTitle,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l.careerSubtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (profile != null) ...[
            SizedBox(height: 24.h),
            // Name and position on the left, time with the team on the right.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _Identity(profile: profile, stepDays: currentStepDays),
                ),
                SizedBox(width: 12.w),
                _Tenure(profile: profile),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: _StatPill(
                    value: profile.contractCount,
                    label: l.careerContracts,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _StatPill(
                    value: timeline!.promotionCount,
                    label: l.careerPromotions,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: _StatPill(
                    value: profile.trainingCount,
                    label: l.careerTrainings,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final CareerProfile profile;
  final int? stepDays;

  const _Identity({required this.profile, this.stepDays});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final role = [
      profile.jobPositionName,
      profile.branchName,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          profile.name,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (role.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            role,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (profile.salaryStructureName != null) ...[
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stairs_rounded, size: 14.sp, color: Colors.white),
                SizedBox(width: 4.w),
                Flexible(
                  child: Text(
                    [
                      '${l.careerStep}: ${profile.salaryStructureName}',
                      if (stepDays != null)
                        l.careerDaysShort.replaceAll('{n}', '$stepDays'),
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Tenure extends StatelessWidget {
  final CareerProfile profile;

  const _Tenure({required this.profile});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hire = profile.hireDate;
    if (hire == null) return const SizedBox.shrink();

    final caption = TextStyle(
      fontSize: 11.sp,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.85),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 150.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              formatTenure(l, hire, tenureEnd(profile)),
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.1,
                color: Colors.white,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Text(l.careerWithTeam, style: caption, textAlign: TextAlign.end),
          Text(
            l.careerSince.replaceAll('{date}', formatCareerDate(context, hire)),
            style: caption,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final int value;
  final String label;

  const _StatPill({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Translucent white icon tile used on the indigo header.
class _GlassTile extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _GlassTile({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, size: 20, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
