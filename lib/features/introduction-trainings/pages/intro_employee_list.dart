import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../task-management/models/task_model.dart' show EmployeeBrief;
import '../cubit/intro_employee_cubit.dart';
import '../cubit/intro_employee_state.dart';

// Brand accent for the introduction-trainings feature (matches the entry card).
const Color _accent = AppColors.cx43C19F;

class IntroEmployeeList extends StatelessWidget {
  const IntroEmployeeList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => IntroEmployeeCubit(AuthManager())..loadEmployees(),
      child: const _IntroEmployeeView(),
    );
  }
}

class _IntroEmployeeView extends StatefulWidget {
  const _IntroEmployeeView();

  @override
  State<_IntroEmployeeView> createState() => _IntroEmployeeViewState();
}

class _IntroEmployeeViewState extends State<_IntroEmployeeView> {
  String _query = '';

  List<EmployeeBrief> _filter(List<EmployeeBrief> all) {
    if (_query.trim().isEmpty) return all;
    final q = _query.toLowerCase();
    return all
        .where((e) =>
            e.fullName.toLowerCase().contains(q) ||
            (e.departmentName ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: l.introEmployeesHeader,
              subtitle: l.introEmployeesSubtitle,
              onBack: () => context.pop(),
            ),
            _SearchField(
              hint: l.introSearchHint,
              onChanged: (v) => setState(() => _query = v),
            ),
            Expanded(
              child: BlocBuilder<IntroEmployeeCubit, IntroEmployeeState>(
                builder: (context, state) {
                  if (state is IntroEmployeeLoading ||
                      state is IntroEmployeeInitial) {
                    return const _ListSkeleton();
                  }
                  if (state is IntroEmployeeError) {
                    return _ErrorView(
                      message: state.message,
                      onRetry: () =>
                          context.read<IntroEmployeeCubit>().loadEmployees(),
                    );
                  }
                  if (state is IntroEmployeeLoaded) {
                    final items = _filter(state.employees);
                    return RefreshIndicator(
                      color: _accent,
                      onRefresh: () =>
                          context.read<IntroEmployeeCubit>().loadEmployees(),
                      child: items.isEmpty
                          ? _EmptyView(message: l.introNoEmployees)
                          : ListView.separated(
                              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: items.length,
                              separatorBuilder: (_, __) => SizedBox(height: 10.h),
                              itemBuilder: (_, i) => _EmployeeCard(
                                employee: items[i],
                                progress: state.progress[items[i].id],
                                onTap: () => context.push(
                                  '/introTrainingList',
                                  extra: items[i],
                                ),
                              ),
                            ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onBack;
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 16.w, 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20.sp,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.h),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(Icons.school_outlined, color: _accent, size: 22.sp),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchField({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 10.h),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(fontSize: 14.sp, color: theme.colorScheme.onSurface),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 14.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 20.sp,
            color: theme.colorScheme.onSurface.withOpacity(0.45),
          ),
          filled: true,
          fillColor: isDark
              ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.4)
              : AppColors.cxF5F7F9,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(color: _accent.withOpacity(0.6), width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  final EmployeeBrief employee;
  final EmployeeProgress? progress;
  final VoidCallback onTap;
  const _EmployeeCard({
    required this.employee,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subtitle = (employee.departmentName ?? '').trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark
                  ? theme.colorScheme.onSurface.withOpacity(0.06)
                  : AppColors.cxPlatinumGray,
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
              _EmployeeAvatar(employee: employee),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      employee.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w400,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              _ProgressBadge(progress: progress),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact completion ring shown on the right of each employee card.
class _ProgressBadge extends StatelessWidget {
  final EmployeeProgress? progress;
  const _ProgressBadge({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = 42.r;
    final p = progress;

    // Still loading this employee's summary.
    if (p == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SizedBox(
            width: 16.r,
            height: 16.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.r,
              valueColor: AlwaysStoppedAnimation<Color>(
                _accent.withOpacity(0.4),
              ),
            ),
          ),
        ),
      );
    }

    // No trainings assigned → nothing to measure.
    if (p.total == 0) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.12),
            width: 2,
          ),
        ),
        child: Text(
          '—',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      );
    }

    final allDone = p.percent >= 100;
    final color = allDone ? AppColors.cxSuccess : _accent;

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
              value: p.percent.clamp(0, 100) / 100,
              strokeWidth: 4.r,
              backgroundColor: theme.colorScheme.onSurface.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '${p.percent}%',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeAvatar extends StatelessWidget {
  final EmployeeBrief employee;
  const _EmployeeAvatar({required this.employee});

  String get _initials {
    final parts = employee.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final size = 44.r;
    final placeholder = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accent, AppColors.cx4AC1A7],
        ),
      ),
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.cxWhite,
        ),
      ),
    );

    final url = employee.photoUrl;
    if (url == null || url.isEmpty) return placeholder;

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return placeholder;
        },
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      itemCount: 8,
      separatorBuilder: (_, __) => SizedBox(height: 10.h),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF2A2A32) : const Color(0xFFEDEDED),
        highlightColor:
            isDark ? const Color(0xFF3A3A44) : const Color(0xFFF7F7F7),
        child: Container(
          height: 68.h,
          decoration: BoxDecoration(
            color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
            borderRadius: BorderRadius.circular(16.r),
          ),
          padding: EdgeInsets.all(12.r),
          child: Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 160.w,
                      height: 12.h,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      width: 100.w,
                      height: 10.h,
                      color: Colors.white,
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
}

class _EmptyView extends StatelessWidget {
  final String message;
  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 120.h),
        Icon(
          Icons.people_outline_rounded,
          size: 56.sp,
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
