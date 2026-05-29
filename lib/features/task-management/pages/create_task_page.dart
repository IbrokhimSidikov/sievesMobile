import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../cubit/create_task_cubit.dart';
import '../cubit/create_task_state.dart';
import '../models/task_model.dart';

class CreateTaskPage extends StatelessWidget {
  const CreateTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateTaskCubit(AuthManager())..loadForm(),
      child: const _CreateTaskView(),
    );
  }
}

class _CreateTaskView extends StatelessWidget {
  const _CreateTaskView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return BlocConsumer<CreateTaskCubit, CreateTaskState>(
      listenWhen: (prev, curr) =>
          prev.submitted != curr.submitted ||
          prev.submitError != curr.submitError,
      listener: (context, state) {
        if (state.submitted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l.taskCreated),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
          context.pop(true);
        } else if (state.submitError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.submitError!),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<CreateTaskCubit>();
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: Text(
              l.createTask,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: TextButton(
                  onPressed:
                      state.canSubmit ? () => cubit.submit() : null,
                  child: state.submitting
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          l.create,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            color: state.canSubmit
                                ? const Color(0xFF6366F1)
                                : theme.disabledColor,
                          ),
                        ),
                ),
              ),
            ],
          ),
          body: state.loadingForm
              ? const Center(child: CircularProgressIndicator())
              : state.formError != null
                  ? _ErrorView(
                      message: state.formError!,
                      onRetry: () => cubit.loadForm(),
                    )
                  : _Form(state: state, cubit: cubit),
        );
      },
    );
  }
}

class _Form extends StatelessWidget {
  final CreateTaskState state;
  final CreateTaskCubit cubit;
  const _Form({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(l.createTaskTitleHint),
          SizedBox(height: 6.h),
          TextField(
            decoration: _inputDecoration(context, l.createTaskTitleHint),
            onChanged: cubit.setTitle,
          ),
          SizedBox(height: 16.h),

          _SectionLabel(l.description),
          SizedBox(height: 6.h),
          TextField(
            maxLines: 3,
            decoration:
                _inputDecoration(context, l.createTaskDescriptionHint),
            onChanged: cubit.setDescription,
          ),
          SizedBox(height: 16.h),

          _SectionLabel(l.priority),
          SizedBox(height: 6.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: TaskPriority.values
                .map((p) => _PriorityChip(
                      priority: p,
                      selected: state.priority == p,
                      onTap: () => cubit.setPriority(p),
                    ))
                .toList(),
          ),
          SizedBox(height: 16.h),

          _SectionLabel(l.department),
          SizedBox(height: 6.h),
          _Dropdown<int>(
            hint: l.selectDepartment,
            value: state.selectedDepartmentId,
            items: state.departments
                .map((d) => DropdownMenuItem(value: d.id, child: Text(d.name)))
                .toList(),
            onChanged: (v) {
              if (v != null) cubit.selectDepartment(v);
            },
          ),
          SizedBox(height: 16.h),

          if (state.selectedDepartmentId != null) ...[
            _SectionLabel(l.taskSpace),
            SizedBox(height: 6.h),
            state.loadingSpaces
                ? const LinearProgressIndicator(minHeight: 2)
                : state.spaces.isEmpty
                    ? _EmptyHint(l.noSpacesForDepartment)
                    : _Dropdown<int>(
                        hint: l.selectSpace,
                        value: state.selectedSpaceId,
                        items: state.spaces
                            .map((s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(s.name),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) cubit.selectSpace(v);
                        },
                      ),
            SizedBox(height: 16.h),
          ],

          if (state.selectedSpaceId != null) ...[
            _SectionLabel(l.taskList),
            SizedBox(height: 6.h),
            state.loadingLists
                ? const LinearProgressIndicator(minHeight: 2)
                : state.lists.isEmpty
                    ? _EmptyHint(l.noListsForSpace)
                    : _Dropdown<int>(
                        hint: l.selectList,
                        value: state.selectedListId,
                        items: state.lists
                            .map((l) => DropdownMenuItem(
                                  value: l.id,
                                  child: Text(l.name),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) cubit.selectList(v);
                        },
                      ),
            SizedBox(height: 16.h),
          ],

          _SectionLabel(l.dueDate),
          SizedBox(height: 6.h),
          _DateField(
            value: state.dueDate,
            hint: l.pickDueDate,
            onPick: (d) => cubit.setDueDate(d),
            onClear: () => cubit.setDueDate(null),
          ),
          SizedBox(height: 16.h),

          _SectionLabel('${l.assignees} (${state.selectedAssigneeIds.length})'),
          SizedBox(height: 6.h),
          _AssigneeField(
            state: state,
            cubit: cubit,
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: theme.brightness == Brightness.dark
          ? const Color(0xFF1F1F1F)
          : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.4),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface.withOpacity(0.7),
        letterSpacing: 0.3,
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF1F1F1F)
            : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.5),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          hint: Text(
            hint,
            style: TextStyle(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
          value: value,
          items: items,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 14.sp,
            color: theme.colorScheme.onSurface,
          ),
          iconEnabledColor: theme.colorScheme.onSurface.withOpacity(0.65),
          dropdownColor: theme.brightness == Brightness.dark
              ? const Color(0xFF1F1F1F)
              : Colors.white,
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint(this.text);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          color: theme.colorScheme.error,
        ),
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final TaskPriority priority;
  final bool selected;
  final VoidCallback onTap;

