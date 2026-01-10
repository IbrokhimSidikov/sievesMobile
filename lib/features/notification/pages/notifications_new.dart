import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/model/notification_model.dart';
import '../../../core/services/notification/notification_storage_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _debugStorage();
  }
  
  // Debug function to check storage
  Future<void> _debugStorage() async {
    try {
      final notifications = await NotificationStorageService().getNotifications();
      print('📊 DEBUG: Total notifications in storage: ${notifications.length}');
      for (var n in notifications) {
        print('  📨 ${n.title} (${n.type}) - ${n.timeAgo} - Read: ${n.isRead}');
      }
    } catch (e) {
      print('❌ DEBUG: Error checking storage: $e');
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      print('📱 Loading notifications from storage...');
      final notifications = await NotificationStorageService().getNotifications();
      print('✅ Loaded ${notifications.length} notifications');
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    
    final filtered = _filter == 'All'
        ? _notifications
        : _filter == 'Unread'
            ? _notifications.where((n) => !n.isRead).toList()
            : _notifications.where((n) => n.type.toLowerCase() == _filter.toLowerCase()).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F14) : AppColors.cxSoftWhite,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [const Color(0xFF1A1A24), const Color(0xFF252532)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [AppColors.cxWhite, AppColors.cxF5F7F9],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.cxBlack).withOpacity(0.1),
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
                    colors: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
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
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: TextStyle(
                        color: Colors.white,
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
                  AppLocalizations.of(context).notifications,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  AppLocalizations.of(context).notificationsSubtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxSilverTint,
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
                color: isDark ? const Color(0xFF252532) : AppColors.cxF5F7F9,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF374151)
                      : AppColors.cxPlatinumGray.withOpacity(0.4),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).markAllRead,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFFD1D5DB) : AppColors.cxGraphiteGray,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(int unreadCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filters = ['All', 'Unread'];
    
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
                      ? (isDark
                          ? LinearGradient(
                              colors: [const Color(0xFF6366F1).withOpacity(0.2), const Color(0xFF4F46E5).withOpacity(0.2)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [AppColors.cxWhite, AppColors.cxF5F7F9],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ))
                      : null,
                  color: selected
                      ? null
                      : (isDark ? const Color(0xFF1A1A24) : AppColors.cxWhite),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: selected
                        ? (isDark ? const Color(0xFF6366F1) : AppColors.cxPlatinumGray.withOpacity(0.4))
                        : (isDark ? const Color(0xFF374151) : AppColors.cxPlatinumGray.withOpacity(0.3)),
                  ),
                  boxShadow: [
                    if (selected)
                      BoxShadow(
                        color: (isDark ? Colors.black : AppColors.cxBlack).withOpacity(0.1),
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
                        color: selected
                            ? (isDark ? const Color(0xFF6366F1) : AppColors.cxDarkCharcoal)
                            : (isDark ? const Color(0xFF9CA3AF) : AppColors.cxGraphiteGray),
                      ),
                    ),
                    if (showBadge) ...[
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          '$unreadCount',
                          style: TextStyle(
                            color: Colors.white,
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

  Widget _buildNotificationList(List<NotificationModel> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
        ),
      );
    }
    
    if (items.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A24) : AppColors.cxWhite,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.cxBlack).withOpacity(0.1),
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
            color: isDark
                ? const Color(0xFF252532)
                : AppColors.cxPlatinumGray.withOpacity(0.25),
          ),
          itemBuilder: (context, index) {
            final n = items[index];
            return InkWell(
              onTap: () => _markAsRead(n.id),
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
                                  n.title,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                n.timeAgo,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: isDark ? const Color(0xFF6B7280) : AppColors.cxSilverTint,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            n.body,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxGraphiteGray,
                              height: 1.35,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              _buildTag(n.type),
                              const Spacer(),
                              if (!n.isRead)
                                Container(
                                  width: 8.w,
                                  height: 8.w,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1),
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
                      color: isDark ? const Color(0xFF374151) : AppColors.cxPlatinumGray,
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

  Widget _buildLeadingIcon(NotificationModel n) {
    final Color from = n.colorFrom;
    final Color to = n.colorTo;
    final IconData icon = n.icon;

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
          child: Icon(icon, color: Colors.white, size: 18.sp),
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252532) : AppColors.cxF5F7F9,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark
              ? const Color(0xFF374151)
              : AppColors.cxPlatinumGray.withOpacity(0.35),
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxGraphiteGray,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : AppColors.cxWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.cxBlack).withOpacity(0.1),
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
                  gradient: isDark
                      ? LinearGradient(
                          colors: [const Color(0xFF1A1A24), const Color(0xFF252532)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [AppColors.cxWhite, AppColors.cxF5F7F9],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : AppColors.cxPlatinumGray.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.notifications_off_rounded,
                  color: isDark ? const Color(0xFF6B7280) : AppColors.cxPlatinumGray,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                AppLocalizations.of(context).noNotifications,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFFE8E8F0) : AppColors.cxDarkCharcoal,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                AppLocalizations.of(context).noNotSubTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? const Color(0xFF9CA3AF) : AppColors.cxGraphiteGray,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAllAsRead() async {
    await NotificationStorageService().markAllAsRead();
    await _loadNotifications();
  }

  Future<void> _markAsRead(String id) async {
    await NotificationStorageService().markAsRead(id);
    await _loadNotifications();
  }
}
