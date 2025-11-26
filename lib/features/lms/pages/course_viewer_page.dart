import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'dart:developer' as developer;
import '../../../core/constants/app_colors.dart';
import '../models/test.dart';

class CourseViewerPage extends StatefulWidget {
  final Test test;

  const CourseViewerPage({super.key, required this.test});

  @override
  State<CourseViewerPage> createState() => _CourseViewerPageState();
}

class _CourseViewerPageState extends State<CourseViewerPage> {
  final PdfViewerController _pdfController = PdfViewerController();
  double _progress = 0.0;
  bool _canProceedToTest = false;
  int _currentPage = 0;
  int _totalPages = 0;
  bool _hasReachedEnd = false;
  bool _isLoadingPdf = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    developer.log('CourseViewerPage initialized', name: 'CourseViewer');
    developer.log('Test ID: ${widget.test.id}', name: 'CourseViewer');
    developer.log('Course URL: ${widget.test.courseUrl}', name: 'CourseViewer');
  }

  @override
  void dispose() {
    developer.log('CourseViewerPage disposed', name: 'CourseViewer');
    _pdfController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    if (_totalPages > 0) {
      setState(() {
        _progress = (_currentPage + 1) / _totalPages;
        
        // User can proceed if they've reached at least 90% or the last page
        _canProceedToTest = _progress >= 0.9 || _hasReachedEnd;
        
        developer.log(
          'Progress updated: ${(_progress * 100).toInt()}% (Page ${_currentPage + 1}/$_totalPages)',
          name: 'CourseViewer',
        );
        developer.log('Can proceed to test: $_canProceedToTest', name: 'CourseViewer');
      });
    }
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    developer.log(
      'Page changed: ${details.oldPageNumber} → ${details.newPageNumber}',
      name: 'CourseViewer',
    );
    
    setState(() {
      _currentPage = details.newPageNumber - 1;
      
      // Check if user reached the last page
      if (_currentPage >= _totalPages - 1) {
        _hasReachedEnd = true;
        developer.log('User reached the last page!', name: 'CourseViewer');
      }
    });
    _updateProgress();
  }

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    developer.log(
      'PDF loaded successfully! Total pages: ${details.document.pages.count}',
      name: 'CourseViewer',
    );
    
    setState(() {
      _totalPages = details.document.pages.count;
      _isLoadingPdf = false;
      _loadError = null;
    });
    _updateProgress();
  }

  void _proceedToTest() {
    developer.log('Proceed to test button clicked', name: 'CourseViewer');
    
    if (!_canProceedToTest) {
      developer.log('Course not completed yet, showing dialog', name: 'CourseViewer');
      _showCompletionRequiredDialog();
      return;
    }

    developer.log('Course completed! Navigating to test detail', name: 'CourseViewer');
    
    // Update test with course completion
    final updatedTest = widget.test.copyWith(courseCompleted: true);
    
    // Navigate to test detail page
    context.pushReplacement('/testDetail', extra: updatedTest);
  }

  void _showCompletionRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.cxWarning,
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Complete Course',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            'Please read through the course material to unlock the test. You need to reach at least 90% of the content.',
            style: TextStyle(
              fontSize: 15.sp,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Continue Reading',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cxRoyalBlue,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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
                    AppColors.cxWhite,
                    AppColors.cxF5F7F9,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildProgressBar(),
              Expanded(
                child: _buildPdfViewer(),
              ),
              _buildBottomBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.test.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Course Material',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.cxRoyalBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.cxRoyalBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${_currentPage + 1}/$_totalPages',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxRoyalBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reading Progress',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${(_progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: _canProceedToTest
                      ? AppColors.cxEmeraldGreen
                      : AppColors.cxRoyalBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8.h,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                _canProceedToTest
                    ? AppColors.cxEmeraldGreen
                    : AppColors.cxRoyalBlue,
              ),
            ),
          ),
          if (_canProceedToTest) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.cxEmeraldGreen,
                  size: 16.sp,
                ),
                SizedBox(width: 6.w),
                Text(
                  'You can now proceed to the test!',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cxEmeraldGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPdfViewer() {
    if (widget.test.courseUrl == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 80.sp,
              color: AppColors.cxSilverTint,
            ),
            SizedBox(height: 16.h),
            Text(
              'No course material available',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxGraphiteGray,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Stack(
          children: [
            SfPdfViewer.network(
              widget.test.courseUrl!,
              controller: _pdfController,
              onPageChanged: _onPageChanged,
              onDocumentLoaded: _onDocumentLoaded,
              onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                developer.log(
                  'PDF LOAD FAILED! Error: ${details.error}',
                  name: 'CourseViewer',
                  error: details.error,
                );
                developer.log('Description: ${details.description}', name: 'CourseViewer');
                
                setState(() {
                  _isLoadingPdf = false;
                  _loadError = details.description ?? 'Failed to load PDF';
                });
                
                // Show error to user
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to load PDF: ${details.description}'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              pageLayoutMode: PdfPageLayoutMode.single,
              scrollDirection: PdfScrollDirection.vertical,
            ),
            // Loading indicator
            if (_isLoadingPdf)
              Container(
                color: Colors.white,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.cxRoyalBlue),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Loading PDF...',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cxGraphiteGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Error display
            if (_loadError != null)
              Container(
                color: Colors.white,
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 64.sp,
                          color: AppColors.cxCrimsonRed,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Failed to Load PDF',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cxGraphiteGray,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.cxSilverTint,
                          ),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isLoadingPdf = true;
                              _loadError = null;
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cxRoyalBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 24.w,
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
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
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
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
            // Navigation buttons
            Expanded(
              child: Row(
                children: [
                  _buildNavButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () {
                      if (_currentPage > 0) {
                        _pdfController.previousPage();
                      }
                    },
                    enabled: _currentPage > 0,
                  ),
                  SizedBox(width: 12.w),
                  _buildNavButton(
                    icon: Icons.arrow_forward_ios_rounded,
                    onTap: () {
                      if (_currentPage < _totalPages - 1) {
                        _pdfController.nextPage();
                      }
                    },
                    enabled: _currentPage < _totalPages - 1,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            // Proceed button
            Expanded(
              flex: 2,
              child: Container(
                height: 50.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _canProceedToTest
                        ? [
                            AppColors.cxEmeraldGreen,
                            AppColors.cxEmeraldGreen.withOpacity(0.8),
                          ]
                        : [
                            AppColors.cxSilverTint,
                            AppColors.cxSilverTint.withOpacity(0.8),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: _canProceedToTest
                      ? [
                          BoxShadow(
                            color: AppColors.cxEmeraldGreen.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _proceedToTest,
                    borderRadius: BorderRadius.circular(12.r),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _canProceedToTest
                                ? Icons.check_circle_outline_rounded
                                : Icons.lock_outline_rounded,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            _canProceedToTest ? 'Start Test' : 'Complete Course',
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: 50.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: enabled
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: enabled
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12.r),
          child: Center(
            child: Icon(
              icon,
              color: enabled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              size: 20.sp,
            ),
          ),
        ),
      ),
    );
  }
}
