import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../models/test.dart';
import '../models/test_answer.dart';
import '../models/test_session.dart';

class TestResultPage extends StatelessWidget {
  final Test test;
  final int? score;
  final Map<String, TestAnswer> answers;
  final int timeTaken; // in seconds
  final int? sessionId;
  final Map<String, dynamic>? sessionData;

  const TestResultPage({
    super.key,
    required this.test,
    this.score,
    required this.answers,
    required this.timeTaken,
    this.sessionId,
    this.sessionData,
  });

  int? _parseScore(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) {
      final doubleValue = double.tryParse(value);
      return doubleValue?.toInt();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final actualScore = sessionData != null 
        ? _parseScore(sessionData!['score_percentage']) ?? score ?? 0
        : score ?? 0;
    
    print('📊 Test Result Page:');
    print('   Score from sessionData: ${sessionData?['score_percentage']}');
    print('   Parsed actualScore: $actualScore');
    print('   Passing score: ${test.passingScore}');
    print('   isPassed: ${actualScore >= test.passingScore}');
    
    final isPassed = actualScore >= test.passingScore;
    final correctAnswers = sessionData != null
        ? (sessionData!['correct_answers'] as int?) ?? _calculateCorrectAnswers()
        : _calculateCorrectAnswers();
    final totalQuestions = test.questions!.length;

    return WillPopScope(
      onWillPop: () async {
        context.go('/lmsPage');
        return false;
      },
      child: Scaffold(
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
                      isPassed ? AppColors.cxEmeraldGreen.withOpacity(0.1) : AppColors.cxCrimsonRed.withOpacity(0.1),
                      AppColors.cxWhite,
                      AppColors.cxF5F7F9,
                    ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 40.h),
                        _buildResultHeader(context, isPassed),
                        SizedBox(height: 32.h),
                        _buildScoreCard(context, isPassed, correctAnswers, totalQuestions, actualScore),
                        SizedBox(height: 24.h),
                        _buildStatsCards(context),
                        SizedBox(height: 24.h),
                        _buildReviewSection(context),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
                _buildActionButtons(context, isPassed),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultHeader(BuildContext context, bool isPassed) {
    return Column(
      children: [
        Container(
          width: 120.w,
          height: 120.h,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: isPassed
                  ? [AppColors.cxEmeraldGreen, AppColors.cxEmeraldGreen.withOpacity(0.7)]
                  : [AppColors.cxCrimsonRed, AppColors.cxCrimsonRed.withOpacity(0.7)],
            ),
            boxShadow: [
              BoxShadow(
                color: (isPassed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed).withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            isPassed ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
            color: Colors.white,
            size: 60.sp,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          isPassed ? 'Congratulations!' : 'Keep Trying!',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          isPassed
              ? 'You passed the test!'
              : 'You need ${test.passingScore}% to pass',
          style: TextStyle(
            fontSize: 16.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(BuildContext context, bool isPassed, int correctAnswers, int totalQuestions, int actualScore) {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Your Score',
            style: TextStyle(
              fontSize: 16.sp,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160.w,
                height: 160.h,
                child: CircularProgressIndicator(
                  value: actualScore / 100,
                  strokeWidth: 12.w,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPassed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$actualScore%',
                    style: TextStyle(
                      fontSize: 48.sp,
                      fontWeight: FontWeight.bold,
                      color: isPassed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '$correctAnswers / $totalQuestions',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: (isPassed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: (isPassed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isPassed ? Icons.emoji_events_rounded : Icons.info_outline_rounded,
                  color: isPassed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  isPassed ? 'PASSED' : 'NOT PASSED',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isPassed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    final minutes = timeTaken ~/ 60;
    final seconds = timeTaken % 60;
    final correctAnswers = _calculateCorrectAnswers();
    final totalQuestions = test.questions!.length;
    final incorrectAnswers = totalQuestions - correctAnswers;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              Icons.check_circle_rounded,
              'Correct',
              '$correctAnswers',
              AppColors.cxEmeraldGreen,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              context,
              Icons.cancel_rounded,
              'Incorrect',
              '$incorrectAnswers',
              AppColors.cxCrimsonRed,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              context,
              Icons.timer_outlined,
              'Time',
              '${minutes}m ${seconds}s',
              AppColors.cxRoyalBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String label, String value, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24.sp,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                color: AppColors.cxRoyalBlue,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Test Summary',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSummaryRow(context, 'Test Name', test.title),
          _buildSummaryRow(context, 'Category', test.category),
          _buildSummaryRow(context, 'Total Questions', '${test.questions!.length}'),
          _buildSummaryRow(context, 'Passing Score', '${test.passingScore}%'),
          _buildSummaryRow(context, 'Your Score', '$score%'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isPassed) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 56.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.go('/lmsPage'),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Center(
                      child: Text(
                        'Back to Tests',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!isPassed) ...[
              SizedBox(width: 12.w),
              Expanded(
                child: Container(
                  height: 56.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.go('/lmsPage');
                        // In a real app, you'd navigate back to test detail to retake
                      },
                      borderRadius: BorderRadius.circular(16.r),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.replay_rounded,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Retake Test',
                              style: TextStyle(
                                fontSize: 16.sp,
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
              ),
            ],
          ],
        ),
      ),
    );
  }

  int _calculateCorrectAnswers() {
    int correctCount = 0;
    for (var question in test.questions!) {
      final answer = answers[question.id];
      if (answer != null) {
        final correctOptionIds = question.options
            .where((opt) => opt.isCorrect)
            .map((opt) => opt.id)
            .toSet();
        final selectedIds = answer.selectedOptionIds.toSet();

        if (correctOptionIds.length == selectedIds.length &&
            correctOptionIds.containsAll(selectedIds)) {
          correctCount++;
        }
      }
    }
    return correctCount;
  }
}
