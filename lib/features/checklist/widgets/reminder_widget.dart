import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../models/checklist_field_model.dart';

class ReminderWidget extends StatelessWidget {
  final ChecklistField field;
  final ThemeData theme;
  final bool isDark;

  const ReminderWidget({
    super.key,
    required this.field,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final reminderDateStr = field.metadata?['reminderDate'] as String?;
    final reminderDate = reminderDateStr != null
        ? DateTime.tryParse(reminderDateStr)
        : null;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFBBF24).withOpacity(0.1),
            const Color(0xFFF59E0B).withOpacity(0.1),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFFBBF24),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBF24).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_rounded,
              color: const Color(0xFFF59E0B),
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
                if (reminderDate != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    'Due: ${DateFormat('dd MMM yyyy, HH:mm').format(reminderDate)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: const Color(0xFFF59E0B),
            size: 16.sp,
          ),
        ],
      ),
    );
  }
}
