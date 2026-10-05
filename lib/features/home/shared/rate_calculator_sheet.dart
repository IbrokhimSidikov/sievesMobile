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

double? _parse(String text) =>
    double.tryParse(text.replaceAll(' ', '').replaceAll(',', '.'));

/// Two-way converter between the announcement's currency and UZS, using the
/// day's amount as the rate: 1 [currency] = amount UZS.
Future<void> showRateCalculatorSheet(
  BuildContext context,
  DaySessionAnnouncement announcement,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.tokens.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (_) => _RateCalculatorSheet(
      rate: announcement.amount!,
      foreignCurrency:
          announcement.currencyCode ??
          announcement.currencySymbol ??
          _defaultForeignCurrency,
    ),
  );
}

class _RateCalculatorSheet extends StatefulWidget {
  final double rate;
  final String foreignCurrency;

  const _RateCalculatorSheet({
    required this.rate,
    required this.foreignCurrency,
  });

  @override
  State<_RateCalculatorSheet> createState() => _RateCalculatorSheetState();
}

class _RateCalculatorSheetState extends State<_RateCalculatorSheet> {
  final _foreignController = TextEditingController(text: '1');
  late final _localController = TextEditingController(
    text: formatRateAmount(widget.rate),
  );

  @override
  void dispose() {
    _foreignController.dispose();
    _localController.dispose();
    super.dispose();
  }

  void _onForeignChanged(String text) {
    final value = _parse(text);
    _localController.text = value == null
        ? ''
        : formatRateAmount(value * widget.rate);
  }

  void _onLocalChanged(String text) {
    final value = _parse(text);
    _foreignController.text = value == null || widget.rate == 0
        ? ''
        : formatRateAmount(value / widget.rate);
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
            Text(
              l.rateCalculator,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              '1 ${widget.foreignCurrency} = '
              '${formatRateAmount(widget.rate)} $_localCurrency',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: tokens.primary,
              ),
            ),
            SizedBox(height: 16.h),
            _AmountField(
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
            _AmountField(
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

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const _AmountField({
    required this.controller,
    required this.currency,
    required this.onChanged,
    this.autofocus = false,
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
      autofocus: autofocus,
      onChanged: onChanged,
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
