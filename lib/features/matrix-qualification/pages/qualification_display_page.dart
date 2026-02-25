import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';

class QualificationDisplayPage extends StatefulWidget {
  const QualificationDisplayPage({super.key});

  @override
  State<QualificationDisplayPage> createState() => _QualificationDisplayPageState();
}

class _QualificationDisplayPageState extends State<QualificationDisplayPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _qualificationResults = [];

  @override
  void initState() {
    super.initState();
    _loadQualificationResults();
  }

  Future<void> _loadQualificationResults() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authManager = AuthManager();
      final employeeId = authManager.currentEmployeeId;

      if (employeeId == null) {
        print('❌ No employee ID available');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final results = await authManager.apiService.getMyQualificationResults(employeeId);

      if (results != null) {
        setState(() {
          _qualificationResults = results;
          _isLoading = false;
        });
        print('✅ Loaded ${_qualificationResults.length} qualification results');
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading qualification results: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  double get _averageRating {
    if (_qualificationResults.isEmpty) return 0;

    final total = _qualificationResults.fold<double>(0, (sum, item) {
      final rating = (item['rating'] ?? 0) as num;
      return sum + rating.toDouble();
    });
    
    return total / _qualificationResults.length;
  }

  Map<int, int> get _ratingDistribution {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var item in _qualificationResults) {
      final rating = (item['rating'] ?? 0) as num;
      final ratingInt = rating.toInt();
      if (ratingInt >= 1 && ratingInt <= 5) {
        distribution[ratingInt] = (distribution[ratingInt] ?? 0) + 1;
      }
    }
    
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    theme.scaffoldBackgroundColor,
                    theme.colorScheme.surface,
                  ]
                : [
                    AppColors.cxWhite,
                    AppColors.cxF5F7F9,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(localizations, isDark, theme),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState(isDark, theme)
                    : _qualificationResults.isEmpty
                        ? _buildEmptyState(localizations, isDark, theme)
                        : SingleChildScrollView(
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPieChartCard(localizations, isDark, theme),
                                SizedBox(height: 24.h),
                                _buildRatingCards(isDark, theme),
                                SizedBox(height: 20.h),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations localizations, bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.cxEmeraldGreen.withOpacity(0.8),
                  AppColors.cxEmeraldGreen.withOpacity(0.6),
                ]
              : [
                  AppColors.cxEmeraldGreen,
                  AppColors.cxEmeraldGreen.withOpacity(0.8),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxEmeraldGreen.withOpacity(isDark ? 0.2 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.cxWhite,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.cxWhite.withOpacity(isDark ? 0.15 : 0.2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.cxWhite.withOpacity(isDark ? 0.2 : 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: AppColors.cxWhite,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.qualificationDisplayPage,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxWhite,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'View your qualification results',
                  style: TextStyle(
                    fontSize: 12.sp,
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

  Widget _buildRatingCards(bool isDark, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Qualifications',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: isDark ? theme.colorScheme.onSurface : AppColors.cxDarkCharcoal,
          ),
        ),
        SizedBox(height: 12.h),
        ...List.generate(_qualificationResults.length, (index) {
          final result = _qualificationResults[index];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildRatingCard(result, isDark, theme),
          );
        }),
      ],
    );
  }

  Widget _buildRatingCard(Map<String, dynamic> result, bool isDark, ThemeData theme) {
    final qualification = result['qualification'] as Map<String, dynamic>?;
    final title = qualification?['title'] ?? 'Unknown';
    final rating = (result['rating'] ?? 0) as num;
    final ratingInt = rating.toInt();
    final comment = result['comment'] ?? '';

    final color = AppColors.cxEmeraldGreen;

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: ratingInt > 0
              ? color.withOpacity(isDark ? 0.5 : 0.3)
              : (isDark
                  ? theme.colorScheme.outline.withOpacity(0.3)
                  : AppColors.cxPlatinumGray.withOpacity(0.5)),
          width: ratingInt > 0 ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(isDark ? 0.3 : 0.2),
                      color.withOpacity(isDark ? 0.2 : 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: color,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? theme.colorScheme.onSurface : AppColors.cxDarkCharcoal,
                      ),
                    ),
                    if (comment.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        comment,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? theme.colorScheme.onSurfaceVariant
                              : AppColors.cxSilverTint,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              final starRating = index + 1;
              final isSelected = ratingInt >= starRating;

              return Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(isDark ? 0.3 : 0.15)
                      : (isDark
                          ? theme.colorScheme.surfaceContainerHighest
                          : AppColors.cxF5F7F9),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? color
                        : (isDark
                            ? theme.colorScheme.outline.withOpacity(0.3)
                            : AppColors.cxPlatinumGray),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: isSelected
                      ? color
                      : (isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : AppColors.cxSilverTint),
                  size: 24.sp,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(AppLocalizations localizations, bool isDark, ThemeData theme) {
    final hasRatings = _ratingDistribution.values.any((count) => count > 0);

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline.withOpacity(0.3)
              : AppColors.cxPlatinumGray.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart_outline_rounded,
                color: isDark ? theme.colorScheme.primary : AppColors.cxEmeraldGreen,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Rating Distribution',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? theme.colorScheme.onSurface : AppColors.cxDarkCharcoal,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cxEmeraldGreen.withOpacity(0.2),
                      AppColors.cxEmeraldGreen.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  'Avg: ${_averageRating.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.cxEmeraldGreen.withOpacity(0.9) : AppColors.cxEmeraldGreen,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 200.h,
            child: hasRatings
                ? PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 50.r,
                      sections: _buildPieChartSections(isDark),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.analytics_outlined,
                          size: 48.sp,
                          color: isDark
                              ? theme.colorScheme.onSurfaceVariant
                              : AppColors.cxSilverTint,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No ratings available',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark
                                ? theme.colorScheme.onSurfaceVariant
                                : AppColors.cxSilverTint,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          if (hasRatings) ...[
            SizedBox(height: 20.h),
            _buildLegend(isDark, theme),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(bool isDark) {
    final distribution = _ratingDistribution;
    final colors = [
      AppColors.cxCrimsonRed,
      AppColors.cxWarning,
      AppColors.cxAmberGold,
      AppColors.cxEmeraldGreen,
      AppColors.cxRoyalBlue,
    ];

    return distribution.entries
        .where((entry) => entry.value > 0)
        .map((entry) {
          final rating = entry.key;
          final count = entry.value;

          return PieChartSectionData(
            color: colors[rating - 1].withOpacity(isDark ? 0.8 : 1.0),
            value: count.toDouble(),
            title: '$count',
            radius: 50.r,
            titleStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.cxWhite,
            ),
          );
        })
        .toList();
  }

  Widget _buildLegend(bool isDark, ThemeData theme) {
    final colors = [
      AppColors.cxCrimsonRed,
      AppColors.cxWarning,
      AppColors.cxAmberGold,
      AppColors.cxEmeraldGreen,
      AppColors.cxRoyalBlue,
    ];
    final labels = ['1 Star', '2 Stars', '3 Stars', '4 Stars', '5 Stars'];

    return Wrap(
      spacing: 12.w,
      runSpacing: 8.h,
      children: List.generate(5, (index) {
        final count = _ratingDistribution[index + 1] ?? 0;
        if (count == 0) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 12.h,
              decoration: BoxDecoration(
                color: colors[index].withOpacity(isDark ? 0.8 : 1.0),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              labels[index],
              style: TextStyle(
                fontSize: 11.sp,
                color: isDark
                    ? theme.colorScheme.onSurfaceVariant
                    : AppColors.cxGraphiteGray,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildLoadingState(bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: isDark ? theme.colorScheme.primary : AppColors.cxEmeraldGreen,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading qualifications...',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : AppColors.cxSilverTint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations, bool isDark, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.verified_user_outlined,
            size: 64.sp,
            color: isDark
                ? theme.colorScheme.onSurfaceVariant
                : AppColors.cxSilverTint,
          ),
          SizedBox(height: 16.h),
          Text(
            'No qualifications available',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? theme.colorScheme.onSurface : AppColors.cxDarkCharcoal,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Complete a qualification assessment first',
            style: TextStyle(
              fontSize: 14.sp,
              color: isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : AppColors.cxSilverTint,
            ),
          ),
        ],
      ),
    );
  }
}
