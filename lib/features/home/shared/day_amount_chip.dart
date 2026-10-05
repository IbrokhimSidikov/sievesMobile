import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/model/day_session_announcement_model.dart';
import '../../../core/theme/app_tokens.dart';
import 'rate_calculator_sheet.dart';

/// Compact pill next to the employee status badge on the home page showing
/// the day's rate set by an admin ("-" when not set). Tapping it opens the
/// rate calculator.
class DayAmountChip extends StatelessWidget {
  final DaySessionAnnouncement announcement;

  const DayAmountChip({super.key, required this.announcement});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final amount = announcement.amount;
    final currency = announcement.currencyCode ?? announcement.currencySymbol;
    final isSet = amount != null;
    // Unset rate: quiet neutral pill; set rate: indigo-tinted, tappable.
    final accent = isSet ? tokens.primary : tokens.textTertiary;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          if (isSet)
            BoxShadow(
              color: tokens.primary.withValues(alpha: 0.18),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Material(
        color: isSet ? tokens.primaryContainer : tokens.surfaceTint,
        shape: StadiumBorder(
          side: BorderSide(color: accent.withValues(alpha: 0.30)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isSet
              ? () => showRateCalculatorSheet(context, announcement)
              : null,
          child: Padding(
            padding: EdgeInsets.fromLTRB(4.w, 4.h, 10.w, 4.h),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 19.sp,
                  height: 19.sp,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.currency_exchange_rounded,
                    size: 11.sp,
                    color: tokens.surface,
                  ),
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        if (isSet && currency != null)
                          TextSpan(
                            text: '$currency ',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: tokens.textSecondary,
                            ),
                          ),
                        TextSpan(
                          text: isSet ? formatRateAmount(amount) : '-',
                        ),
                      ],
                    ),
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: isSet ? tokens.textPrimary : tokens.textSecondary,
                      letterSpacing: 0.3,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSet) ...[
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 14.sp,
                    color: tokens.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