  const _PriorityChip({
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _priorityColor(priority);
    return InkWell(
      borderRadius: BorderRadius.circular(20.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.18) : Colors.transparent,
          border: Border.all(
            color: selected ? color : color.withOpacity(0.35),
            width: selected ? 1.4 : 0.8,
          ),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag, size: 12.sp, color: color),
            SizedBox(width: 6.w),
            Text(
              priority.displayLabel,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final DateTime? value;
  final String hint;
  final ValueChanged<DateTime> onPick;
  final VoidCallback onClear;

  const _DateField({
    required this.value,
    required this.hint,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: now.subtract(const Duration(days: 1)),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) onPick(picked);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF1F1F1F)
              : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_outlined,
              size: 18.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                value == null
                    ? hint
                    : '${value!.year}-${_two(value!.month)}-${_two(value!.day)}',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: value == null
                      ? theme.colorScheme.onSurface.withOpacity(0.55)
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (value != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 18.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _two(int n) => n < 10 ? '0$n' : '$n';
}

class _AssigneeField extends StatelessWidget {
  final CreateTaskState state;
  final CreateTaskCubit cubit;
  const _AssigneeField({required this.state, required this.cubit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final selectedEmployees = state.employees
        .where((e) => state.selectedAssigneeIds.contains(e.id))
        .toList();
    final hasSelection = state.selectedAssigneeIds.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => _openSheet(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF1F1F1F)
              : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.people_outline,
              size: 18.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: !hasSelection
                  ? Text(
                      l.selectAssignees,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                    )
                  : Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: selectedEmployees
                          .map((e) => Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8.w,
                                  vertical: 3.h,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1)
                                      .withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  e.fullName,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6366F1),
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
            ),
            Icon(
              Icons.expand_more,
              size: 20.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ],
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    cubit.loadEmployees();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return BlocProvider.value(
          value: cubit,
          child: const _AssigneeSheet(),
        );
      },
    );
  }
}

class _AssigneeSheet extends StatefulWidget {
  const _AssigneeSheet();

  @override
  State<_AssigneeSheet> createState() => _AssigneeSheetState();
}

class _AssigneeSheetState extends State<_AssigneeSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;

    return BlocBuilder<CreateTaskCubit, CreateTaskState>(
      builder: (context, state) {
        final cubit = context.read<CreateTaskCubit>();
        final q = _query.trim().toLowerCase();
        final filtered = q.isEmpty
            ? state.employees
            : state.employees
                .where((e) =>
                    e.fullName.toLowerCase().contains(q) ||
                    (e.departmentName ?? '').toLowerCase().contains(q))
                .toList();

        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              children: [
                SizedBox(height: 8.h),
                Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    children: [
                      Text(
                        '${l.assignees} (${state.selectedAssigneeIds.length})',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          l.confirm,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: TextField(
                    cursorColor: theme.colorScheme.onSurface,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: l.searchEmployees,
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.55),
                      ),
                      filled: true,
                      fillColor: theme.brightness == Brightness.dark
                          ? const Color(0xFF1F1F1F)
                          : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                            color: theme.dividerColor.withOpacity(0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                            color: theme.dividerColor.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: Color(0xFF6366F1),
                          width: 1.4,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 10.h,
                      ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                SizedBox(height: 10.h),
                Expanded(
                  child: _buildBody(state, cubit, filtered, theme, l),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    CreateTaskState state,
    CreateTaskCubit cubit,
    List<EmployeeBrief> filtered,
    ThemeData theme,
    AppLocalizations l,
  ) {
    if (state.loadingEmployees) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.employeesError != null) {
      return _ErrorView(
        message: state.employeesError!,
        onRetry: () => cubit.loadEmployees(force: true),
      );
    }
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          l.noEmployees,
          style: TextStyle(
            fontSize: 13.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.55),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: theme.dividerColor.withOpacity(0.3),
      ),
      itemBuilder: (_, i) {
        final e = filtered[i];
        final isSelected = state.selectedAssigneeIds.contains(e.id);
        return InkWell(
          onTap: () => cubit.toggleAssignee(e.id),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor:
                      const Color(0xFF6366F1).withOpacity(0.15),
                  backgroundImage: e.photoUrl != null
                      ? NetworkImage(e.photoUrl!)
                      : null,
                  child: e.photoUrl == null
                      ? Text(
                          e.fullName.isEmpty
                              ? '?'
                              : e.fullName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF6366F1),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.fullName,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (e.departmentName != null &&
                          e.departmentName!.isNotEmpty)
                        Text(
                          e.departmentName!,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isSelected,
                  onChanged: (_) => cubit.toggleAssignee(e.id),
                  activeColor: const Color(0xFF6366F1),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        );
      },
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
