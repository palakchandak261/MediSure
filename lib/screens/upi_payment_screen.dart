import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../core/config/app_config.dart';
import '../services/razorpay_service.dart';

/// Payment screen supporting both:
///   - Razorpay SDK (Android/iOS) — full payment gateway with cards, UPI, wallets
///   - UPI QR code (web + fallback) — direct UPI deep link
class UpiPaymentScreen extends StatefulWidget {
  final double amount;
  final String pharmacyName;
  final String orderId;
  final String upiId;
  final String note;
  final VoidCallback onPaymentSuccess;
  final String? userEmail;
  final String? userPhone;
  final String? userName;

  const UpiPaymentScreen({
    super.key,
    required this.amount,
    required this.pharmacyName,
    required this.orderId,
    required this.upiId,
    required this.note,
    required this.onPaymentSuccess,
    this.userEmail,
    this.userPhone,
    this.userName,
  });

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  bool _isVerifying = false;
  bool _paymentDone = false;
  bool _useRazorpay = false;
  int _countdown = 300;
  Timer? _countdownTimer;

  // Razorpay key from .env
  String get _razorpayKeyId => AppConfig.razorpayKeyId;
  bool get _razorpayAvailable =>
      !kIsWeb &&
      _razorpayKeyId.isNotEmpty &&
      !_razorpayKeyId.startsWith('rzp_test_your');

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startCountdown();

    // Default to Razorpay if available
    _useRazorpay = _razorpayAvailable;

