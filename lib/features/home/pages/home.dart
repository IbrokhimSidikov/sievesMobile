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

  List<_ModuleItem> get modules {
    final localizations = AppLocalizations.of(context);
    return [
      _ModuleItem(localizations.profile, Icons.person_outline, AppColors.cxPrimary, '/profile'),
      _ModuleItem(localizations.attendance, Icons.calendar_today_outlined, AppColors.cxSuccess, '/attendance'),
      _ModuleItem(localizations.breakRecords, Icons.coffee_outlined, AppColors.cxWarning, '/breakRecords'),
      _ModuleItem(localizations.learning, Icons.laptop_mac_sharp, AppColors.cx4AC1A7, null),
      _ModuleItem(localizations.history, Icons.history_outlined, AppColors.cxBlue, '/history'),
      _ModuleItem(localizations.lWallet, Icons.wallet_outlined, AppColors.cxPurple, null),

    ];
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
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addObserver(this);
    _loadUnreadCount();
    
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
            Text(
              _getUserDisplayName(),
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),

            SizedBox(height: 24.sp),

            // Apple-Style Tiles
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.only(top: 8.sp, bottom: 32.sp),
                itemCount: modules.length,
                itemBuilder: (context, index) {
                  // Calculate parallax effect
                  final itemPosition = index * 120.h;
                  final difference = _scrollOffset - itemPosition;
                  final parallaxOffset = difference * 0.15;
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.sp),
                    child: Transform.translate(
                      offset: Offset(0, -parallaxOffset),
                      child: _AppleTile(
                        module: modules[index],
                        index: index,
                        onTap: () => _navigateToModule(modules[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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

// Apple-Style Tile Widget
class _AppleTile extends StatefulWidget {
  final _ModuleItem module;
  final int index;
  final VoidCallback onTap;

  const _AppleTile({
    required this.module,
    required this.index,
    required this.onTap,
  });

  @override
  State<_AppleTile> createState() => _AppleTileState();
}

class _AppleTileState extends State<_AppleTile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
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
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        Future.delayed(Duration(milliseconds: 100), widget.onTap);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Hero(
          tag: 'module_${widget.index}',
          child: Container(
            height: 110.h,
            margin: EdgeInsets.symmetric(horizontal: 4.sp),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.r),
              gradient: LinearGradient(
                colors: [
                  widget.module.color.withOpacity(0.92),
                  widget.module.color.withOpacity(0.88),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.module.color.withOpacity(0.25),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                  spreadRadius: -3,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: Offset(0, 12),
                  spreadRadius: -6,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Subtle background pattern
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.r),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.08),
                          Colors.transparent,
                          Colors.black.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                
                // Decorative corner element
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 80.sp,
                    height: 80.sp,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                
                // Content
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 16.sp),
                  child: Row(
                    children: [
                      // Icon with Apple-style minimal background
                      Container(
                        width: 56.sp,
                        height: 56.sp,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.r),
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          widget.module.icon,
                          size: 30.sp,
                          color: Colors.white,
                        ),
                      ),
                      
                      SizedBox(width: 16.sp),
                      
                      // Text content - Apple-style typography
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.module.title,
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                            ),
                            SizedBox(height: 4.sp),
                            Text(
                              _getSubtitle(widget.module.title),
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withOpacity(0.85),
                                letterSpacing: -0.1,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Chevron indicator
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white.withOpacity(0.6),
                        size: 24.sp,
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
    
    // Match against translated titles
    if (title == localizations.profile) {
      return localizations.profileSubtitle;
    } else if (title == localizations.attendance) {
      return localizations.attendanceSubtitle;
    } else if (title == localizations.breakRecords) {
      return localizations.breakRecordsSubtitle;
    } else if (title == localizations.history) {
      return localizations.historySubtitle;
    } else if (title == localizations.lWallet) {
      return localizations.lWalletSubtitle;
    } else if (title == localizations.learning) {
      return localizations.learningSubtitle;
    } else {
      return "Tap to explore";
    }
  }
}
