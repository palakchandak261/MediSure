import '../core/config/app_config.dart';
import '../models/payment_session_model.dart';
import '../models/order_model.dart';
import 'backend_service.dart';

class PaymentService {
  PaymentService._internal();

  static final PaymentService instance = PaymentService._internal();

  Future<PaymentSession> createUpiSession({
    required String orderId,
    required double amount,
    required String pharmacyName,
  }) async {
    if (BackendService.instance.enabled) {
      return await BackendService.instance.createPaymentSession({
        'orderId': orderId,
        'amount': amount,
        'currency': 'INR',
        'pharmacyName': pharmacyName,
      });
    }

    if (AppConfig.upiId.isEmpty || AppConfig.upiPayeeName.isEmpty) {
      throw PaymentException(
        'UPI configuration is missing. Set UPI_ID and UPI_PAYEE_NAME in your environment.',
      );
    }

    return PaymentSession(
      paymentReference: orderId,
      upiId: AppConfig.upiId,
      payeeName: AppConfig.upiPayeeName,
      amount: amount,
      note: 'MediSure Order #$orderId',
      requiresVerification: false,
    );
  }

  Future<bool> verifyUpiPayment({required String paymentReference}) async {
    if (BackendService.instance.enabled) {
      return await BackendService.instance.verifyPayment(paymentReference);
    }
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}

class PaymentException implements Exception {
  final String message;
  PaymentException(this.message);
  @override
  String toString() => 'PaymentException: $message';
}
