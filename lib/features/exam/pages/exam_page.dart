import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/exam_models.dart';
import 'exam_intro_page.dart';
import 'exam_result_page.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  final _authManager = AuthManager();

  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<ExamSummary> _exams = [];

  AppLocalizations get _l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    try {
      final raw = await _authManager.apiService.fetchMyExams();
      final exams = raw.map((e) => ExamSummary.fromJson(e)).toList();
      if (mounted) {
        setState(() {
          _exams = exams;
          _isLoading = false;
        });
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

  Future<void> _openExam(ExamSummary exam) async {
    if (exam.isCompleted) {
      if (exam.attemptId == null) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ExamResultPage(
            attemptId: exam.attemptId!,
            examTitle: exam.title,
          ),
        ),
      );
      return;
    }

    // available or in_progress -> intro (Start resumes an in-progress attempt)
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExamIntroPage(exam: exam)),
    );
    // Refresh state after returning from the exam flow.
    if (mounted) _loadExams();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F14) : AppColors.cxF5F7F9,
      appBar: AppBar(
        title: Text(_l10n.examListTitle),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadExams,
        child: _isLoading
            ? _buildShimmer(isDark)
            : _hasError
                ? _buildError(isDark)
                : _exams.isEmpty
                    ? _buildEmpty(isDark)
                    : _buildList(isDark),
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    final base = isDark ? const Color(0xFF1A1A24) : Colors.grey[300]!;
    final highlight = isDark ? const Color(0xFF252532) : Colors.grey[100]!;

    Widget box(double w, double h, {double radius = 8}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: base,
            borderRadius: BorderRadius.circular(radius.r),
          ),
        );

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      itemCount: 5,
      itemBuilder: (_, __) => Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A24) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDark
                ? const Color(0xFF374151)
                : AppColors.cxPlatinumGray.withOpacity(0.4),
          ),
        ),
        child: Shimmer.fromColors(
          baseColor: base,
          highlightColor: highlight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  box(160.w, 16.h),
                  box(70.w, 22.h, radius: 8),
                ],
              ),
              SizedBox(height: 12.h),
              box(double.infinity, 12.h, radius: 6),
              SizedBox(height: 6.h),
              box(220.w, 12.h, radius: 6),
              SizedBox(height: 16.h),
              Row(
                children: [
                  box(70.w, 14.h),
                  SizedBox(width: 12.w),
                  box(50.w, 14.h),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList(bool isDark) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      itemCount: _exams.length,
      itemBuilder: (_, i) => _buildCard(_exams[i], isDark),
    );
  }

  Widget _buildCard(ExamSummary exam, bool isDark) {
    final badge = _stateBadge(exam);

    return GestureDetector(
      onTap: () => _openExam(exam),
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A24) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isDark
                ? const Color(0xFF374151)
                : AppColors.cxPlatinumGray.withOpacity(0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    exam.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? const Color(0xFFE8E8F0)
                          : AppColors.cxDarkCharcoal,
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: badge.color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    badge.label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: badge.color,
                    ),
                  ),
                ),
              ],
            ),
            if (exam.description != null && exam.description!.isNotEmpty) ...[
              SizedBox(height: 6.h),
              Text(
                exam.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.sp,
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : AppColors.cxSilverTint,
                  height: 1.4,
                ),
              ),
            ],
            SizedBox(height: 12.h),
            Row(
              children: [
                _metaChip(
                  isDark,
                  Icons.timer_outlined,
                  exam.durationMinutes > 0
                      ? '${exam.durationMinutes} ${_l10n.examMinutesShort}'
                      : _l10n.examNoTimeLimit,
                ),
                SizedBox(width: 10.w),
                _metaChip(
                  isDark,
                  Icons.emoji_events_outlined,
                  '${exam.passingScore}%',
                ),
                const Spacer(),
                if (exam.isCompleted && exam.scorePercentage != null)
                  Text(
                    '${exam.scorePercentage!.round()}%',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: (exam.passed ?? false)
                          ? AppColors.cxEmeraldGreen
                          : AppColors.cxCrimsonRed,
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : AppColors.cxSilverTint,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaChip(bool isDark, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 15.r,
            color:
                isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.sp,
            color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
          ),
        ),
      ],
    );
  }

  _Badge _stateBadge(ExamSummary exam) {
    if (exam.isCompleted) {
      final passed = exam.passed ?? false;
      return _Badge(
        passed ? _l10n.examResultPassed : _l10n.examResultFailed,
        passed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed,
      );
    }
    if (exam.isInProgress) {
      return _Badge(_l10n.examStateInProgress, AppColors.cxAmberGold);
    }
    return _Badge(_l10n.examStateAvailable, AppColors.cxRoyalBlue);
  }

  Widget _buildEmpty(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 120.h),
        Icon(Icons.assignment_outlined,
            size: 64.r,
            color:
                isDark ? const Color(0xFF374151) : AppColors.cxPlatinumGray),
        SizedBox(height: 16.h),
        Center(
          child: Text(
            _l10n.examNoAssigned,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? const Color(0xFFE8E8F0)
                  : AppColors.cxDarkCharcoal,
            ),
          ),
        ),
        SizedBox(height: 6.h),
        Center(
          child: Text(
            _l10n.examNoAssignedDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.sp,
              color:
                  isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(bool isDark) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 120.h),
        Icon(Icons.error_outline_rounded,
            size: 56.r, color: AppColors.cxCrimsonRed),
        SizedBox(height: 12.h),
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark
                    ? const Color(0xFF9CA3AF)
                    : AppColors.cxSilverTint,
              ),
            ),
          ),
        ),
        SizedBox(height: 20.h),
        Center(
          child: TextButton(
            onPressed: _loadExams,
            child: Text(_l10n.examBackToExams),
          ),
        ),
      ],
    );
  }
}

class _Badge {
  final String label;
  final Color color;
  _Badge(this.label, this.color);
}
