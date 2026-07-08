import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/exam_models.dart';
import 'exam_result_page.dart';

/// The locked exam executioner. Once here the user is committed:
///  - the OS back gesture asks for confirmation, then submits as-is;
///  - backgrounding / app-switching (any non-resumed lifecycle state)
///    terminates and auto-submits the attempt;
///  - the countdown auto-submits when it hits zero.
/// Every path routes forward to the result — never back into the exam.
class ExamTakingPage extends StatefulWidget {
  final ExamAttempt attempt;
  const ExamTakingPage({super.key, required this.attempt});

  @override
  State<ExamTakingPage> createState() => _ExamTakingPageState();
}

class _ExamTakingPageState extends State<ExamTakingPage>
    with WidgetsBindingObserver {
  final _authManager = AuthManager();
  final _pageController = PageController();

  // questionId -> selected optionIds
  final Map<int, Set<int>> _selected = {};

  int _currentIndex = 0;
  bool _finalized = false; // guards against double submit
  bool _isSubmitting = false;

  Timer? _timer;
  int _remainingSeconds = 0; // 0 with no expiry means "no limit"
  bool _hasTimeLimit = false;

  List<ExamQuestion> get _questions => widget.attempt.questions;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ── Lifecycle: leaving the app terminates the exam ─────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      if (!_finalized && !_isSubmitting) {
        _terminate(reason: 'app_backgrounded');
      }
    }
  }

  // ── Timer ──────────────────────────────────────────────────────────────────
  void _initTimer() {
    final expiresAt = widget.attempt.expiresAt;
    if (widget.attempt.durationMinutes <= 0 || expiresAt == null) {
      _hasTimeLimit = false;
      return;
    }
    _hasTimeLimit = true;
    _remainingSeconds = expiresAt.difference(DateTime.now()).inSeconds;
    if (_remainingSeconds <= 0) {
      // Already expired before we even rendered.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _terminate(reason: 'time_expired');
      });
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final left = expiresAt.difference(DateTime.now()).inSeconds;
      if (left <= 0) {
        if (mounted) setState(() => _remainingSeconds = 0);
        _terminate(reason: 'time_expired');
      } else if (mounted) {
        setState(() => _remainingSeconds = left);
      }
    });
  }

  String get _formattedTime {
    final m = _remainingSeconds ~/ 60;
    final s = _remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ── Selection ───────────────────────────────────────────────────────────────
  void _toggleOption(ExamQuestion q, int optionId) {
    setState(() {
      final set = _selected.putIfAbsent(q.id, () => <int>{});
      if (q.isMultiple) {
        if (!set.remove(optionId)) set.add(optionId);
      } else {
        set
          ..clear()
          ..add(optionId);
      }
      if (set.isEmpty) _selected.remove(q.id);
    });
  }

  int get _answeredCount =>
      _selected.values.where((s) => s.isNotEmpty).length;

  List<Map<String, dynamic>> _buildAnswers() {
    return _selected.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => {
              'question_id': e.key,
              'selected_option_ids': e.value.toList(),
            })
        .toList();
  }

  // ── Navigation ───────────────────────────────────────────────────────────────
  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    setState(() => _currentIndex = index);
  }

  // ── Submit (button) — shows the score immediately ──────────────────────────
  Future<void> _submit() async {
    if (_finalized) return;
    _finalized = true;
    _timer?.cancel();
    setState(() => _isSubmitting = true);

    try {
      final data = await _authManager.apiService.submitExam(
        attemptId: widget.attempt.attemptId,
        answers: _buildAnswers(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ExamResultPage(
            attemptId: widget.attempt.attemptId,
            examTitle: widget.attempt.title,
            initialResult: ExamResult.fromJson(data),
          ),
        ),
      );
    } catch (_) {
      // Fall back to fetching the result (backend still finalizes on read).
      _goToResultFetching();
    }
  }

  // ── Terminate (background / exit / time) — submit as-is ────────────────────
  Future<void> _terminate({required String reason}) async {
    if (_finalized) return;
    _finalized = true;
    _timer?.cancel();

    // Fire the submit; we don't block navigation on it. The backend also has a
    // lazy-expiry safety net if this request never lands.
    // ignore: unawaited_futures
    _authManager.apiService
        .submitExam(
          attemptId: widget.attempt.attemptId,
          answers: _buildAnswers(),
          reason: reason,
        )
        .catchError((_) => <String, dynamic>{});

    _goToResultFetching();
  }

  void _goToResultFetching() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ExamResultPage(
          attemptId: widget.attempt.attemptId,
          examTitle: widget.attempt.title,
        ),
      ),
    );
  }

  // ── Back guard ───────────────────────────────────────────────────────────────
  Future<bool> _onWillPop() async {
    if (_finalized) return true;
    final confirm = await _confirmExit();
    if (confirm == true) {
      await _terminate(reason: 'user_exit');
    }
    return false; // navigation handled by _terminate
  }

  Future<bool?> _confirmExit() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1A1A24) : AppColors.cxPureWhite,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(_l10n.examEndConfirmTitle,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text(_l10n.examEndConfirmBody,
            style: TextStyle(fontSize: 14.sp, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cxCrimsonRed,
              foregroundColor: Colors.white,
            ),
            child: Text(_l10n.examEndConfirmTitle),
          ),
        ],
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F14) : AppColors.cxF5F7F9,
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(isDark),
              _buildProgress(isDark),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentIndex = i),
                  itemCount: _questions.length,
                  itemBuilder: (_, i) => _buildQuestionCard(_questions[i], isDark),
                ),
              ),
              _buildBottomBar(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
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
            onTap: _onWillPop,
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252532) : AppColors.cxF5F7F9,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(Icons.close_rounded,
                  size: 18.r,
                  color: isDark
                      ? const Color(0xFFE8E8F0)
                      : AppColors.cxDarkCharcoal),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              widget.attempt.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
              ),
            ),
          ),
          if (_hasTimeLimit)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: _remainingSeconds <= 30
                    ? AppColors.cxCrimsonRed
                    : AppColors.cxRoyalBlue,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined, color: Colors.white, size: 16.r),
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

  Widget _buildProgress(bool isDark) {
    final total = _questions.length;
    final progress = total == 0 ? 0.0 : _answeredCount / total;
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
                '${_currentIndex + 1} / $total',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : AppColors.cxSilverTint,
                ),
              ),
              Text(
                '$_answeredCount / $total',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cxRoyalBlue,
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
              backgroundColor:
                  isDark ? const Color(0xFF252532) : AppColors.cxPlatinumGray,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.cxRoyalBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(ExamQuestion question, bool isDark) {
    final selected = _selected[question.id] ?? <int>{};

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A24) : Colors.white,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF374151)
                    : AppColors.cxPlatinumGray.withOpacity(0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.text,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: isDark
                        ? const Color(0xFFE8E8F0)
                        : AppColors.cxDarkCharcoal,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  question.isMultiple
                      ? _l10n.examSelectAllThatApply
                      : _l10n.examSelectOne,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : AppColors.cxSilverTint,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          ...question.options.map((option) {
            final isSelected = selected.contains(option.id);
            return _buildOptionTile(
              isDark: isDark,
              text: option.text,
              isSelected: isSelected,
              isMultiple: question.isMultiple,
              onTap: () => _toggleOption(question, option.id),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required bool isDark,
    required String text,
    required bool isSelected,
    required bool isMultiple,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cxRoyalBlue.withOpacity(isDark ? 0.2 : 0.08)
              : (isDark ? const Color(0xFF1A1A24) : Colors.white),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected
                ? AppColors.cxRoyalBlue
                : (isDark
                    ? const Color(0xFF374151)
                    : AppColors.cxPlatinumGray.withOpacity(0.5)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 26.w,
              height: 26.w,
              decoration: BoxDecoration(
                shape: isMultiple ? BoxShape.rectangle : BoxShape.circle,
                borderRadius:
                    isMultiple ? BorderRadius.circular(7.r) : null,
                color: isSelected ? AppColors.cxRoyalBlue : null,
                border: isSelected
                    ? null
                    : Border.all(
                        color: isDark
                            ? const Color(0xFF374151)
                            : AppColors.cxPlatinumGray,
                        width: 1.5,
                      ),
              ),
              child: isSelected
                  ? Icon(Icons.check_rounded, color: Colors.white, size: 17.r)
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  height: 1.4,
                  color: isSelected
                      ? (isDark
                          ? const Color(0xFFE8E8F0)
                          : AppColors.cxDarkCharcoal)
                      : (isDark
                          ? const Color(0xFFD1D5DB)
                          : AppColors.cxGraphiteGray),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == _questions.length - 1;

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
      child: Row(
        children: [
          if (!isFirst)
            Container(
              width: 54.w,
              height: 54.h,
              margin: EdgeInsets.only(right: 12.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252532) : AppColors.cxF5F7F9,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _goToPage(_currentIndex - 1),
                  borderRadius: BorderRadius.circular(14.r),
                  child: Icon(Icons.arrow_back_rounded,
                      color: isDark
                          ? const Color(0xFFE8E8F0)
                          : AppColors.cxDarkCharcoal,
                      size: 22.r),
                ),
              ),
            ),
          Expanded(
            child: SizedBox(
              height: 54.h,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : (isLast ? _submit : () => _goToPage(_currentIndex + 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLast
                      ? AppColors.cxEmeraldGreen
                      : AppColors.cxRoyalBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 22.w,
                        height: 22.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isLast ? _l10n.examSubmit : _l10n.next,
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
