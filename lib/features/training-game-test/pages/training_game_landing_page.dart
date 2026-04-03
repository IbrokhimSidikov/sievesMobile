import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../training-test/data/training_course_model.dart';
import '../data/game_session_model.dart';
import 'training_game_session.dart';

class TrainingGameLandingPage extends StatefulWidget {
  const TrainingGameLandingPage({super.key});

  @override
  State<TrainingGameLandingPage> createState() =>
      _TrainingGameLandingPageState();
}

class _TrainingGameLandingPageState extends State<TrainingGameLandingPage>
    with SingleTickerProviderStateMixin {
  final _authManager = AuthManager();
  late final TabController _tabController;

  // Courses
  bool _coursesLoading = true;
  bool _coursesError = false;
  String _coursesErrorMsg = '';
  List<TrainingCourse> _courses = [];

  // Leaderboard
  bool _rankLoading = true;
  bool _rankError = false;
  List<GameSession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCourses();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _coursesLoading = true;
      _coursesError = false;
      _coursesErrorMsg = '';
    });

    try {
      final courses = await _authManager.apiService.fetchTrainingCourses();
      final gameCourses =
          courses.where((c) => c.type?.toLowerCase() == 'game').toList();
      if (mounted) {
        setState(() {
          _courses = gameCourses;
          _coursesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _coursesError = true;
          _coursesErrorMsg = e.toString().replaceAll('Exception: ', '');
          _coursesLoading = false;
        });
      }
    }
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _rankLoading = true;
      _rankError = false;
    });

    try {
      final raw = await _authManager.apiService.fetchGameSessions();
      final sessions = raw
          .map((j) => GameSession.fromJson(j as Map<String, dynamic>))
          .toList();
      // Sort descending by score
      sessions.sort((a, b) => b.score.compareTo(a.score));
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _rankLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _rankError = true;
          _rankLoading = false;
        });
      }
    }
  }

  // ── Branch ID → Name map (edit as needed) ──────────────────────────────
  static const Map<int, String> _branchNames = {
    1: 'Branch 1',
    2: 'Administratsiya',
    3: 'Yunusobod',
    4: 'Beruniy',
    5: 'Chilonzor',
    11: 'Maksim G',
    14: 'Boulevard',
    15: 'Ava',
    25: 'Yangiyo\'l',
    26: 'High Town',
    // add more entries here
  };

  String _branchName(int? branchId) =>
      branchId != null ? (_branchNames[branchId] ?? 'Branch $branchId') : '—';

  void _startGame(TrainingCourse course) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => TrainingGameSession(
              courseId: course.id,
              courseName: course.name,
            ),
          ),
        )
        .then((_) => _loadLeaderboard());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F14) : AppColors.cxF5F7F9,
      body: Column(
        children: [
          _buildHeader(l10n, isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 0 — Courses
                _coursesLoading
                    ? _buildLoadingShimmer(isDark)
                    : _coursesError
                        ? _buildErrorState(l10n, isDark)
                        : _courses.isEmpty
                            ? _buildEmptyState(l10n, isDark)
                            : _buildCourseList(l10n, isDark),
                // Tab 1 — Leaderboard
                _rankLoading
                    ? _buildLeaderboardShimmer(isDark)
                    : _rankError
                        ? _buildLeaderboardError(l10n, isDark)
                        : _sessions.isEmpty
                            ? _buildLeaderboardEmpty(l10n, isDark)
                            : _buildLeaderboard(l10n, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(AppLocalizations l10n, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.cxEmeraldGreen.withOpacity(0.85),
                  AppColors.cx43C19F.withOpacity(0.6),
                ]
              : [
                  AppColors.cxEmeraldGreen,
                  AppColors.cx43C19F,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxEmeraldGreen.withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title row
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 52.h, 20.w, 16.h),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 18.r,
                    ),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.trainingGame,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        l10n.trainingGameSubtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sports_esports_rounded,
                        color: Colors.white,
                        size: 16.r,
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        l10n.gameMode,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Tab bar
          TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white.withOpacity(0.6),
            labelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.menu_book_rounded, size: 17.r),
                    SizedBox(width: 6.w),
                    Text(l10n.courses),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events_rounded, size: 17.r),
                    SizedBox(width: 6.w),
                    Text(l10n.leaderboard),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Courses loading shimmer ─────────────────────────────────────────────
  Widget _buildLoadingShimmer(bool isDark) {
    final base = isDark ? const Color(0xFF1A1A24) : Colors.grey[300]!;
    final highlight = isDark ? const Color(0xFF252532) : Colors.grey[100]!;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: EdgeInsets.only(bottom: 16.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A24) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
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
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100.w,
                  height: 22.h,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                SizedBox(height: 12.h),
                Container(
                  width: double.infinity,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 200.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  width: 130.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildErrorState(AppLocalizations l10n, bool isDark) {
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
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFE8E8F0)
                    : AppColors.cxDarkCharcoal,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _coursesErrorMsg,
              style: TextStyle(
                fontSize: 13.sp,
                color:
                    isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 28.h),
            GestureDetector(
              onTap: _loadCourses,
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 28.w, vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.cxEmeraldGreen, AppColors.cx43C19F],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cxEmeraldGreen.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        color: Colors.white, size: 20.r),
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

  // ── Empty ─────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: AppColors.cxEmeraldGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.sports_esports_outlined,
                  size: 52.r, color: AppColors.cxEmeraldGreen),
            ),
            SizedBox(height: 20.h),
            Text(
              l10n.noCourses,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFE8E8F0)
                    : AppColors.cxDarkCharcoal,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.trainingGameEmptyDesc,
              style: TextStyle(
                fontSize: 13.sp,
                color:
                    isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Course list ───────────────────────────────────────────────────────────
  Widget _buildCourseList(AppLocalizations l10n, bool isDark) {
    return Column(
      children: [
        // Info banner
        Container(
          margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.cxEmeraldGreen.withOpacity(0.2),
                      AppColors.cx43C19F.withOpacity(0.12),
                    ]
                  : [
                      AppColors.cxEmeraldGreen.withOpacity(0.1),
                      AppColors.cx43C19F.withOpacity(0.06),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: AppColors.cxEmeraldGreen.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  color: AppColors.cxEmeraldGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.sports_esports_rounded,
                  color: AppColors.cxEmeraldGreen,
                  size: 22.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.trainingGamePickCourse,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFE8E8F0)
                            : AppColors.cxDarkCharcoal,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${_courses.length} ${l10n.coursesFound}',
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
                  color: AppColors.cxEmeraldGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.cxEmeraldGreen.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_courses.length}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cxEmeraldGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 24.h),
            itemCount: _courses.length,
            itemBuilder: (_, i) =>
                _buildCourseCard(_courses[i], l10n, isDark),
          ),
        ),
      ],
    );
  }

  // ── Course card ───────────────────────────────────────────────────────────
  Widget _buildCourseCard(
      TrainingCourse course, AppLocalizations l10n, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? const Color(0xFF374151)
              : AppColors.cxPlatinumGray.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _startGame(course),
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme badge
                if (course.theme != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.cxEmeraldGreen.withOpacity(
                          isDark ? 0.25 : 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.cxEmeraldGreen.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.label_rounded,
                          size: 13.r,
                          color: AppColors.cxEmeraldGreen,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          '${l10n.courseTheme}: ${course.theme!.name}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFE8E8F0)
                                : AppColors.cxDarkCharcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: course.theme != null ? 12.h : 0),
                // Course name row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.cxEmeraldGreen.withOpacity(
                                isDark ? 0.3 : 0.15),
                            AppColors.cx43C19F.withOpacity(
                                isDark ? 0.2 : 0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: AppColors.cxEmeraldGreen.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.cast_for_education_rounded,
                        color: AppColors.cxEmeraldGreen,
                        size: 22.r,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? const Color(0xFFE8E8F0)
                                  : AppColors.cxDarkCharcoal,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            course.description,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: isDark
                                  ? const Color(0xFFD1D5DB)
                                  : AppColors.cxGraphiteGray,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Start game button
                Container(
                  height: 44.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.cxEmeraldGreen,
                        AppColors.cx43C19F,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cxEmeraldGreen.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _startGame(course),
                      borderRadius: BorderRadius.circular(14.r),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 20.r),
                            SizedBox(width: 6.w),
                            Text(
                              l10n.startGame,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Leaderboard shimmer ───────────────────────────────────────────────────
  Widget _buildLeaderboardShimmer(bool isDark) {
    final base = isDark ? const Color(0xFF1A1A24) : Colors.grey[300]!;
    final highlight = isDark ? const Color(0xFF252532) : Colors.grey[100]!;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
      itemCount: 6,
      itemBuilder: (_, __) => Container(
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A24) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
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
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: base,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 140.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 90.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: base,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 52.w,
                  height: 28.h,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Leaderboard error ─────────────────────────────────────────────────────
  Widget _buildLeaderboardError(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48.r, color: AppColors.cxCrimsonRed),
          SizedBox(height: 16.h),
          Text(
            l10n.errorLoadingCourses,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
            ),
          ),
          SizedBox(height: 16.h),
          GestureDetector(
            onTap: _loadLeaderboard,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.cxEmeraldGreen, AppColors.cx43C19F],
                ),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Text(
                l10n.retry,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Leaderboard empty ─────────────────────────────────────────────────────
  Widget _buildLeaderboardEmpty(AppLocalizations l10n, bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.emoji_events_outlined,
                size: 52.r,
                color: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              l10n.noLeaderboardData,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFE8E8F0)
                    : AppColors.cxDarkCharcoal,
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

  // ── Leaderboard list ──────────────────────────────────────────────────────
  Widget _buildLeaderboard(AppLocalizations l10n, bool isDark) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 24.h),
      itemCount: _sessions.length,
      itemBuilder: (_, i) => _buildRankCard(_sessions[i], i, isDark),
    );
  }

  Widget _buildRankCard(GameSession session, int index, bool isDark) {
    final rank = index + 1;
    final score = session.score;
    final isPassed = session.status.toLowerCase() == 'passed';

    // Medal colours for top 3
    final Color rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : isDark
                    ? const Color(0xFF6366F1)
                    : AppColors.cxEmeraldGreen;

    final bool isTopThree = rank <= 3;

    // Name resolution: prefer individual full name, fall back to identity username
    final individual = session.employee?.individual;
    final fullName = (individual != null && individual.fullName.isNotEmpty)
        ? individual.fullName
        : session.identity?.username ?? '—';
    final branchName = _branchName(session.employee?.branchId);
    final courseName = session.course?.name ?? '—';

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
                ? rankColor.withOpacity(0.15)
                : Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: isTopThree ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        child: Row(
          children: [
            // Rank badge
            Container(
              width: 44.w,
              height: 44.h,
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
                    ? Icon(
                        Icons.emoji_events_rounded,
                        size: 22.r,
                        color: rankColor,
                      )
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
            // Name + username + course
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
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
                  SizedBox(height: 3.h),
                  Row(
                    children: [
                      Icon(
                        Icons.store_rounded,
                        size: 12.r,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : AppColors.cxSilverTint,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        branchName,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : AppColors.cxSilverTint,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_rounded,
                        size: 12.r,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : AppColors.cxSilverTint,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          courseName,
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
            // Score pill
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
