import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';

class EmployeeProductivity extends StatelessWidget {
  const EmployeeProductivity({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    theme.scaffoldBackgroundColor,
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerHighest,
                  ]
                : [
                    AppColors.cxWhite,
                    AppColors.cxF5F7F9,
                    AppColors.cxF7F6F9,
                  ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, localizations, isDark, theme),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildProductivityCard(
                        context,
                        title: localizations.productivityTimerCard,
                        subtitle: localizations.productivityTimerCardSubtitle,
                        icon: Icons.timer_outlined,
                        gradientColors: [
                          AppColors.cxRoyalBlue,
                          AppColors.cxRoyalBlue.withOpacity(0.8),
                        ],
                        onTap: () => context.push('/productivityTimer'),
                        isDark: isDark,
                        theme: theme,
                      ),
                      SizedBox(height: 24.h),
                      _buildProductivityCard(
                        context,
                        title: localizations.matrixQualification,
                        subtitle: localizations.matrixQualificationSubtitle,
                        icon: Icons.grid_on_outlined,
                        gradientColors: [
                          AppColors.cxPurple,
                          AppColors.cxPurple.withOpacity(0.8),
                        ],
                        onTap: () => context.push('/matrixQualificationPage'),
                        isDark: isDark,
                        theme: theme,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppLocalizations localizations, bool isDark, ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  theme.colorScheme.primary,
                  theme.colorScheme.primaryContainer,
                ]
              : [
                  AppColors.cx43C19F,
                  AppColors.cx4AC1A7,
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? theme.colorScheme.primary.withOpacity(0.3)
                : AppColors.cx43C19F.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.cxWhite.withOpacity(isDark ? 0.15 : 0.2),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: AppColors.cxWhite.withOpacity(isDark ? 0.2 : 0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: AppColors.cxWhite,
                  size: 32.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.employeeProductivity,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cxWhite,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      localizations.employeeProductivitySubtitle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.cxWhite.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductivityCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    required bool isDark,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    gradientColors[0].withOpacity(0.8),
                    gradientColors[1].withOpacity(0.6),
                  ]
                : gradientColors,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(isDark ? 0.3 : 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: gradientColors[0].withOpacity(isDark ? 0.15 : 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
          border: Border.all(
            color: isDark
                ? AppColors.cxWhite.withOpacity(0.1)
                : AppColors.cxWhite.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.cxWhite.withOpacity(isDark ? 0.15 : 0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.cxWhite.withOpacity(isDark ? 0.2 : 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: AppColors.cxWhite,
                size: 40.sp,
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cxWhite,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.cxWhite.withOpacity(0.9),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.cxWhite.withOpacity(isDark ? 0.15 : 0.2),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.cxWhite,
                size: 20.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
