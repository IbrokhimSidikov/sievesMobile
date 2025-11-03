import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/services/auth/auth_service.dart';
import '../../../core/services/api/api_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final AuthManager _authManager = AuthManager(); // Use singleton instance
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0;
  
  final List<_ModuleItem> modules = [
    _ModuleItem("Profile", Icons.person_outline, AppColors.cxPrimary, '/profile'),
    _ModuleItem("Attendance", Icons.calendar_today_outlined, AppColors.cxSuccess, '/attendance'),
    _ModuleItem("Break Records", Icons.coffee_outlined, AppColors.cxWarning, '/breakRecords'),
    _ModuleItem("History", Icons.history_outlined, AppColors.cxBlue, '/history'),
    _ModuleItem("Achievements", Icons.emoji_events_outlined, AppColors.cxPurple, null),
  ];

  // Helper method to get user's display name
  String _getUserDisplayName() {
    final identity = _authManager.currentIdentity;
    
    if (identity != null) {
      // Try to get full name from employee individual data
      if (identity.employee?.individual != null) {
        final firstName = identity.employee!.individual!.firstName;
        final lastName = identity.employee!.individual!.lastName;
        if (firstName != null && lastName != null) {
          return '$firstName $lastName 👋';
        }
      }
      
      // Fallback to username or email
      return '${identity.username} 👋';
    }
    
    // Fallback if no user data available
    return 'Welcome 👋';
  }

  // Handle navigation to different modules
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
          content: Text('This feature is coming soon!'),
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
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
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
          'Dashboard',
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.sp),
            child: IconButton(
              onPressed: () {
                context.push(AppRoutes.notification);
              },
              icon: Icon(
                Icons.notifications_none,
                color: theme.colorScheme.onSurface,
              ),
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
            Text(
              "Dear,",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
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
    switch (title) {
      case "Profile":
        return "Personal information";
      case "Attendance":
        return "Work hours & tracking";
      case "Break Records":
        return "Meal history";
      case "History":
        return "Activity log";
      case "Achievements":
        return "Your rewards";
      default:
        return "Tap to explore";
    }
  }
}
