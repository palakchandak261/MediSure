import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../services/notification_delivery_service.dart';

class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  late OrderModel _order;
  Timer? _refreshTimer;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _userId = Provider.of<AuthService>(context, listen: false).currentUser?.uid;

    // Register callback for real-time updates
    OrderService.instance.registerStatusCallback(_order.id, _onStatusUpdate);

    // Also poll every 5 seconds as backup
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => _reload());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    OrderService.instance.unregisterStatusCallbacks(_order.id);
    super.dispose();
  }

  void _onStatusUpdate(OrderModel updated) {
    if (mounted) setState(() => _order = updated);
  }

  Future<void> _reload() async {
    if (_userId == null) return;
    final fresh = await OrderService.instance.getOrder(_userId!, _order.id);
    if (fresh != null && mounted) setState(() => _order = fresh);
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 10),
          Text('Cancel Order?'),
        ]),
        content: const Text(
            'Are you sure you want to cancel this order? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No, Keep It')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true || _userId == null) return;
    await OrderService.instance.cancelOrder(_userId!, _order.id);
    await _reload();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Order cancelled successfully'),
        backgroundColor: Colors.red,
      ));
    }
  }

  // Steps definition — only show up to current status (or cancelled)
  List<_Step> get _steps {
    final isCancelled = _order.status == OrderStatus.cancelled;
    final currentIdx = isCancelled ? -1 : _order.status.index;

    final allSteps = [
      _Step(OrderStatus.confirmed, 'Order Placed', Icons.check_circle_rounded,
          'Your order has been confirmed'),
      _Step(OrderStatus.processing, 'Processing', Icons.inventory_2_rounded,
          'Pharmacy is preparing your medicines'),
      _Step(OrderStatus.shipped, 'Shipped', Icons.local_shipping_rounded,
          'Out for delivery'),
      _Step(OrderStatus.delivered, 'Delivered', Icons.home_rounded,
          'Order delivered successfully'),
    ];

    return allSteps.map((s) {
      final stepIdx = s.status.index;
      final isDone = !isCancelled && stepIdx <= currentIdx;
      final isActive = !isCancelled && stepIdx == currentIdx;
      return s.copyWith(isDone: isDone, isActive: isActive);
    }).toList();
  }

  Color get _headerColor {
    switch (_order.status) {
      case OrderStatus.delivered:
        return const Color(0xFF2E7D32);
      case OrderStatus.cancelled:
        return const Color(0xFFC62828);
      case OrderStatus.shipped:
        return const Color(0xFF00695C);
      default:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = _order.status == OrderStatus.cancelled;
    final isDelivered = _order.status == OrderStatus.delivered;
    final canCancel = !isCancelled &&
        _order.status != OrderStatus.shipped &&
        _order.status != OrderStatus.delivered;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_headerColor, _headerColor.withValues(alpha: 0.7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order Tracking',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('Live status updates every 5s',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 11)),
                        ],
                      ),
                    ),
                    // Live indicator
                    if (!isCancelled && !isDelivered)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF69F0AE),
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            const Text('LIVE',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildStatusBanner(),
                        const SizedBox(height: 16),
                        _buildTrackingCard(),
                        const SizedBox(height: 16),
                        _buildOrderDetails(),
                        const SizedBox(height: 16),
                        if (_order.contactEmail != null ||
                            _order.contactPhone != null)
                          _buildContactCard(),
                        if (_order.contactEmail != null ||
                            _order.contactPhone != null)
                          const SizedBox(height: 16),
                        if (canCancel)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _cancelOrder,
                              icon: const Icon(Icons.cancel_rounded,
                                  color: Colors.red),
                              label: const Text('Cancel Order',
                                  style: TextStyle(color: Colors.red)),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
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

  Widget _buildStatusBanner() {
    final isCancelled = _order.status == OrderStatus.cancelled;
    final isDelivered = _order.status == OrderStatus.delivered;

    Color bg;
    IconData icon;
    String title, sub;

    if (isCancelled) {
      bg = const Color(0xFFC62828);
      icon = Icons.cancel_rounded;
      title = 'Order Cancelled';
      sub = 'Order #${_order.id.substring(0, 8).toUpperCase()}';
    } else if (isDelivered) {
      bg = const Color(0xFF2E7D32);
      icon = Icons.check_circle_rounded;
      title = 'Order Delivered! 🎉';
      sub = 'Thank you for your order';
    } else {
      bg = _headerColor;
      icon = Icons.local_shipping_rounded;
      title = '${_order.statusEmoji} ${_order.statusText}';
      sub = 'Order #${_order.id.substring(0, 8).toUpperCase()}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: bg.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17)),
                const SizedBox(height: 3),
                Text(sub,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                if (!isCancelled &&
                    !isDelivered &&
                    _order.estimatedDelivery != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Est. delivery: ${_formatDateTime(_order.estimatedDelivery!)}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard() {
    final steps = _steps;
    final isCancelled = _order.status == OrderStatus.cancelled;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded,
                  color: Color(0xFF1565C0), size: 20),
              const SizedBox(width: 8),
              const Text('Order Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              if (isCancelled)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('CANCELLED',
                      style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Cancelled banner
          if (isCancelled)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_rounded,
                      color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This order was cancelled.',
                      style: TextStyle(
                          color: Colors.red.shade700, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Steps
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final isLast = i == steps.length - 1;
            final ts = _order.statusTimestamps[step.status.name];

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circle + line
                Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: step.isDone
                            ? (isCancelled
                                ? Colors.grey.shade400
                                : const Color(0xFF2E7D32))
                            : step.isActive
                                ? const Color(0xFF1565C0)
                                : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        boxShadow: step.isActive
                            ? [
                                BoxShadow(
                                    color: const Color(0xFF1565C0)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 2)
                              ]
                            : null,
                      ),
                      child: Icon(
                        step.isDone
                            ? Icons.check_rounded
                            : step.icon,
                        color: step.isDone || step.isActive
                            ? Colors.white
                            : Colors.grey.shade400,
                        size: 18,
                      ),
                    ),
                    if (!isLast)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        width: 2,
                        height: 44,
                        color: step.isDone
                            ? (isCancelled
                                ? Colors.grey.shade300
                                : const Color(0xFF2E7D32))
                            : Colors.grey.shade200,
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: isLast ? 0 : 28, top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.label,
                          style: TextStyle(
                            fontWeight: step.isDone || step.isActive
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 14,
                            color: step.isDone || step.isActive
                                ? const Color(0xFF1A1A2E)
                                : Colors.grey.shade400,
                          ),
                        ),
                        if (step.isDone || step.isActive) ...[
                          const SizedBox(height: 2),
                          Text(
                            step.subtitle,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500),
                          ),
                          if (ts != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              _formatDateTime(DateTime.parse(ts)),
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade400),
                            ),
                          ],
                        ],
                        // Pulsing "in progress" indicator
                        if (step.isActive && !isCancelled) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                    color: Color(0xFF1565C0),
                                    shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 5),
                              Text('In progress...',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: const Color(0xFF1565C0),
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOrderDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_pharmacy_rounded,
                  color: Color(0xFF1565C0), size: 20),
              const SizedBox(width: 8),
              Text(_order.pharmacyName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 12),
          ..._order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE3F2FD),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.medication_rounded,
                          color: Color(0xFF1565C0), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.medicineName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text('${item.dosage} × ${item.quantity}',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    Text('₹${item.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0))),
                  ],
                ),
              )),
          const Divider(height: 16),
          _DetailRow('Total', '₹${_order.totalAmount.toStringAsFixed(0)}',
              bold: true),
          const SizedBox(height: 4),
          _DetailRow('Payment', _order.paymentMethod),
          const SizedBox(height: 4),
          _DetailRow('Delivery to', _order.deliveryAddress),
          const SizedBox(height: 4),
          _DetailRow('Ordered at', _formatDateTime(_order.orderedAt)),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    final isEmail = _order.contactType == 'email';
    final contact = isEmail ? _order.contactEmail : _order.contactPhone;
    final isDelivered = _order.status == OrderStatus.delivered;
    final isCancelled = _order.status == OrderStatus.cancelled;
    final isConfigured = NotificationDeliveryService.isConfigured;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDelivered
                ? Colors.green.shade200
                : const Color(0xFFBBDEFB)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isEmail ? Icons.email_rounded : Icons.chat_rounded,
                color: isEmail
                    ? const Color(0xFF1565C0)
                    : const Color(0xFF2E7D32),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isEmail ? 'Email Notifications' : 'WhatsApp Notifications',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Contact chip
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isEmail
                  ? const Color(0xFFE3F2FD)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isEmail ? Icons.alternate_email : Icons.phone_rounded,
                  size: 16,
                  color: isEmail
                      ? const Color(0xFF1565C0)
                      : const Color(0xFF2E7D32),
                ),
                const SizedBox(width: 8),
                Text(contact ?? '',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isEmail
                            ? const Color(0xFF1565C0)
                            : const Color(0xFF2E7D32))),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Setup instructions if EmailJS not configured
          if (!isConfigured) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings_rounded,
                          color: Colors.orange.shade700, size: 16),
                      const SizedBox(width: 6),
                      Text('EmailJS Setup Required (5 min, free)',
                          style: TextStyle(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _SetupStep('1', 'Go to emailjs.com → Sign Up Free'),
                  _SetupStep('2', 'Email Services → Add Gmail → name it "MediSure" → copy SERVICE_ID'),
                  _SetupStep('3', 'Email Templates → Create New → paste HTML from assets/emailjs_template.html → copy TEMPLATE_ID'),
                  _SetupStep('4', 'Account → API Keys → copy PUBLIC_KEY'),
                  _SetupStep('5', 'Open lib/services/notification_delivery_service.dart → paste all 3 values'),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '📧 Sender: medisure.notify@gmail.com (your Gmail)\n'
                      '💬 WhatsApp: Opens wa.me link automatically',
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Notification log
          _NotifRow(
            sent: isConfigured,
            label: isConfigured
                ? 'Order confirmation sent to $contact'
                : 'Order confirmation (EmailJS not configured)',
            time: _formatDateTime(_order.orderedAt),
          ),
          if (_order.statusTimestamps['processing'] != null)
            _NotifRow(
              sent: isConfigured,
              label: isConfigured
                  ? 'Processing update sent'
                  : 'Processing update (not sent)',
              time: _formatDateTime(
                  DateTime.parse(_order.statusTimestamps['processing']!)),
            ),
          if (_order.statusTimestamps['shipped'] != null)
            _NotifRow(
              sent: isConfigured,
              label: isConfigured
                  ? 'Shipped notification sent'
                  : 'Shipped notification (not sent)',
              time: _formatDateTime(
                  DateTime.parse(_order.statusTimestamps['shipped']!)),
            ),
          if (isDelivered && _order.statusTimestamps['delivered'] != null)
            _NotifRow(
              sent: isConfigured,
              label: isConfigured
                  ? '🎉 Delivery confirmation sent!'
                  : '🎉 Delivery confirmation (not sent)',
              time: _formatDateTime(
                  DateTime.parse(_order.statusTimestamps['delivered']!)),
              highlight: true,
            ),
          if (isCancelled)
            _NotifRow(
              sent: isConfigured,
              label: isConfigured
                  ? 'Cancellation notification sent'
                  : 'Cancellation notification (not sent)',
              time: _formatDateTime(DateTime.now()),
              isCancel: true,
            ),
          if (!isDelivered && !isCancelled)
            _NotifRow(
              sent: false,
              label: 'Delivery confirmation (pending)',
              time: 'Will be sent on delivery',
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year}  $h:$m $ampm';
  }
}

