/// Amount an admin set for the branch's current day session.
///
/// [amount] is null when nothing was set for the day session yet; the home
/// page then shows "-". [canView] is false for employees who are neither a
/// manager nor a director; the home page hides the amount for them.
class DaySessionAnnouncement {
  final bool canView;
  final int? daySessionId;
  final String? date;
  final double? amount;
  final String? currencyCode;
  final String? currencySymbol;
  final String? note;

  const DaySessionAnnouncement({
    this.canView = false,
    this.daySessionId,
    this.date,
    this.amount,
    this.currencyCode,
    this.currencySymbol,
    this.note,
  });

  factory DaySessionAnnouncement.fromJson(Map<String, dynamic> json) {
    final currency = json['currency'] as Map<String, dynamic>?;
    final rawAmount = json['amount'];
    return DaySessionAnnouncement(
      canView: json['can_view'] == true,
      daySessionId: json['day_session_id'] as int?,
      date: json['date'] as String?,
      amount: rawAmount == null ? null : double.tryParse(rawAmount.toString()),
      currencyCode: currency?['code'] as String?,
      currencySymbol: currency?['symbol'] as String?,
      note: json['note'] as String?,
    );
  }
}
