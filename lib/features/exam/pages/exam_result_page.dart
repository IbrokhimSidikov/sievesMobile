import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/exam_models.dart';

class ExamResultPage extends StatefulWidget {
  final int attemptId;
  final String examTitle;

  /// When the result is already known (right after submitting) pass it to skip
  /// the initial network fetch.
  final ExamResult? initialResult;

  const ExamResultPage({
    super.key,
    required this.attemptId,
    required this.examTitle,
    this.initialResult,
  });

  @override
  State<ExamResultPage> createState() => _ExamResultPageState();
}

class _ExamResultPageState extends State<ExamResultPage> {
  final _authManager = AuthManager();

  bool _isLoading = true;
  ExamResult? _result;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    if (widget.initialResult != null) {
      _result = widget.initialResult;
      _isLoading = false;
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final data =
          await _authManager.apiService.fetchExamResult(widget.attemptId);
      if (mounted) {
        setState(() {
          _result = ExamResult.fromJson(data);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      // Result is terminal — back returns to the exam list.
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F0F14) : AppColors.cxF5F7F9,
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _result == null
                  ? _buildUnavailable(isDark)
                  : _buildResult(isDark, _result!),
        ),
      ),
    );
  }

  Widget _buildResult(bool isDark, ExamResult result) {
    final passed = result.passed;
    final color =
        passed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 120.w,
                    height: 120.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.12),
                      border: Border.all(color: color, width: 3),
                    ),
                    child: Center(
                      child: Text(
                        '${result.scorePercentage.round()}%',
                        style: TextStyle(
                          fontSize: 30.sp,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Icon(
                    passed
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    color: color,
                    size: 28.r,
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    passed ? _l10n.examResultPassed : _l10n.examResultFailed,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    widget.examTitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: isDark
                          ? const Color(0xFFE8E8F0)
                          : AppColors.cxDarkCharcoal,
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(18.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1A1A24) : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat(
                          isDark,
                          '${result.correctAnswers}/${result.totalQuestions}',
                          _l10n.examCorrect,
                        ),
                        _divider(isDark),
                        if (result.totalPoints > 0) ...[
                          _stat(
                            isDark,
                            '${result.earnedPoints}/${result.totalPoints}',
                            _l10n.examPoints,
                          ),
                          _divider(isDark),
                        ],
                        _stat(
                          isDark,
                          '${result.passingScore}%',
                          _l10n.examPassingScore,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
          child: SizedBox(
            width: double.infinity,
            height: 54.h,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cxRoyalBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                _l10n.examBackToExams,
                style:
                    TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider(bool isDark) {
    return Container(
      width: 1,
      height: 40.h,
      color: isDark ? const Color(0xFF374151) : AppColors.cxPlatinumGray,
    );
  }

  Widget _stat(bool isDark, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
          ),
        ),
      ],
    );
  }

  Widget _buildUnavailable(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded,
              size: 48.r, color: AppColors.cxSilverTint),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_l10n.examBackToExams),
          ),
        ],
      ),
    );
  }
}
