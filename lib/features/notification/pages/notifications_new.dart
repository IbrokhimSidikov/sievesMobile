import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/model/notification_model.dart';
import '../../../core/services/auth/auth_manager.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isMarkingAll = false;
  String _filter = 'All';

  final _api = AuthManager().apiService;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final raw = await _api.getMyNotifications();
      final notifications = raw
          .map((json) => NotificationModel.fromApiJson(json))
          .toList();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll) return;
    final hasUnread = _notifications.any((n) => !n.isRead);
    if (!hasUnread) return;

    setState(() => _isMarkingAll = true);
    try {
      await _api.markAllNotificationsAsRead();
      if (mounted) {
        setState(() {
          _notifications = _notifications
              .map((n) => n.isRead
                  ? n
                  : n.copyWith(isRead: true, readAt: DateTime.now()))
              .toList();
          _isMarkingAll = false;
        });
        // ScaffoldMessenger.of(context).showSnackBar(
        //   SnackBar(
        //     content: Row(
        //       children: [
        //         const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
        //         SizedBox(width: 10.w),
        //         Text(
        //           AppLocalizations.of(context).markAllRead,
        //           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        //         ),
        //       ],
        //     ),
        //     backgroundColor: const Color(0xFF6366F1),
        //     behavior: SnackBarBehavior.floating,
        //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        //     duration: const Duration(seconds: 2),
        //   ),
        // );
      }
    } catch (e) {
      if (mounted) setState(() => _isMarkingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    final filtered = _filter == 'All'
        ? _notifications
        : _notifications.where((n) => !n.isRead).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF2F4F8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark, unreadCount),
            _buildFilters(isDark, unreadCount),
            Expanded(
              child: _isLoading
                  ? _buildShimmer(isDark)
                  : _buildNotificationList(isDark, filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, int unreadCount) {
    return Container(
      padding: EdgeInsets.fromLTRB(30.w, 20.h, 20.w, 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF12121A) : AppColors.cxWhite,
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.notifications_rounded,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -4.w,
                  top: -4.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isDark ? const Color(0xFF12121A) : AppColors.cxWhite,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).notifications,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFF0F0F8) : AppColors.cxDarkCharcoal,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  unreadCount > 0
                      ? '$unreadCount unread message${unreadCount == 1 ? '' : 's'}'
                      : AppLocalizations.of(context).notificationsSubtitle,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: unreadCount > 0
                        ? const Color(0xFF6366F1)
                        : (isDark ? const Color(0xFF6B7280) : AppColors.cxSilverTint),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          _buildMarkAllButton(isDark, unreadCount),
        ],
      ),
    );
  }

  Widget _buildMarkAllButton(bool isDark, int unreadCount) {
    final bool canMark = unreadCount > 0 && !_isMarkingAll;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: canMark
            ? const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: canMark
            ? null
            : (isDark ? const Color(0xFF1E1E2A) : const Color(0xFFF0F0F5)),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: canMark
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canMark ? _markAllAsRead : null,
          borderRadius: BorderRadius.circular(22.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
            child: _isMarkingAll
                ? SizedBox(
                    width: 14.w,
                    height: 14.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: canMark
                          ? Colors.white
                          : (isDark ? const Color(0xFF6366F1) : AppColors.cxRoyalBlue),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.done_all_rounded,
                        size: 13.sp,
                        color: canMark
                            ? Colors.white
                            : (isDark
                                ? const Color(0xFF4B5563)
                                : AppColors.cxSilverTint),
                      ),
                      SizedBox(width: 5.w),
                      Text(
                        AppLocalizations.of(context).markAllRead,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: canMark
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFF4B5563)
                                  : AppColors.cxSilverTint),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(bool isDark, int unreadCount) {
    final filters = ['All', 'Unread'];

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF2F4F8),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final bool selected = _filter == f;
            final bool showBadge = f == 'Unread' && unreadCount > 0;
            return Padding(
              padding: EdgeInsets.only(right: 10.w),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: selected
                        ? null
                        : (isDark ? const Color(0xFF12121A) : AppColors.cxWhite),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: selected
                          ? Colors.transparent
                          : (isDark ? const Color(0xFF1E1E2A) : const Color(0xFFE8E8EE)),
                      width: 1,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: (isDark ? Colors.black : Colors.black).withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        f,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: selected
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFF9CA3AF)
                                  : const Color(0xFF52526A)),
                        ),
                      ),
                      if (showBadge) ...[
                        SizedBox(width: 7.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white.withOpacity(0.3)
                                : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '$unreadCount',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
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
      ),
    );
  }

  Widget _buildShimmer(bool isDark) {
    final baseColor = isDark ? const Color(0xFF1E1E2A) : const Color(0xFFE8E8EE);
    final highlightColor = isDark ? const Color(0xFF2A2A3A) : const Color(0xFFF5F5FA);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
        itemCount: 7,
        itemBuilder: (context, index) {
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2A) : AppColors.cxWhite,
              borderRadius: BorderRadius.circular(18.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46.w,
                  height: 46.w,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              height: 14.h,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(7.r),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            width: 40.w,
                            height: 11.h,
                            decoration: BoxDecoration(
                              color: baseColor,
                              borderRadius: BorderRadius.circular(5.r),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 11.h,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                      ),
                      SizedBox(height: 5.h),
                      Container(
                        height: 11.h,
                        width: 160.w,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Container(
                        height: 22.h,
                        width: 70.w,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(11.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationList(bool isDark, List<NotificationModel> items) {
    if (items.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFF6366F1),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final n = items[index];
          return _buildNotificationCard(isDark, n, index);
        },
      ),
    );
  }

  Widget _buildNotificationCard(bool isDark, NotificationModel n, int index) {
    final Color from = n.colorFrom;
    final Color to = n.colorTo;
    final bool isUnread = !n.isRead;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? (isUnread ? const Color(0xFF17172A) : const Color(0xFF12121A))
            : (isUnread ? const Color(0xFFFAFAFF) : AppColors.cxWhite),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isUnread
              ? from.withOpacity(isDark ? 0.35 : 0.2)
              : (isDark
                  ? const Color(0xFF1E1E2A)
                  : const Color(0xFFEEEEF4)),
          width: isUnread ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnread
                ? from.withOpacity(isDark ? 0.12 : 0.07)
                : (isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04)),
            blurRadius: isUnread ? 14 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLeadingIcon(from, to, n.icon, isUnread, isDark),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          n.title,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                            color: isDark
                                ? (isUnread ? const Color(0xFFF0F0F8) : const Color(0xFFB0B0C0))
                                : (isUnread ? AppColors.cxDarkCharcoal : const Color(0xFF4A4A5A)),
                            height: 1.3,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            n.timeAgo,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: isDark
                                  ? const Color(0xFF4B5563)
                                  : AppColors.cxSilverTint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isUnread) ...[  
                            SizedBox(height: 4.h),
                            Container(
                              width: 7.w,
                              height: 7.w,
                              decoration: BoxDecoration(
                                color: from,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: from.withOpacity(0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    n.body,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark
                          ? (isUnread ? const Color(0xFF9CA3AF) : const Color(0xFF4B5563))
                          : (isUnread ? const Color(0xFF52526A) : AppColors.cxSilverTint),
                      height: 1.45,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      _buildTag(from, to, n.type, isDark),
                      const Spacer(),
                      if (n.isRead && n.readAt != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.done_all_rounded,
                              size: 12.sp,
                              color: isDark
                                  ? const Color(0xFF374151)
                                  : AppColors.cxPlatinumGray,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              _formatReadAt(n.readAt!),
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: isDark
                                    ? const Color(0xFF374151)
                                    : AppColors.cxPlatinumGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon(
    Color from,
    Color to,
    IconData icon,
    bool isUnread,
    bool isDark,
  ) {
    return Container(
      width: 46.w,
      height: 46.w,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [from, to],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13.r),
        boxShadow: isUnread
            ? [
                BoxShadow(
                  color: from.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: Colors.white, size: 20.sp),
    );
  }

  Widget _buildTag(Color from, Color to, String text, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [from.withOpacity(isDark ? 0.18 : 0.1), to.withOpacity(isDark ? 0.12 : 0.07)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: from.withOpacity(isDark ? 0.3 : 0.2),
          width: 0.8,
        ),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: isDark ? from.withOpacity(0.85) : from,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1E2A), const Color(0xFF252535)]
                      : [const Color(0xFFF0F0F8), const Color(0xFFE8E8F2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE0E0EA),
                ),
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                color: isDark ? const Color(0xFF3A3A4A) : const Color(0xFFCCCCDD),
                size: 36.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              AppLocalizations.of(context).noNotifications,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFD0D0E0) : AppColors.cxDarkCharcoal,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              AppLocalizations.of(context).noNotSubTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: isDark ? const Color(0xFF4B5563) : AppColors.cxSilverTint,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatReadAt(DateTime readAt) {
    final now = DateTime.now();
    final isToday = readAt.year == now.year &&
        readAt.month == now.month &&
        readAt.day == now.day;
    final h = readAt.hour.toString().padLeft(2, '0');
    final m = readAt.minute.toString().padLeft(2, '0');
    if (isToday) return '$h:$m';
    return '${readAt.day}/${readAt.month}';
  }
}
