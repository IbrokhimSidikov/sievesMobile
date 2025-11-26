import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../../core/constants/app_colors.dart';
import '../models/test.dart';
import '../models/test_answer.dart';

class TestResultPage extends StatelessWidget {
  final Test test;
  final int score;
  final Map<String, TestAnswer> answers;
  final int timeTaken; // in seconds

  const TestResultPage({
    super.key,
    required this.test,
    required this.score,
    required this.answers,
    required this.timeTaken,
  });

  @override
  Widget build(BuildContext context) {
    final isPassed = score >= test.passingScore;
    final correctAnswers = _calculateCorrectAnswers();
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
              colors: [
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
                        _buildResultHeader(isPassed),
                        SizedBox(height: 32.h),
                        _buildScoreCard(isPassed, correctAnswers, totalQuestions),
                        SizedBox(height: 24.h),
                        _buildStatsCards(),
                        SizedBox(height: 24.h),
                        _buildReviewSection(),
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

  Widget _buildResultHeader(bool isPassed) {
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
            color: AppColors.cxDarkCharcoal,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          isPassed
              ? 'You passed the test!'
              : 'You need ${test.passingScore}% to pass',
          style: TextStyle(
            fontSize: 16.sp,
            color: AppColors.cxSilverTint,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard(bool isPassed, int correctAnswers, int totalQuestions) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              color: AppColors.cxSilverTint,
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
                  value: score / 100,
                  strokeWidth: 12.w,
                  backgroundColor: AppColors.cxF5F7F9,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isPassed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed,
                  ),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$score%',
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
                      color: AppColors.cxSilverTint,
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

  Widget _buildStatsCards() {
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
              Icons.check_circle_rounded,
              'Correct',
              '$correctAnswers',
              AppColors.cxEmeraldGreen,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
              Icons.cancel_rounded,
              'Incorrect',
              '$incorrectAnswers',
              AppColors.cxCrimsonRed,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _buildStatCard(
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

  Widget _buildStatCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              color: AppColors.cxDarkCharcoal,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.cxSilverTint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: AppColors.cxDarkCharcoal,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildSummaryRow('Test Name', test.title),
          _buildSummaryRow('Category', test.category),
          _buildSummaryRow('Total Questions', '${test.questions!.length}'),
          _buildSummaryRow('Passing Score', '${test.passingScore}%'),
          _buildSummaryRow('Your Score', '$score%'),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.cxSilverTint,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.cxDarkCharcoal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isPassed) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  color: AppColors.cxF5F7F9,
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
                          color: AppColors.cxDarkCharcoal,
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