    if (_razorpayAvailable) {
      RazorpayService.instance.init(
        onSuccess: _onRazorpaySuccess,
        onFailure: _onRazorpayFailure,
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownTimer?.cancel();
    if (_razorpayAvailable) RazorpayService.instance.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown <= 0 || _paymentDone) {
        t.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  String get _countdownText {
    final m = (_countdown ~/ 60).toString().padLeft(2, '0');
    final s = (_countdown % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _upiDeepLink {
    final amt = widget.amount.toStringAsFixed(2);
    final note = Uri.encodeComponent(widget.note);
    return 'upi://pay?pa=${widget.upiId}&pn=${Uri.encodeComponent(widget.pharmacyName)}&am=$amt&cu=INR&tn=$note';
  }

  String get _upiId => widget.upiId.isNotEmpty ? widget.upiId : AppConfig.upiId;

  Future<void> _openUpiApp() async {
    final uri = Uri.parse(_upiDeepLink);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(
          Uri.parse('https://pay.google.com'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open UPI app. Please use a different payment option.'),
          ),
        );
      }
    }
  }

  Future<void> _startRazorpayPayment() async {
    setState(() => _isVerifying = true);
    try {
      await RazorpayService.instance.startPayment(
        amount: widget.amount,
        orderId: widget.orderId,
        pharmacyName: widget.pharmacyName,
        userEmail: widget.userEmail ?? '',
        userPhone: widget.userPhone ?? '',
        userName: widget.userName ?? '',
      );
    } catch (e) {
      setState(() => _isVerifying = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment error: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Fall back to UPI QR
        setState(() => _useRazorpay = false);
      }
    }
  }

  void _onRazorpaySuccess(PaymentSuccessResponse response) async {
    setState(() => _isVerifying = true);
    bool verified = true;

    if (response.orderId != null && response.signature != null) {
      verified = await RazorpayService.instance.verifyPayment(
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId ?? '',
        razorpaySignature: response.signature!,
      );
    }

    setState(() {
      _isVerifying = false;
      _paymentDone = verified;
    });

    if (verified && mounted) {
      _countdownTimer?.cancel();
      widget.onPaymentSuccess();
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verification failed. Please contact support.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onRazorpayFailure(PaymentFailureResponse response) {
    setState(() => _isVerifying = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${response.message ?? "Unknown error"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmUpiPayment() async {
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isVerifying = false;
      _paymentDone = true;
    });
    _countdownTimer?.cancel();
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      widget.onPaymentSuccess();
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F2F8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildAmountCard(),
                        const SizedBox(height: 16),
                        if (_razorpayAvailable) _buildPaymentToggle(),
                        const SizedBox(height: 16),
                        if (_useRazorpay && _razorpayAvailable)
                          _buildRazorpaySection()
                        else
                          _buildUpiSection(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context, false),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Payment',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text('Secure payment powered by Razorpay',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _countdown < 60
                  ? Colors.red.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: _countdown < 60 ? Colors.red.shade300 : Colors.white30),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_rounded, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Text(_countdownText,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('Pay Exactly',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            '₹${widget.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text('to ${widget.pharmacyName}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Order #${widget.orderId}',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _useRazorpay = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: _useRazorpay
                      ? const Color(0xFF3949AB)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.payment_rounded,
                        color: _useRazorpay ? Colors.white : Colors.grey,
                        size: 22),
                    const SizedBox(height: 4),
                    Text('Razorpay',
                        style: TextStyle(
                            color: _useRazorpay ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    Text('Cards, UPI, Wallets',
                        style: TextStyle(
                            color: _useRazorpay
                                ? Colors.white70
                                : Colors.grey.shade400,
                            fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _useRazorpay = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: !_useRazorpay
                      ? const Color(0xFF3949AB)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(14),
                    bottomRight: Radius.circular(14),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_rounded,
                        color: !_useRazorpay ? Colors.white : Colors.grey,
                        size: 22),
                    const SizedBox(height: 4),
                    Text('UPI QR',
                        style: TextStyle(
                            color: !_useRazorpay ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    Text('GPay, PhonePe, Paytm',
                        style: TextStyle(
                            color: !_useRazorpay
                                ? Colors.white70
                                : Colors.grey.shade400,
                            fontSize: 10)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRazorpaySection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(Icons.payment_rounded,
                  color: Color(0xFF3949AB), size: 48),
              const SizedBox(height: 12),
              const Text('Pay with Razorpay',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Text(
                'Supports Credit/Debit Cards, UPI, Net Banking, Wallets & EMI',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PaymentBadge('VISA', Colors.blue),
                  const SizedBox(width: 8),
                  _PaymentBadge('MC', Colors.red),
                  const SizedBox(width: 8),
                  _PaymentBadge('UPI', Colors.green),
                  const SizedBox(width: 8),
                  _PaymentBadge('NB', Colors.orange),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!_paymentDone)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isVerifying ? null : _startRazorpayPayment,
              icon: _isVerifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.payment_rounded),
              label: Text(
                _isVerifying
                    ? 'Opening Payment...'
                    : 'Pay ₹${widget.amount.toStringAsFixed(0)} with Razorpay',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3949AB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          )
        else
          _buildSuccessBanner(),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.cancel_rounded),
            label: const Text('Cancel Payment'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpiSection() {
    return Column(
      children: [
        // QR Code card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('Scan with any UPI App',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 4),
              Text('GPay • PhonePe • Paytm • BHIM',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 16),
              ScaleTransition(
                scale: _pulseAnim,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: const Color(0xFF3949AB), width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: _upiDeepLink,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Color(0xFF1A237E),
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Color(0xFF283593),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _UpiLogo('G', Colors.blue),
                  const SizedBox(width: 10),
                  _UpiLogo('P', Colors.purple),
                  const SizedBox(width: 10),
                  _UpiLogo('₹', Colors.orange),
                  const SizedBox(width: 10),
                  _UpiLogo('B', Colors.green),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // UPI ID section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Or pay using UPI ID',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EAF6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF3949AB).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.account_balance_wallet_rounded,
                        color: Color(0xFF3949AB), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_upiId,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1A237E))),
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _upiId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('UPI ID copied!'),
                            duration: Duration(seconds: 1),
                            backgroundColor: Color(0xFF3949AB),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3949AB),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Text('Copy',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded,
                        color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Enter exact amount ₹${widget.amount.toStringAsFixed(2)} while paying',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!kIsWeb)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openUpiApp,
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open UPI App (GPay / PhonePe / Paytm)',
                  style: TextStyle(fontSize: 14)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3949AB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        const SizedBox(height: 10),
        if (!_paymentDone) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isVerifying ? null : _confirmUpiPayment,
              icon: _isVerifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.check_circle_rounded),
              label: Text(
                _isVerifying
                    ? 'Verifying Payment...'
                    : 'I have Paid ₹${widget.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.cancel_rounded),
              label: const Text('Cancel Payment'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ] else
          _buildSuccessBanner(),
      ],
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_rounded,
              color: Colors.green.shade700, size: 28),
          const SizedBox(width: 12),
          Text('Payment Successful!',
              style: TextStyle(
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
        ],
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _PaymentBadge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _UpiLogo extends StatelessWidget {
  final String letter;
  final Color color;
  const _UpiLogo(this.letter, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Text(letter,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
