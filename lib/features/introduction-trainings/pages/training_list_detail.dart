import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../task-management/models/task_model.dart' show EmployeeBrief;
import '../cubit/checklist_cubit.dart';
import '../cubit/checklist_state.dart';
import '../models/intro_training.dart';

const Color _accent = AppColors.cx43C19F;
const Color _doneColor = AppColors.cxSuccess;

class TrainingListDetail extends StatelessWidget {
  final EmployeeBrief employee;
  const TrainingListDetail({super.key, required this.employee});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChecklistCubit(AuthManager())..load(employee.id),
      child: _ChecklistView(employee: employee),
    );
  }
}

class _ChecklistView extends StatelessWidget {
  final EmployeeBrief employee;
  const _ChecklistView({required this.employee});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final canManage = AuthManager().canManageIntroTrainings;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20.sp,
            color: theme.colorScheme.onSurface,
          ),
        ),
        title: Text(
          l.introChecklistTitle,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: BlocBuilder<ChecklistCubit, ChecklistState>(
        builder: (context, state) {
          if (state is ChecklistLoading || state is ChecklistInitial) {
            return const _DetailSkeleton();
          }
          if (state is ChecklistError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<ChecklistCubit>().load(employee.id),
            );
          }
          if (state is ChecklistLoaded) {
            final data = state.data;
            return RefreshIndicator(
              color: _accent,
              onRefresh: () => context.read<ChecklistCubit>().load(employee.id),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
                children: [
                  _SummaryCard(employee: employee, summary: data.summary),
                  SizedBox(height: 16.h),
                  if (data.trainings.isEmpty)
                    _EmptyInline(message: l.introNoTrainings)
                  else
                    ...data.trainings.map(
                      (t) => Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: _TrainingCard(
                          training: t,
                          onTap: () => _openChecklistSheet(
                            context,
                            trainingId: t.id,
                            employeeId: employee.id,
                            canManage: canManage,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _openChecklistSheet(
    BuildContext context, {
    required int trainingId,
    required int employeeId,
    required bool canManage,
  }) {
    final cubit = context.read<ChecklistCubit>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _ChecklistSheet(
          trainingId: trainingId,
          employeeId: employeeId,
          canManage: canManage,
        ),
      ),
    );
  }
}

// ============================================================================
// Summary card
// ============================================================================

class _SummaryCard extends StatelessWidget {
  final EmployeeBrief employee;
  final IntroSummary summary;
  const _SummaryCard({required this.employee, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final subtitle = (employee.departmentName ?? '').trim();

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [_accent.withOpacity(0.28), AppColors.cx4AC1A7.withOpacity(0.16)]
              : [_accent, AppColors.cx4AC1A7],
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: _accent.withOpacity(0.3),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      style: TextStyle(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cxWhite,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: AppColors.cxWhite.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              _ProgressRing(percent: summary.percent),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _StatChip(
                label: l.introCompleted,
                value: '${summary.completed}',
                icon: Icons.check_circle_rounded,
              ),
              SizedBox(width: 10.w),
              _StatChip(
                label: l.introPending,
                value: '${summary.pending}',
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l.introCompletedOfTotal(summary.completed, summary.total),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.cxWhite.withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressRing extends StatelessWidget {
  final int percent;
  const _ProgressRing({required this.percent});

  @override
  Widget build(BuildContext context) {
    final size = 60.r;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: (percent.clamp(0, 100)) / 100,
              strokeWidth: 5.r,
              backgroundColor: AppColors.cxWhite.withOpacity(0.28),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.cxWhite),
            ),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.cxWhite,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.cxWhite.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18.sp, color: AppColors.cxWhite),
            SizedBox(width: 8.w),
            Text(
              value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.cxWhite,
              ),
            ),
            SizedBox(width: 5.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.cxWhite.withOpacity(0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Training card (collapsed row → opens bottom sheet)
// ============================================================================

class _TrainingCard extends StatelessWidget {
  final IntroTraining training;
  final VoidCallback onTap;
  const _TrainingCard({required this.training, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    final total = training.summary.total;
    final done = training.summary.completed;
    final allDone = total > 0 && done == total;
    final statusColor = allDone ? _doneColor : theme.colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: allDone
                  ? _doneColor.withOpacity(isDark ? 0.35 : 0.25)
                  : (isDark
                      ? theme.colorScheme.onSurface.withOpacity(0.06)
                      : AppColors.cxPlatinumGray),
              width: 1,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(9.r),
                decoration: BoxDecoration(
                  color: (allDone ? _doneColor : _accent).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  allDone
                      ? Icons.verified_rounded
                      : Icons.menu_book_rounded,
                  size: 20.sp,
                  color: allDone ? _doneColor : _accent,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      training.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        Icon(
                          allDone
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 13.sp,
                          color: statusColor.withOpacity(allDone ? 1 : 0.4),
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          allDone ? l.introChecked : l.introNotChecked,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: statusColor.withOpacity(allDone ? 1 : 0.55),
                          ),
                        ),
                        Text(
                          '  ·  $done/$total',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: theme.colorScheme.onSurface.withOpacity(0.45),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              _MiniCountBadge(done: done, total: total, allDone: allDone),
              SizedBox(width: 6.w),
              Icon(
                Icons.chevron_right_rounded,
                size: 22.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniCountBadge extends StatelessWidget {
  final int done;
  final int total;
  final bool allDone;
  const _MiniCountBadge({
    required this.done,
    required this.total,
    required this.allDone,
  });

  @override
  Widget build(BuildContext context) {
    final color = allDone ? _doneColor : _accent;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        '$done/$total',
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ============================================================================
// Bottom sheet: check the training's items (live, scrollable)
// ============================================================================

class _ChecklistSheet extends StatelessWidget {
  final int trainingId;
  final int employeeId;
  final bool canManage;
  const _ChecklistSheet({
    required this.trainingId,
    required this.employeeId,
    required this.canManage,
  });

  IntroTraining? _find(ChecklistState state) {
    if (state is! ChecklistLoaded) return null;
    for (final t in state.data.trainings) {
      if (t.id == trainingId) return t;
    }
    return null;
  }

  /// Opens the detailed item dialog where the user can add a note and submit
  /// the completion for this exact checklist item.
  void _openItemDialog(
    BuildContext context, {
    required int trainingId,
    required IntroChecklistItem item,
    required bool canManage,
  }) {
    final cubit = context.read<ChecklistCubit>();
    showDialog(
      context: context,
      builder: (_) => _ChecklistItemDialog(
        item: item,
        canManage: canManage,
        onSubmit: (completed, note) => cubit.toggleItem(
          trainingId: trainingId,
          checklistId: item.id,
          completed: completed,
          note: note,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: BlocBuilder<ChecklistCubit, ChecklistState>(
        builder: (context, state) {
          final training = _find(state);
          final updating =
              state is ChecklistLoaded ? state.updating : const <int>{};

          if (training == null) {
            return SizedBox(
              height: 200.h,
              child: Center(
                child: Text(
                  l.introNoTrainings,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            );
          }

          final total = training.summary.total;
          final done = training.summary.completed;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 10.h),
              // Drag handle
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 14.h, 12.w, 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            training.title,
                            style: TextStyle(
                              fontSize: 17.sp,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            l.introCompletedOfTotal(done, total),
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        size: 22.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: 5.h,
                    backgroundColor:
                        theme.colorScheme.onSurface.withOpacity(0.08),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(_doneColor),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              // Scrollable items
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(
                    12.w,
                    8.h,
                    12.w,
                    MediaQuery.of(context).padding.bottom + 20.h,
                  ),
                  itemCount: training.items.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (_, i) {
                    final item = training.items[i];
                    return _SheetItemRow(
                      item: item,
                      canManage: canManage,
                      isUpdating: updating.contains(item.id),
                      onTap: () => _openItemDialog(
                        context,
                        trainingId: trainingId,
                        item: item,
                        canManage: canManage,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SheetItemRow extends StatelessWidget {
  final IntroChecklistItem item;
  final bool canManage;
  final bool isUpdating;
  final VoidCallback onTap;

  const _SheetItemRow({
    required this.item,
    required this.canManage,
    required this.isUpdating,
    required this.onTap,
  });

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String? _byline() {
    if (!item.completed) return null;
    final d = item.completedAt;
    final date =
        d != null ? '${d.day} ${_months[d.month - 1]} ${d.year}' : null;
    final name = (item.completedByName ?? '').trim();
    if (name.isNotEmpty && date != null) return '$name · $date';
    if (name.isNotEmpty) return name;
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final byline = _byline();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isUpdating ? null : onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: item.completed
                ? _doneColor.withOpacity(isDark ? 0.10 : 0.06)
                : (isDark
                    ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)
                    : AppColors.cxF5F7F9),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: item.completed
                  ? _doneColor.withOpacity(0.35)
                  : theme.colorScheme.onSurface.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 26.r,
                height: 26.r,
                child: isUpdating
                    ? Padding(
                        padding: EdgeInsets.all(3.r),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.r,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(_accent),
                        ),
                      )
                    : Icon(
                        item.completed
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 26.sp,
                        color: item.completed
                            ? _doneColor
                            : theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: theme.colorScheme.onSurface.withOpacity(
                          item.completed ? 0.6 : 0.9,
                        ),
                        decoration: item.completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor:
                            theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    if ((item.description ?? '').trim().isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        item.description!.trim(),
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                          height: 1.3,
                        ),
                      ),
                    ],
                    if ((item.note ?? '').trim().isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.sticky_note_2_outlined,
                              size: 13.sp,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.45),
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                item.note!.trim(),
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (byline != null) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 12.sp,
                            color: _doneColor.withOpacity(0.8),
                          ),
                          SizedBox(width: 4.w),
                          Flexible(
                            child: Text(
                              byline,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: _doneColor.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.chevron_right_rounded,
                size: 20.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Item detail dialog: read the item, add a note, submit the completion
// ============================================================================

class _ChecklistItemDialog extends StatefulWidget {
  final IntroChecklistItem item;
  final bool canManage;

  /// Called with the desired completion state and the (optional) note.
  final void Function(bool completed, String? note) onSubmit;

  const _ChecklistItemDialog({
    required this.item,
    required this.canManage,
    required this.onSubmit,
  });

  @override
  State<_ChecklistItemDialog> createState() => _ChecklistItemDialogState();
}

class _ChecklistItemDialogState extends State<_ChecklistItemDialog> {
  late final TextEditingController _noteController;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.item.note ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _submit(bool completed) {
    final raw = _noteController.text.trim();
    widget.onSubmit(completed, raw.isEmpty ? null : raw);
    Navigator.of(context).pop();
  }

  String? _byline() {
    if (!widget.item.completed) return null;
    final d = widget.item.completedAt;
    final date =
        d != null ? '${d.day} ${_months[d.month - 1]} ${d.year}' : null;
    final name = (widget.item.completedByName ?? '').trim();
    if (name.isNotEmpty && date != null) return '$name · $date';
    if (name.isNotEmpty) return name;
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context);
    final item = widget.item;
    final completed = item.completed;
    final byline = _byline();
    final description = (item.description ?? '').trim();

    return Dialog(
      backgroundColor: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22.r),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: status icon + label + close
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(9.r),
                    decoration: BoxDecoration(
                      color: (completed ? _doneColor : _accent)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      completed
                          ? Icons.verified_rounded
                          : Icons.checklist_rounded,
                      size: 20.sp,
                      color: completed ? _doneColor : _accent,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      completed ? l.introChecked : l.introItemDetails,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: (completed ? _doneColor : _accent),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Icon(
                        Icons.close_rounded,
                        size: 22.sp,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              // Title
              Text(
                item.title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (description.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14.sp,
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ],
              if (byline != null) ...[
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14.sp,
                      color: _doneColor.withOpacity(0.85),
                    ),
                    SizedBox(width: 5.w),
                    Flexible(
                      child: Text(
                        byline,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: _doneColor.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              SizedBox(height: 18.h),
              // Note / comment field (or read-only view)
              if (widget.canManage) ...[
                Text(
                  l.introAddNote,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
                SizedBox(height: 8.h),
                TextField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 6,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: theme.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: l.introNoteHint,
                    hintStyle: TextStyle(
                      fontSize: 13.sp,
                      color: theme.colorScheme.onSurface.withOpacity(0.35),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.3)
                        : AppColors.cxF5F7F9,
                    contentPadding: EdgeInsets.all(12.r),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: _accent, width: 1.4),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _submit(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: completed ? _accent : _doneColor,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                    icon: Icon(
                      completed ? Icons.save_rounded : Icons.check_rounded,
                      size: 20.sp,
                    ),
                    label: Text(
                      completed ? l.introUpdateNote : l.introSubmitDone,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (completed) ...[
                  SizedBox(height: 8.h),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () => _submit(false),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.cxCrimsonRed,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      icon: Icon(Icons.undo_rounded, size: 18.sp),
                      label: Text(
                        l.introMarkNotDone,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ] else if ((item.note ?? '').trim().isNotEmpty) ...[
                Text(
                  l.introAddNote,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface.withOpacity(0.75),
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? theme.colorScheme.surfaceContainerHighest
                            .withOpacity(0.3)
                        : AppColors.cxF5F7F9,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    item.note!.trim(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      height: 1.4,
                      color: theme.colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// States
// ============================================================================

class _EmptyInline extends StatelessWidget {
  final String message;
  const _EmptyInline({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(top: 60.h),
      child: Column(
        children: [
          Icon(
            Icons.checklist_rtl_rounded,
            size: 52.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.25),
          ),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final block = isDark
        ? theme.colorScheme.surface
        : AppColors.cxF5F7F9;
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 24.h),
      children: [
        Container(
          height: 150.h,
          decoration: BoxDecoration(
            color: block,
            borderRadius: BorderRadius.circular(22.r),
          ),
        ),
        SizedBox(height: 16.h),
        for (int i = 0; i < 5; i++)
          Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: Container(
              height: 72.h,
              decoration: BoxDecoration(
                color: block,
                borderRadius: BorderRadius.circular(16.r),
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
    final l = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 52.sp,
              color: AppColors.cxCrimsonRed.withOpacity(0.8),
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            SizedBox(height: 20.h),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: _accent),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l.retry),
            ),
          ],
        ),
      ),
    );
  }
}
