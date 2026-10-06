import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/model/day_session_announcement_model.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/theme/app_tokens.dart';
import 'rate_calculator_sheet.dart';
import 'rate_editor_sheet.dart';

/// Compact pill next to the page title on the home page showing the day's
/// buy and sell rates set by an admin ("-" when not set). Tapping it opens
/// the rate calculator; editors can set the rates from there (or directly
/// when nothing is set yet). [apiService] performs the save; [onChanged]
/// receives the refreshed announcement after a successful one.
class DayAmountChip extends StatelessWidget {
  final DaySessionAnnouncement announcement;
  final ApiService apiService;
  final ValueChanged<DaySessionAnnouncement>? onChanged;

  const DayAmountChip({
    super.key,
    required this.announcement,
    required this.apiService,
    this.onChanged,
  });

  Future<void> _onTap(BuildContext context) async {
    if (announcement.isSet) {
      final action = await showRateCalculatorSheet(context, announcement);
      if (action != RateSheetAction.edit || !context.mounted) return;
    }
    final updated = await showRateEditorSheet(
      context,
      announcement,
      apiService: apiService,
    );
    if (updated != null) onChanged?.call(updated);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l = AppLocalizations.of(context);
    final isSet = announcement.isSet;
    final canEdit = announcement.canEdit;
    final tappable = isSet || canEdit;
    final currency = announcement.currencyCode ?? announcement.currencySymbol;
    // Unset rate: quiet neutral pill; set rate: indigo-tinted.
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
          onTap: tappable ? () => _onTap(context) : null,
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
                if (isSet)
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RateLine(
                          label: l.buyLabel,
                          amount: announcement.buyAmount!,
                          currency: currency,
                        ),
                        SizedBox(height: 1.h),
                        _RateLine(
                          label: l.sellLabel,
                          amount: announcement.sellAmount!,
                          currency: currency,
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    '-',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: tokens.textSecondary,
                      height: 1.2,
                    ),
                  ),
                if (tappable) ...[
                  SizedBox(width: 4.w),
                  Icon(
                    isSet ? Icons.chevron_right_rounded : Icons.edit_rounded,
                    size: isSet ? 14.sp : 12.sp,
                    color: isSet ? tokens.primary : tokens.textSecondary,
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

/// One "Buy 12 650" row inside the chip.
class _RateLine extends StatelessWidget {
  final String label;
  final double amount;
  final String? currency;

  const _RateLine({
    required this.label,
    required this.amount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
          TextSpan(text: formatRateAmount(amount)),
          if (currency != null)
            TextSpan(
              text: ' $currency',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: tokens.textSecondary,
              ),
            ),
        ],
      ),
      style: TextStyle(
        fontSize: 10.sp,
        fontWeight: FontWeight.w800,
        color: tokens.textPrimary,
        letterSpacing: 0.2,
        height: 1.2,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
