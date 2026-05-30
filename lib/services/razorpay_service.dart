import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../core/config/app_config.dart';
import 'backend_service.dart';

/// Razorpay payment service.
///
/// Flow:
///   1. Call [startPayment] — creates a Razorpay order on the backend
///   2. Razorpay SDK opens the payment sheet
///   3. On success, [onSuccess] is called with the payment ID
///   4. Backend verifies the signature via [verifyPayment]
///
/// Requirements:
///   - RAZORPAY_KEY_ID in .env (rzp_test_* for testing)
///   - Backend running with RAZORPAY_KEY_ID + RAZORPAY_KEY_SECRET
///   - razorpay_flutter: ^1.3.6 in pubspec.yaml
///
/// Note: Razorpay SDK only works on Android/iOS.
/// On web, falls back to UPI QR code flow.
class RazorpayService {
  RazorpayService._();
  static final RazorpayService instance = RazorpayService._();

  Razorpay? _razorpay;

  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onFailure;
  Function(ExternalWalletResponse)? _onWallet;

  /// Initialize Razorpay listeners. Call once per screen lifecycle.
  void init({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    Function(ExternalWalletResponse)? onWallet,
  }) {
    if (kIsWeb) return; // Razorpay SDK not supported on web

    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _onWallet = onWallet;

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleFailure);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleWallet);
    debugPrint('✅ Razorpay initialized');
  }

  /// Dispose Razorpay listeners. Call in dispose().
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }

  /// Start a Razorpay payment.
  ///
  /// If backend is enabled, creates a Razorpay order first (recommended).
  /// Otherwise opens Razorpay checkout directly with the amount.
  Future<void> startPayment({
    required double amount,
    required String orderId,
    required String pharmacyName,
    required String userEmail,
    required String userPhone,
    required String userName,
  }) async {
    if (kIsWeb) {
      throw RazorpayException('Razorpay SDK is not supported on web. Use UPI QR code instead.');
    }

    final keyId = AppConfig.razorpayKeyId;
    if (keyId.isEmpty || keyId.startsWith('rzp_test_your')) {
      throw RazorpayException(
        'Razorpay key not configured.\n'
        'Set RAZORPAY_KEY_ID in .env (get from dashboard.razorpay.com)',
      );
    }

    String? razorpayOrderId;

    // Create order on backend for signature verification
    if (BackendService.instance.enabled) {
      try {
        final session = await BackendService.instance.createPaymentSession({
          'orderId': orderId,
          'amount': amount,
          'currency': 'INR',
          'pharmacyName': pharmacyName,
          'type': 'razorpay',
        });
        razorpayOrderId = session.paymentReference;
        debugPrint('Razorpay order created: $razorpayOrderId');
      } catch (e) {
        debugPrint('Backend order creation failed, proceeding without order ID: $e');
      }
    }

    final options = <String, dynamic>{
      'key': keyId,
      'amount': (amount * 100).toInt(), // Razorpay uses paise
      'currency': 'INR',
      'name': pharmacyName,
      'description': 'MediSure Order #$orderId',
      'prefill': {
        'contact': userPhone,
        'email': userEmail,
        'name': userName,
      },
      'theme': {
        'color': '#5C6BC0',
      },
      'retry': {
        'enabled': true,
        'max_count': 3,
      },
      'send_sms_hash': true,
      'remember_customer': false,
    };

    if (razorpayOrderId != null && razorpayOrderId.startsWith('order_')) {
      options['order_id'] = razorpayOrderId;
    }

    try {
      _razorpay!.open(options);
    } catch (e) {
      throw RazorpayException('Failed to open Razorpay: $e');
    }
  }

  void _handleSuccess(PaymentSuccessResponse response) {
    debugPrint('✅ Razorpay payment success: ${response.paymentId}');
    _onSuccess?.call(response);
  }

  void _handleFailure(PaymentFailureResponse response) {
    debugPrint('❌ Razorpay payment failed: ${response.message}');
    _onFailure?.call(response);
  }

  void _handleWallet(ExternalWalletResponse response) {
    debugPrint('Razorpay external wallet: ${response.walletName}');
    _onWallet?.call(response);
  }

  /// Verify payment signature with backend.
  Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    if (!BackendService.instance.enabled) {
      // Without backend, trust the client-side success callback
      return true;
    }

    try {
      return await BackendService.instance.verifyRazorpayPayment(
        razorpayOrderId: razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: razorpaySignature,
      );
    } catch (e) {
      debugPrint('Payment verification error: $e');
      return false;
    }
  }
}

class RazorpayException implements Exception {
  final String message;
  RazorpayException(this.message);
  @override
  String toString() => message;
}
