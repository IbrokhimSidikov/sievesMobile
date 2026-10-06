import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/model/day_session_announcement_model.dart';
import '../../../core/theme/app_tokens.dart';

/// Local currency the day's rate converts into.
const String _localCurrency = 'UZS';

/// Currency shown when the admin left the currency empty.
const String _defaultForeignCurrency = 'USD';

final NumberFormat _format = NumberFormat('#,##0.##', 'en_US');

/// `12650.5` -> `12 650.5`
String formatRateAmount(double value) =>
    _format.format(value).replaceAll(',', ' ');

/// `12 650.5` / `12,650.5` -> `12650.5`
double? parseRateAmount(String text) =>
    double.tryParse(text.replaceAll(' ', '').replaceAll(',', '.'));

/// Why the calculator sheet was closed.
enum RateSheetAction {
  /// The editor tapped "Edit rates"; the caller opens the editor sheet.
  edit,
}

enum _RateSide { buy, sell }

/// Two-way converter between the announcement's currency and UZS, using the
/// day's buy or sell rate (switchable): 1 [currency] = rate UZS.
/// Resolves with [RateSheetAction.edit] when an editor asks to change the
/// rates, null otherwise.
Future<RateSheetAction?> showRateCalculatorSheet(
  BuildContext context,
  DaySessionAnnouncement announcement,
) {
  return showModalBottomSheet<RateSheetAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.tokens.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (_) => _RateCalculatorSheet(
      buyRate: announcement.buyAmount!,
      sellRate: announcement.sellAmount!,
      canEdit: announcement.canEdit,
      foreignCurrency:
          announcement.currencyCode ??
          announcement.currencySymbol ??
          _defaultForeignCurrency,
    ),
  );
}

class _RateCalculatorSheet extends StatefulWidget {
  final double buyRate;
  final double sellRate;
  final bool canEdit;
  final String foreignCurrency;

  const _RateCalculatorSheet({
    required this.buyRate,
    required this.sellRate,
    required this.canEdit,
    required this.foreignCurrency,
  });

  @override
  State<_RateCalculatorSheet> createState() => _RateCalculatorSheetState();
}

class _RateCalculatorSheetState extends State<_RateCalculatorSheet> {
  _RateSide _side = _RateSide.buy;
  final _foreignController = TextEditingController(text: '1');
  late final _localController = TextEditingController(
    text: formatRateAmount(_rate),
  );

  double get _rate => _side == _RateSide.buy ? widget.buyRate : widget.sellRate;

  @override
  void dispose() {
    _foreignController.dispose();
    _localController.dispose();
    super.dispose();
  }

  void _onForeignChanged(String text) {
    final value = parseRateAmount(text);
    _localController.text = value == null
        ? ''
        : formatRateAmount(value * _rate);
  }

  void _onLocalChanged(String text) {
    final value = parseRateAmount(text);
    _foreignController.text = value == null || _rate == 0
        ? ''
        : formatRateAmount(value / _rate);
  }

  void _onSideChanged(_RateSide side) {
    if (side == _side) return;
    HapticFeedback.selectionClick();
    setState(() => _side = side);
    // Keep the foreign amount, recompute the local one with the new rate.
    _onForeignChanged(_foreignController.text);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20.w,
        12.h,
        20.w,
        20.h + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: tokens.outlineStrong,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.rateCalculator,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                if (widget.canEdit)
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.of(context).pop(RateSheetAction.edit),
                    icon: Icon(Icons.edit_rounded, size: 16.sp),
                    label: Text(l.editRates),
                    style: TextButton.styleFrom(
                      foregroundColor: tokens.primary,
                      textStyle: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 12.h),
            _SideToggle(
              side: _side,
              buyLabel: '${l.buyLabel} · ${formatRateAmount(widget.buyRate)}',
              sellLabel:
                  '${l.sellLabel} · ${formatRateAmount(widget.sellRate)}',
              onChanged: _onSideChanged,
            ),
            SizedBox(height: 12.h),
            Text(
              '1 ${widget.foreignCurrency} = '
              '${formatRateAmount(_rate)} $_localCurrency',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: tokens.primary,
              ),
            ),
            SizedBox(height: 16.h),
            RateAmountField(
              controller: _foreignController,
              currency: widget.foreignCurrency,
              onChanged: _onForeignChanged,
              autofocus: true,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Icon(
                Icons.swap_vert_rounded,
                size: 22.sp,
                color: tokens.textSecondary,
              ),
            ),
            RateAmountField(
              controller: _localController,
              currency: _localCurrency,
              onChanged: _onLocalChanged,
            ),
            SizedBox(height: 12.h),
            Text(
              l.rateCalculatorHint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.sp, color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill tabs (design.md §7.12) choosing between the buy and sell rate.
class _SideToggle extends StatelessWidget {
  final _RateSide side;
  final String buyLabel;
  final String sellLabel;
  final ValueChanged<_RateSide> onChanged;

  const _SideToggle({
    required this.side,
    required this.buyLabel,
    required this.sellLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget pill(_RateSide value, String label) {
      final selected = value == side;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: Semantics(
            button: true,
            selected: selected,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 36.h,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? (isDark ? tokens.surfaceElevated : tokens.surface)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8.r),
                boxShadow: [
                  if (selected && !isDark)
                    BoxShadow(
                      color: tokens.shadow.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: selected ? tokens.textPrimary : tokens.textSecondary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: tokens.surfaceTint,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          pill(_RateSide.buy, buyLabel),
          pill(_RateSide.sell, sellLabel),
        ],
      ),
    );
  }
}

/// Large numeric input with a currency suffix, shared by the calculator and
/// the rate editor.
class RateAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const RateAmountField({
    super.key,
    required this.controller,
    required this.currency,
    this.onChanged,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide(color: tokens.outlineStrong),
    );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9., ]'))],
      style: TextStyle(
        fontSize: 22.sp,
        fontWeight: FontWeight.w700,
        color: tokens.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: tokens.surfaceTint,
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: BorderSide(color: tokens.primary, width: 1.5),
        ),
        suffixIcon: Padding(
          padding: EdgeInsets.only(right: 16.w),
          child: Center(
            widthFactor: 1,
            child: Text(
              currency,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: tokens.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
