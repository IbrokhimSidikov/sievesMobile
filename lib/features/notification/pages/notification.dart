import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Placeholder notifications
  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'type': 'System',
      'title': 'Welcome to Sieves!',
      'message': 'Your account is set up. Explore new features and updates.',
      'time': 'Now',
      'icon': Icons.auto_awesome_rounded,
      'colorFrom': AppColors.cxRoyalBlue,
      'colorTo': AppColors.cxBlue,
      'isRead': false,
    },
    {
      'id': 2,
      'type': 'Attendance',
      'title': 'Check-in Successful',
      'message': 'You checked in at 09:01 AM. Have a great day! ',
      'time': '10m',
      'icon': Icons.login_rounded,
      'colorFrom': AppColors.cxEmeraldGreen,
      'colorTo': AppColors.cx43C19F,
      'isRead': false,
    },
    {
      'id': 3,
      'type': 'Payroll',
      'title': 'Salary Processed',
      'message': 'Your salary for Sep has been processed. View details.',
      'time': '1h',
      'icon': Icons.payments_rounded,
      'colorFrom': AppColors.cxWarning,
      'colorTo': AppColors.cxFEDA84,
      'isRead': true,
    },
    {
      'id': 4,
      'type': 'Break',
      'title': 'Meal Approved',
      'message': 'Your break meal request was approved by supervisor.',
      'time': 'Yesterday',
      'icon': Icons.free_breakfast_rounded,
      'colorFrom': AppColors.cxWarning,
      'colorTo': AppColors.cxFEDA84,
      'isRead': true,
    },
  ];

  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['isRead'] == false).length;
    final filtered = _filter == 'All'
        ? _notifications
        : _filter == 'Unread'
            ? _notifications.where((n) => n['isRead'] == false).toList()
            : _notifications.where((n) => n['type'] == _filter).toList();

    return Scaffold(
      backgroundColor: AppColors.cxSoftWhite,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(unreadCount),
              SizedBox(height: 20.h),
              _buildFilters(unreadCount),
              SizedBox(height: 16.h),
              Expanded(
                child: _buildNotificationList(filtered),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(int unreadCount) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.cxWhite, AppColors.cxF5F7F9],
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cxRoyalBlue, AppColors.cxBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: AppColors.cxWhite,
                  size: 24.sp,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -2.w,
                  top: -2.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.cxWarning,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.cxWhite, width: 2),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: TextStyle(
                        color: AppColors.cxWhite,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cxDarkCharcoal,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Stay updated with your latest activity',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.cxSilverTint,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _markAllAsRead,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.cxF5F7F9,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: AppColors.cxPlatinumGray.withOpacity(0.4)),
              ),
              child: Text(
                'Mark all read',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cxGraphiteGray,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(int unreadCount) {
    final filters = ['All', 'Unread', 'System', 'Attendance', 'Payroll', 'Break'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final bool selected = _filter == f;
          final bool showBadge = f == 'Unread' && unreadCount > 0;
          return Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: () => setState(() => _filter = f),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(
                          colors: [AppColors.cxWhite, AppColors.cxF5F7F9],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: selected ? null : AppColors.cxWhite,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.cxPlatinumGray.withOpacity(selected ? 0.4 : 0.3),
                  ),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: AppColors.cxBlack.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      f,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: selected ? AppColors.cxDarkCharcoal : AppColors.cxGraphiteGray,
                      ),
                    ),
                    if (showBadge) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.cxWarning,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: AppColors.cxWhite,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNotificationList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async => Future.delayed(const Duration(milliseconds: 700)),
      child: Container(
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
        child: ListView.separated(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: AppColors.cxPlatinumGray.withOpacity(0.25),
          ),
          itemBuilder: (context, index) {
            final n = items[index];
            final bool isRead = n['isRead'] == true;
            return InkWell(
              onTap: () => _markAsRead(n['id'] as int),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLeadingIcon(n),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  n['title'] as String,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cxDarkCharcoal,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                n['time'] as String,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.cxSilverTint,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            n['message'] as String,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.cxGraphiteGray,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              _buildTag(n['type'] as String),
                              const Spacer(),
                              if (!isRead)
                                Container(
                                  width: 8.w,
                                  height: 8.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.cxWarning,
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.cxPlatinumGray,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(Map<String, dynamic> n) {
    final Color from = n['colorFrom'] as Color;
    final Color to = n['colorTo'] as Color;
    final IconData icon = n['icon'] as IconData;

    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [from.withOpacity(0.12), to.withOpacity(0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: from.withOpacity(0.25), width: 0.7),
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [from, to],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: AppColors.cxWhite, size: 18.sp),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.cxF5F7F9,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.cxPlatinumGray.withOpacity(0.35)),
      ),
    child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.cxGraphiteGray,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cxWhite, AppColors.cxF5F7F9],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: AppColors.cxPlatinumGray.withOpacity(0.3)),
                ),
                child: Icon(
                  Icons.notifications_off_rounded,
                  color: AppColors.cxPlatinumGray,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'No notifications yet',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cxDarkCharcoal,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'You’re all caught up. We\'ll let you know when there’s something new.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.cxGraphiteGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (final n in _notifications) {
        n['isRead'] = true;
      }
    });
  }

  void _markAsRead(int id) {
    setState(() {
      final idx = _notifications.indexWhere((e) => e['id'] == id);
      if (idx != -1) _notifications[idx]['isRead'] = true;
    });
  }
}
