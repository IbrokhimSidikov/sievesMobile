import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class DateFieldWidget extends StatelessWidget {
  final DateTime? value;
  final Function(DateTime?) onChanged;
  final ThemeData theme;
  final bool isDark;

  const DateFieldWidget({
    super.key,
    required this.value,
    required this.onChanged,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: isDark ? const Color(0xFF252532) : const Color(0xFFF5F5F7),
          border: Border.all(
            color: value != null
                ? const Color(0xFF4ECDC4)
                : isDark
                    ? const Color(0xFF374151)
                    : const Color(0xFFE5E5EA),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              color: value != null
                  ? const Color(0xFF4ECDC4)
                  : theme.colorScheme.onSurfaceVariant,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                value != null
                    ? DateFormat('dd MMM yyyy').format(value!)
                    : 'Select date',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: value != null ? FontWeight.w500 : FontWeight.w400,
                  color: value != null
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ),
            if (value != null)
              IconButton(
                icon: Icon(
                  Icons.clear_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 20.sp,
                ),
                onPressed: () => onChanged(null),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            colorScheme: theme.colorScheme.copyWith(
              primary: const Color(0xFF4ECDC4),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onChanged(picked);
    }
  }
}
