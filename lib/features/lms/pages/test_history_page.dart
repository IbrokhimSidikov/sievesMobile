import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../models/test_session.dart';
import '../models/course.dart';

class TestHistoryPage extends StatefulWidget {
  const TestHistoryPage({super.key});

  @override
  State<TestHistoryPage> createState() => _TestHistoryPageState();
}

class _TestHistoryPageState extends State<TestHistoryPage> with SingleTickerProviderStateMixin {
  List<TestSession> _sessions = [];
  Map<int, Course> _courseMap = {};
  bool _isLoading = true;
  String? _errorMessage;
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
    
    _loadAllSessions();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authManager = AuthManager();
      final accessToken = await authManager.authService.getAccessToken();
      
      if (accessToken == null) {
        setState(() {
          _errorMessage = 'Authentication required';
          _isLoading = false;
        });
        return;
      }
      
      print('📡 Fetching all test sessions...');
      
      // Fetch all sessions without course_id filter
      final sessionsResponse = await http.get(
        Uri.parse('https://api.v3.sievesapp.com/course/sessions/my'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      
      print('   Sessions Response Status: ${sessionsResponse.statusCode}');
      
      if (sessionsResponse.statusCode == 200) {
        final List<dynamic> sessionsData = json.decode(sessionsResponse.body);
        final sessions = sessionsData.map((json) => TestSession.fromJson(json)).toList();
        
        // Sort by most recent first
        sessions.sort((a, b) => (b.completedAt ?? b.startedAt).compareTo(a.completedAt ?? a.startedAt));
        
        print('✅ Loaded ${sessions.length} total sessions');
        
        // Get unique course IDs
        final courseIds = sessions.map((s) => s.courseId).toSet();
        
        // Fetch course details for each unique course
        print('📡 Fetching details for ${courseIds.length} courses...');
        final courseMap = <int, Course>{};
        
        for (final courseId in courseIds) {
          try {
            final courseResponse = await http.get(
              Uri.parse('https://api.v3.sievesapp.com/course/$courseId'),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json',
              },
            );
            
            if (courseResponse.statusCode == 200) {
              final courseJson = json.decode(courseResponse.body);
              courseMap[courseId] = Course.fromJson(courseJson);
            }
          } catch (e) {
            print('⚠️ Failed to load course $courseId: $e');
          }
        }
        
        print('✅ Loaded ${courseMap.length} course details');
        
        setState(() {
          _sessions = sessions;
          _courseMap = courseMap;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load test history';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading test history: $e');
      setState(() {
        _errorMessage = 'Error loading test history';
        _isLoading = false;
      });
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
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildSessionsList(),
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
              Text(
                'Test History',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
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
                  Icons.history_rounded,
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
                      'Your Test Journey',
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'All your test attempts',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isLoading)
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
                    '${_sessions.length} ${_sessions.length == 1 ? 'Test' : 'Tests'}',
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
      padding: EdgeInsets.all(20.w),
      itemCount: 5,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              margin: EdgeInsets.only(bottom: 16.h),
              height: 120.h,
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
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 20.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withOpacity(0.1 * _shimmerAnimation.value)
                            : Colors.grey.withOpacity(0.3 * _shimmerAnimation.value),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      height: 16.h,
                      width: 200.w,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? Colors.white.withOpacity(0.08 * _shimmerAnimation.value)
                            : Colors.grey.withOpacity(0.25 * _shimmerAnimation.value),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    Spacer(),
                    Row(
                      children: [
                        Container(
                          height: 14.h,
                          width: 100.w,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withOpacity(0.08 * _shimmerAnimation.value)
                                : Colors.grey.withOpacity(0.25 * _shimmerAnimation.value),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                        ),
                        Spacer(),
                        Container(
                          height: 30.h,
                          width: 60.w,
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withOpacity(0.1 * _shimmerAnimation.value)
                                : Colors.grey.withOpacity(0.3 * _shimmerAnimation.value),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildErrorState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80.sp,
            color: AppColors.cxCrimsonRed,
          ),
          SizedBox(height: 16.h),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _loadAllSessions,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList() {
    if (_sessions.isEmpty) {
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
              'No test history yet',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxGraphiteGray,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Start taking tests to see your history',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.cxSilverTint,
              ),
            ),
          ],
        ),
      );
    }

    // Group sessions by date
    final groupedSessions = <String, List<TestSession>>{};
    for (final session in _sessions) {
      final date = session.completedAt ?? session.startedAt;
      final dateKey = _getDateKey(date);
      groupedSessions.putIfAbsent(dateKey, () => []).add(session);
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: groupedSessions.length,
      itemBuilder: (context, index) {
        final dateKey = groupedSessions.keys.elementAt(index);
        final sessions = groupedSessions[dateKey]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ),
            ...sessions.map((session) => _buildSessionCard(session)).toList(),
            SizedBox(height: 24.h),
          ],
        );
      },
    );
  }

  Widget _buildSessionCard(TestSession session) {
    final theme = Theme.of(context);
    final course = _courseMap[session.courseId];
    final isPassed = session.status.toLowerCase() == 'passed';
    final statusColor = isPassed ? AppColors.cxEmeraldGreen : AppColors.cxCrimsonRed;
    final score = session.scorePercentage?.toInt() ?? 0;
    final categoryColor = _getCategoryColor(course?.category ?? 'default');
    
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
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
            // Could navigate to course detail or show session details
          },
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (course != null) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: categoryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: categoryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          course.category ?? 'General',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            color: categoryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Expanded(
                      child: Text(
                        course?.name ?? 'Course #${session.courseId}',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withOpacity(0.1),
                        statusColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPassed ? Icons.check_rounded : Icons.close_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 14.sp,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${session.correctAnswers ?? 0}/${session.totalQuestions} correct',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14.sp,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  _formatTime(session.completedAt ?? session.startedAt),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '$score%',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
