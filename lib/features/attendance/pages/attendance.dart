import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

class Attendance extends StatefulWidget {
  const Attendance({super.key});

  @override
  State<Attendance> createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  // Sample data for demonstration
  final List<Map<String, dynamic>> workEntries = [
    {
      'date': '2025-09-01',
      'startTime': '10:27:40',
      'endTime': '19:00:00',
      'status': 'Closed',
      'mood': '😊'
    },
    {
      'date': '2025-09-02',
      'startTime': '10:08:07',
      'endTime': '19:00:00',
      'status': 'Closed',
      'mood': '🤔'
    },
    {
      'date': '2025-09-03',
      'startTime': '09:51:32',
      'endTime': '18:51:32',
      'status': 'Closed',
      'mood': '😊'
    },
    {
      'date': '2025-09-04',
      'startTime': '10:16:41',
      'endTime': '18:03:21',
      'status': 'Closed',
      'mood': '😊'
    },
    {
      'date': '2025-09-05',
      'startTime': '10:22:03',
      'endTime': '19:00:00',
      'status': 'Closed',
      'mood': '😊'
    },
    {
      'date': '2025-09-06',
      'startTime': '10:48:50',
      'endTime': '17:49:02',
      'status': 'Closed',
      'mood': '😊'
    },
    {
      'date': '2025-09-07',
      'startTime': '',
      'endTime': '',
      'status': 'Open',
      'mood': ''
    },
    {
      'date': '2025-09-08',
      'startTime': '10:01:19',
      'endTime': '17:30:00',
      'status': 'Closed',
      'mood': '😊'
    },
  ];

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
                Text(
                  'September 2025',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.cxSilverTint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkEntriesTable() {
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

  Widget _buildTableRow(Map<String, dynamic> entry, int index) {
    final isEvenRow = index % 2 == 0;
    final isOpenStatus = entry['status'] == 'Open';
    
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
          _buildDataCell(_formatDate(entry['date']), flex: 2),
          _buildDataCell(entry['startTime'], flex: 2, isEmpty: entry['startTime'].isEmpty),
          _buildDataCell(entry['endTime'], flex: 2, isEmpty: entry['endTime'].isEmpty),
          _buildStatusCell(entry['status'], flex: 2),
          _buildMoodCell(entry['mood'], flex: 1),
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
    final isOpen = status == 'Open';
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

  Widget _buildMoodCell(String mood, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Center(
        child: mood.isEmpty 
          ? Text(
              '-',
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.cxSilverTint,
              ),
            )
          : Text(
              mood,
              style: TextStyle(fontSize: 18.sp),
            ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
