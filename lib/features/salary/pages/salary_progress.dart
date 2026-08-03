import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/salary_timeline_model.dart';

/// Shows the signed-in employee their own salary progression: where they sit
/// on the company salary ladder, and the full history of contract periods that
/// got them there.
class SalaryProgress extends StatefulWidget {
  const SalaryProgress({super.key});

  @override
  State<SalaryProgress> createState() => _SalaryProgressState();
}

class _SalaryProgressState extends State<SalaryProgress> {
  final AuthManager _authManager = AuthManager();
  late final ApiService _apiService;

  bool _loading = true;
  bool _hasError = false;
  SalaryTimeline? _data;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(_authManager.authService);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });

    final employeeId = _authManager.currentEmployeeId;
    if (employeeId == null) {
      setState(() {
        _loading = false;
        _hasError = true;
      });
      return;
    }

    final data = await _apiService.getEmployeeSalaryTimeline(employeeId);
    if (!mounted) return;
    setState(() {
      _data = data;
      _hasError = data == null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(l10n: l10n, isDark: isDark, theme: theme, data: _data),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: theme.colorScheme.primary,
                child: _buildBody(l10n, isDark, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, bool isDark, ThemeData theme) {
    if (_loading) {
      return _SalaryShimmer(isDark: isDark, theme: theme);
    }

    if (_hasError || _data == null) {
      return _StatePlaceholder(
        icon: Icons.error_outline_rounded,
        title: l10n.salaryProgressError,
        subtitle: l10n.salaryProgressRetryHint,
        actionLabel: l10n.salaryProgressRetry,
        onAction: _load,
        isDark: isDark,
        theme: theme,
      );
    }

    final data = _data!;
    if (data.timeline.isEmpty && data.ladder.isEmpty) {
      return _StatePlaceholder(
        icon: Icons.timeline_rounded,
        title: l10n.salaryProgressEmpty,
        subtitle: l10n.salaryProgressEmptyHint,
        isDark: isDark,
        theme: theme,
      );
    }

    final chartPoints = _chartPoints(data);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
      children: [
        if (chartPoints.length >= 2) ...[
          _SalaryChart(
            points: chartPoints,
            l10n: l10n,
            isDark: isDark,
            theme: theme,
          ),
          SizedBox(height: 20.h),
        ],
        _CurrentStepCard(data: data, l10n: l10n, isDark: isDark, theme: theme),
        SizedBox(height: 20.h),
        _StatsRow(data: data, l10n: l10n, isDark: isDark, theme: theme),
        SizedBox(height: 20.h),
        _NextStepCard(data: data, l10n: l10n, isDark: isDark, theme: theme),
        SizedBox(height: 28.h),
        if (data.timeline.isNotEmpty) ...[
          _SectionTitle(title: l10n.salaryHistory, theme: theme),
          SizedBox(height: 14.h),
          _HistoryView(data: data, l10n: l10n, isDark: isDark, theme: theme),
        ],
      ],
    );
  }

  /// Chronological (oldest→newest) points that have a real monthly rate — only
  /// salary levels the employee actually reached are plotted.
  List<_ChartPoint> _chartPoints(SalaryTimeline data) {
    final points = <_ChartPoint>[];
    for (final e in data.timeline) {
      if (e.monthlyRate == null) continue;
      points.add(_ChartPoint(
        rate: e.monthlyRate!,
        date: e.startDate,
        label: e.salaryStructureName,
      ));
    }
    return points;
  }
}

// ─── Formatting helpers ──────────────────────────────────────────────────────

String _formatMoney(double? rate, AppLocalizations l10n) {
  if (rate == null) return '—';
  final formatted = NumberFormat('#,###', 'en').format(rate).replaceAll(',', ' ');
  return '$formatted ${l10n.currencyUzs}';
}

String _formatDate(DateTime? d) {
  if (d == null) return '—';
  return DateFormat('dd MMM yyyy').format(d);
}

