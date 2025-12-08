import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class Checklist extends StatefulWidget {
  const Checklist({super.key});

  @override
  State<Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<Checklist> {
  final List<ChecklistItem> _tasks = [];
  final TextEditingController _taskController = TextEditingController();

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  void _addTask() {
    if (_taskController.text.trim().isNotEmpty) {
      setState(() {
        _tasks.add(ChecklistItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _taskController.text.trim(),
          isCompleted: false,
          createdAt: DateTime.now(),
        ));
        _taskController.clear();
      });
    }
  }

  void _toggleTask(String id) {
    setState(() {
      final index = _tasks.indexWhere((task) => task.id == id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          isCompleted: !_tasks[index].isCompleted,
        );
      }
    });
  }

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((task) => task.id == id);
    });
  }

  void _showAddTaskDialog() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Row(
            children: [
              Icon(
                Icons.add_task_rounded,
                color: const Color(0xFF4ECDC4),
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Text(
                'New Task',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: TextField(
            controller: _taskController,
            autofocus: true,
            maxLines: 3,
            style: TextStyle(
              fontSize: 16.sp,
              color: theme.colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Enter task description...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF252532)
                  : const Color(0xFFF5F5F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16.w),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _taskController.clear();
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _addTask();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ECDC4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              ),
              child: Text(
                'Add',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final completedTasks = _tasks.where((task) => task.isCompleted).length;
    final totalTasks = _tasks.length;
    final progress = totalTasks > 0 ? completedTasks / totalTasks : 0.0;

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
          'Checklist',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: Column(
        children: [
          // Progress Card
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.r),
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A1A24), const Color(0xFF252532)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFF5F5F7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '$completedTasks of $totalTasks',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4ECDC4),
                            const Color(0xFF44B3AA),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4ECDC4).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${(progress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8.h,
                    backgroundColor: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFE5E5EA),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4ECDC4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tasks List
          Expanded(
            child: _tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 80.sp,
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No tasks yet',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Tap + to add your first task',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    itemCount: _tasks.length,
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      return _buildTaskItem(task, theme, isDark);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: const Color(0xFF4ECDC4),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Task',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskItem(ChecklistItem task, ThemeData theme, bool isDark) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteTask(task.id),
      background: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
        ),
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28.sp,
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: isDark
              ? const Color(0xFF1A1A24)
              : const Color(0xFFFFFFFF),
          border: Border.all(
            color: task.isCompleted
                ? const Color(0xFF4ECDC4)
                : isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE5E5EA),
            width: 1.5,
          ),
          boxShadow: task.isCompleted
              ? [
                  BoxShadow(
                    color: const Color(0xFF4ECDC4).withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () => _toggleTask(task.id),
              child: Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: task.isCompleted
                      ? const LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44B3AA)],
                        )
                      : null,
                  border: Border.all(
                    color: task.isCompleted
                        ? Colors.transparent
                        : isDark
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                    width: 2,
                  ),
                ),
                child: task.isCompleted
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18.sp,
                      )
                    : null,
              ),
            ),
            
            SizedBox(width: 16.w),
            
            // Task Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: task.isCompleted
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _formatDate(task.createdAt),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            // Delete Button
            IconButton(
              onPressed: () => _deleteTask(task.id),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                size: 22.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class ChecklistItem {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;

  ChecklistItem({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
  });

  ChecklistItem copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
