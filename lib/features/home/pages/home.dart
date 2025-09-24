import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final List<_ModuleItem> modules = [
    _ModuleItem("Profile", Icons.person_outline, AppColors.cxPrimary),
    _ModuleItem("Attendance", Icons.calendar_today_outlined, AppColors.cxSuccess),
    _ModuleItem("Break Records", Icons.coffee_outlined, AppColors.cxWarning),
    _ModuleItem("History", Icons.history_outlined, AppColors.cxBlue),
    _ModuleItem("Achievements", Icons.emoji_events_outlined, AppColors.cxPurple),
  ];

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
            child: Icon(
              Icons.notifications_none,
              color: AppColors.cxBlack,
              size: 28.sp,
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
              "Ibrokhim Sidikov 👋",
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
                  return _DashboardCard(module: module);
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

  _ModuleItem(this.title, this.icon, this.color);
}

// Dashboard Card Widget
class _DashboardCard extends StatelessWidget {
  final _ModuleItem module;

  const _DashboardCard({required this.module});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to respective module
      },
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