/// Compact money for chart axes, e.g. 2 500 000 → "2.5M", 850 000 → "850K".
String _abbrevMoney(double rate) {
  if (rate >= 1000000) {
    final v = rate / 1000000;
    return '${v.toStringAsFixed(v >= 10 ? 0 : 1)}M';
  }
  if (rate >= 1000) {
    return '${(rate / 1000).toStringAsFixed(0)}K';
  }
  return rate.toStringAsFixed(0);
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.l10n,
    required this.isDark,
    required this.theme,
    required this.data,
  });

  final AppLocalizations l10n;
  final bool isDark;
  final ThemeData theme;
  final SalaryTimeline? data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 22.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [theme.colorScheme.primary, theme.colorScheme.primaryContainer]
              : [AppColors.cxRoyalBlue, AppColors.cxPrimary],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28.r)),
        boxShadow: [
          BoxShadow(
            color: (isDark ? theme.colorScheme.primary : AppColors.cx43C19F)
                .withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: AppColors.cxWhite,
            iconSize: 20.sp,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.w),
          ),
          SizedBox(width: 4.w),
          Container(
            padding: EdgeInsets.all(11.r),
            decoration: BoxDecoration(
              color: AppColors.cxWhite.withOpacity(isDark ? 0.15 : 0.2),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppColors.cxWhite.withOpacity(isDark ? 0.2 : 0.3),
              ),
            ),
            child: Icon(
              Icons.trending_up_rounded,
              color: AppColors.cxWhite,
              size: 26.sp,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.salaryProgress,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxWhite,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  data?.branchName?.isNotEmpty == true
                      ? data!.branchName!
                      : l10n.salaryProgressSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.cxWhite.withOpacity(0.9),
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

// ─── Current step hero card ──────────────────────────────────────────────────

class _CurrentStepCard extends StatelessWidget {
  const _CurrentStepCard({
    required this.data,
    required this.l10n,
    required this.isDark,
    required this.theme,
  });

  final SalaryTimeline data;
  final AppLocalizations l10n;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final current = data.currentEntry;
    final totalSteps = data.totalSteps;
    final step = current?.step;
    final progress = (step != null && totalSteps > 0)
        ? (step / totalSteps).clamp(0.0, 1.0)
        : 0.0;

    final gradient = isDark
        ? [
            theme.colorScheme.primary.withOpacity(0.85),
            theme.colorScheme.primaryContainer.withOpacity(0.7),
          ]
        : [AppColors.cxRoyalBlue, const Color(0xFF5AA0F0)];

    return Container(
      padding: EdgeInsets.all(22.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(isDark ? 0.3 : 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.currentSalaryStep,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.cxWhite.withOpacity(0.85),
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              if (current?.isOngoing == true)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.cxWhite.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7.w,
                        height: 7.w,
                        decoration: const BoxDecoration(
                          color: AppColors.cxWhite,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        l10n.salaryActive,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cxWhite,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            current?.salaryStructureName ?? l10n.salaryNotAssigned,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.cxWhite,
              letterSpacing: 0.2,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _formatMoney(current?.monthlyRate, l10n),
            style: TextStyle(
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.cxWhite,
              letterSpacing: 0.2,
            ),
          ),
          Text(
            l10n.perMonth,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.cxWhite.withOpacity(0.8),
            ),
          ),
          if (step != null && totalSteps > 0) ...[
            SizedBox(height: 18.h),
            Row(
              children: [
                Text(
                  l10n.stepXofY(step, totalSteps),
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cxWhite,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxWhite,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9.h,
                backgroundColor: AppColors.cxWhite.withOpacity(0.25),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.cxWhite),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Stats row (tenure + total steps) ────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.data,
    required this.l10n,
    required this.isDark,
    required this.theme,
  });

  final SalaryTimeline data;
  final AppLocalizations l10n;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            icon: Icons.event_available_rounded,
            value: data.totalDays != null
                ? l10n.daysCount(data.totalDays!)
                : '—',
            label: l10n.totalTenure,
            color: AppColors.cxEmeraldGreen,
          ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: _statTile(
            icon: Icons.stairs_rounded,
            value: '${data.timeline.length}',
            label: l10n.salaryChanges,
            color: AppColors.cxPurple,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    final surface =
        isDark ? theme.colorScheme.surface : AppColors.cxWhite;
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withOpacity(0.4)
              : AppColors.cxPlatinumGray,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Next step (upcoming salary structure) ───────────────────────────────────

class _NextStepCard extends StatelessWidget {
  const _NextStepCard({
    required this.data,
    required this.l10n,
    required this.isDark,
    required this.theme,
  });

  final SalaryTimeline data;
  final AppLocalizations l10n;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (data.ladder.isEmpty) return const SizedBox.shrink();

    final currentStep = data.currentEntry?.step;
    final currentRate = data.currentEntry?.monthlyRate ?? 0;
    final totalSteps = data.totalSteps;
    final nextStepNum = (currentStep ?? 0) + 1;

    SalaryLadderStep? next;
    for (final s in data.ladder) {
      if (s.step == nextStepNum) {
        next = s;
        break;
      }
    }

    // Already on the highest rung → celebrate instead of pointing forward.
    if (next == null) {
      if (currentStep == null || totalSteps == 0) {
        return const SizedBox.shrink();
      }
      return _topReachedCard();
    }

    final delta = next.monthlyRate - currentRate;
    final accent = isDark ? const Color(0xFFA78BFA) : AppColors.cxPurple;

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(isDark ? 0.22 : 0.12),
            accent.withOpacity(isDark ? 0.08 : 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: accent.withOpacity(0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(11.r),
                decoration: BoxDecoration(
                  color: accent.withOpacity(isDark ? 0.28 : 0.16),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(Icons.flag_rounded, color: accent, size: 22.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nextSalaryStep.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        letterSpacing: 0.8,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      next.salaryStructureName,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (totalSteps > 0)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(isDark ? 0.25 : 0.14),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    l10n.stepXofY(next.step, totalSteps),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatMoney(next.monthlyRate, l10n),
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    l10n.perMonth,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (delta > 0)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: AppColors.cxEmeraldGreen.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_upward_rounded,
                              size: 14.sp, color: AppColors.cxEmeraldGreen),
                          SizedBox(width: 2.w),
                          Text(
                            _formatMoney(delta, l10n),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.cxEmeraldGreen,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        l10n.salaryRaiseAhead,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.cxEmeraldGreen.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topReachedCard() {
    final accent = isDark ? const Color(0xFFFEDA84) : AppColors.cxAmberGold;
    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(isDark ? 0.22 : 0.14),
            accent.withOpacity(isDark ? 0.08 : 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(color: accent.withOpacity(0.5), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: accent.withOpacity(isDark ? 0.28 : 0.18),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(Icons.emoji_events_rounded, color: accent, size: 26.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.salaryTopReached,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  l10n.salaryTopReachedHint,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.3,
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

// ─── Section title ───────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17.sp,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
        letterSpacing: 0.2,
      ),
    );
  }
}

// ─── Salary growth line chart ────────────────────────────────────────────────

/// A single plotted salary level the employee actually reached.
class _ChartPoint {
  final double rate;
  final DateTime? date;
  final String? label;

  _ChartPoint({required this.rate, required this.date, required this.label});
}

class _SalaryChart extends StatelessWidget {
  const _SalaryChart({
    required this.points,
    required this.l10n,
    required this.isDark,
    required this.theme,
  });

  final List<_ChartPoint> points;
  final AppLocalizations l10n;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final lineColor = isDark ? const Color(0xFF34D399) : AppColors.cxRoyalBlue;
    final surface = isDark ? theme.colorScheme.surface : AppColors.cxWhite;

    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].rate),
    ];

    final rates = points.map((p) => p.rate).toList();
    final minRate = rates.reduce((a, b) => a < b ? a : b);
    final maxRate = rates.reduce((a, b) => a > b ? a : b);
    // Pad the vertical range so the line never touches the frame edges.
    final span = (maxRate - minRate).abs();
    final pad = span == 0 ? (maxRate == 0 ? 1 : maxRate * 0.15) : span * 0.25;
    final minY = (minRate - pad).clamp(0, double.infinity).toDouble();
    final maxY = maxRate + pad;

    final first = points.first.rate;
    final last = points.last.rate;
    final growth = first == 0 ? 0.0 : ((last - first) / first) * 100;

    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 18.h, 18.w, 12.h),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withOpacity(0.4)
              : AppColors.cxPlatinumGray,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.salaryGrowth,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _formatMoney(last, l10n),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              if (growth > 0)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.cxEmeraldGreen.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up_rounded,
                          size: 15.sp, color: AppColors.cxEmeraldGreen),
                      SizedBox(width: 4.w),
                      Text(
                        '+${growth.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cxEmeraldGreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 18.h),
          SizedBox(
            height: 150.h,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) <= 0 ? null : (maxY - minY) / 3,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: (isDark
                            ? theme.colorScheme.outline
                            : AppColors.cxPlatinumGray)
                        .withOpacity(0.5),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40.w,
                      interval: (maxY - minY) <= 0 ? null : (maxY - minY) / 2,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max || value == meta.min) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: Text(
                            _abbrevMoney(value),
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22.h,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final i = value.round();
                        if (i < 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final d = points[i].date;
                        if (d == null) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            DateFormat("MMM ''yy").format(d),
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        isDark ? const Color(0xFF252532) : AppColors.cx1C1C1E,
                    tooltipRoundedRadius: 10.r,
                    getTooltipItems: (touched) => touched.map((t) {
                      final p = points[t.x.round()];
                      return LineTooltipItem(
                        '${_formatMoney(p.rate, l10n)}\n',
                        TextStyle(
                          color: AppColors.cxWhite,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                        ),
                        children: [
                          TextSpan(
                            text: p.date != null
                                ? DateFormat('dd MMM yyyy').format(p.date!)
                                : (p.label ?? ''),
                            style: TextStyle(
                              color: AppColors.cxWhite.withOpacity(0.75),
                              fontWeight: FontWeight.w400,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.32,
                    preventCurveOverShooting: true,
                    color: lineColor,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: surface,
                        strokeWidth: 2.5,
                        strokeColor: lineColor,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withOpacity(0.28),
                          lineColor.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History timeline ────────────────────────────────────────────────────────

class _HistoryView extends StatelessWidget {
  const _HistoryView({
    required this.data,
    required this.l10n,
    required this.isDark,
    required this.theme,
  });

  final SalaryTimeline data;
  final AppLocalizations l10n;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // Raise vs the chronologically previous period (data.timeline is oldest
    // first). Displayed newest first, so we walk the reversed list but keep the
    // delta relative to the earlier period.
    final n = data.timeline.length;
    final rows = <Widget>[];
    for (var display = 0; display < n; display++) {
      final idx = n - 1 - display; // chronological index
      final e = data.timeline[idx];
      double? delta;
      if (idx > 0 && e.monthlyRate != null &&
          data.timeline[idx - 1].monthlyRate != null) {
        delta = e.monthlyRate! - data.timeline[idx - 1].monthlyRate!;
      }
      rows.add(_timelineRow(
        e,
        delta: delta,
        isFirstEver: idx == 0,
        isFirst: display == 0,
        isLast: display == n - 1,
      ));
    }
    return Column(children: rows);
  }

  Widget _timelineRow(
    SalaryTimelineEntry e, {
    required double? delta,
    required bool isFirstEver,
    required bool isFirst,
    required bool isLast,
  }) {
    final primary = theme.colorScheme.primary;
    final surface = isDark ? theme.colorScheme.surface : AppColors.cxWhite;
    final railColor = theme.colorScheme.outline.withOpacity(0.5);

    // Accent + rail-dot semantics: ongoing → primary, a raise → green,
    // the very first period → neutral.
    final Color accent = e.isOngoing
        ? primary
        : (delta != null && delta > 0)
            ? AppColors.cxEmeraldGreen
            : isFirstEver
                ? AppColors.cxSilverTint
                : primary;
    final IconData dotIcon = e.isOngoing
        ? Icons.bolt_rounded
        : (delta != null && delta > 0)
            ? Icons.trending_up_rounded
            : isFirstEver
                ? Icons.flag_rounded
                : Icons.check_rounded;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline rail with an icon node
          Column(
            children: [
              Container(
                width: 2.w,
                height: 8.h,
                color: isFirst ? Colors.transparent : railColor,
              ),
              Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: surface, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(dotIcon, size: 14.sp, color: AppColors.cxWhite),
              ),
              Expanded(
                child: Container(
                  width: 2.w,
                  color: isLast ? Colors.transparent : railColor,
                ),
              ),
            ],
          ),
          SizedBox(width: 14.w),
          // Card
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: 14.h),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isDark
                      ? theme.colorScheme.outline.withOpacity(0.4)
                      : AppColors.cxPlatinumGray,
                ),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left accent stripe + body
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 4.w,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(18.r),
                              bottomLeft: Radius.circular(18.r),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.all(16.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        e.salaryStructureName ??
                                            l10n.salaryNotAssigned,
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.w700,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (e.isOngoing)
                                      _pill(
                                        l10n.salaryActive,
                                        primary,
                                        filled: true,
                                      )
                                    else if (e.step != null)
                                      _pill(
                                        l10n.stepShort(e.step!),
                                        primary,
                                      ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      _formatMoney(e.monthlyRate, l10n),
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w800,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    if (delta != null && delta > 0) ...[
                                      SizedBox(width: 8.w),
                                      _raiseChip(delta),
                                    ],
                                  ],
                                ),
                                SizedBox(height: 12.h),
                                _metaRow(
                                  Icons.calendar_today_rounded,
                                  '${_formatDate(e.startDate)}  →  '
                                  '${e.isOngoing ? l10n.salaryNow : _formatDate(e.periodEndDate)}',
                                ),
                                if (e.periodDays != null) ...[
                                  SizedBox(height: 6.h),
                                  _metaRow(
                                    Icons.schedule_rounded,
                                    l10n.daysCount(e.periodDays!),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color, {bool filled = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: filled ? AppColors.cxWhite : color,
        ),
      ),
    );
  }

  Widget _raiseChip(double delta) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: AppColors.cxEmeraldGreen.withOpacity(isDark ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.arrow_upward_rounded,
              size: 12.sp, color: AppColors.cxEmeraldGreen),
          SizedBox(width: 2.w),
          Text(
            _formatMoney(delta, l10n),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.cxEmeraldGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13.sp, color: theme.colorScheme.onSurfaceVariant),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty / error placeholder ───────────────────────────────────────────────

class _StatePlaceholder extends StatelessWidget {
  const _StatePlaceholder({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.theme,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final ThemeData theme;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 120.h),
        Icon(icon,
            size: 64.sp, color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6)),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: 24.h),
                ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Loading skeleton ────────────────────────────────────────────────────────

class _SalaryShimmer extends StatelessWidget {
  const _SalaryShimmer({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF1A1A24) : Colors.grey[300]!;
    final highlight = isDark ? const Color(0xFF252532) : Colors.grey[100]!;

    Widget box(double w, double h, {double radius = 12}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(radius.r),
          ),
        );

    Widget card(double height) => Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(22.r),
          ),
        );

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
        children: [
          // Chart placeholder
          card(210.h),
          SizedBox(height: 20.h),
          // Current step hero placeholder
          card(180.h),
          SizedBox(height: 20.h),
          // Stat tiles
          Row(
            children: [
              Expanded(child: card(96.h)),
              SizedBox(width: 14.w),
              Expanded(child: card(96.h)),
            ],
          ),
          SizedBox(height: 28.h),
          box(120.w, 18.h),
          SizedBox(height: 16.h),
          // History rows
          for (var i = 0; i < 3; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26.w,
                  height: 26.w,
                  decoration: BoxDecoration(color: base, shape: BoxShape.circle),
                ),
                SizedBox(width: 14.w),
                Expanded(child: card(110.h)),
              ],
            ),
            SizedBox(height: 14.h),
          ],
        ],
      ),
    );
  }
}
