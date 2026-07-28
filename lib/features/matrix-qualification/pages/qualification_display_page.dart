import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shimmer/shimmer.dart';
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

  /// UUIDs of parent fields that are currently expanded to reveal sub-fields.
  final Set<String> _expandedParents = {};

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

  /// Only real (leaf) ratings feed the stats; computed parent entries are
  /// derived aggregates and would otherwise double-count.
  List<Map<String, dynamic>> get _leafResults => _qualificationResults
      .where((item) => item['is_computed'] != true)
      .toList();

  double get _averageRating {
    final leaves = _leafResults;
    if (leaves.isEmpty) return 0;

    final total = leaves.fold<double>(0, (sum, item) {
      final rating = (item['rating'] ?? 0) as num;
      return sum + rating.toDouble();
    });

    return total / leaves.length;
  }

  Map<int, int> get _ratingDistribution {
    final distribution = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};

    for (var item in _leafResults) {
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

  void _showStarInfoDialog(AppLocalizations localizations, bool isDark, ThemeData theme) {
    final starData = [
      (
        title: localizations.star1Title,
        desc: localizations.star1Desc,
        color: AppColors.cxCrimsonRed,
        icon: Icons.school_rounded,
      ),
      (
        title: localizations.star2Title,
        desc: localizations.star2Desc,
        color: AppColors.cxWarning,
        icon: Icons.person_rounded,
      ),
      (
        title: localizations.star3Title,
        desc: localizations.star3Desc,
        color: AppColors.cxAmberGold,
        icon: Icons.bolt_rounded,
      ),
      (
        title: localizations.star4Title,
        desc: localizations.star4Desc,
        color: AppColors.cxEmeraldGreen,
        icon: Icons.groups_rounded,
      ),
      (
        title: localizations.star5Title,
        desc: localizations.star5Desc,
        color: AppColors.cxRoyalBlue,
        icon: Icons.trending_up_rounded,
      ),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 12.h),
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.onSurfaceVariant.withOpacity(0.3)
                      : AppColors.cxPlatinumGray,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.cxEmeraldGreen.withOpacity(0.2),
                            AppColors.cxEmeraldGreen.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(
                        Icons.star_rounded,
                        color: AppColors.cxEmeraldGreen,
                        size: 22.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.starRatingTitle,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? theme.colorScheme.onSurface
                                  : AppColors.cxDarkCharcoal,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            localizations.starRatingSubtitle,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark
                                  ? theme.colorScheme.onSurfaceVariant
                                  : AppColors.cxSilverTint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    children: [
                      ...starData.asMap().entries.map((entry) {
                        final i = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Container(
                            padding: EdgeInsets.all(14.r),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? theme.colorScheme.surfaceContainerHighest
                                  : item.color.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: item.color.withOpacity(isDark ? 0.35 : 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        item.color.withOpacity(isDark ? 0.3 : 0.2),
                                        item.color.withOpacity(isDark ? 0.15 : 0.08),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10.r),
                                  ),
                                  child: Icon(
                                    item.icon,
                                    color: item.color,
                                    size: 20.sp,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          ...List.generate(i + 1, (_) => Padding(
                                            padding: EdgeInsets.only(right: 2.w),
                                            child: Icon(
                                              Icons.star_rounded,
                                              color: item.color,
                                              size: 13.sp,
                                            ),
                                          )),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: isDark
                                              ? theme.colorScheme.onSurface
                                              : AppColors.cxDarkCharcoal,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        item.desc,
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          height: 1.4,
                                          color: isDark
                                              ? theme.colorScheme.onSurfaceVariant
                                              : AppColors.cxGraphiteGray,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
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
          GestureDetector(
            onTap: () => _showStarInfoDialog(localizations, isDark, theme),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.cxWhite.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.cxWhite.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                color: AppColors.cxWhite,
                size: 20.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCards(bool isDark, ThemeData theme) {
    final groups = _buildGroups();

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
        ...groups.map((group) {
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: group.children.isEmpty
                ? _buildLeafCard(group.parent, isDark, theme)
                : _buildParentGroupCard(group, isDark, theme),
          );
        }),
      ],
    );
  }

  /// Builds display groups: each computed parent with its sub-field results,
  /// plus standalone (parent-less) leaves as single-item groups.
  List<({Map<String, dynamic> parent, List<Map<String, dynamic>> children})>
      _buildGroups() {
    String? parentUuidOf(Map<String, dynamic> r) =>
        (r['qualification'] as Map<String, dynamic>?)?['parent_uuid'] as String?;
    String? qualUuidOf(Map<String, dynamic> r) =>
        (r['qualification'] as Map<String, dynamic>?)?['uuid'] as String?;

    final parents =
        _qualificationResults.where((r) => r['is_computed'] == true).toList();
    final leaves =
        _qualificationResults.where((r) => r['is_computed'] != true).toList();
    final claimed = <Map<String, dynamic>>{};

    final groups =
        <({Map<String, dynamic> parent, List<Map<String, dynamic>> children})>[];

    for (final parent in parents) {
      final parentUuid = qualUuidOf(parent);
      final children = leaves
          .where((leaf) => parentUuidOf(leaf) == parentUuid)
          .toList();
      claimed.addAll(children);
      groups.add((parent: parent, children: children));
    }

    // Standalone leaves (and any orphans) become single-item groups.
    for (final leaf in leaves) {
      if (!claimed.contains(leaf)) {
        groups.add((parent: leaf, children: const []));
      }
    }

    return groups;
  }

  /// Expandable parent card: tap the header to reveal its sub-fields compactly.
  Widget _buildParentGroupCard(
    ({Map<String, dynamic> parent, List<Map<String, dynamic>> children}) group,
    bool isDark,
    ThemeData theme,
  ) {
    final qualification = group.parent['qualification'] as Map<String, dynamic>?;
    final uuid = qualification?['uuid']?.toString() ?? '';
    final title = qualification?['title'] ?? 'Unknown';
    final average = ((group.parent['rating'] ?? 0) as num).toDouble();
    final roundedForStars = average.round();
    final color = AppColors.cxEmeraldGreen;
    final isExpanded = _expandedParents.contains(uuid);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.10) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: color.withOpacity(isDark ? 0.45 : 0.30),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (tappable)
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedParents.remove(uuid);
                  } else {
                    _expandedParents.add(uuid);
                  }
                });
              },
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: color.withOpacity(isDark ? 0.30 : 0.18),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        isExpanded ? Icons.folder_open_rounded : Icons.folder_rounded,
                        color: color,
                        size: 18.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? theme.colorScheme.onSurface : AppColors.cxDarkCharcoal,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              _buildMiniStars(roundedForStars, color, isDark, theme),
                              SizedBox(width: 6.w),
                              Text(
                                '${group.children.length} sub-field${group.children.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: isDark
                                      ? theme.colorScheme.onSurfaceVariant
                                      : AppColors.cxSilverTint,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: color.withOpacity(isDark ? 0.25 : 0.15),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        average > 0 ? average.toStringAsFixed(1) : '—',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark
                            ? theme.colorScheme.onSurfaceVariant
                            : AppColors.cxSilverTint,
                        size: 22.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expanded children
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: EdgeInsets.fromLTRB(12.r, 0, 12.r, 8.r),
              child: Column(
                children: [
                  Divider(
                    height: 8.h,
                    thickness: 1,
                    color: color.withOpacity(0.15),
                  ),
                  ...group.children.map(
                    (child) => _buildChildRow(child, color, isDark, theme),
                  ),
                ],
              ),
            ),
            crossFadeState:
                isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  /// One compact row for a sub-field inside an expanded parent.
  Widget _buildChildRow(
    Map<String, dynamic> result,
    Color color,
    bool isDark,
    ThemeData theme,
  ) {
    final qualification = result['qualification'] as Map<String, dynamic>?;
    final title = qualification?['title'] ?? 'Unknown';
    final ratingInt = ((result['rating'] ?? 0) as num).toInt();

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.h),
      child: Row(
        children: [
          Icon(Icons.subdirectory_arrow_right_rounded,
              size: 15.sp,
              color: isDark
                  ? theme.colorScheme.onSurfaceVariant
                  : AppColors.cxSilverTint),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? theme.colorScheme.onSurface : AppColors.cxDarkCharcoal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8.w),
          _buildMiniStars(ratingInt, color, isDark, theme),
          SizedBox(width: 6.w),
          Text(
            '$ratingInt',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// A compact standalone (parent-less) leaf card.
  Widget _buildLeafCard(
      Map<String, dynamic> result, bool isDark, ThemeData theme) {
    final qualification = result['qualification'] as Map<String, dynamic>?;
    final title = qualification?['title'] ?? 'Unknown';
    final ratingInt = ((result['rating'] ?? 0) as num).toInt();
    final comment = result['comment'] ?? '';
    final color = AppColors.cxEmeraldGreen;

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: ratingInt > 0
              ? color.withOpacity(isDark ? 0.45 : 0.25)
              : (isDark
                  ? theme.colorScheme.outline.withOpacity(0.3)
                  : AppColors.cxPlatinumGray.withOpacity(0.5)),
          width: ratingInt > 0 ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.28 : 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.star_rounded, color: color, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? theme.colorScheme.onSurface : AppColors.cxDarkCharcoal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (comment.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    comment,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: isDark
                          ? theme.colorScheme.onSurfaceVariant
                          : AppColors.cxSilverTint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _buildMiniStars(ratingInt, color, isDark, theme),
          SizedBox(width: 6.w),
          Text(
            '$ratingInt',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// A compact inline row of 5 small stars filled up to [filled].
  Widget _buildMiniStars(
      int filled, Color color, bool isDark, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isSelected = filled >= index + 1;
        return Icon(
          isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 13.sp,
          color: isSelected
              ? color
              : (isDark
                  ? theme.colorScheme.onSurfaceVariant.withOpacity(0.5)
                  : AppColors.cxPlatinumGray),
        );
      }),
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
    final baseColor = isDark ? const Color(0xFF1E1E2A) : const Color(0xFFE8E8EE);
    final highlightColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF5F5FA);
    final cardBg = isDark ? theme.colorScheme.surface : AppColors.cxWhite;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pie chart card skeleton
            Container(
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      Container(
                        width: 20.w,
                        height: 20.w,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 140.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(7.r),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 70.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  // Pie chart circle skeleton
                  Center(
                    child: Container(
                      width: 180.w,
                      height: 180.w,
                      decoration: BoxDecoration(
                        color: baseColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 100.w,
                          height: 100.w,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF12121A) : AppColors.cxF5F7F9,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  // Legend skeleton
                  Row(
                    children: List.generate(3, (i) => Padding(
                      padding: EdgeInsets.only(right: 14.w),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10.w,
                            height: 10.w,
                            decoration: BoxDecoration(
                              color: baseColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Container(
                            width: 44.w,
                            height: 10.h,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(5.r),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            // Section title skeleton
            Container(
              width: 160.w,
              height: 16.h,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            SizedBox(height: 12.h),
            // Rating card skeletons
            ...List.generate(4, (i) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42.w,
                          height: 42.w,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 14.h,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(7.r),
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Container(
                                height: 11.h,
                                width: 120.w,
                                decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(5.r),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    // Stars row skeleton
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (_) => Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      )),
                    ),
                  ],
                ),
              ),
            )),
            SizedBox(height: 8.h),
          ],
        ),
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
