class BreakOrderResponse {
  final List<BreakOrder> orders;

  BreakOrderResponse({required this.orders});

  factory BreakOrderResponse.fromJson(List<dynamic> json) {
    return BreakOrderResponse(
      orders: json.map((order) => BreakOrder.fromJson(order)).toList(),
    );
  }
}

class BreakOrder {
  final int id;
  final int branchId;
  final int employeeId;
  final int breakEmployeeId;
  final int? breakPhotoId;
  final int value;
  final int paid;
  final String startTime;
  final String createdAt;
  final List<OrderItem> orderItems;
  final BreakPhoto? breakPhoto;

  BreakOrder({
    required this.id,
    required this.branchId,
    required this.employeeId,
    required this.breakEmployeeId,
    this.breakPhotoId,
    required this.value,
    required this.paid,
    required this.startTime,
    required this.createdAt,
    required this.orderItems,
    this.breakPhoto,
  });

  factory BreakOrder.fromJson(Map<String, dynamic> json) {
    return BreakOrder(
      id: json['id'] ?? 0,
      branchId: json['branch_id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      breakEmployeeId: json['break_employee_id'] ?? 0,
      breakPhotoId: json['break_photo_id'],
      value: json['value'] ?? 0,
      paid: json['paid'] ?? 0,
      startTime: json['start_time'] ?? '',
      createdAt: json['created_at'] ?? '',
      orderItems: json['orderItems'] != null
          ? (json['orderItems'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList()
          : [],
      breakPhoto: json['breakPhoto'] != null
          ? BreakPhoto.fromJson(json['breakPhoto'])
          : null,
    );
  }
}

class OrderItem {
  final int id;
  final int orderId;
  final int productId;
  final int quantity;
  final int price;
  final int totalPrice;
  final Product? product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.price,
    required this.totalPrice,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      orderId: json['order_id'] ?? 0,
      productId: json['product_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? 0,
      totalPrice: json['total_price'] ?? 0,
      product: json['product'] != null
          ? Product.fromJson(json['product'])
          : null,
    );
  }
}

class Product {
  final int id;
  final String name;
  final int? photoId;
  final String type;

  Product({
    required this.id,
    required this.name,
    this.photoId,
    required this.type,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Product',
      photoId: json['photo_id'],
      type: json['type'] ?? 'storable',
    );
  }
}

class BreakPhoto {
  final int id;
  final String belongsTo;
  final String path;
  final String thumbnail;
  final String name;
  final String format;
  final String createdAt;

  BreakPhoto({
    required this.id,
    required this.belongsTo,
    required this.path,
    required this.thumbnail,
    required this.name,
    required this.format,
    required this.createdAt,
  });

  factory BreakPhoto.fromJson(Map<String, dynamic> json) {
    return BreakPhoto(
      id: json['id'] ?? 0,
      belongsTo: json['belongs_to'] ?? '',
      path: json['path'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      name: json['name'] ?? '',
      format: json['format'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  String get fullUrl => 'https://app.sievesapp.com/$path/$name.$format';
  String get thumbnailUrl => 'https://app.sievesapp.com/$thumbnail/$name.$format';
}
