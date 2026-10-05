import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_tokens.dart';

/// Compact bottom sheet explaining one salary step: overline "Step", the
/// step name as title, and the `t_salary_structure.description` text.
/// Layout follows design.md §7.8 (r28 top corners, grab handle, 20 gutter).
Future<void> showSalaryStepSheet(
  BuildContext context, {
  required String name,
  required String description,
}) {
  final tokens = context.tokens;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: tokens.surface,
    barrierColor: tokens.textPrimary.withValues(alpha: 0.45),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (_) => _SalaryStepSheet(name: name, description: description),
  );
}

class _SalaryStepSheet extends StatelessWidget {
  const _SalaryStepSheet({required this.name, required this.description});

  final String name;
  final String description;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l = AppLocalizations.of(context);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: tokens.outlineStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Container(
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    color: tokens.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: tokens.primary.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Icon(
                    Icons.stairs_rounded,
                    size: 24.sp,
                    color: tokens.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.careerStep.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: tokens.textSecondary,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: Icon(
                    Icons.close_rounded,
                    size: 22.sp,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: tokens.surfaceTint,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: tokens.textPrimary,
                    ),
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

/// Small "i" affordance placed after a step name wherever a hint exists.
class SalaryStepHintIcon extends StatelessWidget {
  const SalaryStepHintIcon({super.key, required this.color, this.size});

  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.info_outline_rounded, size: size ?? 14.sp, color: color);
  }
}
