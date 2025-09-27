import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

class BreakRecords extends StatefulWidget {
  const BreakRecords({super.key});

  @override
  State<BreakRecords> createState() => _BreakRecordsState();
}

class _BreakRecordsState extends State<BreakRecords> {
  // Sample data for demonstration
  final List<Map<String, dynamic>> breakRecords = [
    {
      'id': 1,
      'photo': 'https://via.placeholder.com/150x150/43C19F/FFFFFF?text=Photo1',
      'date': '2025-08-31 13:07:41',
      'items': ['CHEESE BURGER x 1', 'ICE TEA x 1', 'MAYO 1 POT x 1'],
      'amount': 52000,
    },
    {
      'id': 2,
      'photo': 'https://via.placeholder.com/150x150/4AC1A7/FFFFFF?text=Photo2',
      'date': '2025-09-01 13:06:20',
      'items': ['COMBO x 1 → ICE TEA', 'BURGER x 1'],
      'amount': 53000,
    },
    {
      'id': 3,
      'photo': 'https://via.placeholder.com/150x150/78D9BF/FFFFFF?text=Photo3',
      'date': '2025-09-02 13:15:13',
      'items': ['COMBO x 1 → ICE TEA', 'CHEESE BURGER x 1'],
      'amount': 57000,
    },
    {
      'id': 4,
      'photo': 'https://via.placeholder.com/150x150/FEDA84/FFFFFF?text=Photo4',
      'date': '2025-09-03 13:08:01',
      'items': ['SPECIAL COMBO x 1', 'EXTRA SAUCE x 2'],
      'amount': 59000,
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
              
              // Break Records List
              Expanded(
                child: _buildBreakRecordsList(),
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
                colors: [AppColors.cxWarning, AppColors.cxFEDA84],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.coffee_rounded,
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
                  'Break Records',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxDarkCharcoal,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Your meal history',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.cxSilverTint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.cxWarning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.cxWarning.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${breakRecords.length} Records',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxWarning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakRecordsList() {
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
          
          // Records List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: breakRecords.length,
              itemBuilder: (context, index) {
                return _buildRecordCard(breakRecords[index], index);
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
          _buildHeaderCell('#', flex: 1),
          _buildHeaderCell('Date', flex: 3),
          _buildHeaderCell('Amount', flex: 2),
          _buildHeaderCell('Details', flex: 1),
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

  Widget _buildRecordCard(Map<String, dynamic> record, int index) {
    final isEvenRow = index % 2 == 0;
    
    return InkWell(
      onTap: () => _showItemDetailsPopup(record),
      borderRadius: BorderRadius.circular(0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isEvenRow ? AppColors.cxWhite : AppColors.cxF5F7F9.withOpacity(0.3),
          border: Border(
            bottom: BorderSide(
              color: AppColors.cxPlatinumGray.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ID Number
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cxWarning, AppColors.cxFEDA84],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Center(
                  child: Text(
                    '${record['id']}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cxWhite,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Date & Time
          Expanded(
            flex: 3,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDate(record['date']),
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cxGraphiteGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _formatTime(record['date']),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppColors.cxSilverTint,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          // Amount
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cxRoyalBlue.withOpacity(0.12),
                      AppColors.cxBlue.withOpacity(0.12),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.cxRoyalBlue.withOpacity(0.25),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '${record['amount']}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxRoyalBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          // Details indicator
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.cxWarning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AppColors.cxWarning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.visibility_rounded,
                  color: AppColors.cxWarning,
                  size: 16.sp,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showItemDetailsPopup(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.cxWhite,
                  AppColors.cxF5F7F9,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cxBlack.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with photo and basic info
                Row(
                  children: [
                    Container(
                      width: 60.w,
                      height: 60.w,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cxBlack.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: Image.network(
                          record['photo'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.cxWarning, AppColors.cxFEDA84],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                Icons.restaurant_rounded,
                                color: AppColors.cxWhite,
                                size: 24.sp,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Break Record #${record['id']}',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cxDarkCharcoal,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '${_formatDate(record['date'])} at ${_formatTime(record['date'])}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.cxSilverTint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.cxRoyalBlue.withOpacity(0.15),
                                  AppColors.cxBlue.withOpacity(0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: AppColors.cxRoyalBlue.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              'Total: ${record['amount']}',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cxRoyalBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 24.h),
                
                // Items section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Order Details',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cxDarkCharcoal,
                    ),
                  ),
                ),
                
                SizedBox(height: 12.h),
                
                // Items list
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.cxF7F6F9.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.cxPlatinumGray.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: record['items'].map<Widget>((item) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.cxEmeraldGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: AppColors.cxEmeraldGreen.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(6.w),
                              decoration: BoxDecoration(
                                color: AppColors.cxEmeraldGreen,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Icon(
                                Icons.restaurant_menu_rounded,
                                color: AppColors.cxWhite,
                                size: 16.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cxEmeraldGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                
                SizedBox(height: 20.h),
                
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.cxWarning, AppColors.cxFEDA84],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.close_rounded,
                            color: AppColors.cxWhite,
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cxWhite,
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
      },
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
    } catch (e) {
      return dateStr.split(' ')[0];
    }
  }

  String _formatTime(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.split(' ')[1] ?? '';
    }
  }
}
