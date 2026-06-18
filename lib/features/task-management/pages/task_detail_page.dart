import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../cubit/task_detail_cubit.dart';
import '../cubit/task_detail_state.dart';
import '../models/task_comment_model.dart';
import '../models/task_model.dart';

class TaskDetailPage extends StatelessWidget {
  final int taskId;
  const TaskDetailPage({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskDetailCubit(AuthManager())..load(taskId),
      child: _TaskDetailView(taskId: taskId),
    );
  }
}

class _TaskDetailView extends StatefulWidget {
  final int taskId;
  const _TaskDetailView({required this.taskId});

  @override
  State<_TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<_TaskDetailView> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
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
          l.taskDetails,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
      body: BlocConsumer<TaskDetailCubit, TaskDetailState>(
        listener: (context, state) {
          if (state is TaskDetailError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TaskDetailLoading || state is TaskDetailInitial) {
            return const _TaskDetailSkeleton();
          }
          if (state is TaskDetailError) {
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
                    Text(state.message, textAlign: TextAlign.center),
                    SizedBox(height: 16.h),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<TaskDetailCubit>().load(widget.taskId),
                      icon: const Icon(Icons.refresh),
                      label: Text(l.retry),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is TaskDetailLoaded) {
            return _buildLoaded(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, TaskDetailLoaded state) {
    final theme = Theme.of(context);
    final task = state.task;

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            children: [
              _buildHeader(theme, task),
              SizedBox(height: 16.h),
              _buildStatusSection(context, state),
              SizedBox(height: 16.h),
              _buildMetaSection(theme, task),
              if (task.description != null &&
                  task.description!.trim().isNotEmpty) ...[
                SizedBox(height: 16.h),
                _buildDescriptionSection(theme, task),
              ],
              SizedBox(height: 16.h),
              _buildImagesSection(context, state),
              SizedBox(height: 20.h),
              _buildCommentsSection(theme, state.comments),
              SizedBox(height: 12.h),
            ],
          ),
        ),
        _buildCommentInput(context, state),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, TaskModel task) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5.w,
          height: 42.h,
          margin: EdgeInsets.only(right: 12.w, top: 4.h),
          decoration: BoxDecoration(
            color: _priorityColor(task.priority),
            borderRadius: BorderRadius.circular(3.r),
          ),
        ),
        Expanded(
          child: Text(
            task.title,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context, TaskDetailLoaded state) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final current = state.task.status;
    final isCancelled = current == TaskStatus.cancelled;
    final currentColor = _statusColor(current);

    final baseCard = _cardDecoration(theme);
    return Container(
      padding: EdgeInsets.fromLTRB(14.sp, 14.sp, 14.sp, 12.sp),
      decoration: BoxDecoration(
        borderRadius: baseCard.borderRadius,
        border: baseCard.border,
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? [
                  currentColor.withOpacity(0.10),
                  const Color(0xFF1F1F1F),
                ]
              : [
                  currentColor.withOpacity(0.06),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: label + current chip + spinner
          Row(
            children: [
              Text(
                l.currentStatus.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const Spacer(),
              if (state.isUpdatingStatus)
                SizedBox(
                  width: 14.w,
                  height: 14.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(currentColor),
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          // Big current-status chip
          _CurrentStatusChip(status: current),
          if (isCancelled) ...[
            SizedBox(height: 12.h),
            _CancelledBanner(message: l.taskCancelledBanner),
          ],
          SizedBox(height: 16.h),
          // Workflow stepper (the 4 main statuses)
          _WorkflowStepper(
            currentStatus: current,
            disabled: state.isUpdatingStatus,
            onStepTap: (target) =>
                _confirmAndChangeStatus(context, current, target),
          ),
          SizedBox(height: 6.h),
          Center(
            child: Text(
              l.tapToChange,
              style: TextStyle(
                fontSize: 10.5.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.45),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          SizedBox(height: 10.h),
          Divider(
            height: 1,
            color: theme.dividerColor.withOpacity(0.4),
          ),
          SizedBox(height: 6.h),
          // Cancel / Reopen action
          Center(
            child: TextButton.icon(
              onPressed: state.isUpdatingStatus
                  ? null
                  : () => isCancelled
                      ? _confirmAndChangeStatus(
                          context,
                          current,
                          TaskStatus.todo,
                          isReopen: true,
                        )
                      : _confirmAndChangeStatus(
                          context,
                          current,
                          TaskStatus.cancelled,
                          isCancel: true,
                        ),
              icon: Icon(
                isCancelled
                    ? Icons.refresh_rounded
                    : Icons.cancel_outlined,
                size: 16.sp,
                color: isCancelled
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
              label: Text(
                isCancelled ? l.reopenTask : l.cancelTask,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: isCancelled
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndChangeStatus(
    BuildContext context,
    TaskStatus from,
    TaskStatus to, {
    bool isCancel = false,
    bool isReopen = false,
  }) async {
    if (from == to) return;
    final l = AppLocalizations.of(context);
    final cubit = context.read<TaskDetailCubit>();

    final title = isCancel
        ? l.cancelTask
        : isReopen
            ? l.reopenTask
            : l.changeStatusTitle;
    final body = isCancel
        ? l.cancelTaskConfirm
        : isReopen
            ? l.reopenTaskConfirm
            : l.changeStatusBody(from.displayLabel, to.displayLabel);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmStatusDialog(
        title: title,
        body: body,
        from: from,
        to: to,
        isDestructive: isCancel,
      ),
    );

    if (confirmed == true) {
      await cubit.updateStatus(to);
    }
  }

  Widget _buildMetaSection(ThemeData theme, TaskModel task) {
    final l = AppLocalizations.of(context);
    final items = <_MetaRow>[
      _MetaRow(
        icon: Icons.flag_outlined,
        label: l.priority,
        value: task.priority.displayLabel,
        color: _priorityColor(task.priority),
      ),
      if (task.list != null)
        _MetaRow(
          icon: Icons.folder_outlined,
          label: l.taskList,
          value: task.list!.space != null
              ? '${task.list!.space!.name} / ${task.list!.name}'
              : task.list!.name,
        ),
      if (task.dueDate != null)
        _MetaRow(
          icon: Icons.event_outlined,
          label: l.dueDate,
          value: _formatFullDate(task.dueDate!),
          color: _isOverdue(task) ? const Color(0xFFEF4444) : null,
        ),
      if (task.startDate != null)
        _MetaRow(
          icon: Icons.play_circle_outline,
          label: l.startDate,
          value: _formatFullDate(task.startDate!),
        ),
      if (task.estimatedHours != null)
        _MetaRow(
          icon: Icons.schedule_outlined,
          label: l.estimatedHours,
          value: '${task.estimatedHours}h',
        ),
    ];

    return Container(
      padding: EdgeInsets.all(14.sp),
      decoration: _cardDecoration(theme),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            items[i],
            if (i < items.length - 1)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Divider(
                  height: 1,
                  color: theme.dividerColor.withOpacity(0.4),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(ThemeData theme, TaskModel task) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.sp),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.description,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            task.description ?? '',
            style: TextStyle(
              fontSize: 14.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.85),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadImages(BuildContext context) async {
    final cubit = context.read<TaskDetailCubit>();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;
      final files = picked.map((x) => File(x.path)).toList();
      await cubit.uploadImages(files);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not pick images'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _confirmDeleteImage(
    BuildContext context,
    TaskImageModel image,
  ) async {
    final l = AppLocalizations.of(context);
    final cubit = context.read<TaskDetailCubit>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deleteImage),
        content: Text(l.deleteImageConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.deleteImage.replaceAll('?', '')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await cubit.deleteImage(image.id);
    }
  }

  void _openImageViewer(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(12.w),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48.sp,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8.h,
              right: 8.w,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(ctx).pop(),
                  child: Padding(
                    padding: EdgeInsets.all(6.sp),
                    child: Icon(Icons.close, color: Colors.white, size: 20.sp),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(BuildContext context, TaskDetailLoaded state) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final images = state.task.images;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.sp),
      decoration: _cardDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image_outlined,
                size: 16.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              SizedBox(width: 6.w),
              Text(
                '${l.attachments} (${images.length})',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (state.isUploadingImage)
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton.icon(
                  onPressed: () => _pickAndUploadImages(context),
                  icon: Icon(Icons.add_photo_alternate_outlined, size: 16.sp),
                  label: Text(
                    l.addPhoto,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          if (images.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Text(
                l.noAttachments,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: images
                  .map((img) => _TaskImageThumb(
                        image: img,
                        onTap: () => _openImageViewer(context, img.url),
                        onDelete: () => _confirmDeleteImage(context, img),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(
    ThemeData theme,
    List<TaskCommentModel> comments,
  ) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            children: [
              Icon(
                Icons.mode_comment_outlined,
                size: 16.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              SizedBox(width: 6.w),
              Text(
                '${l.comments} (${comments.length})',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
        if (comments.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Center(
              child: Text(
                l.noComments,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
          )
        else
          ...comments.map((c) => _CommentTile(comment: c)),
      ],
    );
  }

  Widget _buildCommentInput(BuildContext context, TaskDetailLoaded state) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withOpacity(0.4),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                enabled: !state.isSendingComment,
                minLines: 1,
                maxLines: 4,
                cursorColor: theme.colorScheme.onSurface,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: theme.colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: l.addCommentHint,
                  hintStyle: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF1F1F1F)
                      : const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.r),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  isDense: true,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Material(
              color: const Color(0xFF6366F1),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: state.isSendingComment
                    ? null
                    : () async {
                        final text = _commentController.text;
                        if (text.trim().isEmpty) return;
                        await context
                            .read<TaskDetailCubit>()
                            .addComment(text);
                        _commentController.clear();
                        Future.delayed(
                          const Duration(milliseconds: 100),
                          () {
                            if (_scrollController.hasClients) {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration:
                                    const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              );
                            }
                          },
                        );
                      },
                child: Container(
                  width: 40.w,
                  height: 40.w,
                  alignment: Alignment.center,
                  child: state.isSendingComment
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(
        color: theme.dividerColor.withOpacity(0.4),
        width: 0.7,
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

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface.withOpacity(0.7);
    return Row(
      children: [
        Icon(icon, size: 16.sp, color: c),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: color ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _TaskImageThumb extends StatelessWidget {
  final TaskImageModel image;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TaskImageThumb({
    required this.image,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = 84.w;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10.r),
            child: Image.network(
              image.url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  width: size,
                  height: size,
                  color: theme.dividerColor.withOpacity(0.2),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                width: size,
                height: size,
                color: theme.dividerColor.withOpacity(0.2),
                alignment: Alignment.center,
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 22.sp,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: -6.h,
          right: -6.w,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: EdgeInsets.all(2.sp),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: theme.scaffoldBackgroundColor, width: 1.5),
              ),
              child: Icon(Icons.close, size: 13.sp, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  final TaskCommentModel comment;
  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final author = comment.author;
    final photoUrl = author?.photoUrl;
    final displayName = author?.displayName ??
        (comment.authorId != null ? 'Employee #${comment.authorId}' : 'Unknown');
    final initials = author?.initials ??
        (comment.authorId != null ? '#' : '?');

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1F1F1F)
            : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 13.r,
                backgroundColor: const Color(0xFF6366F1),
                backgroundImage:
                    photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        initials,
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (comment.createdAt != null) ...[
                SizedBox(width: 8.w),
                Text(
                  _formatRelative(comment.createdAt!),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.only(left: 34.w),
            child: Text(
              comment.content,
              style: TextStyle(
                fontSize: 13.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.85),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
//  Status section widgets
// ───────────────────────────────────────────────────────────────────────────

class _CurrentStatusChip extends StatelessWidget {
  final TaskStatus status;
  const _CurrentStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26.w,
            height: 26.w,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(_statusIcon(status), size: 16.sp, color: Colors.white),
          ),
          SizedBox(width: 10.w),
          Text(
            status.displayLabel,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelledBanner extends StatelessWidget {
  final String message;
  const _CancelledBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.10),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.35),
          width: 0.7,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14.sp,
            color: const Color(0xFFEF4444),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowStepper extends StatelessWidget {
  final TaskStatus currentStatus;
  final bool disabled;
  final void Function(TaskStatus target) onStepTap;

  static const List<TaskStatus> _flow = [
    TaskStatus.todo,
    TaskStatus.inProgress,
    TaskStatus.review,
    TaskStatus.done,
  ];

  const _WorkflowStepper({
    required this.currentStatus,
    required this.disabled,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCancelled = currentStatus == TaskStatus.cancelled;
    final currentIndex =
        isCancelled ? -1 : _flow.indexOf(currentStatus).clamp(0, _flow.length - 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _flow.length; i++) ...[
          Expanded(
            child: _StepperNode(
              status: _flow[i],
              state: isCancelled
                  ? _StepState.muted
                  : i < currentIndex
                      ? _StepState.passed
                      : i == currentIndex
                          ? _StepState.current
                          : _StepState.future,
              disabled: disabled,
              onTap: () => onStepTap(_flow[i]),
            ),
          ),
          if (i < _flow.length - 1)
            _Connector(
              passed: !isCancelled && i < currentIndex,
              dimmed: isCancelled,
              color: isCancelled
                  ? theme.dividerColor
                  : _statusColor(_flow[i + 1]),
            ),
        ],
      ],
    );
  }
}

enum _StepState { passed, current, future, muted }

class _StepperNode extends StatelessWidget {
  final TaskStatus status;
  final _StepState state;
  final bool disabled;
  final VoidCallback onTap;

  const _StepperNode({
    required this.status,
    required this.state,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _statusColor(status);
    final isCurrent = state == _StepState.current;
    final isPassed = state == _StepState.passed;
    final isMuted = state == _StepState.muted;

    final Color circleFill;
    final Color circleBorder;
    final Color iconColor;
    final double circleSize = isCurrent ? 40.w : 32.w;

    if (isMuted) {
      circleFill = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE5E7EB);
      circleBorder = theme.dividerColor;
      iconColor = theme.colorScheme.onSurface.withOpacity(0.35);
    } else if (isPassed) {
      circleFill = color.withOpacity(0.18);
      circleBorder = color.withOpacity(0.7);
      iconColor = color;
    } else if (isCurrent) {
      circleFill = color;
      circleBorder = color;
      iconColor = Colors.white;
    } else {
      circleFill = isDark
          ? const Color(0xFF1F1F1F)
          : Colors.white;
      circleBorder = color.withOpacity(0.35);
      iconColor = color.withOpacity(0.6);
    }

    return GestureDetector(
      onTap: disabled || isCurrent ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              color: circleFill,
              shape: BoxShape.circle,
              border: Border.all(color: circleBorder, width: isCurrent ? 2 : 1.5),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isPassed ? Icons.check_rounded : _statusIcon(status),
              size: isCurrent ? 20.sp : 16.sp,
              color: iconColor,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            status.displayLabel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isCurrent ? 11.sp : 10.sp,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
              color: isMuted
                  ? theme.colorScheme.onSurface.withOpacity(0.4)
                  : isCurrent || isPassed
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  final bool passed;
  final bool dimmed;
  final Color color;

  const _Connector({
    required this.passed,
    required this.dimmed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h),
      child: SizedBox(
        width: 18.w,
        height: 2.h,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: dimmed
                ? color.withOpacity(0.3)
                : passed
                    ? color.withOpacity(0.7)
                    : color.withOpacity(0.25),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _ConfirmStatusDialog extends StatelessWidget {
  final String title;
  final String body;
  final TaskStatus from;
  final TaskStatus to;
  final bool isDestructive;

  const _ConfirmStatusDialog({
    required this.title,
    required this.body,
    required this.from,
    required this.to,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final toColor = _statusColor(to);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
      child: Padding(
        padding: EdgeInsets.all(20.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon header
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: (isDestructive ? const Color(0xFFEF4444) : toColor)
                    .withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isDestructive
                    ? Icons.warning_amber_rounded
                    : _statusIcon(to),
                size: 24.sp,
                color: isDestructive ? const Color(0xFFEF4444) : toColor,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              body,
              style: TextStyle(
                fontSize: 13.sp,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
                height: 1.4,
              ),
            ),
            SizedBox(height: 16.h),
            // From → To visual
            Row(
              children: [
                Expanded(child: _MiniStatusChip(status: from, dimmed: true)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 18.sp,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                Expanded(child: _MiniStatusChip(status: to)),
              ],
            ),
            SizedBox(height: 18.h),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      l.cancel,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isDestructive ? const Color(0xFFEF4444) : toColor,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(
                      l.confirm,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
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

class _MiniStatusChip extends StatelessWidget {
  final TaskStatus status;
  final bool dimmed;
  const _MiniStatusChip({required this.status, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(dimmed ? 0.08 : 0.15),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: color.withOpacity(dimmed ? 0.25 : 0.45),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _statusIcon(status),
            size: 12.sp,
            color: color.withOpacity(dimmed ? 0.6 : 1),
          ),
          SizedBox(width: 5.w),
          Flexible(
            child: Text(
              status.displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: color.withOpacity(dimmed ? 0.7 : 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _statusIcon(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return Icons.radio_button_unchecked;
    case TaskStatus.inProgress:
      return Icons.bolt_rounded;
    case TaskStatus.review:
      return Icons.visibility_outlined;
    case TaskStatus.done:
      return Icons.check_circle_outline;
    case TaskStatus.cancelled:
      return Icons.close_rounded;
  }
}

class _TaskDetailSkeleton extends StatelessWidget {
  const _TaskDetailSkeleton();

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
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        children: [
          // Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              block(height: 42.h, width: 5.w, radius: 3),
              SizedBox(width: 12.w),
              Expanded(child: block(height: 24.h, radius: 6)),
            ],
          ),
          SizedBox(height: 18.h),
          // Status card
          block(height: 90.h, radius: 14),
          SizedBox(height: 16.h),
          // Meta card
          block(height: 160.h, radius: 14),
          SizedBox(height: 16.h),
          // Description
          block(height: 110.h, radius: 14),
          SizedBox(height: 20.h),
          // Comments header
          Row(
            children: [
              block(height: 14.h, width: 100.w, radius: 6),
            ],
          ),
          SizedBox(height: 10.h),
          // Comment tiles
          for (int i = 0; i < 3; i++) ...[
            block(height: 70.h, radius: 12),
            SizedBox(height: 8.h),
          ],
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

String _formatFullDate(DateTime d) {
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
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

String _formatRelative(DateTime d) {
  final diff = DateTime.now().difference(d);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return _formatFullDate(d);
}
