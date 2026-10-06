import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/model/day_session_announcement_model.dart';
import '../../../core/services/api/api_service.dart';
import '../../../core/theme/app_tokens.dart';
import 'rate_calculator_sheet.dart';

/// Local currency the rates are expressed in.
const String _localCurrency = 'UZS';

/// Bottom sheet where an allowed employee sets today's buy and sell rates.
/// Resolves with the refreshed announcement after a successful save, null
/// when dismissed.
Future<DaySessionAnnouncement?> showRateEditorSheet(
  BuildContext context,
  DaySessionAnnouncement announcement, {
  required ApiService apiService,
}) {
  return showModalBottomSheet<DaySessionAnnouncement>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.tokens.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
    ),
    builder: (_) =>
        _RateEditorSheet(announcement: announcement, apiService: apiService),
  );
}

class _RateEditorSheet extends StatefulWidget {
  final DaySessionAnnouncement announcement;
  final ApiService apiService;

  const _RateEditorSheet({
    required this.announcement,
    required this.apiService,
  });

  @override
  State<_RateEditorSheet> createState() => _RateEditorSheetState();
}

class _RateEditorSheetState extends State<_RateEditorSheet> {
  late final _buyController = TextEditingController(
    text: _initial(widget.announcement.buyAmount),
  );
  late final _sellController = TextEditingController(
    text: _initial(widget.announcement.sellAmount),
  );
  final _sellFocus = FocusNode();
  bool _saving = false;
  String? _error;

  static String _initial(double? value) =>
      value == null ? '' : formatRateAmount(value);

  @override
  void dispose() {
    _buyController.dispose();
    _sellController.dispose();
    _sellFocus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    final buy = parseRateAmount(_buyController.text);
    final sell = parseRateAmount(_sellController.text);
    if (buy == null || sell == null || buy <= 0 || sell <= 0) {
      setState(() => _error = l.ratesRequired);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.apiService.setDaySessionAnnouncement(
        buyAmount: buy,
        sellAmount: sell,
      );
      if (!mounted) return;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(l.ratesSaved)));
      Navigator.of(context).pop(updated);
    } on DaySessionAnnouncementException catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = '${l.ratesSaveFailed}: ${e.message}';
      });
    }
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
              l.setDayRates,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: tokens.textPrimary,
              ),
            ),
            if (widget.announcement.date != null) ...[
              SizedBox(height: 4.h),
              Text(
                widget.announcement.date!,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: tokens.primary,
                ),
              ),
            ],
            SizedBox(height: 16.h),
            _FieldLabel(l.buyRate),
            RateAmountField(
              controller: _buyController,
              currency: _localCurrency,
              autofocus: true,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => _sellFocus.requestFocus(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            SizedBox(height: 12.h),
            _FieldLabel(l.sellRate),
            RateAmountField(
              controller: _sellController,
              focusNode: _sellFocus,
              currency: _localCurrency,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error != null) ...[
              SizedBox(height: 8.h),
              Text(
                _error!,
                style: TextStyle(fontSize: 12.sp, color: tokens.error),
              ),
            ],
            SizedBox(height: 20.h),
            SizedBox(
              height: 52.h,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: tokens.primary,
                  foregroundColor: tokens.textOnAccent,
                  disabledBackgroundColor: tokens.primary.withValues(
                    alpha: 0.4,
                  ),
                  disabledForegroundColor: tokens.textOnAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  textStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20.sp,
                        height: 20.sp,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: tokens.textOnAccent,
                        ),
                      )
                    : Text(l.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: context.tokens.textSecondary,
        ),
      ),
    );
  }
}
