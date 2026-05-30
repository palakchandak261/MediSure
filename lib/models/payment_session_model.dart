class PaymentSession {
  final String paymentReference;
  final String upiId;
  final String payeeName;
  final double amount;
  final String currency;
  final String note;
  final bool requiresVerification;
  final String? razorpayOrderId;
  final String? razorpayKeyId;
  final String? type; // 'razorpay', 'upi_fallback', null

  PaymentSession({
    required this.paymentReference,
    required this.upiId,
    required this.payeeName,
    required this.amount,
    this.currency = 'INR',
    required this.note,
    this.requiresVerification = true,
    this.razorpayOrderId,
    this.razorpayKeyId,
    this.type,
  });

  bool get isRazorpay => type == 'razorpay' && razorpayOrderId != null;

  factory PaymentSession.fromMap(Map<String, dynamic> map) {
    return PaymentSession(
      paymentReference: map['paymentReference']?.toString() ?? '',
      upiId: map['upiId']?.toString() ?? '',
      payeeName: map['payeeName']?.toString() ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      currency: map['currency']?.toString() ?? 'INR',
      note: map['note']?.toString() ?? '',
      requiresVerification: map['requiresVerification'] == true,
      razorpayOrderId: map['razorpayOrderId']?.toString(),
      razorpayKeyId: map['razorpayKeyId']?.toString(),
      type: map['type']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'paymentReference': paymentReference,
        'upiId': upiId,
        'payeeName': payeeName,
        'amount': amount,
        'currency': currency,
        'note': note,
        'requiresVerification': requiresVerification,
        if (razorpayOrderId != null) 'razorpayOrderId': razorpayOrderId,
        if (razorpayKeyId != null) 'razorpayKeyId': razorpayKeyId,
        if (type != null) 'type': type,
      };
}
