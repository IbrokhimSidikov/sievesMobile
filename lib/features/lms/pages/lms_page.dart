import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../models/test.dart';

class LmsPage extends StatefulWidget {
  const LmsPage({super.key});

  @override
  State<LmsPage> createState() => _LmsPageState();
}

class _LmsPageState extends State<LmsPage> {
  bool _isLoading = true;
  List<Test> _tests = [];

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() => _isLoading = true);
    
    // Simulate API call - Replace with actual API integration
    await Future.delayed(const Duration(seconds: 1));
    
    // Sample test data with course URLs
    _tests = [
      Test(
        id: '1',
        title: 'Food Safety & Hygiene',
        description: 'Essential food safety practices and hygiene standards for restaurant staff',
        category: 'Safety',
        duration: 15,
        totalQuestions: 10,
        passingScore: 70,
        imageUrl: 'https://images.unsplash.com/photo-1556910103-1c02745aae4d?w=400',
        courseUrl: 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf', // Working sample PDF
        isCompleted: false,
        courseCompleted: false,
      ),
      Test(
        id: '2',
        title: 'Customer Service Excellence',
        description: 'Master the art of providing exceptional customer service',
        category: 'Service',
        duration: 20,
        totalQuestions: 15,
        passingScore: 75,
        imageUrl: 'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=400',
        courseUrl: 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf', // Working sample PDF
        isCompleted: true,
        courseCompleted: true,
        userScore: 85,
      ),
      Test(
        id: '3',
        title: 'Kitchen Operations',
        description: 'Understanding kitchen workflow, equipment, and procedures',
        category: 'Operations',
        duration: 25,
        totalQuestions: 20,
        passingScore: 80,
        imageUrl: 'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400',
        courseUrl: 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf', // Working sample PDF
        isCompleted: false,
        courseCompleted: false,
      ),
      Test(
        id: '4',
        title: 'Menu Knowledge',
        description: 'Complete guide to menu items, ingredients, and preparation methods',
        category: 'Product',
        duration: 30,
        totalQuestions: 25,
        passingScore: 75,
        imageUrl: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400',
        courseUrl: 'https://mozilla.github.io/pdf.js/web/compressed.tracemonkey-pldi-09.pdf', // Working sample PDF
        isCompleted: true,
        courseCompleted: true,
        userScore: 92,
      ),
    ];
    
    setState(() => _isLoading = false);
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
                    AppColors.cxF7F6F9,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _buildTestList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 32.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning Center',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Test your knowledge',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${_tests.length} Tests',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          height: 180.h,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20.r),
          ),
        );
      },
    );
  }

  Widget _buildTestList() {
    if (_tests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 80.sp,
              color: AppColors.cxSilverTint,
            ),
            SizedBox(height: 16.h),
            Text(
              'No tests available',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxGraphiteGray,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: _tests.length,
      itemBuilder: (context, index) {
        return _buildTestCard(_tests[index]);
      },
    );
  }

  Widget _buildTestCard(Test test) {
    final theme = Theme.of(context);
    final categoryColor = _getCategoryColor(test.category);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.push('/testDetail', extra: test);
          },
          borderRadius: BorderRadius.circular(20.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image header
              if (test.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                  ),
                  child: Stack(
                    children: [
                      Image.network(
                        test.imageUrl!,
                        height: 140.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 140.h,
                            color: categoryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.image_not_supported,
                              size: 40.sp,
                              color: categoryColor,
                            ),
                          );
                        },
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Category badge
                      Positioned(
                        top: 12.h,
                        left: 12.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: categoryColor,
                            borderRadius: BorderRadius.circular(8.r),
                            boxShadow: [
                              BoxShadow(
                                color: categoryColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            test.category,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Completion badge
                      if (test.isCompleted)
                        Positioned(
                          top: 12.h,
                          right: 12.w,
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.cxEmeraldGreen,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cxEmeraldGreen.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16.sp,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              
              // Content
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      test.description,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 16.h),
                    
                    // Test info row
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.quiz_outlined,
                          '${test.totalQuestions} Questions',
                          AppColors.cxRoyalBlue,
                        ),
                        SizedBox(width: 8.w),
                        _buildInfoChip(
                          Icons.timer_outlined,
                          '${test.duration} min',
                          AppColors.cxWarning,
                        ),
                        SizedBox(width: 8.w),
                        _buildInfoChip(
                          Icons.emoji_events_outlined,
                          '${test.passingScore}%',
                          AppColors.cxEmeraldGreen,
                        ),
                      ],
                    ),
                    
                    // Score display if completed
                    if (test.isCompleted && test.userScore != null) ...[
                      SizedBox(height: 12.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.cxEmeraldGreen.withOpacity(0.1),
                              AppColors.cxEmeraldGreen.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.cxEmeraldGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: AppColors.cxEmeraldGreen,
                              size: 16.sp,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'Your Score: ${test.userScore}%',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cxEmeraldGreen,
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
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: color,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
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
