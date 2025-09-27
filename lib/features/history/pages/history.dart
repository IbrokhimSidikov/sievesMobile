import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

class History extends StatefulWidget {
  const History({super.key});

  @override
  State<History> createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  // Sample data for demonstration
  final List<Map<String, dynamic>> historyRecords = [
    {
      'type': 'Информация',
      'date': '02-02-2024 17:20:17',
      'comment': 'Системада рўйхатдан утди\nРегистровала: Abdugani Alimxanov',
      'branch': 'Администрация',
      'color': AppColors.cxBlue,
    },
    {
      'type': 'Информация',
      'date': '02-02-2024 17:23:24',
      'comment': 'Odob bo\'yicha trening',
      'branch': 'Администрация',
      'color': AppColors.cxBlue,
    },
    {
      'type': 'Информация',
      'date': '02-02-2024 18:43:14',
      'comment': 'Синов муддатини утди.Кабул килди: Abdugani Alimxanov',
      'branch': 'Администрация',
      'color': AppColors.cxBlue,
    },
    {
      'type': 'Информация',
      'date': '10-02-2024 18:49:25',
      'comment': 'Синов муддатини утди.Кабул килди: Abdugani Alimxanov',
      'branch': 'Администрация',
      'color': AppColors.cxBlue,
    },
    {
      'type': 'Достижение',
      'date': '14-02-2024 12:25:40',
      'comment': 'Ходим оформить килинди.Оформить килди: Abdugani Alimxanov',
      'branch': 'Администрация',
      'color': AppColors.cxEmeraldGreen,
    },
    {
      'type': 'Устное предупреждение',
      'date': '15-03-2024 09:15:30',
      'comment': 'Опоздание на работу без уважительной причины',
      'branch': 'Администрация',
      'color': AppColors.cxWarning,
    },
    {
      'type': 'Объяснительное письмо',
      'date': '20-03-2024 14:30:45',
      'comment': 'Нарушение дресс-кода компании',
      'branch': 'Администрация',
      'color': AppColors.cxAmberGold,
    },
    {
      'type': 'Испытательный срок',
      'date': '25-03-2024 11:20:15',
      'comment': 'Продление испытательного срока на 1 месяц',
      'branch': 'Администрация',
      'color': AppColors.cxPurple,
    },
  ];

  // Record type filter
  String selectedFilter = 'Все';
  final List<String> filterOptions = [
    'Все',
    'Информация',
    'Достижение',
    'Устное предупреждение',
    'Объяснительное письмо',
    'Испытательный срок',
    'Освобождение от должности'
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
              SizedBox(height: 20.h),
              
              // Filter Section
              _buildFilterSection(),
              SizedBox(height: 20.h),
              
              // History Timeline
              Expanded(
                child: _buildHistoryTimeline(),
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
                colors: [AppColors.cxBlue, AppColors.cx02D5F5],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              Icons.history_rounded,
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
                  'History Records',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxDarkCharcoal,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Employee activity timeline',
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
              color: AppColors.cxBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.cxBlue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '${_getFilteredRecords().length} Records',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.cxWhite,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.cxBlack.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Type',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.cxDarkCharcoal,
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 35.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filterOptions.length,
              itemBuilder: (context, index) {
                final option = filterOptions[index];
                final isSelected = selectedFilter == option;
                return Container(
                  margin: EdgeInsets.only(right: 8.w),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        selectedFilter = option;
                      });
                    },
                    borderRadius: BorderRadius.circular(18.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [AppColors.cxBlue, AppColors.cx02D5F5],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected ? null : AppColors.cxF5F7F9,
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: isSelected ? Colors.transparent : AppColors.cxPlatinumGray.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.cxWhite : AppColors.cxGraphiteGray,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTimeline() {
    final filteredRecords = _getFilteredRecords();
    
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
      child: ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: filteredRecords.length,
        itemBuilder: (context, index) {
          return _buildTimelineItem(filteredRecords[index], index, filteredRecords.length);
        },
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> record, int index, int totalItems) {
    final isLast = index == totalItems - 1;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: record['color'],
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.cxWhite,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: record['color'].withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Container(
                width: 2.w,
                height: 60.h,
                color: AppColors.cxPlatinumGray.withOpacity(0.3),
              ),
          ],
        ),
        
        SizedBox(width: 16.w),
        
        // Content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  record['color'].withOpacity(0.05),
                  record['color'].withOpacity(0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: record['color'].withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type and Date row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: record['color'],
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        record['type'],
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.cxWhite,
                        ),
                      ),
                    ),
                    Text(
                      record['date'],
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.cxSilverTint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12.h),
                
                // Comment
                Text(
                  record['comment'],
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.cxGraphiteGray,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                
                SizedBox(height: 8.h),
                
                // Branch
                Row(
                  children: [
                    Icon(
                      Icons.business_rounded,
                      size: 14.sp,
                      color: record['color'],
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      record['branch'],
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: record['color'],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getFilteredRecords() {
    if (selectedFilter == 'Все') {
      return historyRecords;
    }
    return historyRecords.where((record) => record['type'] == selectedFilter).toList();
  }
}
