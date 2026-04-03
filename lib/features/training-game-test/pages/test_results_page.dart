import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../training-test/data/test_models.dart';

class TestResultsPage extends StatefulWidget {
  final String courseName;
  final List<Test> questions;
  final Map<int, int> selectedAnswers;
  final int elapsedSeconds;
  final bool terminated;
  final String? terminationReason;

  const TestResultsPage({
    super.key,
    required this.courseName,
    required this.questions,
    required this.selectedAnswers,
    required this.elapsedSeconds,
    required this.terminated,
    this.terminationReason,
  });

  @override
  State<TestResultsPage> createState() => _TestResultsPageState();
}

class _TestResultsPageState extends State<TestResultsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  // Computed results
  late int _totalQuestions;
  late int _answeredQuestions;
  late int _correctAnswers;
  late int _incorrectAnswers;
  late int _skippedQuestions;
  late double _scorePercent;
  late bool _passed;

  // View toggle
  bool _showReview = false;

  @override
  void initState() {
    super.initState();
    _computeResults();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _computeResults() {
    _totalQuestions = widget.questions.length;
    _answeredQuestions = widget.selectedAnswers.length;
    _skippedQuestions = _totalQuestions - _answeredQuestions;

    _correctAnswers = 0;
    for (final question in widget.questions) {
      final selectedOptionId = widget.selectedAnswers[question.id];
      if (selectedOptionId == null) continue;
      final selectedOption = question.options
          .where((o) => o.id == selectedOptionId)
          .firstOrNull;
      if (selectedOption != null && selectedOption.isCorrect) {
        _correctAnswers++;
      }
    }

    _incorrectAnswers = _answeredQuestions - _correctAnswers;
    _scorePercent = _totalQuestions > 0
        ? (_correctAnswers / _totalQuestions) * 100
        : 0.0;
    _passed = _scorePercent >= 60;
  }

  String get _formattedTime {
    final m = widget.elapsedSeconds ~/ 60;
    final s = widget.elapsedSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _terminationMessage(AppLocalizations l10n) {
    switch (widget.terminationReason) {
      case 'app_backgrounded':
        return l10n.sessionEndedBg;
      case 'user_exit':
        return l10n.sessionEndedExit;
      default:
        return l10n.sessionWasTerminated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return WillPopScope(
      onWillPop: () async {
        _goHome(context);
        return false;
      },
      child: Scaffold(
        backgroundColor:
            isDark ? const Color(0xFF0F0F14) : AppColors.cxF5F7F9,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(isDark, l10n),
                  Expanded(
                    child: _showReview
                        ? _buildReviewList(isDark, l10n)
                        : _buildResultsSummary(isDark, l10n),
                  ),
                  _buildBottomActions(isDark, l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
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
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF252532)
                  : AppColors.cxF5F7F9,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              widget.terminated
                  ? Icons.stop_circle_outlined
                  : Icons.emoji_events_outlined,
              size: 20.r,
              color: widget.terminated
                  ? AppColors.cxCrimsonRed
                  : AppColors.cxAmberGold,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.terminated ? l10n.sessionTerminated : l10n.testComplete,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFE8E8F0)
                        : AppColors.cxDarkCharcoal,
                  ),
                ),
                Text(
                  widget.courseName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : AppColors.cxSilverTint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Toggle review button
          if (!widget.terminated || _answeredQuestions > 0)
            GestureDetector(
              onTap: () => setState(() => _showReview = !_showReview),
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF252532)
                      : AppColors.cxPlatinumGray,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  _showReview ? l10n.summary : l10n.review,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFE8E8F0)
                        : AppColors.cxDarkCharcoal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  Widget _buildResultsSummary(bool isDark, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Terminated banner
          if (widget.terminated) _buildTerminatedBanner(isDark, l10n),

          // Score circle card
          _buildScoreCard(isDark, l10n),
          SizedBox(height: 16.h),

          // Stats row
          _buildStatsRow(isDark, l10n),
          SizedBox(height: 16.h),

          // Time & meta card
          _buildMetaCard(isDark, l10n),
        ],
      ),
    );
  }

  Widget _buildTerminatedBanner(bool isDark, AppLocalizations l10n) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.cxCrimsonRed.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.cxCrimsonRed.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: AppColors.cxCrimsonRed, size: 20.r),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              _terminationMessage(l10n),
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.cxCrimsonRed,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(bool isDark, AppLocalizations l10n) {
    final scoreColor = widget.terminated
        ? AppColors.cxCrimsonRed
        : (_passed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed);

    final gradientColors = widget.terminated
        ? [AppColors.cxCrimsonRed, const Color(0xFFFF6B6B)]
        : (_passed
            ? [AppColors.cxEmeraldGreen, AppColors.cx43C19F]
            : [AppColors.cxCrimsonRed, const Color(0xFFFF6B6B)]);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(28.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientColors[0].withOpacity(isDark ? 0.25 : 0.12),
            gradientColors[1].withOpacity(isDark ? 0.15 : 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: gradientColors[0].withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Score circle
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: widget.terminated && _answeredQuestions == 0
                  ? Icon(Icons.close_rounded,
                      color: Colors.white, size: 48.r)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_scorePercent.round()}%',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          widget.terminated
                              ? l10n.partial
                              : (_passed ? l10n.passed : l10n.failed),
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white.withOpacity(0.85),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            widget.terminated
                ? l10n.incomplete
                : (_passed ? l10n.congratulationsMsg : l10n.betterLuckMsg),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            widget.terminated
                ? l10n.resultsBasedOnAnswered
                : l10n.scoredOutOf(_correctAnswers, _totalQuestions),
            style: TextStyle(
              fontSize: 13.sp,
              color:
                  isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          // Score bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: _totalQuestions > 0
                  ? _scorePercent / 100
                  : 0,
              minHeight: 10.h,
              backgroundColor: scoreColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            icon: Icons.check_circle_outline_rounded,
            value: '$_correctAnswers',
            label: l10n.correct,
            color: AppColors.cxEmeraldGreen,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            icon: Icons.cancel_outlined,
            value: '$_incorrectAnswers',
            label: l10n.wrong,
            color: AppColors.cxCrimsonRed,
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: _buildStatCard(
            isDark: isDark,
            icon: Icons.remove_circle_outline_rounded,
            value: '$_skippedQuestions',
            label: l10n.skipped,
            color: AppColors.cxWarning,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20.r),
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color:
                  isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? const Color(0xFF374151)
              : AppColors.cxPlatinumGray.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMetaRow(
            isDark: isDark,
            icon: Icons.timer_outlined,
            label: l10n.timeSpent,
            value: _formattedTime,
            color: const Color(0xFF6366F1),
          ),
          Divider(
            height: 20.h,
            color: isDark
                ? const Color(0xFF374151)
                : AppColors.cxPlatinumGray.withOpacity(0.5),
          ),
          _buildMetaRow(
            isDark: isDark,
            icon: Icons.quiz_outlined,
            label: l10n.totalQuestions,
            value: '$_totalQuestions',
            color: AppColors.cxRoyalBlue,
          ),
          Divider(
            height: 20.h,
            color: isDark
                ? const Color(0xFF374151)
                : AppColors.cxPlatinumGray.withOpacity(0.5),
          ),
          _buildMetaRow(
            isDark: isDark,
            icon: Icons.edit_note_outlined,
            label: l10n.answered,
            value: '$_answeredQuestions / $_totalQuestions',
            color: AppColors.cxWarning,
          ),
          Divider(
            height: 20.h,
            color: isDark
                ? const Color(0xFF374151)
                : AppColors.cxPlatinumGray.withOpacity(0.5),
          ),
          _buildMetaRow(
            isDark: isDark,
            icon: widget.terminated
                ? Icons.stop_circle_outlined
                : Icons.flag_outlined,
            label: l10n.status,
            value: widget.terminated
                ? l10n.terminated
                : (_passed ? l10n.passed : l10n.failed),
            color: widget.terminated
                ? AppColors.cxCrimsonRed
                : (_passed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: color, size: 18.r),
        ),
        SizedBox(width: 12.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            color:
                isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
          ),
        ),
      ],
    );
  }

  // ── Review list ───────────────────────────────────────────────────────────
  Widget _buildReviewList(bool isDark, AppLocalizations l10n) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
      itemCount: widget.questions.length,
      itemBuilder: (_, i) {
        final question = widget.questions[i];
        final selectedOptionId = widget.selectedAnswers[question.id];
        final wasAnswered = selectedOptionId != null;
        final selectedOption = wasAnswered
            ? question.options.where((o) => o.id == selectedOptionId).firstOrNull
            : null;
        final isCorrect = selectedOption?.isCorrect ?? false;

        Color statusColor;
        IconData statusIcon;
        String statusLabel;

        if (!wasAnswered) {
          statusColor = AppColors.cxWarning;
          statusIcon = Icons.remove_circle_outline_rounded;
          statusLabel = l10n.skipped;
        } else if (isCorrect) {
          statusColor = AppColors.cxEmeraldGreen;
          statusIcon = Icons.check_circle_outline_rounded;
          statusLabel = l10n.correct;
        } else {
          statusColor = AppColors.cxCrimsonRed;
          statusIcon = Icons.cancel_outlined;
          statusLabel = l10n.wrong;
        }

        return Container(
          margin: EdgeInsets.only(bottom: 14.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A24) : Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: statusColor.withOpacity(0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question header row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Q${i + 1}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 5.h),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: statusColor.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon,
                              color: statusColor, size: 13.r),
                          SizedBox(width: 4.w),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                // Question text
                Text(
                  question.question,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFFE8E8F0)
                        : AppColors.cxDarkCharcoal,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12.h),
                // Options
                ...question.options.take(4).toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final option = entry.value;
                  final label = String.fromCharCode(65 + idx);
                  final isUserAnswer = option.id == selectedOptionId;
                  final isRightAnswer = option.isCorrect;

                  Color? tileColor;
                  Color? borderColor;
                  Widget? trailing;

                  if (isRightAnswer) {
                    tileColor = AppColors.cxEmeraldGreen.withOpacity(0.1);
                    borderColor = AppColors.cxEmeraldGreen.withOpacity(0.5);
                    trailing = Icon(Icons.check_rounded,
                        color: AppColors.cxEmeraldGreen, size: 16.r);
                  } else if (isUserAnswer && !isRightAnswer) {
                    tileColor = AppColors.cxCrimsonRed.withOpacity(0.08);
                    borderColor = AppColors.cxCrimsonRed.withOpacity(0.4);
                    trailing = Icon(Icons.close_rounded,
                        color: AppColors.cxCrimsonRed, size: 16.r);
                  }

                  return Container(
                    margin: EdgeInsets.only(bottom: 6.h),
                    padding: EdgeInsets.symmetric(
                        horizontal: 12.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: tileColor ??
                          (isDark
                              ? const Color(0xFF252532)
                              : AppColors.cxF5F7F9),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: borderColor ??
                            (isDark
                                ? const Color(0xFF374151)
                                : AppColors.cxPlatinumGray.withOpacity(0.4)),
                        width: isRightAnswer || (isUserAnswer && !isRightAnswer)
                            ? 1.5
                            : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24.w,
                          height: 24.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isRightAnswer
                                ? AppColors.cxEmeraldGreen.withOpacity(0.15)
                                : (isUserAnswer && !isRightAnswer
                                    ? AppColors.cxCrimsonRed.withOpacity(0.15)
                                    : (isDark
                                        ? const Color(0xFF374151)
                                        : AppColors.cxPlatinumGray)),
                          ),
                          child: Center(
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: isRightAnswer
                                    ? AppColors.cxEmeraldGreen
                                    : (isUserAnswer && !isRightAnswer
                                        ? AppColors.cxCrimsonRed
                                        : (isDark
                                            ? const Color(0xFF9CA3AF)
                                            : AppColors.cxSilverTint)),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            option.text,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: isRightAnswer || (isUserAnswer && !isRightAnswer)
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isRightAnswer
                                  ? AppColors.cxEmeraldGreen
                                  : (isUserAnswer && !isRightAnswer
                                      ? AppColors.cxCrimsonRed
                                      : (isDark
                                          ? const Color(0xFFD1D5DB)
                                          : AppColors.cxGraphiteGray)),
                              height: 1.4,
                            ),
                          ),
                        ),
                        if (trailing != null) trailing,
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Bottom actions ────────────────────────────────────────────────────────
  Widget _buildBottomActions(bool isDark, AppLocalizations l10n) {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
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
            // Back to courses
            Expanded(
              child: GestureDetector(
                onTap: () => _goHome(context),
                child: Container(
                  height: 54.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF252532)
                        : AppColors.cxPlatinumGray,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF374151)
                          : AppColors.cxPlatinumGray,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.home_outlined,
                          size: 18.r,
                          color: isDark
                              ? const Color(0xFFE8E8F0)
                              : AppColors.cxDarkCharcoal,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          l10n.backToCourseList,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFE8E8F0)
                                : AppColors.cxDarkCharcoal,
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
    );
  }

  void _goHome(BuildContext context) {
    // Pop back to the course list (removes both session + results pages)
    Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/trainingTestPage');
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}