// ── HELPER WIDGETS ────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  const _DetailRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      bold ? FontWeight.bold : FontWeight.w500,
                  color: bold
                      ? const Color(0xFF1565C0)
                      : const Color(0xFF1A1A2E))),
        ),
      ],
    );
  }
}

class _NotifRow extends StatelessWidget {
  final bool sent;
  final String label, time;
  final bool highlight;
  final bool isCancel;
  const _NotifRow({
    required this.sent,
    required this.label,
    required this.time,
    this.highlight = false,
    this.isCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCancel
        ? Colors.red.shade600
        : highlight
            ? Colors.green.shade700
            : sent
                ? Colors.grey[700]
                : Colors.grey[400];

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(
            sent ? Icons.check_circle_rounded : Icons.schedule_rounded,
            size: 14,
            color: isCancel
                ? Colors.red.shade400
                : highlight
                    ? Colors.green.shade500
                    : sent
                        ? Colors.green.shade400
                        : Colors.grey[400],
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: highlight
                        ? FontWeight.bold
                        : FontWeight.normal)),
          ),
          Text(time,
              style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

// ── SETUP STEP WIDGET ─────────────────────────────────────────────────────────
class _SetupStep extends StatelessWidget {
  final String number;
  final String text;
  const _SetupStep(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11, color: Colors.orange.shade800, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ── STEP MODEL ────────────────────────────────────────────────────────────────
class _Step {
  final OrderStatus status;
  final String label;
  final IconData icon;
  final String subtitle;
  final bool isDone;
  final bool isActive;

  const _Step(this.status, this.label, this.icon, this.subtitle,
      {this.isDone = false, this.isActive = false});

  _Step copyWith({bool? isDone, bool? isActive}) => _Step(
        status, label, icon, subtitle,
        isDone: isDone ?? this.isDone,
        isActive: isActive ?? this.isActive,
      );
}
