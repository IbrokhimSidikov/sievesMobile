import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../cubit/task_list_cubit.dart';
import '../cubit/task_list_state.dart';
import '../models/task_model.dart';

class TaskManagementPage extends StatelessWidget {
  const TaskManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskListCubit(AuthManager())..loadMyTasks(),
      child: const _TaskManagementView(),
    );
  }
}

class _TaskManagementView extends StatefulWidget {
  const _TaskManagementView();

  @override
  State<_TaskManagementView> createState() => _TaskManagementViewState();
}

class _TaskManagementViewState extends State<_TaskManagementView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<TaskStatus> _tabStatuses = [
    TaskStatus.todo,
    TaskStatus.inProgress,
    TaskStatus.review,
    TaskStatus.done,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabStatuses.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(
          l.tasks,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l.createTask,
            icon: Icon(Icons.add, color: theme.colorScheme.onSurface),
            onPressed: () async {
              final created = await context.push<bool>('/taskCreate');
              if (created == true && context.mounted) {
                context.read<TaskListCubit>().loadMyTasks();
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onSurface),
            onPressed: () => context.read<TaskListCubit>().loadMyTasks(),
          ),
        ],
      ),
      body: BlocBuilder<TaskListCubit, TaskListState>(
        builder: (context, state) {
          if (state is TaskListLoading || state is TaskListInitial) {
            return const _TaskListSkeleton();
          }
          if (state is TaskListError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<TaskListCubit>().loadMyTasks(),
            );
          }
          if (state is TaskListLoaded) {
            return Column(
              children: [
                _buildTabBar(theme, state),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabStatuses.map((status) {
                      final tasks = state.grouped[status] ?? const [];
                      return RefreshIndicator(
                        onRefresh: () =>
                            context.read<TaskListCubit>().loadMyTasks(),
                        child: tasks.isEmpty
                            ? _EmptyView(status: status)
                            : ListView.separated(
                                padding: EdgeInsets.fromLTRB(
                                  16.w,
                                  12.h,
                                  16.w,
                                  24.h,
                                ),
                                itemCount: tasks.length,
                                separatorBuilder: (_, __) =>
                                    SizedBox(height: 10.h),
                                itemBuilder: (_, i) =>
                                    _TaskCard(task: tasks[i]),
                              ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, TaskListLoaded state) {
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.4),
            width: 0.5,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: theme.colorScheme.onSurface,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.55),
        indicatorColor: const Color(0xFF6366F1),
        indicatorWeight: 2.5,
        labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        tabs: _tabStatuses.map((status) {
          final count = state.grouped[status]?.length ?? 0;
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(status.displayLabel),
                SizedBox(width: 6.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6.w,
                    vertical: 1.h,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final priorityColor = _priorityColor(task.priority);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () async {
          await context.push('/taskDetail/${task.id}');
          if (context.mounted) {
            context.read<TaskListCubit>().loadMyTasks();
          }
        },
        child: Container(
          padding: EdgeInsets.all(14.sp),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.dividerColor.withOpacity(0.4),
              width: 0.7,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4.w,
                    height: 36.h,
                    margin: EdgeInsets.only(right: 10.w, top: 2.h),
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _StatusPill(status: task.status),
                ],
              ),
              if (task.description != null && task.description!.isNotEmpty) ...[
                SizedBox(height: 6.h),
                Padding(
                  padding: EdgeInsets.only(left: 14.w),
                  child: Text(
                    task.description!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.65),
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.only(left: 14.w),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 6.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MetaChip(
                      icon: Icons.flag_outlined,
                      label: task.priority.displayLabel,
                      color: priorityColor,
                    ),
                    if (task.list != null)
                      _MetaChip(
                        icon: Icons.folder_outlined,
                        label: task.list!.name,
                        color: const Color(0xFF6366F1),
                      ),
                    if (task.dueDate != null)
                      _MetaChip(
                        icon: Icons.event_outlined,
                        label: _formatDate(task.dueDate!),
                        color: _isOverdue(task)
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF0EA5E9),
                      ),
                    if (task.commentCount > 0)
                      _MetaChip(
                        icon: Icons.mode_comment_outlined,
                        label: '${task.commentCount}',
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isOverdue(TaskModel task) {
    if (task.dueDate == null) return false;
    if (task.status == TaskStatus.done ||
        task.status == TaskStatus.cancelled) {
      return false;
    }
    return task.dueDate!.isBefore(DateTime.now());
  }
}

class _StatusPill extends StatelessWidget {
  final TaskStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withOpacity(0.35), width: 0.7),
      ),
      child: Text(
        status.displayLabel,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final TaskStatus status;
  const _EmptyView({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 80.h),
        Icon(
          Icons.task_alt,
          size: 64.sp,
          color: theme.colorScheme.onSurface.withOpacity(0.2),
        ),
        SizedBox(height: 16.h),
        Center(
          child: Text(
            l.noTasksInStatus(status.displayLabel),
            style: TextStyle(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.sp,
              color: const Color(0xFFEF4444),
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
            SizedBox(height: 16.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskListSkeleton extends StatelessWidget {
  const _TaskListSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
    final highlightColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF3F4F6);

    Widget block({
      required double height,
      double? width,
      double radius = 10,
    }) {
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius.r),
        ),
      );
    }

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: [
          // Tab bar placeholder
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
            child: Row(
              children: [
                for (int i = 0; i < 4; i++) ...[
                  block(height: 18.h, width: 72.w, radius: 6),
                  if (i < 3) SizedBox(width: 14.w),
                ],
              ],
            ),
          ),
          Container(height: 1, color: Colors.white24),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
              itemCount: 6,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (_, __) => block(height: 110.h, radius: 16),
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return const Color(0xFF64748B);
    case TaskStatus.inProgress:
      return const Color(0xFF0EA5E9);
    case TaskStatus.review:
      return const Color(0xFFF59E0B);
    case TaskStatus.done:
      return const Color(0xFF10B981);
    case TaskStatus.cancelled:
      return const Color(0xFFEF4444);
  }
}

Color _priorityColor(TaskPriority p) {
  switch (p) {
    case TaskPriority.low:
      return const Color(0xFF94A3B8);
    case TaskPriority.normal:
      return const Color(0xFF6366F1);
    case TaskPriority.high:
      return const Color(0xFFF59E0B);
    case TaskPriority.urgent:
      return const Color(0xFFEF4444);
  }
}

String _formatDate(DateTime d) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[d.month - 1]} ${d.day}';
}
