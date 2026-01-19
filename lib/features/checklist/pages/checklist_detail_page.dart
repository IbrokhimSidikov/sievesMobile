import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../cubit/checklist_cubit.dart';
import '../cubit/checklist_state.dart';

class ChecklistDetailPage extends StatefulWidget {
  final int checklistId;

  const ChecklistDetailPage({
    super.key,
    required this.checklistId,
  });

  @override
  State<ChecklistDetailPage> createState() => _ChecklistDetailPageState();
}

class _ChecklistDetailPageState extends State<ChecklistDetailPage> {
  @override
  void initState() {
    super.initState();
    context.read<ChecklistCubit>().loadChecklist(widget.checklistId);
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
        title: BlocBuilder<ChecklistCubit, ChecklistState>(
          builder: (context, state) {
            if (state is ChecklistLoaded) {
              return Text(
                state.checklist.name,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      body: BlocConsumer<ChecklistCubit, ChecklistState>(
        listener: (context, state) {
          if (state is ChecklistSubmitted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        state.message,
                        style: TextStyle(fontSize: 15.sp),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF4ECDC4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            );
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted) context.pop();
            });
          }
        },
        builder: (context, state) {
          if (state is ChecklistLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF4ECDC4),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    AppLocalizations.of(context).loaderChecklist,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ChecklistError) {
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
                      AppLocalizations.of(context).error,
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
                        context.read<ChecklistCubit>().loadChecklist(widget.checklistId);
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
                        AppLocalizations.of(context).retry,
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

          if (state is ChecklistSubmitting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    color: Color(0xFF4ECDC4),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    AppLocalizations.of(context).checklistSubmission,
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ChecklistLoaded) {
            return Column(
              children: [
                _buildProgressCard(state, theme, isDark),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                    itemCount: state.checklist.items.length,
                    itemBuilder: (context, index) {
                      final item = state.checklist.items[index];
                      final isChecked = state.itemStates[item.id] ?? false;
                      return _buildChecklistItem(
                        item,
                        isChecked,
                        theme,
                        isDark,
                      );
                    },
                  ),
                ),
                _buildSubmitButton(state, theme, isDark),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildChecklistItem(
    dynamic item,
    bool isChecked,
    ThemeData theme,
    bool isDark,
  ) {
    return BlocBuilder<ChecklistCubit, ChecklistState>(
      builder: (context, state) {
        final note = state is ChecklistLoaded ? (state.itemNotes[item.id] ?? '') : '';
        
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: isDark ? const Color(0xFF1A1A24) : Colors.white,
            border: Border.all(
              color: isChecked
                  ? const Color(0xFF4ECDC4)
                  : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E5EA)),
              width: isChecked ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              CheckboxListTile(
                value: isChecked,
                onChanged: (value) {
                  context.read<ChecklistCubit>().toggleItem(item.id);
                },
                title: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: item.description != null
                    ? Padding(
                        padding: EdgeInsets.only(top: 4.h),
                        child: Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : null,
                activeColor: const Color(0xFF4ECDC4),
                checkColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 12.h),
                child: TextField(
                  controller: TextEditingController(text: note)
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: note.length),
                    ),
                  onChanged: (value) {
                    context.read<ChecklistCubit>().updateItemNote(item.id, value);
                  },
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).addNoteOptional,
                    hintStyle: TextStyle(
                      fontSize: 13.sp,
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
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    prefixIcon: Icon(
                      Icons.note_outlined,
                      size: 18.sp,
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.done,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(ChecklistLoaded state, ThemeData theme, bool isDark) {
    final progress = state.progress;
    final completedCount = state.itemStates.values.where((v) => v).length;
    final totalCount = state.checklist.items.length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
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
                    AppLocalizations.of(context).overallProgress,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '$completedCount of $totalCount',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              Container(
                width: 70.w,
                height: 70.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF44B3AA)],
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
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
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
    );
  }

  Widget _buildSubmitButton(
    ChecklistLoaded state,
    ThemeData theme,
    bool isDark,
  ) {
    final canSubmit = state.progress == 1.0;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A24) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: canSubmit
              ? () {
                  context.read<ChecklistCubit>().submitChecklist();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canSubmit
                ? const Color(0xFF4ECDC4)
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 16.h),
            elevation: 0,
            minimumSize: Size(double.infinity, 56.h),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context).submitChecklist,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Icons.check_circle_rounded,
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
