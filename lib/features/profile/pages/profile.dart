import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/work_time_calculator.dart';
import '../../../core/model/work_entry_model.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final AuthManager _authManager = AuthManager();
  final AuthService _authService = AuthService();
  late final ApiService _apiService = ApiService(_authService);
  Map<String, dynamic>? _profileData;
  List<WorkEntry> _workEntries = [];
  bool _isLoading = true;
  bool _isLoadingWorkEntries = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadCurrentMonthWorkEntries();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get current identity from AuthManager
      final identity = _authManager.currentIdentity;
      
      if (identity == null) {
        throw Exception('No user identity found. Please login again.');
      }

      // Convert Identity model to Map for UI consumption
      final identityData = {
        'id': identity.id,
        'email': identity.email,
        'username': identity.username,
        'role': identity.role,
        'phone': identity.phone,
        'allowance': identity.allowance,
        'employee': identity.employee != null ? {
          'id': identity.employee!.id,
          'status': identity.employee!.status,
          'individual': identity.employee!.individual != null ? {
            'firstName': identity.employee!.individual!.firstName,
            'lastName': identity.employee!.individual!.lastName,
            'email': identity.employee!.individual!.email,
            'phone': identity.employee!.individual!.phone,
            'photo': identity.employee!.individual!.photo,
          } : null,
          'branch': identity.employee!.branch != null ? {
            'name': identity.employee!.branch!.name,
            'address': identity.employee!.branch!.address,
          } : null,
          'jobPosition': identity.employee!.jobPosition != null ? {
            'name': identity.employee!.jobPosition!.name,
          } : null,
          'department': identity.employee!.department != null ? {
            'name': identity.employee!.department!.name,
          } : null,
          'reward': identity.employee!.reward != null ? {
            'amount': identity.employee!.reward!.amount,
            'type': identity.employee!.reward!.type,
          } : null,
        } : null,
      };
      
      if (mounted) {
        setState(() {
          _profileData = identityData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Get current month's start and end dates in ISO format
  Map<String, String> _getCurrentMonthDateRange() {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return {
      'startDate': firstDayOfMonth.toIso8601String().split('T')[0],
      'endDate': lastDayOfMonth.toIso8601String().split('T')[0],
    };
  }

  /// Fetch work entries for the current month from API
  Future<void> _loadCurrentMonthWorkEntries() async {
    try {
      setState(() {
        _isLoadingWorkEntries = true;
      });

      final employeeId = _authManager.currentEmployeeId;
      if (employeeId == null) {
        print('❌ No employee ID found');
        setState(() {
          _isLoadingWorkEntries = false;
        });
        return;
      }

      final dateRange = _getCurrentMonthDateRange();
      print('📅 Fetching work entries from ${dateRange['startDate']} to ${dateRange['endDate']}');

      final workEntries = await _apiService.getWorkEntries(
        employeeId,
        dateRange['startDate']!,
        dateRange['endDate']!,
      );

      if (mounted) {
        setState(() {
          _workEntries = workEntries ?? [];
          _isLoadingWorkEntries = false;
        });
        print('✅ Loaded ${_workEntries.length} work entries for current month');
      }
    } catch (e) {
      print('❌ Error loading work entries: $e');
      if (mounted) {
        setState(() {
          _workEntries = [];
          _isLoadingWorkEntries = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Colors.red.shade600,
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cxBlack,
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.cxBlack.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: AppColors.cxBlack.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade700],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.cxPureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: AppColors.cxPureWhite,
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.red.shade600,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Logging out...',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppColors.cxBlack.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

        // Perform logout
        await _authManager.logout();

        // Navigate to onboard page and clear navigation stack
        if (mounted) {
          context.go(AppRoutes.onboard);
        }
      } catch (e) {
        // Hide loading dialog
        if (mounted) {
          Navigator.of(context).pop();
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to logout. Please try again.',
                style: TextStyle(color: AppColors.cxPureWhite),
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          );
        }
      }
    }
  }

  /// Get formatted current month string
  String _getCurrentMonthString() {
    final now = DateTime.now();
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cxSoftWhite,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.cxSoftWhite,
              AppColors.cxPlatinumGray.withOpacity(0.3),
              AppColors.cxPureWhite,
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState()
              : _error != null
                  ? _buildErrorState()
                  : _buildProfileContent(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: AppColors.cxRoyalBlue,
            strokeWidth: 3,
          ),
          SizedBox(height: 16.h),
          Text(
            'Loading profile...',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.cxBlack.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.red.withOpacity(0.7),
            ),
            SizedBox(height: 16.h),
            Text(
              'Failed to load profile',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxBlack,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _error ?? 'Unknown error occurred',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.cxBlack.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _loadProfileData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cxRoyalBlue,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.cxPureWhite,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_profileData == null) {
      return _buildErrorState();
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 24.h),
          _buildProfileCard(),
          SizedBox(height: 20.h),
          _buildWorkHoursCard(),
          SizedBox(height: 20.h),
          _buildJobInfoCard(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.cxBlack,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            'Profile',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.cxBlack,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.1),
                Colors.red.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.red.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            onPressed: _handleLogout,
            icon: Icon(
              Icons.logout_rounded,
              color: Colors.red.shade600,
              size: 24.sp,
            ),
            tooltip: 'Logout',
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    final individual = _profileData?['employee']?['individual'];
    final identity = _profileData;
    final employee = _profileData?['employee'];
    final employeeIndividual = employee?['individual'];
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cxRoyalBlue,
            AppColors.cxEmeraldGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxRoyalBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // Profile Photo
            Container(
              width: 100.w,
              height: 100.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cxPureWhite.withOpacity(0.3),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: individual?['photo'] != null
                    ? Image.network(
                        individual['photo'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
                      )
                    : _buildDefaultAvatar(),
              ),
            ),
            SizedBox(height: 16.h),
            // Name
            Text(
              '${employeeIndividual?['firstName'] ?? ''} ${employeeIndividual?['lastName'] ?? ''}'.trim().isNotEmpty 
                  ? '${employeeIndividual?['firstName'] ?? ''} ${employeeIndividual?['lastName'] ?? ''}'.trim()
                  : 'No name',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.cxPureWhite,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8.h),
            // Email
            Text(
              identity?['email'] ?? 'No email',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.cxPureWhite.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            AppColors.cxPureWhite.withOpacity(0.3),
            AppColors.cxPureWhite.withOpacity(0.1),
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: 50.sp,
        color: AppColors.cxPureWhite.withOpacity(0.8),
      ),
    );
  }

  Widget _buildWorkHoursCard() {
    // Use work entries fetched from API (already filtered to current month)
    final currentMonthEntries = _workEntries;
    
    // Calculate hours using WorkTimeCalculator
    final totalHoursFormatted = WorkTimeCalculator.calculateTotalHours(currentMonthEntries);
    final totalHours = WorkTimeCalculator.getTotalHoursAsDouble(currentMonthEntries);
    final dayHoursFormatted = WorkTimeCalculator.calculateDayHours(currentMonthEntries);
    final dayHours = WorkTimeCalculator.getDayHoursAsDouble(currentMonthEntries);
    final nightHoursFormatted = WorkTimeCalculator.calculateNightHours(currentMonthEntries);
    final nightHours = WorkTimeCalculator.getNightHoursAsDouble(currentMonthEntries);
    final isOvertime = WorkTimeCalculator.isOvertime(currentMonthEntries);
    
    // Display current month
    final month = _getCurrentMonthString();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cxEmeraldGreen,
            AppColors.cxEmeraldGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxEmeraldGreen.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: _isLoadingWorkEntries
            ? _buildWorkHoursShimmer()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          Icons.access_time_rounded,
                          color: AppColors.cxPureWhite,
                          size: 28.sp,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Work Hours',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cxPureWhite,
                              ),
                            ),
                            Text(
                              month,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.cxPureWhite.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Overtime badge
                      if (isOvertime)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            'OVERTIME',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cxPureWhite,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 24.h),
                  
                  // Total hours - prominent display with formatted time
                  Center(
                    child: Column(
                      children: [
                        Text(
                          totalHoursFormatted,
                          style: TextStyle(
                            fontSize: 48.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.cxPureWhite,
                            height: 1.0,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Total Hours (${totalHours.toStringAsFixed(1)}h)',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.cxPureWhite.withOpacity(0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: 24.h),
                  
                  // Day and Night hours breakdown
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.cxPureWhite.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.cxPureWhite.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.wb_sunny_outlined,
                                color: AppColors.cxPureWhite,
                                size: 24.sp,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                dayHoursFormatted,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cxPureWhite,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${dayHours.toStringAsFixed(1)}h',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cxPureWhite.withOpacity(0.9),
                                ),
                              ),
                              Text(
                                'Day Hours',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.cxPureWhite.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.cxPureWhite.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: AppColors.cxPureWhite.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.nightlight_round_outlined,
                                color: AppColors.cxPureWhite,
                                size: 24.sp,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                nightHoursFormatted,
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cxPureWhite,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '${nightHours.toStringAsFixed(1)}h',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cxPureWhite.withOpacity(0.9),
                                ),
                              ),
                              Text(
                                'Night Hours',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: AppColors.cxPureWhite.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWorkHoursShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.cxPureWhite.withOpacity(0.2),
      highlightColor: AppColors.cxPureWhite.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Row(
            children: [
              Container(
                width: 52.w,
                height: 52.h,
                decoration: BoxDecoration(
                  color: AppColors.cxPureWhite.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: AppColors.cxPureWhite.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 80.w,
                      height: 14.h,
                      decoration: BoxDecoration(
                        color: AppColors.cxPureWhite.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          
          // Total hours shimmer - prominent display
          Center(
            child: Column(
              children: [
                Container(
                  width: 180.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: 140.w,
                  height: 18.h,
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.h),
          
          // Day and Night hours shimmer breakdown
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.cxPureWhite.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 60.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        width: 40.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        width: 70.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.cxPureWhite.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.cxPureWhite.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 60.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        width: 40.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        width: 70.w,
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: AppColors.cxPureWhite.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobInfoCard() {
    final jobPosition = _profileData?['employee']?['jobPosition'];
    final branch = _profileData?['employee']?['branch'];
    
    return _buildInfoCard(
      title: 'Job Information',
      icon: Icons.work_outline,
      children: [
        _buildInfoRow('Position', jobPosition?['name'] ?? 'Not specified'),
        _buildInfoRow('Branch', branch?['name'] ?? 'Not specified'),
        _buildInfoRow('Department', _profileData?['employee']?['department']?['name'] ?? 'Not specified'),
        _buildInfoRow('Employee ID', _profileData?['employee']?['id']?.toString() ?? 'N/A'),
      ],
    );
  }


  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cxPureWhite,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxBlack.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.cxRoyalBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    color: AppColors.cxRoyalBlue,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cxBlack,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.cxBlack.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.cxBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
