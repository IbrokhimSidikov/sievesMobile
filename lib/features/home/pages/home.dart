import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/theme/theme_cubit.dart';
import '../../../core/services/notification/notification_storage_service.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/model/story_model.dart';
import '../../stories/pages/story_viewer.dart';
import '../../stories/widgets/story_avatar.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final AuthManager _authManager = AuthManager();
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  int _unreadNotificationCount = 0;
  Timer? _refreshTimer;
  String? _currentEmployeeStatus;
  bool _isLoadingStatus = true;
  late final ApiService _apiService;
  List<UserStories> _userStories = [];
  bool _isLoadingStories = true;

  List<_ModuleItem> get modules {
    final localizations = AppLocalizations.of(context);
    final allModules = [
      _ModuleItem(localizations.profile, Icons.person_outline, AppColors.cxPrimary, '/profile'),
      _ModuleItem(localizations.attendance, Icons.calendar_today_outlined, AppColors.cxSuccess, '/attendance'),
      _ModuleItem(localizations.breakRecords, Icons.coffee_outlined, AppColors.cxWarning, '/breakRecords'),
      _ModuleItem(localizations.learning, Icons.laptop_mac_sharp, AppColors.cx4AC1A7, '/lmsPage'),
      _ModuleItem(localizations.calendar, Icons.calendar_month_outlined, const Color(0xFF8B5CF6), '/calendar'),
      _ModuleItem(localizations.history, Icons.history_outlined, AppColors.cxBlue, '/history'),
      _ModuleItem(localizations.lWallet, Icons.wallet_outlined, AppColors.cxPurple, '/wallet'),
      if (_authManager.hasBreakAccess)
        _ModuleItem(localizations.breakOrder, Icons.restaurant_menu_rounded, AppColors.cxFF9800, '/breakOrder'),
      if (_authManager.hasBreakAccess)
      _ModuleItem(localizations.faceVerification, Icons.face_2_outlined, const Color(0xFF64B6FF), '/faceVerification'),
      if (_authManager.hasStopwatchAccess)
        _ModuleItem(localizations.productivityTimer, Icons.timer_outlined, const Color(0xFFFF6B6B), '/productivityTimer'),
      _ModuleItem(localizations.checklist, Icons.checklist_outlined, const Color(0xFF4ECDC4), '/checklist'),

    ];
    return allModules;
  }

  // Helper method to get user's display name
  String _getUserDisplayName() {
    final identity = _authManager.currentIdentity;

    if (identity != null) {
      if (identity.employee?.individual != null) {
        final firstName = identity.employee!.individual!.firstName;
        final lastName = identity.employee!.individual!.lastName;
        if (firstName != null && lastName != null) {
          return '$firstName $lastName 👋';
        }
      }
      
      return '${identity.username} 👋';
    }
    
    return 'Welcome 👋';
  }

  void _navigateToModule(_ModuleItem module) {
    if (module.route != null) {
      context.push(module.route!);
    } else {
      _showComingSoon(module.title);
    }
  }

  // Show coming soon dialog for unimplemented modules
  void _showComingSoon(String moduleTitle) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$moduleTitle'),
          content: Text(AppLocalizations.of(context).comingSoon),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(_authManager.authService);
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    _loadUnreadCount();
    _loadCurrentStatus();
    _loadUserStories();
    
    // Refresh badge every 5 seconds when on home page
    _startPeriodicRefresh();
  }
  
  void _startPeriodicRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadUnreadCount();
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Refresh when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _loadUnreadCount();
      // Refresh employee status when returning to home
      _loadCurrentStatus();
    }
  }
  
  Future<void> _loadCurrentStatus() async {
    final employeeId = _authManager.currentEmployeeId;
    if (employeeId != null) {
      final status = await _apiService.getCurrentEmployeeStatus(employeeId);
      if (mounted) {
        setState(() {
          _currentEmployeeStatus = status;
          _isLoadingStatus = false;
        });
        print('🔄 [HOME] Status loaded from API: $status');
      }
    }
  }

  Future<void> _loadUserStories() async {
    try {
      final stories = await _apiService.getAdminStories();
      if (mounted) {
        setState(() {
          _userStories = stories;
          _isLoadingStories = false;
        });
        final totalStories = stories.fold<int>(0, (sum, userStory) => sum + userStory.stories.length);
        print('📖 [HOME] Admin stories loaded: $totalStories stories from ${stories.length} users');
      }
    } catch (e) {
      print('❌ [HOME] Error loading admin stories: $e');
      if (mounted) {
        setState(() {
          _isLoadingStories = false;
        });
      }
    }
  }

  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
  }

  Future<void> _loadUnreadCount() async {
    final count = await NotificationStorageService().getUnreadCount();
    if (mounted) {
      setState(() {
        _unreadNotificationCount = count;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          AppLocalizations.of(context).dashboard,
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          // Language dropdown
          Padding(
            padding: EdgeInsets.only(right: 8.sp),
            child: _buildLanguageDropdown(theme),
          ),
          // Theme toggle switch
          Padding(
            padding: EdgeInsets.only(right: 12.sp),
            child: GestureDetector(
              onTap: () {
                context.read<ThemeCubit>().toggleTheme();
              },
              child: Container(
                width: 56.w,
                height: 28.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                  gradient: LinearGradient(
                    colors: theme.brightness == Brightness.dark
                        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                        : [Colors.grey.shade300, Colors.grey.shade400],
                  ),
                ),
                child: Stack(
                  children: [
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      alignment: theme.brightness == Brightness.dark
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 24.w,
                        height: 24.h,
                        margin: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          theme.brightness == Brightness.dark
                              ? Icons.nightlight_round
                              : Icons.wb_sunny_rounded,
                          size: 14.sp,
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF6366F1)
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Notification button with badge
          Padding(
            padding: EdgeInsets.only(right: 16.sp),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: () async {
                    await context.push(AppRoutes.notificationNew);
                    // Reload unread count when returning from notifications page
                    _loadUnreadCount();
                  },
                  icon: Icon(
                    Icons.notifications_none,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 8.w,
                    top: 8.h,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: _unreadNotificationCount > 9 ? 5.w : 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        _unreadNotificationCount > 99 ? '99+' : '$_unreadNotificationCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 12.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Section
            // Text(
            //   AppLocalizations.of(context).dear,
            //   style: TextStyle(
            //     fontSize: 18.sp,
            //     fontWeight: FontWeight.w400,
            //     color: theme.colorScheme.onSurfaceVariant,
            //   ),
            // ),
            SizedBox(height: 4.sp),
            Row(
              children: [

                Padding(
                  padding: EdgeInsets.only(right: 22.w),
                  child: _buildUserAvatar(),
                ),
                Expanded(
                  child: Text(
                    _getUserDisplayName(),
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.sp),

            // Uniform Grid Layout
            Expanded(
              child: GridView.builder(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: 8.sp, bottom: 32.sp),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 12.sp,
                  mainAxisSpacing: 12.sp,
                ),
                itemCount: modules.length,
                itemBuilder: (context, index) {
                  return _PremiumCard(
                    module: modules[index],
                    onTap: () => _navigateToModule(modules[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    final identity = _authManager.currentIdentity;
    final userPhoto = identity?.employee?.individual?.photoUrl;
    final firstUserStories = _userStories.isNotEmpty ? _userStories.first : null;
    final hasStories = firstUserStories != null && firstUserStories.stories.isNotEmpty;
    final hasUnviewed = hasStories && firstUserStories.hasUnviewedStories;

    return GestureDetector(
      onTap: hasStories
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StoryViewer(
                    userStories: firstUserStories,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        width: 60.w,
        height: 60.h,
        padding: hasStories ? EdgeInsets.all(3.w) : null,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: hasStories && hasUnviewed
              ? const LinearGradient(
                  colors: [
                    Color(0xFFF58529),
                    Color(0xFFDD2A7B),
                    Color(0xFF8134AF),
                    Color(0xFF515BD4),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                )
              : null,
          border: hasStories && !hasUnviewed
              ? Border.all(
                  color: Colors.grey.shade400,
                  width: 2.w,
                )
              : null,
        ),
        child: Container(
          decoration: hasStories
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 3.w,
                  ),
                )
              : null,
          child: CircleAvatar(
            radius: hasStories ? (60 - 12).r : 30.r,
            backgroundImage: userPhoto != null
                ? NetworkImage(userPhoto)
                : null,
            backgroundColor: Colors.grey.shade300,
            child: userPhoto == null
                ? Icon(
                    Icons.person,
                    size: hasStories ? (60 - 20).sp : 30.sp,
                    color: Colors.grey.shade600,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme) {
    // Use real-time status from API, fallback to cached status if still loading
    final status = (_currentEmployeeStatus ?? _authManager.currentEmployeeStatus)?.toLowerCase() ?? 'offline';
    final isOnline = status == 'online';
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [AppColors.cxEmeraldGreen, AppColors.cxEmeraldGreen.withOpacity(0.8)]
              : [AppColors.cxSilverTint, AppColors.cxSilverTint.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? AppColors.cxEmeraldGreen : AppColors.cxSilverTint).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8.w,
            height: 8.h,
            decoration: const BoxDecoration(
              color: AppColors.cxPureWhite,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.cxPureWhite,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageDropdown(ThemeData theme) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLocale = localeProvider.locale.languageCode;

    // Language map with flags
    final languages = {
      'en': {'name': 'EN', 'flag': '🇬🇧'},
      'uz': {'name': 'UZ', 'flag': '🇺🇿'},
      'ru': {'name': 'RU', 'flag': '🇷🇺'},
    };

    return Container(
      height: 28.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.r),
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
              : [Colors.grey.shade300, Colors.grey.shade400],
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLocale,
          isDense: true,
          icon: Icon(
            Icons.arrow_drop_down,
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF6366F1)
                : Colors.grey.shade700,
            size: 18.sp,
          ),
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          dropdownColor: theme.cardColor,
          borderRadius: BorderRadius.circular(12.r),
          items: languages.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.value['flag']!,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    entry.value['name']!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              localeProvider.setLocale(Locale(newValue));
            }
          },
          selectedItemBuilder: (BuildContext context) {
            return languages.entries.map((entry) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.value['flag']!,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    entry.value['name']!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.brightness == Brightness.dark
                          ? Colors.white
                          : Colors.grey.shade800,
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }
}

// Module Item Model
class _ModuleItem {
  final String title;
  final IconData icon;
  final Color color;
  final String? route;

  _ModuleItem(this.title, this.icon, this.color, this.route);
}

// Premium Uniform Card Widget
class _PremiumCard extends StatefulWidget {
  final _ModuleItem module;
  final VoidCallback onTap;

  const _PremiumCard({
    required this.module,
    required this.onTap,
  });

  @override
  State<_PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<_PremiumCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Future.delayed(const Duration(milliseconds: 100), widget.onTap);
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      widget.module.color.withOpacity(0.25),
                      widget.module.color.withOpacity(0.12),
                    ]
                  : [
                      widget.module.color.withOpacity(0.9),
                      widget.module.color.withOpacity(0.75),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: isDark
                ? Border.all(
                    color: widget.module.color.withOpacity(0.25),
                    width: 1.5,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: widget.module.color.withOpacity(isDark ? 0.12 : 0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                  spreadRadius: -6,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Stack(
              children: [
                // Glassmorphism overlay
                if (isDark)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.04),
                            Colors.transparent,
                            Colors.black.withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                
                // Decorative circle
                Positioned(
                  top: -25,
                  right: -25,
                  child: Container(
                    width: 70.sp,
                    height: 70.sp,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? Colors.white.withOpacity(0.04)
                          : Colors.white.withOpacity(0.12),
                    ),
                  ),
                ),
                
                // Content
                Padding(
                  padding: EdgeInsets.all(16.sp),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon
                      Container(
                        width: 48.sp,
                        height: 48.sp,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          color: isDark
                              ? Colors.white.withOpacity(0.12)
                              : Colors.white.withOpacity(0.22),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.15)
                                : Colors.white.withOpacity(0.25),
                            width: 0.8,
                          ),
                        ),
                        child: Icon(
                          widget.module.icon,
                          size: 24.sp,
                          color: Colors.white,
                        ),
                      ),
                      
                      // Title
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.module.title,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : Colors.white,
                              letterSpacing: -0.3,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.sp),
                          Text(
                            _getSubtitle(widget.module.title),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withOpacity(0.65)
                                  : Colors.white.withOpacity(0.85),
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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

  String _getSubtitle(String title) {
    final localizations = AppLocalizations.of(context);
    if (title == localizations.profile) return localizations.profileSubtitle;
    if (title == localizations.attendance) return localizations.attendanceSubtitle;
    if (title == localizations.breakOrder) return localizations.breakOrderSubtitle;
    if (title == localizations.breakRecords) return localizations.breakRecordsSubtitle;
    if (title == localizations.history) return localizations.historySubtitle;
    if (title == localizations.lWallet) return localizations.lWalletSubtitle;
    if (title == localizations.learning) return localizations.learningSubtitle;
    if (title == localizations.testHistory) return localizations.testHistorySubtitle;
    if (title == localizations.productivityTimer) return localizations.productivityTimerSubtitle;
    if (title == localizations.checklist) return localizations.checklistSubtitle;
    if (title == localizations.faceVerification) return localizations.faceIdSubtitle;
    if (title == localizations.calendar) return localizations.calendarSubtitle;
    return "Tap to explore";
  }
}
