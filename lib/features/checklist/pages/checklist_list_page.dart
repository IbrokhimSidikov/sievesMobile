import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../cubit/checklist_cubit.dart';
import '../cubit/checklist_list_cubit.dart';
import '../cubit/checklist_list_state.dart';
import '../models/checklist_model.dart';
import 'checklist_detail_page.dart';

class ChecklistListPage extends StatefulWidget {
  const ChecklistListPage({super.key});

  @override
  State<ChecklistListPage> createState() => _ChecklistListPageState();
}

class _ChecklistListPageState extends State<ChecklistListPage> {
  @override
  void initState() {
    super.initState();
    context.read<ChecklistListCubit>().loadChecklists();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
      body: BlocBuilder<ChecklistListCubit, ChecklistListState>(
        builder: (context, state) {
          if (state is ChecklistListLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF4ECDC4),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Loading checklists...',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ChecklistListError) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(32.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 64.sp,
                      color: const Color(0xFFEF4444),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Error',
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 24.h),
                    ElevatedButton(
                      onPressed: () {
                        context.read<ChecklistListCubit>().loadChecklists();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ECDC4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ChecklistListLoaded) {
            if (state.checklists.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.checklist_rounded,
                      size: 64.sp,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No checklists found',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'There are no checklists for your branch',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              itemCount: state.checklists.length,
              itemBuilder: (context, index) {
                final checklist = state.checklists[index];
                return _buildChecklistCard(
                  context,
                  checklist,
                  theme,
                  isDark,
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  IconData _getIconForChecklist(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('opening') || lowerName.contains('daily')) {
      return Icons.store_rounded;
    } else if (lowerName.contains('closing')) {
      return Icons.lock_clock_rounded;
    } else if (lowerName.contains('inventory')) {
      return Icons.inventory_2_rounded;
    } else if (lowerName.contains('safety') || lowerName.contains('security')) {
      return Icons.security_rounded;
    } else if (lowerName.contains('clean')) {
      return Icons.cleaning_services_rounded;
    }
    return Icons.checklist_rounded;
  }

  Color _getColorForChecklist(int index) {
    final colors = [
      const Color(0xFF4ECDC4),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEF4444),
      const Color(0xFF10B981),
      const Color(0xFF3B82F6),
    ];
    return colors[index % colors.length];
  }

  Widget _buildChecklistCard(
    BuildContext context,
    Checklist checklist,
    ThemeData theme,
    bool isDark,
  ) {
    final itemCount = checklist.items.length;
    final color = _getColorForChecklist(checklist.id);
    final icon = _getIconForChecklist(checklist.name);

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BlocProvider(
              create: (context) => ChecklistCubit(),
              child: ChecklistDetailPage(
                checklistId: checklist.id,
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
            color: color.withOpacity(0.3),
            width: 1.5,
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
                    icon,
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
                        checklist.name,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        checklist.description ?? 'No description',
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
                if (checklist.isActive)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4ECDC4),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Icon(
                  Icons.business_rounded,
                  size: 16.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Text(
                  checklist.branch.name,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurfaceVariant,
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
                  '$itemCount items',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 16.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: 6.w),
                Text(
                  'Role: ${checklist.role}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurfaceVariant,
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
