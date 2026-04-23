import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../training-test/data/test_result_model.dart';

class GameTestResultPage extends StatefulWidget {
  final int sessionId;
  final String courseName;
  final Future<void>? submitFuture;

  const GameTestResultPage({
    super.key,
    required this.sessionId,
    required this.courseName,
    this.submitFuture,
  });

  @override
  State<GameTestResultPage> createState() => _GameTestResultPageState();
}

class _GameTestResultPageState extends State<GameTestResultPage>
    with SingleTickerProviderStateMixin {
  final _authManager = AuthManager();

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  TestSessionResult? _result;

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _loadResult();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadResult() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      // Wait for the background submit to complete (if provided) before
      // fetching results, so the server has processed the answers.
      if (widget.submitFuture != null) {
        await widget.submitFuture;
      }
      final result =
          await _authManager.apiService.fetchSessionResult(widget.sessionId);
      if (mounted) {
        setState(() {
          _result = result;
          _isLoading = false;
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F1A) : AppColors.cxF5F7F9,
        body: SafeArea(
          child: _isLoading
              ? _buildLoading(isDark, l10n)
              : _hasError
                  ? _buildError(isDark, l10n)
                  : _buildContent(isDark, l10n),
        ),
      ),
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────
  Widget _buildLoading(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.sports_esports_rounded,
                size: 36.r, color: Colors.white),
          ),
          SizedBox(height: 24.h),
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            l10n.loadingResults,
            style: TextStyle(
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : AppColors.cxGraphiteGray,
              fontSize: 15.sp,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              l10n.errorLoadingResults,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? const Color(0xFFE8E8F0)
                    : AppColors.cxDarkCharcoal,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : AppColors.cxGraphiteGray,
              ),
            ),
            SizedBox(height: 28.h),
            GestureDetector(
              onTap: _loadResult,
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.4),
                      blurRadius: 14,
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

  // ── Main content ───────────────────────────────────────────────────────────
  Widget _buildContent(bool isDark, AppLocalizations l10n) {
    final result = _result!;
    final score = double.tryParse(result.scorePercentage) ?? 0.0;
    final isPassed = result.status.toLowerCase() == 'passed';
    final wrong = result.totalMatches - result.correctMatches;

    return CustomScrollView(
      slivers: [
        // ── Hero header ──────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _buildHeroHeader(isDark, l10n, score, isPassed, result),
        ),
        // ── Stats row ────────────────────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 0),
          sliver: SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildStatsRow(isDark, l10n, result, wrong),
            ),
          ),
        ),
        // ── Passing score info ───────────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
          sliver: SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildPassingInfo(isDark, l10n, result, isPassed),
            ),
          ),
        ),
        // ── Detailed results list ────────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 0),
          sliver: SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                l10n.detailedResults,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? const Color(0xFFE8E8F0)
                      : AppColors.cxDarkCharcoal,
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => FadeTransition(
                opacity: _fadeAnimation,
                child:
                    _buildResultItem(isDark, l10n, result.results[i], i + 1),
              ),
              childCount: result.results.length,
            ),
          ),
        ),
        // ── Action button ────────────────────────────────────────────────────
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
          sliver: SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildDoneButton(isDark, l10n),
            ),
          ),
        ),
      ],
    );
  }

  // ── Hero header with score circle ──────────────────────────────────────────
  Widget _buildHeroHeader(
    bool isDark,
    AppLocalizations l10n,
    double score,
    bool isPassed,
    TestSessionResult result,
  ) {
    final heroGradient = isPassed
        ? const [Color(0xFF10B981), Color(0xFF059669)]
        : const [Color(0xFFEF4444), Color(0xFFDC2626)];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
        padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: heroGradient,
          ),
          borderRadius: BorderRadius.circular(28.r),
          boxShadow: [
            BoxShadow(
              color: heroGradient[0].withOpacity(0.4),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Course name badge
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_esports_rounded,
                      size: 14.r, color: Colors.white),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      widget.courseName,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            // Score circle
            ScaleTransition(
              scale: _scaleAnimation,
              child: AnimatedBuilder(
                animation: _progressAnimation,
                builder: (_, __) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 160.r,
                        height: 160.r,
                        child: CircularProgressIndicator(
                          value: (score / 100) * _progressAnimation.value,
                          strokeWidth: 10,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(score * _progressAnimation.value).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 44.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            l10n.score,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.white.withOpacity(0.85),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
            // Result label
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPassed
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: Colors.white,
                  size: 26.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  isPassed
                      ? l10n.congratulations
                      : l10n.keepTrying,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 6.h),
            Text(
              isPassed
                  ? l10n.youPassedTest
                  : '${l10n.youNeedToPass} ${result.passingScore}% ${l10n.toPass}',
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.white.withOpacity(0.88),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats row (Total / Correct / Wrong) ────────────────────────────────────
  Widget _buildStatsRow(
    bool isDark,
    AppLocalizations l10n,
    TestSessionResult result,
    int wrong,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            icon: Icons.quiz_rounded,
            label: l10n.totalQuestions,
            value: '${result.totalQuestions}',
            color: const Color(0xFF6366F1),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            icon: Icons.check_circle_rounded,
            label: l10n.correct,
            value: '${result.correctMatches}',
            color: const Color(0xFF10B981),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            icon: Icons.cancel_rounded,
            label: l10n.wrong,
            value: '$wrong',
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: color.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.1 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(9.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22.r),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? const Color(0xFFE8E8F0)
                  : AppColors.cxDarkCharcoal,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.sp,
              color: isDark
                  ? const Color(0xFF9CA3AF)
                  : AppColors.cxGraphiteGray,
            ),
          ),
        ],
      ),
    );
  }

  // ── Passing score pill ─────────────────────────────────────────────────────
  Widget _buildPassingInfo(
    bool isDark,
    AppLocalizations l10n,
    TestSessionResult result,
    bool isPassed,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isPassed
              ? const Color(0xFF10B981).withOpacity(0.35)
              : const Color(0xFFEF4444).withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 20.r,
            color: isPassed
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              '${l10n.youNeedToPass} ${result.passingScore}% ${l10n.toPass}',
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : AppColors.cxGraphiteGray,
              ),
            ),
          ),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPassed
                    ? [
                        const Color(0xFF10B981),
                        const Color(0xFF059669),
                      ]
                    : [
                        const Color(0xFFEF4444),
                        const Color(0xFFDC2626),
                      ],
              ),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              isPassed ? l10n.youPassedTest : l10n.keepTrying,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Result item ────────────────────────────────────────────────────────────
  Widget _buildResultItem(
    bool isDark,
    AppLocalizations l10n,
    TestResultDetail detail,
    int questionNumber,
  ) {
    final isCorrect = detail.isCorrect;
    final correctColor = const Color(0xFF10B981);
    final wrongColor = const Color(0xFFEF4444);
    final accentColor = isCorrect ? correctColor : wrongColor;

    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(isDark ? 0.08 : 0.06),
            blurRadius: 10,
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
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 14.r,
                      color: accentColor,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      isCorrect ? l10n.correct : l10n.wrong,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  'Q$questionNumber',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6366F1),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            detail.test.question,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? const Color(0xFFE8E8F0)
                  : AppColors.cxDarkCharcoal,
            ),
          ),
          if (detail.option != null) ...[
            SizedBox(height: 10.h),
            _buildOptionAnswer(isDark, detail),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionAnswer(bool isDark, TestResultDetail detail) {
    final isCorrect = detail.isCorrect;
    final accentColor =
        isCorrect ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            size: 18.r,
            color: accentColor,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              detail.option!.text,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? const Color(0xFFE8E8F0)
                    : AppColors.cxDarkCharcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Done button ────────────────────────────────────────────────────────────
  Widget _buildDoneButton(bool isDark, AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(18.r),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_rounded, color: Colors.white, size: 20.r),
            SizedBox(width: 10.w),
            Text(
              l10n.backToCourses,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
