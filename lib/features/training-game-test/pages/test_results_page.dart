import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../data/game_session_model.dart';

class TestResultsPage extends StatefulWidget {
  const TestResultsPage({super.key});

  @override
  State<TestResultsPage> createState() => _TestResultsPageState();
}

class _TestResultsPageState extends State<TestResultsPage> {
  final _authManager = AuthManager();

  bool _loading = true;
  bool _error = false;
  List<GameSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadRanking();
  }

  Future<void> _loadRanking() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final raw = await _authManager.apiService.fetchGameSessions();
      final sessions = raw
          .map((j) => GameSession.fromJson(j as Map<String, dynamic>))
          .where((s) =>
              (s.employeeName?.isNotEmpty ?? false) ||
              (s.employeeRegistrationNumber?.isNotEmpty ?? false))
          .toList();
      sessions.sort((a, b) => b.score.compareTo(a.score));
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    if (_loading) return _buildShimmer(isDark);
    if (_error) return _buildError(isDark, l10n);
    if (_sessions.isEmpty) return _buildEmpty(isDark, l10n);
    return _buildRankingList(isDark, l10n);
  }

  // ── Shimmer ────────────────────────────────────────────────────────────────
  Widget _buildShimmer(bool isDark) {
    final base = isDark ? const Color(0xFF1A1A24) : Colors.grey[300]!;
    final highlight = isDark ? const Color(0xFF252532) : Colors.grey[100]!;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
      itemCount: 8,
      itemBuilder: (_, __) => Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A24) : Colors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isDark
                ? const Color(0xFF374151)
                : AppColors.cxPlatinumGray.withOpacity(0.3),
          ),
        ),
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(color: base, shape: BoxShape.circle),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 150.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 100.w,
                        height: 11.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        width: 180.w,
                        height: 11.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 54.w,
                      height: 30.h,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: 38.w,
                      height: 11.h,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: AppColors.cxCrimsonRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded,
                  size: 48.r, color: AppColors.cxCrimsonRed),
            ),
            SizedBox(height: 20.h),
            Text(
              l10n.errorLoadingCourses,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            GestureDetector(
              onTap: _loadRanking,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.cxEmeraldGreen, AppColors.cx43C19F],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cxEmeraldGreen.withOpacity(0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, color: Colors.white, size: 20.r),
                    SizedBox(width: 8.w),
                    Text(
                      l10n.retry,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────
  Widget _buildEmpty(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(28.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.emoji_events_outlined,
                  size: 52.r, color: const Color(0xFFF59E0B)),
            ),
            SizedBox(height: 20.h),
            Text(
              l10n.noLeaderboardData,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.noLeaderboardDesc,
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Ranking list ───────────────────────────────────────────────────────────
  Widget _buildRankingList(bool isDark, AppLocalizations l10n) {
    return RefreshIndicator(
      color: AppColors.cxEmeraldGreen,
      onRefresh: _loadRanking,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        itemCount: _sessions.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return _buildListHeader(isDark, l10n);
          return _buildRankCard(_sessions[i - 1], i, isDark);
        },
      ),
    );
  }

  Widget _buildListHeader(bool isDark, AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFFF59E0B).withOpacity(0.2),
                  const Color(0xFFF59E0B).withOpacity(0.08),
                ]
              : [
                  const Color(0xFFF59E0B).withOpacity(0.12),
                  const Color(0xFFF59E0B).withOpacity(0.04),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: const Color(0xFFF59E0B),
              size: 22.r,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.leaderboard,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFE8E8F0)
                        : AppColors.cxDarkCharcoal,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.leaderboardSubtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : AppColors.cxSilverTint,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              '${_sessions.length}',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF59E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankCard(GameSession session, int rank, bool isDark) {
    final score = session.score;
    final isPassed = session.status.toLowerCase() == 'passed';
    final isTopThree = rank <= 3;

    final Color rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : isDark
                    ? const Color(0xFF6366F1)
                    : AppColors.cxEmeraldGreen;

    final individual = session.employee?.individual;
    final displayName = session.employeeName?.isNotEmpty == true
        ? session.employeeName!
        : (individual != null && individual.fullName.isNotEmpty)
            ? individual.fullName
            : session.identity?.username ?? '—';

    final regNumber = session.employeeRegistrationNumber;
    final courseDisplay = session.courseName?.isNotEmpty == true
        ? session.courseName!
        : session.course?.name ?? '—';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isTopThree
              ? rankColor.withOpacity(0.5)
              : isDark
                  ? const Color(0xFF374151)
                  : AppColors.cxPlatinumGray.withOpacity(0.35),
          width: isTopThree ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isTopThree
                ? rankColor.withOpacity(0.18)
                : Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: isTopThree ? 18 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            // ── Rank badge ──────────────────────────────────────────────────
            Container(
              width: 46.w,
              height: 46.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isTopThree
                    ? rankColor.withOpacity(isDark ? 0.2 : 0.12)
                    : isDark
                        ? const Color(0xFF252532)
                        : AppColors.cxF5F7F9,
                border: Border.all(color: rankColor.withOpacity(0.5), width: 1.5),
              ),
              child: Center(
                child: isTopThree
                    ? Icon(Icons.emoji_events_rounded, size: 22.r, color: rankColor)
                    : Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                        ),
                      ),
              ),
            ),
            SizedBox(width: 14.w),
            // ── Name / course / reg ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFE8E8F0)
                          : AppColors.cxDarkCharcoal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (regNumber != null) ...[
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(Icons.badge_outlined,
                            size: 12.r,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : AppColors.cxSilverTint),
                        SizedBox(width: 3.w),
                        Text(
                          '#$regNumber',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : AppColors.cxSilverTint,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (session.branchName?.isNotEmpty ?? false) ...[
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(Icons.store_rounded,
                            size: 12.r,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : AppColors.cxSilverTint),
                        SizedBox(width: 3.w),
                        Text(
                          session.branchName!,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : AppColors.cxSilverTint,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded,
                          size: 12.r,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : AppColors.cxSilverTint),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          courseDisplay,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: isDark
                                ? const Color(0xFF9CA3AF)
                                : AppColors.cxSilverTint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // ── Score pill ──────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isPassed
                          ? [AppColors.cxEmeraldGreen, AppColors.cx43C19F]
                          : [
                              AppColors.cxCrimsonRed,
                              AppColors.cxCrimsonRed.withOpacity(0.8),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: (isPassed
                                ? AppColors.cxEmeraldGreen
                                : AppColors.cxCrimsonRed)
                            .withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    '${score.toStringAsFixed(score.truncateToDouble() == score ? 0 : 1)}%',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  '${session.correctMatches}/${session.totalQuestions}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : AppColors.cxSilverTint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
