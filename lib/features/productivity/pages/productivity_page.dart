import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/navigation/app_modules.dart';
import '../../../core/services/auth/auth_manager.dart';
import '../../../core/theme/app_tokens.dart';

/// "Productivity" tab: a hub listing the modules tagged
/// [ModuleGroup.productivity] in `AppModules`.
///
/// Which modules belong here is decided in `lib/core/navigation/app_modules.dart`
/// by setting a module's `group`; this page only renders the list.
class ProductivityPage extends StatelessWidget {
  const ProductivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final tokens = context.tokens;
    final modules = AppModules.inGroup(
      ModuleGroup.productivity,
      l,
      AuthManager(),
    );

    return Scaffold(
      backgroundColor: tokens.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.productivity,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      height: 1.25,
                      color: tokens.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    l.productivitySubtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                      color: tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            Expanded(
              child: modules.isEmpty
                  ? _EmptyState(message: l.noProductivityModules)
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20.w,
                        0,
                        20.w,
                        24.h + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: modules.length,
                      separatorBuilder: (_, __) => SizedBox(height: 12.h),
                      itemBuilder: (context, index) =>
                          _ModuleCard(module: modules[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable `raised` card: accent icon tile, title, subtitle, chevron.
class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final AppModule module;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final accent = module.accent.resolve(context);

    return Semantics(
      button: true,
      label: module.title,
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: () => context.push(module.route),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: tokens.outline),
              boxShadow: [
                BoxShadow(
                  color: tokens.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: accent.withValues(alpha: 0.20)),
                  ),
                  child: Icon(module.icon, size: 24.sp, color: accent),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        module.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      if (module.subtitle != null) ...[
                        SizedBox(height: 2.h),
                        Text(
                          module.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: tokens.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20.sp,
                  color: tokens.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights_rounded, size: 64.sp, color: tokens.textTertiary),
            SizedBox(height: 16.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: tokens.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
