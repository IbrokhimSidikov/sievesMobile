import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

class NoticeDialog extends StatelessWidget {
  final String title;
  final String message;

  const NoticeDialog({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(maxWidth: 400.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDarkMode
                ? [
                    const Color(0xFF2C2C2E),
                    const Color(0xFF1C1C1E),
                  ]
                : [
                    AppColors.cxWhite,
                    AppColors.cxF5F7F9,
                  ],
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                          AppColors.cxWarning.withOpacity(0.2),
                          AppColors.cxWarning.withOpacity(0.1),
                        ]
                      : [
                          AppColors.cxWarning.withOpacity(0.1),
                          AppColors.cxWarning.withOpacity(0.05),
                        ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Row(
                children: [
                  // Info icon
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.cxWarning,
                          AppColors.cxWarning.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.cxWhite,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  // Title
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode
                            ? AppColors.cxWhite
                            : AppColors.cx1C1C1E,
                      ),
                    ),
                  ),
                  // Close button
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.cxWhite.withOpacity(0.1)
                            : AppColors.cx1C1C1E.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Icon(
                        Icons.close,
                        color: isDarkMode
                            ? AppColors.cxWhite
                            : AppColors.cx1C1C1E,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Message content
            Container(
              padding: EdgeInsets.all(24.w),
              child: SingleChildScrollView(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 15.sp,
                    height: 1.6,
                    color: isDarkMode
                        ? AppColors.cxWhite.withOpacity(0.85)
                        : AppColors.cx1C1C1E.withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
