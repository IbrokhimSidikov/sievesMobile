import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/exam_models.dart';
import 'exam_taking_page.dart';
import 'exam_result_page.dart';

class ExamIntroPage extends StatefulWidget {
  final ExamSummary exam;
  const ExamIntroPage({super.key, required this.exam});

  @override
  State<ExamIntroPage> createState() => _ExamIntroPageState();
}

class _ExamIntroPageState extends State<ExamIntroPage> {
  final _authManager = AuthManager();
  bool _isStarting = false;

  AppLocalizations get _l10n => AppLocalizations.of(context);

  Future<void> _start() async {
    final confirmed = await _confirmStart();
    if (confirmed != true) return;

    setState(() => _isStarting = true);
    try {
      final data = await _authManager.apiService.startExam(widget.exam.examId);
      final attempt = ExamAttempt.fromJson(data);
      if (!mounted) return;
      // Replace intro with the locked session so back never returns here.
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ExamTakingPage(attempt: attempt)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isStarting = false);
      final message = e.toString().replaceAll('Exception: ', '');
      // If it was already taken, jump straight to the result when possible.
      if (widget.exam.attemptId != null &&
          message.toLowerCase().contains('already')) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ExamResultPage(
              attemptId: widget.exam.attemptId!,
              examTitle: widget.exam.title,
            ),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<bool?> _confirmStart() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1A1A24) : AppColors.cxPureWhite,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(_l10n.examStartConfirmTitle,
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
        content: Text(_l10n.examStartConfirmBody,
            style: TextStyle(fontSize: 14.sp, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(_l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cxEmeraldGreen,
              foregroundColor: Colors.white,
            ),
            child: Text(_l10n.examStart),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exam = widget.exam;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F14) : AppColors.cxF5F7F9,
      appBar: AppBar(title: Text(exam.title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (exam.description != null &&
                        exam.description!.isNotEmpty) ...[
                      Text(
                        exam.description!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          height: 1.5,
                          color: isDark
                              ? const Color(0xFFD1D5DB)
                              : AppColors.cxGraphiteGray,
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            isDark,
                            Icons.timer_outlined,
                            exam.durationMinutes > 0
                                ? '${exam.durationMinutes} ${_l10n.examMinutesShort}'
                                : '∞',
                            _l10n.examDuration,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _statCard(
                            isDark,
                            Icons.emoji_events_outlined,
                            '${exam.passingScore}%',
                            _l10n.examPassingScore,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    // Rules notice
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18.w),
                      decoration: BoxDecoration(
                        color: AppColors.cxCrimsonRed.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: AppColors.cxCrimsonRed.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: AppColors.cxCrimsonRed, size: 20.r),
                              SizedBox(width: 8.w),
                              Text(
                                _l10n.examRulesTitle,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cxCrimsonRed,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          _rule(isDark, _l10n.examRule1),
                          _rule(isDark, _l10n.examRule2),
                          _rule(isDark, _l10n.examRule3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Start button
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 16.h),
              child: SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: _isStarting ? null : _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cxEmeraldGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: _isStarting
                      ? SizedBox(
                          width: 22.w,
                          height: 22.h,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _l10n.examStart,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
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

  Widget _statCard(bool isDark, IconData icon, String value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 18.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? const Color(0xFF374151)
              : AppColors.cxPlatinumGray.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24.r, color: AppColors.cxRoyalBlue),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color:
                  isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rule(bool isDark, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                color: AppColors.cxCrimsonRed,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.45,
                color: isDark
                    ? const Color(0xFFD1D5DB)
                    : AppColors.cxGraphiteGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
