import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/model/work_entry_model.dart';
import '../../../core/services/auth/auth_manager.dart';

class Attendance extends StatefulWidget {
  const Attendance({super.key});

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> with SingleTickerProviderStateMixin {
  final AuthManager _authManager = AuthManager();
  List<WorkEntry> workEntries = [];
  bool isLoading = true;
  String? errorMessage;
  String currentMonth = '';
  DateTime selectedDate = DateTime.now(); // Track selected month/year
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
    
    _loadWorkEntries();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  // Get current month date range (first day to last day)
  String _getCurrentMonthDateRange() {
    final firstDay = DateTime(selectedDate.year, selectedDate.month, 1);
    final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);
    
    final dateFormat = DateFormat('yyyy-MM-dd');
    return '${dateFormat.format(firstDay)},${dateFormat.format(lastDay)}';
  }

  // Get current month name
  String _getCurrentMonthName() {
    return DateFormat('MMMM yyyy').format(selectedDate);
  }

  // Load work entries from API
  Future<void> _loadWorkEntries() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      currentMonth = _getCurrentMonthName();
    });

    try {
      final employeeId = _authManager.currentEmployeeId;
      
      if (employeeId == null) {
        setState(() {
          errorMessage = 'Employee ID not found. Please log in again.';
          isLoading = false;
        });
        return;
      }

      final dateRange = _getCurrentMonthDateRange();
      print('📅 Loading work entries for employee $employeeId, date range: $dateRange');
      
      // Split the date range into start and end dates
      final dates = dateRange.split(',');
      final startDate = dates[0];
      final endDate = dates[1];
      
      final entries = await _authManager.apiService.getWorkEntries(employeeId, startDate, endDate);
      
      setState(() {
        workEntries = entries ?? [];
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading work entries: $e');
      setState(() {
        errorMessage = 'Failed to load work entries. Please try again.';
        isLoading = false;
      });
    }
  }

  // Navigate to previous month
  void _goToPreviousMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
    });
    _loadWorkEntries();
  }

  // Navigate to next month
  void _goToNextMonth() {
    setState(() {
      selectedDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
    });
    _loadWorkEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cxSoftWhite,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              SizedBox(height: 24.h),
              
              // Work Entries Table
              Expanded(
                child: _buildWorkEntriesTable(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cxWhite,
            AppColors.cxF5F7F9,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxBlack.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cx43C19F, AppColors.cx4AC1A7],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              color: AppColors.cxWhite,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Work Entries',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxDarkCharcoal,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    // Previous month button
                    InkWell(
                      onTap: _goToPreviousMonth,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppColors.cx43C19F.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          size: 16.sp,
                          color: AppColors.cx43C19F,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      currentMonth,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.cxSilverTint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Next month button
                    InkWell(
                      onTap: _goToNextMonth,
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: AppColors.cx43C19F.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          size: 16.sp,
                          color: AppColors.cx43C19F,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Refresh button
          IconButton(
            onPressed: _loadWorkEntries,
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.cx43C19F,
              size: 24.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkEntriesTable() {
    if (isLoading) {
      return _buildSkeletonLoader();
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64.sp,
              color: AppColors.cxWarning,
            ),
            SizedBox(height: 16.h),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.cxGraphiteGray,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _loadWorkEntries,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cx43C19F,
                foregroundColor: AppColors.cxWhite,
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

    if (workEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64.sp,
              color: AppColors.cxSilverTint,
            ),
            SizedBox(height: 16.h),
            Text(
              'No work entries found for this month',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.cxGraphiteGray,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cxWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxBlack.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          _buildTableHeader(),
          
          // Table Rows
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: workEntries.length,
              itemBuilder: (context, index) {
                return _buildTableRow(workEntries[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cxWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxBlack.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header (static)
          _buildTableHeader(),
          
          // Skeleton Rows
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: 8, // Show 8 skeleton rows
              itemBuilder: (context, index) {
                return _buildSkeletonRow(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.cxF5F7F9,
            AppColors.cxF7F6F9,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.r),
          topRight: Radius.circular(16.r),
        ),
      ),
      child: Row(
        children: [
          _buildHeaderCell('Date', flex: 2),
          _buildHeaderCell('Check-in', flex: 2),
          _buildHeaderCell('Check-out', flex: 2),
          _buildHeaderCell('Status', flex: 2),
          _buildHeaderCell('Mood', flex: 1),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String title, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.cxGraphiteGray,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableRow(WorkEntry entry, int index) {
    final isEvenRow = index % 2 == 0;
    final isOpenStatus = entry.isOpen;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isEvenRow ? AppColors.cxWhite : AppColors.cxF5F7F9.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: AppColors.cxPlatinumGray.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildDataCell(entry.formattedDate, flex: 2),
          _buildDataCell(entry.formattedCheckInTime, flex: 2, isEmpty: entry.checkInTime == null),
          _buildDataCell(entry.formattedCheckOutTime, flex: 2, isEmpty: entry.checkOutTime == null),
          _buildStatusCell(entry.displayStatus, flex: 2),
          _buildMoodCell(entry.moodEmoji, flex: 1),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text, {int flex = 1, bool isEmpty = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        isEmpty ? '-' : text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: isEmpty ? AppColors.cxSilverTint : AppColors.cxGraphiteGray,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStatusCell(String status, {int flex = 1}) {
    final isOpen = status.toLowerCase() == 'open';
    return Expanded(
      flex: flex,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: isOpen ? AppColors.cxCrimsonRed.withOpacity(0.1) : AppColors.cxEmeraldGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isOpen ? AppColors.cxCrimsonRed.withOpacity(0.3) : AppColors.cxEmeraldGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: isOpen ? AppColors.cxCrimsonRed : AppColors.cxEmeraldGreen,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoodCell(String emoji, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Text(
          emoji,
          style: TextStyle(fontSize: 20.sp),
        ),
      ),
    );
  }

  Widget _buildSkeletonRow(int index) {
    final isEvenRow = index % 2 == 0;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isEvenRow ? AppColors.cxWhite : AppColors.cxF5F7F9.withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: AppColors.cxPlatinumGray.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildSkeletonCell(flex: 2, width: 60.w), // Date
          _buildSkeletonCell(flex: 2, width: 50.w), // Check-in
          _buildSkeletonCell(flex: 2, width: 50.w), // Check-out
          _buildSkeletonCell(flex: 2, width: 45.w, isStatus: true), // Status
          _buildSkeletonCell(flex: 1, width: 24.w, isEmoji: true), // Mood
        ],
      ),
    );
  }

  Widget _buildSkeletonCell({required int flex, required double width, bool isStatus = false, bool isEmoji = false}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: AnimatedBuilder(
          animation: _shimmerAnimation,
          builder: (context, child) {
            return Container(
              width: width,
              height: isEmoji ? 24.h : (isStatus ? 24.h : 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cxPlatinumGray.withOpacity(_shimmerAnimation.value),
                    AppColors.cxSilverTint.withOpacity(_shimmerAnimation.value * 0.5),
                    AppColors.cxPlatinumGray.withOpacity(_shimmerAnimation.value),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isStatus ? 12.r : (isEmoji ? 12.r : 6.r)),
              ),
            );
          },
        ),
      ),
    );
  }
}
