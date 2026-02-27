import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../data/training_course_model.dart';
import 'test_session_page.dart';

class TrainingTestPage extends StatefulWidget {
  const TrainingTestPage({super.key});

  @override
  State<TrainingTestPage> createState() => _TrainingTestPageState();
}

class _TrainingTestPageState extends State<TrainingTestPage> {
  final _authManager = AuthManager();
  
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  List<TrainingCourse> _courses = [];

  @override
  void initState() {
    super.initState();
    _loadTrainingCourses();
  }

  Future<void> _loadTrainingCourses() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final courses = await _authManager.apiService.fetchTrainingCourses();
      
      if (mounted) {
        setState(() {
          _courses = courses;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F14) : AppColors.cxF5F7F9,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.translate('trainingTest'),
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),),
      body: _isLoading
          ? _buildLoadingState(l10n)
          : _hasError
              ? _buildErrorState(l10n)
              : _courses.isEmpty
                  ? _buildEmptyState(l10n)
                  : _buildCoursesList(l10n, isDark, colorScheme),
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF1A1A24) : Colors.grey[300]!;
    final highlightColor = isDark ? const Color(0xFF252532) : Colors.grey[100]!;

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A24) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : AppColors.cxPlatinumGray.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme badge shimmer
                  Container(
                    width: 120.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Title shimmer
                  Container(
                    width: double.infinity,
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Description shimmer
                  Container(
                    width: double.infinity,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: 200.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  // Resource badges shimmer
                  Row(
                    children: [
                      Container(
                        width: 60.w,
                        height: 26.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        width: 70.w,
                        height: 26.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.r,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.errorLoadingCourses,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              _errorMessage,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _loadTrainingCourses,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 64.r,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.noCourses,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              l10n.availableCourses,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList(AppLocalizations l10n, bool isDark, ColorScheme colorScheme) {
    return Column(
      children: [
        // Header with count
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF6366F1).withOpacity(0.2), const Color(0xFF8B5CF6).withOpacity(0.15)]
                  : [AppColors.cxRoyalBlue.withOpacity(0.1), AppColors.cxEmeraldGreen.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? const Color(0xFF6366F1).withOpacity(0.3) : AppColors.cxPlatinumGray,
              width: 1.5,
            ),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.r),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF6366F1).withOpacity(0.3), const Color(0xFF8B5CF6).withOpacity(0.2)]
                        : [AppColors.cxRoyalBlue.withOpacity(0.2), AppColors.cxRoyalBlue.withOpacity(0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.school_rounded,
                  color: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                  size: 24.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.availableCourses,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '${_courses.length} ${l10n.coursesFound}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF6366F1).withOpacity(0.2)
                      : AppColors.cxRoyalBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isDark ? const Color(0xFF6366F1).withOpacity(0.4) : AppColors.cxRoyalBlue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${_courses.length}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Courses list
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            itemCount: _courses.length,
            itemBuilder: (context, index) {
              return _buildCourseCard(_courses[index], l10n, isDark, colorScheme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(TrainingCourse course, AppLocalizations l10n, bool isDark, ColorScheme colorScheme) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : AppColors.cxPlatinumGray.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : AppColors.cxSilverTint.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (isDark)
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TestSessionPage(
                  courseId: course.id,
                  courseName: course.name,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme badge
                if (course.theme != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFFA78BFA).withOpacity(0.4), const Color(0xFF8B5CF6).withOpacity(0.3)]
                            : [AppColors.cxAmberGold.withOpacity(0.2), AppColors.cxAmberGold.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: isDark ? const Color(0xFFA78BFA).withOpacity(0.6) : AppColors.cxAmberGold.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.label,
                          size: 14.r,
                          color: isDark ? const Color(0xFFA78BFA) : AppColors.cxAmberGold,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${l10n.courseTheme}: ${course.theme!.name}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 12.h),
                // Course name
                Text(
                  course.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                    color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                  ),
                ),
                SizedBox(height: 8.h),
                // Course description
                Text(
                  course.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: isDark ? const Color(0xFFD1D5DB) : AppColors.cxGraphiteGray,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h),
                // Resources row
                Row(
                  children: [
                    if (course.pdfUrl != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? LinearGradient(
                                  colors: [const Color(0xFF34D399).withOpacity(0.3), const Color(0xFF10B981).withOpacity(0.2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isDark ? null : AppColors.cxEmeraldGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: isDark ? const Color(0xFF34D399) : AppColors.cxEmeraldGreen,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.picture_as_pdf,
                              size: 14.r,
                              color: isDark ? const Color(0xFF34D399) : AppColors.cxEmeraldGreen,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'PDF',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isDark ? const Color(0xFF34D399) : AppColors.cxEmeraldGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (course.pdfUrl != null && course.videoUrl != null)
                      SizedBox(width: 8.w),
                    if (course.videoUrl != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          gradient: isDark
                              ? LinearGradient(
                                  colors: [const Color(0xFF6366F1).withOpacity(0.3), const Color(0xFF4F46E5).withOpacity(0.2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isDark ? null : AppColors.cxRoyalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_circle_outline,
                              size: 14.r,
                              color: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Video',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16.r,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
