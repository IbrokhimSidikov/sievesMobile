import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../cubit/checklist_cubit.dart';
import 'checklist_detail_page.dart';

class ChecklistListPage extends StatelessWidget {
  const ChecklistListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fakeChecklists = [
      {
        'id': 1,
        'title': 'Opening Shift Checklist',
        'description': 'Complete all tasks before opening the store',
        'dueDate': DateTime.now().add(const Duration(hours: 2)),
        'sections': 4,
        'completedSections': 0,
        'icon': Icons.store_rounded,
        'color': const Color(0xFF4ECDC4),
      },
      {
        'id': 2,
        'title': 'Closing Shift Checklist',
        'description': 'Ensure all closing procedures are followed',
        'dueDate': DateTime.now().add(const Duration(hours: 8)),
        'sections': 5,
        'completedSections': 2,
        'icon': Icons.lock_clock_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'id': 3,
        'title': 'Weekly Inventory Check',
        'description': 'Verify stock levels and report discrepancies',
        'dueDate': DateTime.now().add(const Duration(days: 2)),
        'sections': 3,
        'completedSections': 3,
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'id': 4,
        'title': 'Safety Inspection',
        'description': 'Monthly safety and compliance check',
        'dueDate': DateTime.now().add(const Duration(days: 7)),
        'sections': 6,
        'completedSections': 0,
        'icon': Icons.security_rounded,
        'color': const Color(0xFFEF4444),
      },
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Checklists',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        itemCount: fakeChecklists.length,
        itemBuilder: (context, index) {
          final checklist = fakeChecklists[index];
          return _buildChecklistCard(
            context,
            checklist,
            theme,
            isDark,
          );
        },
      ),
    );
  }

  Widget _buildChecklistCard(
    BuildContext context,
    Map<String, dynamic> checklist,
    ThemeData theme,
    bool isDark,
  ) {
    final progress = checklist['completedSections'] / checklist['sections'];
    final isCompleted = progress == 1.0;
    final color = checklist['color'] as Color;
    final dueDate = checklist['dueDate'] as DateTime;
    final now = DateTime.now();
    final hoursUntilDue = dueDate.difference(now).inHours;
    final isUrgent = hoursUntilDue < 4 && !isCompleted;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => ChecklistCubit(),
              child: ChecklistDetailPage(
                checklistId: checklist['id'] as int,
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A1A24), const Color(0xFF252532)]
                : [const Color(0xFFFFFFFF), const Color(0xFFF5F5F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: isUrgent
                ? const Color(0xFFEF4444).withOpacity(0.5)
                : color.withOpacity(0.3),
            width: isUrgent ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    checklist['icon'] as IconData,
                    color: Colors.white,
                    size: 26.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checklist['title'] as String,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        checklist['description'] as String,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: const Color(0xFF4ECDC4),
                      size: 24.sp,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16.sp,
                  color: isUrgent
                      ? const Color(0xFFEF4444)
                      : theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Text(
                  isUrgent
                      ? 'Due in $hoursUntilDue hours'
                      : hoursUntilDue < 24
                          ? 'Due in $hoursUntilDue hours'
                          : 'Due in ${(hoursUntilDue / 24).round()} days',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: isUrgent ? FontWeight.w600 : FontWeight.w500,
                    color: isUrgent
                        ? const Color(0xFFEF4444)
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.list_alt_rounded,
                  size: 16.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Text(
                  '${checklist['sections']} sections',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${checklist['completedSections']}/${checklist['sections']}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6.h,
                    backgroundColor: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E5EA),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
