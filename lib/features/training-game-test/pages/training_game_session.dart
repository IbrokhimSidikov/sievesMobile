import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../training-test/data/test_models.dart';
import 'test_results_page.dart';

class TrainingGameSession extends StatefulWidget {
  final int courseId;
  final String courseName;

  const TrainingGameSession({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<TrainingGameSession> createState() => _TrainingGameSessionState();
}

class _TrainingGameSessionState extends State<TrainingGameSession>
    with WidgetsBindingObserver {
  // State
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSubmitting = false;
  bool _sessionTerminated = false;

  // Questions
  List<Test> _questions = [];
  int _currentIndex = 0;

  // Answers: questionId -> selected optionId
  Map<int, int> _selectedAnswers = {};

  // Timer
  Timer? _countdownTimer;
  int _elapsedSeconds = 0;

  // Page controller
  late PageController _pageController;

  // Session
  int? _sessionId;

  // Auth
  final _authManager = AuthManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    _fetchQuestions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ── App lifecycle: terminate if user backgrounds the app ──────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (!_sessionTerminated && !_isLoading && !_isSubmitting) {
        _terminateSession(reason: 'app_backgrounded');
      }
    }
  }

  // ── API ───────────────────────────────────────────────────────────────────
  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final courseWithTests =
          await _authManager.apiService.fetchCourseWithTests(widget.courseId);

      // Start a server-side session
      final sessionId =
          await _authManager.apiService.startTrainingSession(widget.courseId);

      // Filter only multiple-choice questions
      final mcqTests = courseWithTests.tests
          .where((t) => t.options.isNotEmpty)
          .toList();

      // Shuffle and take at most 25 random questions
      mcqTests.shuffle(Random());
      final limited = mcqTests.take(25).toList();

