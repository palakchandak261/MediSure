import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/nearby_pharmacy_service.dart';
import '../services/payment_service.dart';
import '../models/order_model.dart';
import 'order_tracking_screen.dart';
import 'upi_payment_screen.dart';

class OrderScreen extends StatefulWidget {
  final PharmacyModel pharmacy;
  final String? prefilledMedicine;
  final double? prefilledPrice;

  const OrderScreen({
    super.key,
    required this.pharmacy,
    this.prefilledMedicine,
    this.prefilledPrice,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _medicineController = TextEditingController();
  final _dosageController = TextEditingController();
  final _addressController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _contactController = TextEditingController();
  final List<OrderItem> _cartItems = [];
  String _paymentMethod = 'Cash on Delivery';
  String _contactType = 'email'; // 'email' or 'whatsapp'
  bool _isPlacingOrder = false;

  final List<String> _paymentMethods = [
    'Cash on Delivery',
    'UPI',
    'Credit/Debit Card',
    'Net Banking',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledMedicine != null) {
      _medicineController.text = widget.prefilledMedicine!;
      _dosageController.text = 'As prescribed';
      // Auto-add to cart
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addToCart();
      });
    }
  }

  @override
  void dispose() {
    _medicineController.dispose();
    _dosageController.dispose();
    _addressController.dispose();
    _qtyController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _addToCart() {
    if (_medicineController.text.trim().isEmpty) return;
    final price = widget.prefilledPrice ??
        OrderService.instance.getMedicinePrice(
          _medicineController.text,
          widget.pharmacy.name,
        );
    setState(() {
      _cartItems.add(OrderItem(
        medicineName: _medicineController.text.trim(),
        quantity: int.tryParse(_qtyController.text) ?? 1,
        price: price,
        dosage: _dosageController.text.trim(),
      ));
      _medicineController.clear();
      _dosageController.clear();
      _qtyController.text = '1';
    });
  }

  double get _subtotal => _cartItems.fold(0, (s, i) => s + i.total);
  double get _deliveryCharge =>
      _cartItems.isEmpty ? 0 : widget.pharmacy.deliveryCharge.toDouble();
  double get _total => _subtotal + _deliveryCharge;

  Future<void> _placeOrder() async {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one medicine to cart')),
      );
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter delivery address')),
      );
      return;
    }

    String? paymentReference;

    if (_paymentMethod == 'UPI') {
      final orderId = DateTime.now().millisecondsSinceEpoch
          .toString()
          .substring(7)
          .toUpperCase();

      final session = await PaymentService.instance.createUpiSession(
        orderId: orderId,
        amount: _total,
        pharmacyName: widget.pharmacy.name,
      );

      paymentReference = session.paymentReference;

      final paid = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => UpiPaymentScreen(
            amount: session.amount,
            pharmacyName: session.payeeName,
            orderId: session.paymentReference,
            upiId: session.upiId,
            note: session.note,
            onPaymentSuccess: () {},
          ),
        ),
      );

      if (paid != true) return; // User cancelled payment
      if (!mounted) return;
    }

    setState(() => _isPlacingOrder = true);

    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
    final contact = _contactController.text.trim();

    try {
      final order = await OrderService.instance.placeOrder(
        userId: userId,
        pharmacyName: widget.pharmacy.name,
        pharmacyAddress: widget.pharmacy.address,
        items: _cartItems,
        deliveryAddress: _addressController.text.trim(),
        paymentMethod: _paymentMethod,
        contactEmail: _contactType == 'email' && contact.isNotEmpty ? contact : null,
        contactPhone: _contactType == 'whatsapp' && contact.isNotEmpty ? contact : null,
        contactType: _contactType,
      );

      if (mounted) {
        setState(() => _isPlacingOrder = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderTrackingScreen(order: order),
          ),
        );
      }
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order failed: $e')),
        );
      }
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
            colors: [Color(0xFF6B7FED), Color(0xFF9D6FDB), Color(0xFFB565C8)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Medicines',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.pharmacy.name,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.delivery_dining, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.pharmacy.deliveryTime,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add medicine section
                        _SectionCard(
                          title: '💊 Add Medicine',
                          child: Column(
                            children: [
                              TextField(
                                controller: _medicineController,
                                decoration: _inputDecoration('Medicine Name', Icons.medication),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextField(
                                      controller: _dosageController,
                                      decoration: _inputDecoration('Dosage', Icons.science),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _qtyController,
                                      keyboardType: TextInputType.number,
                                      decoration: _inputDecoration('Qty', Icons.numbers),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _addToCart,
                                  icon: const Icon(Icons.add_shopping_cart),
                                  label: const Text('Add to Cart'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6B7FED),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Cart
                        if (_cartItems.isNotEmpty) ...[
                          _SectionCard(
                            title: '🛒 Cart (${_cartItems.length} items)',
                            child: Column(
                              children: [
                                ..._cartItems.asMap().entries.map((entry) {
                                  final i = entry.key;
                                  final item = entry.value;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6B7FED).withValues(alpha: 0.07),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.medication,
                                            color: Color(0xFF6B7FED), size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.medicineName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                '${item.dosage} × ${item.quantity}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          '₹${item.total.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF6B7FED),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Colors.red, size: 18),
                                          onPressed: () =>
                                              setState(() => _cartItems.removeAt(i)),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const Divider(),
                                _BillRow('Subtotal', '₹${_subtotal.toStringAsFixed(0)}'),
                                _BillRow(
                                  'Delivery',
                                  _deliveryCharge == 0
                                      ? 'FREE'
                                      : '₹${_deliveryCharge.toStringAsFixed(0)}',
                                  valueColor: _deliveryCharge == 0
                                      ? Colors.green.shade700
                                      : null,
                                ),
                                const Divider(),
                                _BillRow(
                                  'Total',
                                  '₹${_total.toStringAsFixed(0)}',
                                  isBold: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Delivery address
                        _SectionCard(
                          title: '📍 Delivery Address',
                          child: TextField(
                            controller: _addressController,
                            maxLines: 3,
                            decoration: _inputDecoration(
                              'Enter your full delivery address...',
                              Icons.home,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Payment method
                        _SectionCard(
                          title: '💳 Payment Method',
                          child: Column(
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _paymentMethods.map((method) {
                                final selected = _paymentMethod == method;
                                return ChoiceChip(
                                  label: Text(method),
                                  selected: selected,
                                  selectedColor: const Color(0xFF6B7FED),
                                  onSelected: (_) =>
                                      setState(() => _paymentMethod = method),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        ),
                        // Contact for notifications
                        _SectionCard(
                          title: '📲 Notification Preference',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Get order updates via:',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                              const SizedBox(height: 10),
                              // Toggle Email / WhatsApp
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _contactType = 'email'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color: _contactType == 'email'
                                              ? const Color(0xFF1565C0)
                                              : Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.email_rounded,
                                                size: 16,
                                                color:
                                                    _contactType == 'email'
                                                        ? Colors.white
                                                        : Colors.grey),
                                            const SizedBox(width: 6),
                                            Text('Email',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color:
                                                        _contactType == 'email'
                                                            ? Colors.white
                                                            : Colors.grey,
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _contactType = 'whatsapp'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: BoxDecoration(
                                          color:
                                              _contactType == 'whatsapp'
                                                  ? const Color(0xFF2E7D32)
                                                  : Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.chat_rounded,
                                                size: 16,
                                                color: _contactType ==
                                                        'whatsapp'
                                                    ? Colors.white
                                                    : Colors.grey),
                                            const SizedBox(width: 6),
                                            Text('WhatsApp',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: _contactType ==
                                                            'whatsapp'
                                                        ? Colors.white
                                                        : Colors.grey,
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _contactController,
                                keyboardType: _contactType == 'email'
                                    ? TextInputType.emailAddress
                                    : TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: _contactType == 'email'
                                      ? 'Enter your email address'
                                      : 'Enter WhatsApp number (+91...)',
                                  prefixIcon: Icon(
                                    _contactType == 'email'
                                        ? Icons.email_rounded
                                        : Icons.chat_rounded,
                                    color: _contactType == 'email'
                                        ? const Color(0xFF1565C0)
                                        : const Color(0xFF2E7D32),
                                    size: 20,
                                  ),
                                  border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10)),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 12),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _contactType == 'email'
                                    ? '📧 You\'ll receive order confirmation, shipping & delivery updates on this email'
                                    : '💬 You\'ll receive WhatsApp messages for order confirmation, shipping & delivery',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isPlacingOrder ? null : _placeOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _paymentMethod == 'UPI'
                                  ? const Color(0xFF1A237E)
                                  : const Color(0xFF6B7FED),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _isPlacingOrder
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _paymentMethod == 'UPI'
                                            ? Icons.qr_code_rounded
                                            : Icons.shopping_bag_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _paymentMethod == 'UPI'
                                            ? 'Pay ₹${_total.toStringAsFixed(0)} via UPI'
                                            : 'Place Order • ₹${_total.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
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

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF9D6FDB), size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF2D3142),
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _BillRow(this.label, this.value,
      {this.isBold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 15 : 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 16 : 14,
              color: valueColor ?? (isBold ? const Color(0xFF2D3142) : Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }
}
