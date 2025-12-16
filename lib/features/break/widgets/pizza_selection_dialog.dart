import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/model/inventory_model.dart';

class PizzaSelectionDialog extends StatelessWidget {
  final InventoryItem selectedPizza;
  final Function(String) onPizzaTypeSelected; // 'americano' or 'italiano'

  const PizzaSelectionDialog({
    super.key,
    required this.selectedPizza,
    required this.onPizzaTypeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : AppColors.cxWhite,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Select Pizza Type',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: isDark
                          ? theme.colorScheme.surfaceVariant
                          : AppColors.cxF5F7F9,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: 20.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),

            // Pizza name
            Text(
              selectedPizza.name,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 24.h),

            // Americano Button
            GestureDetector(
              onTap: () {
                onPizzaTypeSelected('americano');
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                        : [const Color(0xFF0071E3), const Color(0xFF0077ED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isDark
                                  ? const Color(0xFF6366F1)
                                  : const Color(0xFF0071E3))
                              .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_pizza_rounded,
                      color: AppColors.cxWhite,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Americano',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cxWhite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Italiano Button
            GestureDetector(
              onTap: () {
                onPizzaTypeSelected('italiano');
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cxWarning, AppColors.cxFEDA84],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cxWarning.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_pizza_rounded,
                      color: AppColors.cxWhite,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Italiano',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.cxWhite,
                      ),
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
