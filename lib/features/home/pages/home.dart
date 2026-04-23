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
      _ModuleItem(
        localizations.profile,
        Icons.person_outline,
        const Color(0xFF8D7B6B),
        '/profile',
      ),
      _ModuleItem(
        localizations.attendance,
        Icons.calendar_today_outlined,
        const Color(0xFF7A6A5A),
        '/attendance',
      ),
      _ModuleItem(
        localizations.breakRecords,
        Icons.coffee_outlined,
        const Color(0xFF9C8878),
        '/breakRecords',
      ),
      _ModuleItem(
        localizations.learning,
        Icons.laptop_mac_sharp,
        const Color(0xFF7B7060),
        '/lmsPage',
      ),
      _ModuleItem(
        localizations.hr,
        Icons.menu_book_outlined,
        const Color(0xFF8A7868),
        '/hrPage',
      ),
      _ModuleItem(
        localizations.history,
        Icons.history_outlined,
        const Color(0xFF6E6050),
        '/history',
      ),
      _ModuleItem(
        localizations.lWallet,
        Icons.wallet_outlined,
        const Color(0xFF957A6A),
        '/wallet',
      ),
      _ModuleItem(
        localizations.qualificationDisplayPage,
        Icons.verified_user_outlined,
        const Color(0xFF7C6C5C),
        '/qualificationDisplayPage',
      ),
      _ModuleItem(
        localizations.feedback,
        Icons.feedback_outlined,
        const Color(0xFF7C6C5C),
        '/feedbackForm',
      ),
      if (_authManager.hasBreakAccess)
        _ModuleItem(
          localizations.breakOrder,
          Icons.restaurant_menu_rounded,
          const Color(0xFF9E8272),
          '/breakOrder',
        ),
      if (_authManager.hasBreakAccess)
        _ModuleItem(
          localizations.faceVerification,
          Icons.face_2_outlined,
          const Color(0xFF856E5E),
          '/faceVerification',
        ),
      if (_authManager.hasStopwatchAccess)
        _ModuleItem(
          localizations.employeeProductivity,
          Icons.timer_outlined,
          const Color(0xFF7A6555),
          '/employeeProductivity',
        ),
      _ModuleItem(
        localizations.checklist,
        Icons.checklist_outlined,
        const Color(0xFF887060),
        '/checklist',
      ),
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
        final totalStories = stories.fold<int>(
          0,
          (sum, userStory) => sum + userStory.stories.length,
        );
        print(
          '📖 [HOME] Admin stories loaded: $totalStories stories from ${stories.length} users',
        );
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
    final count = await _apiService.getUnreadNotificationCount();
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
                        _unreadNotificationCount > 99
                            ? '99+'
                            : '$_unreadNotificationCount',
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
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 12.sp),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4.sp),
                  Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 16.w),
                        child: _buildUserAvatar(),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getUserDisplayName(),
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            _buildStatusBadge(theme),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24.sp),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.sp, 0, 20.sp, 40.sp),
            sliver: SliverToBoxAdapter(child: _buildBentoGrid(theme)),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(ThemeData theme) {
    final mods = modules;
    if (mods.isEmpty) return const SizedBox.shrink();

    final gap = 12.sp;

    // Helper to safely get module at index
    _ModuleItem? at(int i) => i < mods.length ? mods[i] : null;

    // Build rows progressively consuming the modules list
    final rows = <Widget>[];
    int i = 0;

    // ── Row 1: large (2/3) + two smalls stacked (1/3) ──
    if (i < mods.length) {
      final a = at(i++);
      final b = at(i++);
      final c = at(i++);
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (a != null)
                Expanded(
                  flex: 2,
                  child: _BentoCard(
                    module: a,
                    onTap: () => _navigateToModule(a),
                    size: _BentoSize.large,
                  ),
                ),
              if (b != null || c != null) SizedBox(width: gap),
              if (b != null || c != null)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      if (b != null)
                        Expanded(
                          child: _BentoCard(
                            module: b,
                            onTap: () => _navigateToModule(b),
                            size: _BentoSize.small,
                          ),
                        ),
                      if (b != null && c != null) SizedBox(height: gap),
                      if (c != null)
                        Expanded(
                          child: _BentoCard(
                            module: c,
                            onTap: () => _navigateToModule(c),
                            size: _BentoSize.small,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
      rows.add(SizedBox(height: gap));
    }

    // ── Row 2: two medium equal cards ──
    if (i < mods.length) {
      final a = at(i++);
      final b = at(i++);
      rows.add(
        Row(
          children: [
            if (a != null)
              Expanded(
                child: _BentoCard(
                  module: a,
                  onTap: () => _navigateToModule(a),
                  size: _BentoSize.medium,
                ),
              ),
            if (a != null && b != null) SizedBox(width: gap),
            if (b != null)
              Expanded(
                child: _BentoCard(
                  module: b,
                  onTap: () => _navigateToModule(b),
                  size: _BentoSize.medium,
                ),
              ),
          ],
        ),
      );
      rows.add(SizedBox(height: gap));
    }

    // ── Row 3: small (1/3) + large (2/3) — mirrored ──
    if (i < mods.length) {
      final a = at(i++);
      final b = at(i++);
      final c = at(i++);
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (a != null || b != null)
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      if (a != null)
                        Expanded(
                          child: _BentoCard(
                            module: a,
                            onTap: () => _navigateToModule(a),
                            size: _BentoSize.small,
                          ),
                        ),
                      if (a != null && b != null) SizedBox(height: gap),
                      if (b != null)
                        Expanded(
                          child: _BentoCard(
                            module: b,
                            onTap: () => _navigateToModule(b),
                            size: _BentoSize.small,
                          ),
                        ),
                    ],
                  ),
                ),
              if (c != null) SizedBox(width: gap),
              if (c != null)
                Expanded(
                  flex: 2,
                  child: _BentoCard(
                    module: c,
                    onTap: () => _navigateToModule(c),
                    size: _BentoSize.large,
                  ),
                ),
            ],
          ),
        ),
      );
      rows.add(SizedBox(height: gap));
    }

    // ── Remaining: full-width wide cards ──
    while (i < mods.length) {
      final a = at(i++);
      final b = at(i++);
      if (a != null || b != null) {
        rows.add(
          Row(
            children: [
              if (a != null)
                Expanded(
                  child: _BentoCard(
                    module: a,
                    onTap: () => _navigateToModule(a),
                    size: _BentoSize.wide,
                  ),
                ),
              if (a != null && b != null) SizedBox(width: gap),
              if (b != null)
                Expanded(
                  child: _BentoCard(
                    module: b,
                    onTap: () => _navigateToModule(b),
                    size: _BentoSize.wide,
                  ),
                ),
            ],
          ),
        );
        rows.add(SizedBox(height: gap));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildUserAvatar() {
    final identity = _authManager.currentIdentity;
    final userPhoto = identity?.employee?.individual?.photoUrl;
    final firstUserStories = _userStories.isNotEmpty
        ? _userStories.first
        : null;
    final hasStories =
        firstUserStories != null && firstUserStories.stories.isNotEmpty;
    final hasUnviewed = hasStories && firstUserStories.hasUnviewedStories;

    return GestureDetector(
      onTap: hasStories
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      StoryViewer(userStories: firstUserStories),
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
              ? Border.all(color: Colors.grey.shade400, width: 2.w)
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
            backgroundImage: userPhoto != null ? NetworkImage(userPhoto) : null,
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
    final status =
        (_currentEmployeeStatus ?? _authManager.currentEmployeeStatus)
            ?.toLowerCase() ??
        'offline';
    final isOnline = status == 'online';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [
                  AppColors.cxEmeraldGreen,
                  AppColors.cxEmeraldGreen.withOpacity(0.8),
                ]
              : [
                  AppColors.cxSilverTint,
                  AppColors.cxSilverTint.withOpacity(0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color:
                (isOnline ? AppColors.cxEmeraldGreen : AppColors.cxSilverTint)
                    .withOpacity(0.3),
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
                  Text(entry.value['flag']!, style: TextStyle(fontSize: 14.sp)),
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
                  Text(entry.value['flag']!, style: TextStyle(fontSize: 14.sp)),
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

// Bento card size variants
enum _BentoSize { large, medium, small, wide }

// ────────────────────────────────────────────
//  Bento Card
// ────────────────────────────────────────────
class _BentoCard extends StatefulWidget {
  final _ModuleItem module;
  final VoidCallback onTap;
  final _BentoSize size;

  const _BentoCard({
    required this.module,
    required this.onTap,
    required this.size,
  });

  @override
  State<_BentoCard> createState() => _BentoCardState();
}

class _BentoCardState extends State<_BentoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Height per size variant
  double get _height {
    switch (widget.size) {
      case _BentoSize.large:
        return 180.sp;
      case _BentoSize.medium:
        return 130.sp;
      case _BentoSize.small:
        return 84.sp;
      case _BentoSize.wide:
        return 110.sp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = widget.module.color;
    final isLarge = widget.size == _BentoSize.large;
    final isSmall = widget.size == _BentoSize.small;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        Future.delayed(const Duration(milliseconds: 100), widget.onTap);
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22.r),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2F2F2F), const Color(0xFF1A1A1A)]
                  : [color.withOpacity(0.18), color.withOpacity(0.10)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFFFCB74).withOpacity(0.55)
                  : color.withOpacity(0.18),
              width: isDark ? 1.6 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0xFFFFCB74).withOpacity(0.10)
                    : color.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.40 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: Stack(
              children: [
                // ── Background decorative circles ──
                Positioned(
                  top: -28.sp,
                  right: -28.sp,
                  child: Container(
                    width: isLarge ? 110.sp : 70.sp,
                    height: isLarge ? 110.sp : 70.sp,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFFFFCB74).withOpacity(0.08)
                          : color.withOpacity(0.07),
                    ),
                  ),
                ),
                if (!isSmall)
                  Positioned(
                    bottom: -20.sp,
                    left: -20.sp,
                    child: Container(
                      width: isLarge ? 80.sp : 50.sp,
                      height: isLarge ? 80.sp : 50.sp,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFFF6F6F6).withOpacity(0.04)
                            : color.withOpacity(0.05),
                      ),
                    ),
                  ),

                // ── Content ──
                Padding(
                  padding: EdgeInsets.all(isSmall ? 10.sp : 16.sp),
                  child: isSmall
                      ? _buildSmallContent(isDark, color)
                      : _buildFullContent(isDark, color, isLarge),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Small card: icon + title side by side
  Widget _buildSmallContent(bool isDark, Color color) {
    final iconColor = isDark ? const Color(0xFFF6F6F6) : _darken(color, 0.25);
    final textColor = isDark ? const Color(0xFFF6F6F6) : _darken(color, 0.30);
    return Row(
      children: [
        Container(
          width: 34.sp,
          height: 34.sp,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.r),
            color: isDark
                ? Colors.white.withOpacity(0.14)
                : color.withOpacity(0.14),
          ),
          child: Icon(widget.module.icon, size: 18.sp, color: iconColor),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            widget.module.title,
            style: TextStyle(
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
              color: textColor,
              height: 1.25,
              letterSpacing: -0.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Large / medium / wide card: full layout with icon top, title bottom
  Widget _buildFullContent(bool isDark, Color color, bool isLarge) {
    final iconColor = isDark ? const Color(0xFFF6F6F6) : _darken(color, 0.25);
    final titleColor = isDark ? const Color(0xFFF6F6F6) : _darken(color, 0.35);
    final subtitleColor = isDark
        ? const Color(0xFFF6F6F6).withOpacity(0.60)
        : _darken(color, 0.20).withOpacity(0.75);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Icon box
        Container(
          width: isLarge ? 52.sp : 44.sp,
          height: isLarge ? 52.sp : 44.sp,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isLarge ? 16.r : 13.r),
            color: isDark
                ? const Color(0xFFFFCB74).withOpacity(0.15)
                : color.withOpacity(0.14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFFFCB74).withOpacity(0.35)
                  : color.withOpacity(0.22),
              width: 0.8,
            ),
          ),
          child: Icon(
            widget.module.icon,
            size: isLarge ? 26.sp : 22.sp,
            color: iconColor,
          ),
        ),

        // Title + subtitle
        Flexible(
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.module.title,
              style: TextStyle(
                fontSize: isLarge ? 18.sp : 14.sp,
                fontWeight: FontWeight.w700,
                color: titleColor,
                letterSpacing: -0.3,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isLarge) ...[
              SizedBox(height: 4.h),
              Text(
                _getSubtitle(widget.module.title, context),
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
         ),
        ),
      ],
    );
  }

  Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  String _getSubtitle(String title, BuildContext context) {
    final l = AppLocalizations.of(context);
    if (title == l.profile) return l.profileSubtitle;
    if (title == l.attendance) return l.attendanceSubtitle;
    if (title == l.breakOrder) return l.breakOrderSubtitle;
    if (title == l.breakRecords) return l.breakRecordsSubtitle;
    if (title == l.history) return l.historySubtitle;
    if (title == l.lWallet) return l.lWalletSubtitle;
    if (title == l.learning) return l.learningSubtitle;
    if (title == l.productivityTimer) return l.productivityTimerSubtitle;
    if (title == l.checklist) return l.checklistSubtitle;
    if (title == l.faceVerification) return l.faceIdSubtitle;
    if (title == l.calendar) return l.calendarSubtitle;
    return 'Tap to explore';
  }
}
