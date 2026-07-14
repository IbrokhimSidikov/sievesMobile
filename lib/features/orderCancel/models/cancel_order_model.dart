// Models for the cancel-cheque (Otmen chek) feature.
//
// Mirrors the data used by the web `cancel-cheque` component: a list of
// cancelled orders, plus the detail (order items, cashier, type) needed to
// render and submit a cancellation.

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().split('.').first) ?? 0;
}

class CancelOrderItem {
  final String productName;
  final int quantity;
  final int actualPrice;

  CancelOrderItem({
    required this.productName,
    required this.quantity,
    required this.actualPrice,
  });

  int get lineTotal => quantity * actualPrice;

  factory CancelOrderItem.fromJson(Map<String, dynamic> json) {
    return CancelOrderItem(
      productName: json['product']?['name']?.toString() ?? 'Product',
      quantity: _asInt(json['quantity']),
      actualPrice: _asInt(json['actual_price']),
    );
  }
}

class CancelOrder {
  final int id;
  final String receiptNumber;
  final int value;
  final String? startTime;
  final String? employeeName;
  final String? orderTypeName;
  final String? branchName;
  final List<CancelOrderItem> orderItems;

  /// The raw JSON as returned by the API. Kept intact so it can be sent back
  /// verbatim on the cancel (PUT ?cancel=1) request, matching the web flow.
  final Map<String, dynamic> raw;

  CancelOrder({
    required this.id,
    required this.receiptNumber,
    required this.value,
    this.startTime,
    this.employeeName,
    this.orderTypeName,
    this.branchName,
    this.orderItems = const [],
    this.raw = const {},
  });

  factory CancelOrder.fromJson(Map<String, dynamic> json) {
    final items = (json['orderItems'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(CancelOrderItem.fromJson)
            .toList() ??
        <CancelOrderItem>[];

    return CancelOrder(
      id: _asInt(json['id']),
      receiptNumber: json['receipt_number']?.toString() ?? '—',
      value: _asInt(json['value']),
      startTime: json['start_time']?.toString(),
      employeeName:
          json['employee']?['individual']?['full_name']?.toString(),
      orderTypeName: json['orderType']?['name']?.toString(),
      branchName: json['branch']?['name']?.toString(),
      orderItems: items,
      raw: json,
    );
  }
}

/// A person who can be selected as a witness ("Кто в курсе").
class Witness {
  final int id;
  final String fullName;

  Witness({required this.id, required this.fullName});

  @override
  bool operator ==(Object other) => other is Witness && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
