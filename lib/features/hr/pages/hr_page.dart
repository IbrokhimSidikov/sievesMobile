import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_accents.dart';
import '../../../core/theme/app_tokens.dart';

/// HR hub: Calendar, Training test, Training game and Exam.
///
/// Flat layout per design.md: standard header with a back tile tinted in the
/// HR accent (indigo), then a list of `flat` cards (surface, hairline outline,
/// no shadow, no gradient).
class HrPage extends StatelessWidget {
  const HrPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tokens = context.tokens;

    final items = <_HrItem>[
      _HrItem(
        title: l.calendar,
        subtitle: l.calendarSubtitle1,
        icon: Icons.calendar_month_rounded,
        accent: AppAccents.blue,
        route: AppRoutes.calendar,
      ),
      _HrItem(
        title: l.trainingTest,
        subtitle: l.trainingTestSubtitle,
        icon: Icons.quiz_rounded,
        accent: AppAccents.violet,
        route: AppRoutes.trainingTestPage,
      ),
      _HrItem(
        title: l.trainingGame,
        subtitle: l.trainingGameSubtitle,
        icon: Icons.sports_esports_rounded,
        accent: AppAccents.green,
        route: AppRoutes.trainingGameTestPage,
      ),
      _HrItem(
        title: l.examPageTitle,
        subtitle: l.examPageSubtitle,
        icon: Icons.assignment_rounded,
        accent: AppAccents.purple,
        route: AppRoutes.examPage,
      ),
    ];

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HrHeader(title: l.hrTitle, subtitle: l.hrSubtitle),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 12.h),
                itemBuilder: (context, index) => _HrCard(item: items[index]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HrItem {
  const _HrItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final AppAccent accent;
  final String route;
}

/// Standard header (design.md §7.2): 44 px back tile in the page accent,
/// headline title, caption subtitle underneath.
class _HrHeader extends StatelessWidget {
  const _HrHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = AppAccents.indigo.resolve(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: MaterialLocalizations.of(context).backButtonTooltip,
            child: Material(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(12.r),
              child: InkWell(
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go(AppRoutes.home),
                borderRadius: BorderRadius.circular(12.r),
                child: Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: tokens.outline),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20.sp,
                    color: accent,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.25,
                    color: tokens.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Flat module card: 44 px accent icon tile, title, subtitle, chevron.
class _HrCard extends StatelessWidget {
  const _HrCard({required this.item});

  final _HrItem item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = item.accent.resolve(context);

    return Semantics(
      button: true,
      label: item.title,
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () => context.push(item.route),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: tokens.outline),
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: accent.withValues(alpha: 0.20)),
                  ),
                  child: Icon(item.icon, size: 24.sp, color: accent),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: tokens.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20.sp,
                  color: tokens.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
