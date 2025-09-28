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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cxSoftWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 26.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.cxBlack,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.sp),
            child: IconButton(
              onPressed: () {
                context.push(AppRoutes.notification);
              }, icon: Icon(Icons.notifications_none),
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
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4.sp),
            Text(
              _getUserDisplayName(),
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.cxBlack,
              ),
            ),

            SizedBox(height: 24.sp),

            // Grid of Modules
            Expanded(
              child: GridView.builder(
                itemCount: modules.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 20.sp,
                  crossAxisSpacing: 20.sp,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final module = modules[index];
                  return _DashboardCard(
                    module: module,
                    onTap: () => _navigateToModule(module),
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

// Dashboard Card Widget
class _DashboardCard extends StatelessWidget {
  final _ModuleItem module;
  final VoidCallback onTap;

  const _DashboardCard({required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.r),
          gradient: LinearGradient(
            colors: [module.color.withOpacity(0.9), module.color.withOpacity(0.6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: module.color.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(4, 6),
            )
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(module.icon, size: 40.sp, color: AppColors.cxWhite),
              SizedBox(height: 12.sp),
              Text(
                module.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.cxWhite,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
