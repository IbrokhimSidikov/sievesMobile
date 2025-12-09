import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CheckboxFieldWidget extends StatelessWidget {
  final bool value;
  final Function(bool) onChanged;

  const CheckboxFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: value
              ? const Color(0xFF4ECDC4).withOpacity(0.1)
              : isDark
                  ? const Color(0xFF252532)
                  : const Color(0xFFF5F5F7),
          border: Border.all(
            color: value
                ? const Color(0xFF4ECDC4)
                : isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE5E5EA),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: value
                    ? const LinearGradient(
                        colors: [Color(0xFF4ECDC4), Color(0xFF44B3AA)],
                      )
                    : null,
                border: Border.all(
                  color: value
                      ? Colors.transparent
                      : isDark
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF9CA3AF),
                  width: 2,
                ),
              ),
              child: value
                  ? Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18.sp,
                    )
                  : null,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                value ? 'Completed' : 'Mark as complete',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: value
                      ? const Color(0xFF4ECDC4)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
