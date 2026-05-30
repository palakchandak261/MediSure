enum OrderStatus { pending, confirmed, processing, shipped, delivered, cancelled }

class OrderItem {
  final String medicineName;
  final int quantity;
  final double price;
  final String dosage;

  OrderItem({
    required this.medicineName,
    required this.quantity,
    required this.price,
    required this.dosage,
  });

  double get total => price * quantity;

  Map<String, dynamic> toMap() => {
        'medicineName': medicineName,
        'quantity': quantity,
        'price': price,
        'dosage': dosage,
      };

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
        medicineName: map['medicineName'] ?? '',
        quantity: map['quantity'] ?? 1,
        price: (map['price'] ?? 0).toDouble(),
        dosage: map['dosage'] ?? '',
      );
}

class OrderModel {
  final String id;
  final String userId;
  final String pharmacyName;
  final String pharmacyAddress;
  final List<OrderItem> items;
  final OrderStatus status;
  final DateTime orderedAt;
  final DateTime? estimatedDelivery;
  final double totalAmount;
  final String deliveryAddress;
  final String paymentMethod;
  final bool isPaid;

  // Contact info for notifications
  final String? contactEmail;
  final String? contactPhone;
  final String contactType; // 'email' or 'whatsapp'

  // Status timestamps for tracking
  final Map<String, String> statusTimestamps;

  OrderModel({
    required this.id,
    required this.userId,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.items,
    required this.status,
    required this.orderedAt,
    this.estimatedDelivery,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.isPaid,
    this.contactEmail,
    this.contactPhone,
    this.contactType = 'email',
    Map<String, String>? statusTimestamps,
  }) : statusTimestamps = statusTimestamps ?? {};

  String get statusText {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.processing:
        return 'Processing';
      case OrderStatus.shipped:
        return 'Shipped';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get statusEmoji {
    switch (status) {
      case OrderStatus.pending:
        return '⏳';
      case OrderStatus.confirmed:
        return '✅';
      case OrderStatus.processing:
        return '📦';
      case OrderStatus.shipped:
        return '🚚';
      case OrderStatus.delivered:
        return '🏠';
      case OrderStatus.cancelled:
        return '❌';
    }
  }

  /// Returns next status in progression
  OrderStatus? get nextStatus {
    switch (status) {
      case OrderStatus.confirmed:
        return OrderStatus.processing;
      case OrderStatus.processing:
        return OrderStatus.shipped;
      case OrderStatus.shipped:
        return OrderStatus.delivered;
      default:
        return null;
    }
  }

  OrderModel copyWith({
    OrderStatus? status,
    Map<String, String>? statusTimestamps,
    DateTime? estimatedDelivery,
  }) {
    return OrderModel(
      id: id,
      userId: userId,
      pharmacyName: pharmacyName,
      pharmacyAddress: pharmacyAddress,
      items: items,
      status: status ?? this.status,
      orderedAt: orderedAt,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      totalAmount: totalAmount,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      isPaid: isPaid,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      contactType: contactType,
      statusTimestamps: statusTimestamps ?? this.statusTimestamps,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'pharmacyName': pharmacyName,
        'pharmacyAddress': pharmacyAddress,
        'items': items.map((i) => i.toMap()).toList(),
        'status': status.index,
        'orderedAt': orderedAt.toIso8601String(),
        'estimatedDelivery': estimatedDelivery?.toIso8601String(),
        'totalAmount': totalAmount,
        'deliveryAddress': deliveryAddress,
        'paymentMethod': paymentMethod,
        'isPaid': isPaid,
        'contactEmail': contactEmail,
        'contactPhone': contactPhone,
        'contactType': contactType,
        'statusTimestamps': statusTimestamps,
      };

  factory OrderModel.fromMap(Map<String, dynamic> map) => OrderModel(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        pharmacyName: map['pharmacyName'] ?? '',
        pharmacyAddress: map['pharmacyAddress'] ?? '',
        items: (map['items'] as List<dynamic>?)
                ?.map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i)))
                .toList() ??
            [],
        status: OrderStatus.values[map['status'] ?? 0],
        orderedAt:
            DateTime.parse(map['orderedAt'] ?? DateTime.now().toIso8601String()),
        estimatedDelivery: map['estimatedDelivery'] != null
            ? DateTime.parse(map['estimatedDelivery'])
            : null,
        totalAmount: (map['totalAmount'] ?? 0).toDouble(),
        deliveryAddress: map['deliveryAddress'] ?? '',
        paymentMethod: map['paymentMethod'] ?? 'Cash on Delivery',
        isPaid: map['isPaid'] ?? false,
        contactEmail: map['contactEmail'],
        contactPhone: map['contactPhone'],
        contactType: map['contactType'] ?? 'email',
        statusTimestamps: map['statusTimestamps'] != null
            ? Map<String, String>.from(map['statusTimestamps'])
            : {},
      );
}
