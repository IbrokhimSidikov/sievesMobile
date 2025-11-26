import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../models/test.dart';
import '../models/question.dart';
import '../models/answer_option.dart';
import '../models/question_type.dart';

class TestDetailPage extends StatelessWidget {
  final Test test;

  const TestDetailPage({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.cxWhite,
              AppColors.cxF5F7F9,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildInfoSection(),
                      _buildInstructions(),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
              _buildStartButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppColors.cxDarkCharcoal,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              'Test Details',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.cxDarkCharcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final categoryColor = _getCategoryColor(test.category);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
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
          if (test.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24.r),
                topRight: Radius.circular(24.r),
              ),
              child: Stack(
                children: [
                  Image.network(
                    test.imageUrl!,
                    height: 200.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200.h,
                        color: categoryColor.withOpacity(0.1),
                        child: Icon(
                          Icons.quiz_outlined,
                          size: 60.sp,
                          color: categoryColor,
                        ),
                      );
                    },
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16.h,
                    left: 16.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: categoryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        test.category,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (test.isCompleted)
                    Positioned(
                      top: 16.h,
                      right: 16.w,
                      child: Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.cxEmeraldGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cxEmeraldGreen.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  test.title,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.cxDarkCharcoal,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  test.description,
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: AppColors.cxSilverTint,
                    height: 1.5,
                  ),
                ),
                if (test.isCompleted && test.userScore != null) ...[
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cxEmeraldGreen.withOpacity(0.15),
                          AppColors.cxEmeraldGreen.withOpacity(0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.cxEmeraldGreen.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: AppColors.cxEmeraldGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Previous Score',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.cxSilverTint,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                '${test.userScore}%',
                                style: TextStyle(
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cxEmeraldGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (test.userScore! >= test.passingScore)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cxEmeraldGreen,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'PASSED',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: EdgeInsets.all(20.w),
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
          Text(
            'Test Information',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.cxDarkCharcoal,
            ),
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            Icons.quiz_outlined,
            'Total Questions',
            '${test.totalQuestions}',
            AppColors.cxRoyalBlue,
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            Icons.timer_outlined,
            'Duration',
            '${test.duration} minutes',
            AppColors.cxWarning,
          ),
          SizedBox(height: 12.h),
          _buildInfoRow(
            Icons.emoji_events_outlined,
            'Passing Score',
            '${test.passingScore}%',
            AppColors.cxEmeraldGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.cxSilverTint,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.cxDarkCharcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructions() {
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
                Icons.info_outline_rounded,
                color: AppColors.cxRoyalBlue,
                size: 24.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.cxDarkCharcoal,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          _buildInstructionItem('Read each question carefully before answering'),
          _buildInstructionItem('You can navigate between questions freely'),
          _buildInstructionItem('Review your answers before submitting'),
          _buildInstructionItem('You must score ${test.passingScore}% or higher to pass'),
          _buildInstructionItem('Timer will start once you begin the test'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h),
            width: 6.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: AppColors.cxRoyalBlue,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.cxSilverTint,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
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
        child: Container(
          width: double.infinity,
          height: 56.h,
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
                color: const Color(0xFF6366F1).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _startTest(context),
              borderRadius: BorderRadius.circular(16.r),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      test.isCompleted ? Icons.replay_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      test.isCompleted ? 'Retake Test' : 'Start Test',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startTest(BuildContext context) {
    // Generate sample questions for demo
    final questions = _generateSampleQuestions();
    final testWithQuestions = test.copyWith(questions: questions);
    
    context.push('/testTaking', extra: testWithQuestions);
  }

  List<Question> _generateSampleQuestions() {
    // Sample questions based on test category
    return List.generate(test.totalQuestions, (index) {
      return Question(
        id: 'q${index + 1}',
        text: 'Sample question ${index + 1} for ${test.title}?',
        type: index % 3 == 0 ? QuestionType.trueFalse : QuestionType.multipleChoice,
        points: 1,
        explanation: 'This is the explanation for question ${index + 1}.',
        options: index % 3 == 0
            ? [
                AnswerOption(id: 'a1', text: 'True', isCorrect: true),
                AnswerOption(id: 'a2', text: 'False', isCorrect: false),
              ]
            : [
                AnswerOption(id: 'a1', text: 'Option A', isCorrect: index % 4 == 0),
                AnswerOption(id: 'a2', text: 'Option B', isCorrect: index % 4 == 1),
                AnswerOption(id: 'a3', text: 'Option C', isCorrect: index % 4 == 2),
                AnswerOption(id: 'a4', text: 'Option D', isCorrect: index % 4 == 3),
              ],
      );
    });
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'safety':
        return AppColors.cxCrimsonRed;
      case 'service':
        return AppColors.cxRoyalBlue;
      case 'operations':
        return AppColors.cxWarning;
      case 'product':
        return AppColors.cxEmeraldGreen;
      default:
        return AppColors.cxPurple;
    }
  }
}
