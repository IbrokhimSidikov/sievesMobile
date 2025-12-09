import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../cubit/checklist_cubit.dart';
import '../cubit/checklist_state.dart';
import '../widgets/checklist_field_widget.dart';

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
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    context.read<ChecklistCubit>().loadChecklist(widget.checklistId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                state.checklist.title,
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
                    'Loading checklist...',
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
                    'Submitting checklist...',
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
            final sections = state.checklist.sections;
            
            return Column(
              children: [
                _buildProgressCard(state, theme, isDark),
                _buildSectionIndicator(sections.length, theme, isDark),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: sections.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final section = sections[index];
                      return _buildSectionPage(section, state, theme, isDark);
                    },
                  ),
                ),
                _buildNavigationButtons(sections.length, state, theme, isDark),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProgressCard(ChecklistLoaded state, ThemeData theme, bool isDark) {
    final progress = state.progress;
    final completedCount = (progress * state.checklist.sections.fold<int>(
      0,
      (sum, section) => sum + section.fields.where((f) => f.isRequired).length,
    )).round();
    final totalCount = state.checklist.sections.fold<int>(
      0,
      (sum, section) => sum + section.fields.where((f) => f.isRequired).length,
    );

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
                    'Overall Progress',
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

  Widget _buildSectionIndicator(int totalSections, ThemeData theme, bool isDark) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          totalSections,
          (index) => Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w),
            width: _currentPage == index ? 24.w : 8.w,
            height: 8.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              color: _currentPage == index
                  ? const Color(0xFF4ECDC4)
                  : isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E5EA),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionPage(
    dynamic section,
    ChecklistLoaded state,
    ThemeData theme,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4ECDC4).withOpacity(0.1),
                  const Color(0xFF44B3AA).withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: const Color(0xFF4ECDC4).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ECDC4).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.list_alt_rounded,
                        color: const Color(0xFF4ECDC4),
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        section.title,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (section.description != null) ...[
                  SizedBox(height: 12.h),
                  Text(
                    section.description!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 20.h),
          ...section.fields.map<Widget>((field) {
            return ChecklistFieldWidget(
              field: field,
              value: state.fieldValues[field.id],
              onChanged: (value) {
                context.read<ChecklistCubit>().updateField(field.id, value);
              },
            );
          }).toList(),
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons(
    int totalSections,
    ChecklistLoaded state,
    ThemeData theme,
    bool isDark,
  ) {
    final isFirstPage = _currentPage == 0;
    final isLastPage = _currentPage == totalSections - 1;
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
        child: Row(
          children: [
            if (!isFirstPage)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _pageController.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: const Color(0xFF4ECDC4),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back_rounded,
                        color: const Color(0xFF4ECDC4),
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Previous',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4ECDC4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (!isFirstPage) SizedBox(width: 12.w),
            Expanded(
              flex: isFirstPage ? 1 : 1,
              child: ElevatedButton(
                onPressed: isLastPage
                    ? (canSubmit
                        ? () {
                            context.read<ChecklistCubit>().submitChecklist(1);
                          }
                        : null)
                    : () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: canSubmit || !isLastPage
                      ? const Color(0xFF4ECDC4)
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastPage ? 'Submit' : 'Next',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(
                      isLastPage
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                      size: 20.sp,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
