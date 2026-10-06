/// Buy and sell rates an admin set for the branch's current day session.
///
/// [buyAmount] / [sellAmount] are null when nothing was set for the day
/// session yet; the home page then shows "-". [canView] is false for
/// employees who are neither a manager nor a director; the home page hides
/// the chip for them. [canEdit] is true only for the few employees allowed
/// to set the rates from the app.
class DaySessionAnnouncement {
  final bool canView;
  final bool canEdit;
  final int? daySessionId;
  final String? date;
  final double? buyAmount;
  final double? sellAmount;
  final String? currencyCode;
  final String? currencySymbol;
  final String? note;

  const DaySessionAnnouncement({
    this.canView = false,
    this.canEdit = false,
    this.daySessionId,
    this.date,
    this.buyAmount,
    this.sellAmount,
    this.currencyCode,
    this.currencySymbol,
    this.note,
  });

  /// Both rates were set for the day.
  bool get isSet => buyAmount != null && sellAmount != null;

  factory DaySessionAnnouncement.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as Map<String, dynamic>?;
    return DaySessionAnnouncement(
      canView: json['can_view'] == true,
      canEdit: json['can_edit'] == true,
      daySessionId: json['day_session_id'] as int?,
      date: json['date'] as String?,
      buyAmount: _toDouble(json['buy_amount']),
      sellAmount: _toDouble(json['sell_amount']),
      currencyCode: currency?['code'] as String?,
      currencySymbol: currency?['symbol'] as String?,
      note: json['note'] as String?,
    );
  }

  static double? _toDouble(Object? raw) =>
      raw == null ? null : double.tryParse(raw.toString());
}

/// Thrown by [ApiService.setDaySessionAnnouncement] with the server's reason
/// (e.g. 403 for employees who are not allowed to set the rates).
class DaySessionAnnouncementException implements Exception {
  final String message;
  final int? statusCode;

  DaySessionAnnouncementException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