      if (mounted) {
        setState(() {
          _sessionId = sessionId;
          _questions = limited;
          _isLoading = false;
        });
        _startTimer();
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

  // ── Timer ─────────────────────────────────────────────────────────────────
  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsedSeconds++);
      }
    });
  }

  String get _formattedTime {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Answer selection ──────────────────────────────────────────────────────
  void _selectOption(int questionId, int optionId) {
    setState(() {
      _selectedAnswers[questionId] = optionId;
    });
  }

  // ── Navigation ────────────────────────────────────────────────────────────
  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentIndex = index);
  }

  // ── Localized confirm dialog ──────────────────────────────────────────────
  AppLocalizations get _l10n => AppLocalizations.of(context);

  // ── Session termination (exit / background) ───────────────────────────────
  Future<void> _terminateSession({String reason = 'user_exit'}) async {
    if (_sessionTerminated) return;
    _sessionTerminated = true;
    _countdownTimer?.cancel();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TestResultsPage(
          courseName: widget.courseName,
          questions: _questions,
          selectedAnswers: _selectedAnswers,
          elapsedSeconds: _elapsedSeconds,
          terminated: true,
          terminationReason: reason,
        ),
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submitTest() async {
    final unanswered = _questions.length - _selectedAnswers.length;

    if (unanswered > 0) {
      final confirm = await _showConfirmDialog(
        title: _l10n.submitTestTitle,
        message: _l10n.unansweredMsg(unanswered),
        confirmLabel: _l10n.submit,
        confirmColor: AppColors.cxEmeraldGreen,
      );
      if (confirm != true) return;
    }

    setState(() => _isSubmitting = true);
    _countdownTimer?.cancel();
    _sessionTerminated = true;

    // Build option answers payload
    final List<Map<String, dynamic>> optionAnswers = _selectedAnswers.entries
        .map((e) => {'test_id': e.key, 'option_id': e.value})
        .toList();

    try {
      if (_sessionId != null) {
        await _authManager.apiService.submitTrainingSession(
          sessionId: _sessionId!,
          matchAnswers: const [],
          optionAnswers: optionAnswers,
        );
      }
    } catch (e) {
      // Submission failed — still show local results
      print('⚠️ [GameSession] Submit failed: $e');
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TestResultsPage(
          courseName: widget.courseName,
          questions: _questions,
          selectedAnswers: _selectedAnswers,
          elapsedSeconds: _elapsedSeconds,
          terminated: false,
        ),
      ),
    );
  }

  // ── Back button / exit guard ──────────────────────────────────────────────
  Future<bool> _onWillPop() async {
    final shouldExit = await _showConfirmDialog(
      title: _l10n.exitSession,
      message: _l10n.exitSessionMsg,
      confirmLabel: _l10n.exit,
      confirmColor: AppColors.cxCrimsonRed,
    );
    if (shouldExit == true) {
      await _terminateSession(reason: 'user_exit');
    }
    return false; // We handle navigation ourselves
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1A1A24) : AppColors.cxPureWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14.sp,
            color: isDark
                ? const Color(0xFF9CA3AF)
                : AppColors.cxGraphiteGray,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              _l10n.cancel,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : AppColors.cxSilverTint,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F14) : AppColors.cxF5F7F9,
        body: _isLoading
            ? _buildLoadingState(isDark)
            : _hasError
                ? _buildErrorState(isDark)
                : _questions.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildSessionBody(isDark),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoadingState(bool isDark) {
    final base =
        isDark ? const Color(0xFF1A1A24) : Colors.grey[300]!;
    final highlight =
        isDark ? const Color(0xFF252532) : Colors.grey[100]!;

    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(isDark, loading: true),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                children: [
                  // Progress shimmer
                  Shimmer.fromColors(
                    baseColor: base,
                    highlightColor: highlight,
                    child: Container(
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: base,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  // Question card shimmer
                  Container(
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1A24)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                    child: Shimmer.fromColors(
                      baseColor: base,
                      highlightColor: highlight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 60.w,
                            height: 28.h,
                            decoration: BoxDecoration(
                              color: base,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          SizedBox(height: 20.h),
                          Container(
                            width: double.infinity,
                            height: 22.h,
                            decoration: BoxDecoration(
                              color: base,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            width: 220.w,
                            height: 22.h,
                            decoration: BoxDecoration(
                              color: base,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                          SizedBox(height: 32.h),
                          ...List.generate(4, (i) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: Container(
                                width: double.infinity,
                                height: 56.h,
                                decoration: BoxDecoration(
                                  color: base,
                                  borderRadius:
                                      BorderRadius.circular(16.r),
                                ),
                              ),
                            );
                          }),
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

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildErrorState(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(isDark),
          Expanded(
            child: Center(
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
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 48.r,
                        color: AppColors.cxCrimsonRed,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      _l10n.failedToLoadQuestions,
                      style: TextStyle(
                        fontSize: 20.sp,
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
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : AppColors.cxSilverTint,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),
                    GestureDetector(
                      onTap: _fetchQuestions,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 28.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF8B5CF6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFF6366F1).withOpacity(0.4),
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
                              _l10n.tryAgain,
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
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty ─────────────────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(isDark),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(24.r),
                      decoration: BoxDecoration(
                        color: AppColors.cxAmberGold.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.quiz_outlined,
                        size: 48.r,
                        color: AppColors.cxAmberGold,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      _l10n.noQuestionsAvailable,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? const Color(0xFFE8E8F0)
                            : AppColors.cxDarkCharcoal,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _l10n.noMcqQuestions,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: isDark
                            ? const Color(0xFF9CA3AF)
                            : AppColors.cxSilverTint,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32.h),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 28.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF252532)
                              : AppColors.cxPlatinumGray,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Text(
                          _l10n.goBack,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFE8E8F0)
                                : AppColors.cxDarkCharcoal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main session UI ───────────────────────────────────────────────────────
  Widget _buildSessionBody(bool isDark) {
    final question = _questions[_currentIndex];
    final isLast = _currentIndex == _questions.length - 1;
    final answeredCount = _selectedAnswers.length;
    final totalCount = _questions.length;
    final progress = answeredCount / totalCount;

    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(isDark),
          _buildProgressSection(isDark, progress, answeredCount, totalCount),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: _questions.length,
              itemBuilder: (_, i) =>
                  _buildQuestionCard(_questions[i], isDark),
            ),
          ),
          _buildBottomBar(isDark, isLast, question),
        ],
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar(bool isDark, {bool loading = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (!loading) await _onWillPop();
            },
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF252532)
                    : AppColors.cxF5F7F9,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18.r,
                color: isDark
                    ? const Color(0xFFE8E8F0)
                    : AppColors.cxDarkCharcoal,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.courseName,
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
                if (!loading)
                  Text(
                    '${_l10n.question} ${_currentIndex + 1} / ${_questions.length}',
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
          // Timer badge
          if (!loading)
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined,
                      color: Colors.white, size: 16.r),
                  SizedBox(width: 5.w),
                  Text(
                    _formattedTime,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Progress section ──────────────────────────────────────────────────────
  Widget _buildProgressSection(
      bool isDark, double progress, int answered, int total) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      color: isDark
          ? const Color(0xFF1A1A24).withOpacity(0.5)
          : Colors.white.withOpacity(0.7),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _l10n.progress,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : AppColors.cxSilverTint,
                ),
              ),
              Text(
                '$answered / $total ${_l10n.answered}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7.h,
              backgroundColor: isDark
                  ? const Color(0xFF252532)
                  : AppColors.cxPlatinumGray,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6366F1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Question card ─────────────────────────────────────────────────────────
  Widget _buildQuestionCard(Test question, bool isDark) {
    final selectedOptionId = _selectedAnswers[question.id];
    // Show up to 4 options
    final options = question.options.take(4).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A24) : Colors.white,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF374151)
                    : AppColors.cxPlatinumGray.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(isDark ? 0.35 : 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Q badge
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Q${_currentIndex + 1}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Question text
                Text(
                  question.question,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFE8E8F0)
                        : AppColors.cxDarkCharcoal,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          // Options
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final option = entry.value;
            final isSelected = selectedOptionId == option.id;
            final label = String.fromCharCode(65 + idx); // A, B, C, D

            return _buildOptionTile(
              isDark: isDark,
              label: label,
              text: option.text,
              isSelected: isSelected,
              onTap: () => _selectOption(question.id, option.id),
            );
          }),
          SizedBox(height: 12.h),
          // Quick-nav dots
          _buildQuickNavDots(isDark),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required bool isDark,
    required String label,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withOpacity(isDark ? 0.2 : 0.08)
              : (isDark ? const Color(0xFF1A1A24) : Colors.white),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : (isDark
                    ? const Color(0xFF374151)
                    : AppColors.cxPlatinumGray.withOpacity(0.5)),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(isDark ? 0.25 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Label bubble
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36.w,
              height: 36.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark
                        ? const Color(0xFF252532)
                        : AppColors.cxF5F7F9),
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark
                            ? const Color(0xFF374151)
                            : AppColors.cxPlatinumGray,
                        width: 1.5,
                      ),
              ),
              child: Center(
                child: isSelected
                    ? Icon(Icons.check_rounded,
                        color: Colors.white, size: 18.r)
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : AppColors.cxSilverTint,
                        ),
                      ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFFE8E8F0)
                          : AppColors.cxDarkCharcoal)
                      : (isDark
                          ? const Color(0xFFD1D5DB)
                          : AppColors.cxGraphiteGray),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Quick nav dots ────────────────────────────────────────────────────────
  Widget _buildQuickNavDots(bool isDark) {
    return SizedBox(
      height: 32.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _questions.length,
        itemBuilder: (_, i) {
          final isCurrent = i == _currentIndex;
          final isAnswered =
              _selectedAnswers.containsKey(_questions[i].id);
          return GestureDetector(
            onTap: () => _goToPage(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: 6.w),
              width: isCurrent ? 28.w : 28.w,
              height: 28.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isCurrent
                    ? const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      )
                    : null,
                color: isCurrent
                    ? null
                    : isAnswered
                        ? AppColors.cxEmeraldGreen.withOpacity(0.15)
                        : (isDark
                            ? const Color(0xFF252532)
                            : AppColors.cxPlatinumGray),
                border: isCurrent
                    ? null
                    : Border.all(
                        color: isAnswered
                            ? AppColors.cxEmeraldGreen
                            : (isDark
                                ? const Color(0xFF374151)
                                : AppColors.cxSilverTint.withOpacity(0.4)),
                        width: 1.5,
                      ),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: isCurrent
                        ? Colors.white
                        : isAnswered
                            ? AppColors.cxEmeraldGreen
                            : (isDark
                                ? const Color(0xFF9CA3AF)
                                : AppColors.cxSilverTint),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Bottom navigation bar ─────────────────────────────────────────────────
  Widget _buildBottomBar(bool isDark, bool isLast, Test question) {
    final isFirst = _currentIndex == 0;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Previous
            if (!isFirst)
              Container(
                width: 56.w,
                height: 56.h,
                margin: EdgeInsets.only(right: 12.w),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF252532)
                      : AppColors.cxF5F7F9,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : AppColors.cxPlatinumGray,
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _goToPage(_currentIndex - 1),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: isDark
                          ? const Color(0xFFE8E8F0)
                          : AppColors.cxDarkCharcoal,
                      size: 22.r,
                    ),
                  ),
                ),
              ),
            // Next or Submit
            Expanded(
              child: Container(
                height: 56.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLast
                        ? [
                            AppColors.cxEmeraldGreen,
                            AppColors.cx43C19F,
                          ]
                        : [
                            const Color(0xFF6366F1),
                            const Color(0xFF8B5CF6),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  boxShadow: [
                    BoxShadow(
                      color: (isLast
                              ? AppColors.cxEmeraldGreen
                              : const Color(0xFF6366F1))
                          .withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSubmitting
                        ? null
                        : (isLast
                            ? _submitTest
                            : () => _goToPage(_currentIndex + 1)),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Center(
                      child: _isSubmitting && isLast
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Text(
                                  _l10n.submittingEllipsis,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isLast ? _l10n.submitTest : _l10n.next,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Icon(
                                  isLast
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20.r,
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
