import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/cache/lms_cache_service.dart';
import '../models/test.dart';
import '../models/course.dart';
import '../models/test_session.dart';
import '../models/test_with_sessions.dart';

class LmsPage extends StatefulWidget {
  const LmsPage({super.key});

  @override
  State<LmsPage> createState() => _LmsPageState();
}

class _LmsPageState extends State<LmsPage> with SingleTickerProviderStateMixin {
  final LmsCacheService _cacheService = LmsCacheService();
  bool _isLoading = true;
  List<Test> _tests = [];
  String? _loadingCourseId;
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _shimmerAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));
    
    _loadTests();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadTests() async {
    setState(() => _isLoading = true);
    
    try {
      // Clear cache and fetch fresh data
      print('🗑️ Clearing courses cache...');
      await _cacheService.clearCoursesCache();
      
      // Try to load from cache first
      final cachedCourses = await _cacheService.getCachedCourses();
      if (cachedCourses != null) {
        try {
          final allCourses = cachedCourses
              .map((json) => Course.fromJson(json))
              .toList();
          
          print('📊 Total courses: ${allCourses.length}');
          for (var course in allCourses) {
            print('   - ${course.name}: isActive=${course.isActive}, deleted=${course.deleted}');
          }
          
          final courses = allCourses
              .where((course) => course.isActive && !course.deleted)
              .toList();
          
          _tests = courses.map((course) => Test.fromCourse(course)).toList();
          setState(() => _isLoading = false);
          print('📦 Loaded ${_tests.length} active courses from cache');
          return;
        } catch (cacheError) {
          print('❌ Error parsing cached data: $cacheError');
          print('🗑️ Clearing corrupted cache...');
          await _cacheService.clearCoursesCache();
          print('✅ Cache cleared, fetching fresh data...');
        }
      }

      // If no cache, fetch from API
      print('🌐 No cache found, fetching courses from API...');
      final authManager = AuthManager();
      final accessToken = await authManager.authService.getAccessToken();
      
      if (accessToken == null) {
        print('❌ No access token available');
        setState(() => _isLoading = false);
        return;
      }
      
      print('📡 Fetching courses from API...');
      final response = await http.get(
        Uri.parse('https://api.v3.sievesapp.com/course'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      print('   Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final List<dynamic> coursesJson = json.decode(response.body);
        print('✅ Received ${coursesJson.length} courses');
        
        // Cache the raw course data
        final coursesData = coursesJson.cast<Map<String, dynamic>>();
        await _cacheService.cacheCourses(coursesData);
        
        final courses = coursesJson
            .map((json) => Course.fromJson(json))
            .where((course) => course.isActive && !course.deleted)
            .toList();
        
        _tests = courses.map((course) => Test.fromCourse(course)).toList();
        
        print('✅ Loaded ${_tests.length} active courses');
      } else {
        print('❌ Failed to load courses: ${response.statusCode}');
        print('   Response: ${response.body}');
      }
    } catch (e) {
      print('❌ Error loading courses: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _onCourseClicked(BuildContext context, Test test) async {
    setState(() => _loadingCourseId = test.id);
    
    try {
      final authManager = AuthManager();
      final accessToken = await authManager.authService.getAccessToken();
      
      if (accessToken == null) {
        print('❌ No access token available');
        setState(() => _loadingCourseId = null);
        return;
      }
      
      print('📡 Fetching course details and sessions for ID: ${test.id}');
      
      // Fetch both course details and sessions in parallel
      final courseResponse = http.get(
        Uri.parse('https://api.v3.sievesapp.com/course/${test.id}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      final sessionsResponse = http.get(
        Uri.parse('https://api.v3.sievesapp.com/course/sessions/my?course_id=${test.id}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      // Wait for both requests to complete
      final responses = await Future.wait([courseResponse, sessionsResponse]);
      
      print('   Course Response Status: ${responses[0].statusCode}');
      print('   Sessions Response Status: ${responses[1].statusCode}');
      
      Test finalTest = test;
      List<TestSession>? sessions;
      
      // Process course details
      if (responses[0].statusCode == 200) {
        final courseJson = json.decode(responses[0].body);
        final course = Course.fromJson(courseJson);
        
        print('✅ Course details loaded');
        print('   Course: ${course.name}');
        print('   Tests: ${course.tests?.length ?? 0}');
        
        finalTest = Test.fromCourse(course);
      } else {
        print('⚠️ Using basic course info (details fetch failed)');
      }
      
      // Process sessions
      if (responses[1].statusCode == 200) {
        final List<dynamic> sessionsData = json.decode(responses[1].body);
        sessions = sessionsData.map((json) => TestSession.fromJson(json)).toList();
        print('✅ Preloaded ${sessions.length} test sessions');
      } else {
        print('⚠️ No sessions data available');
      }
      
      setState(() => _loadingCourseId = null);
      if (!context.mounted) return;
      
      // Pass both test and sessions
      final testWithSessions = TestWithSessions(
        test: finalTest,
        sessions: sessions,
      );
      context.push('/testDetail', extra: testWithSessions);
    } catch (e) {
      print('❌ Error loading course data: $e');
      
      setState(() => _loadingCourseId = null);
      if (!context.mounted) return;
      
      // Pass test without sessions on error
      final testWithSessions = TestWithSessions(test: test);
      context.push('/testDetail', extra: testWithSessions);
    }
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
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  color: const Color(0xFF6366F1),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Learning Center',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _isLoading ? null : _loadTests,
                  icon: const Icon(Icons.refresh_rounded),
                  color: const Color(0xFF6366F1),
                  tooltip: 'Refresh Courses',
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => context.push('/testHistory'),
                  icon: const Icon(Icons.history_edu_rounded),
                  color: const Color(0xFF6366F1),
                  tooltip: 'Test History',
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
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
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      itemCount: 3,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.only(bottom: 16.h),
              height: 220.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image placeholder
                  Container(
                    height: 140.h,
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withOpacity(0.05 * _shimmerAnimation.value)
                          : Colors.grey.withOpacity(0.2 * _shimmerAnimation.value),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                  ),
                  // Content placeholder
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title placeholder
                        Container(
                          height: 18.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withOpacity(0.1 * _shimmerAnimation.value)
                                : Colors.grey.withOpacity(0.3 * _shimmerAnimation.value),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // Description placeholder
                        Container(
                          height: 14.h,
                          width: 200.w,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withOpacity(0.08 * _shimmerAnimation.value)
                                : Colors.grey.withOpacity(0.25 * _shimmerAnimation.value),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
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
    final isLoading = _loadingCourseId == test.id;
    
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
          onTap: isLoading ? null : () => _onCourseClicked(context, test),
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
            children: [
              Column(
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
              // Loading overlay
              if (isLoading)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      color: theme.colorScheme.surface.withOpacity(0.95),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Loading course...',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 40.w),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: LinearProgressIndicator(
                                minHeight: 8.h,
                                backgroundColor: categoryColor.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  categoryColor,
                                ),
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
