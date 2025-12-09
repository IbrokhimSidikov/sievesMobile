import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/checklist_field_model.dart';
import 'checkbox_field_widget.dart';
import 'text_field_widget.dart';
import 'number_field_widget.dart';
import 'date_field_widget.dart';
import 'reminder_widget.dart';

class ChecklistFieldWidget extends StatelessWidget {
  final ChecklistField field;
  final dynamic value;
  final Function(dynamic) onChanged;

  const ChecklistFieldWidget({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        color: isDark ? const Color(0xFF1A1A24) : const Color(0xFFFFFFFF),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E5EA),
          width: 1.5,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (field.isRequired)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
            ],
          ),
          if (field.description != null) ...[
            SizedBox(height: 6.h),
            Text(
              field.description!,
              style: TextStyle(
                fontSize: 13.sp,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          _buildFieldInput(context, theme, isDark),
        ],
      ),
    );
  }

  Widget _buildFieldInput(BuildContext context, ThemeData theme, bool isDark) {
    switch (field.type) {
      case ChecklistFieldType.checkbox:
        return CheckboxFieldWidget(
          value: value ?? false,
          onChanged: onChanged,
        );
      case ChecklistFieldType.text:
        return TextFieldWidget(
          value: value?.toString() ?? '',
          onChanged: onChanged,
          theme: theme,
          isDark: isDark,
        );
      case ChecklistFieldType.number:
        return NumberFieldWidget(
          value: value?.toString() ?? '',
          onChanged: onChanged,
          theme: theme,
          isDark: isDark,
          metadata: field.metadata,
        );
      case ChecklistFieldType.date:
        return DateFieldWidget(
          value: value as DateTime?,
          onChanged: onChanged,
          theme: theme,
          isDark: isDark,
        );
      case ChecklistFieldType.reminder:
        return ReminderWidget(
          field: field,
          theme: theme,
          isDark: isDark,
        );
      default:
        return Text(
          'Unsupported field type: ${field.type.name}',
          style: TextStyle(
            fontSize: 14.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        );
    }
  }
}
