import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';
import 'order_tracking_screen.dart';
import 'nearby_pharmacy_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
    final orders = await OrderService.instance.getUserOrders(userId);
    setState(() {
      _orders = orders;
      _isLoading = false;
    });
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return const Color(0xFFE65100);
      case OrderStatus.confirmed:
        return const Color(0xFF1565C0);
      case OrderStatus.processing:
        return const Color(0xFF6A1B9A);
      case OrderStatus.shipped:
        return const Color(0xFF00695C);
      case OrderStatus.delivered:
        return const Color(0xFF2E7D32);
      case OrderStatus.cancelled:
        return const Color(0xFFC62828);
    }
  }

  IconData _statusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty_rounded;
      case OrderStatus.confirmed:
        return Icons.check_circle_rounded;
      case OrderStatus.processing:
        return Icons.inventory_2_rounded;
      case OrderStatus.shipped:
        return Icons.local_shipping_rounded;
      case OrderStatus.delivered:
        return Icons.home_rounded;
      case OrderStatus.cancelled:
        return Icons.cancel_rounded;
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
            colors: [Color(0xFF006064), Color(0xFF00838F), Color(0xFF0097A7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
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
                          Text('My Orders',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('Track your medicine deliveries',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NearbyPharmacyScreen()),
                      ).then((_) => _loadOrders()),
                      icon: const Icon(Icons.add_shopping_cart_rounded,
                          size: 16),
                      label: const Text('New Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF006064),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
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
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF00838F)))
                      : _orders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE0F7FA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 52,
                                        color: Color(0xFF00838F)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('No orders yet',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A2E))),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Order medicines from nearby pharmacies\nwith home delivery',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500])),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const NearbyPharmacyScreen()),
                                    ).then((_) => _loadOrders()),
                                    icon: const Icon(
                                        Icons.local_pharmacy_rounded,
                                        size: 18),
                                    label: const Text('Find Pharmacies'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color(0xFF00838F),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 16, 16, 20),
                              itemCount: _orders.length,
                              itemBuilder: (ctx, i) {
                                final order = _orders[i];
                                final statusColor =
                                    _statusColor(order.status);
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => OrderTrackingScreen(
                                          order: order),
                                    ),
                                  ).then((_) => _loadOrders()),
                                  child: Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.06),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        // Status bar
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: statusColor
                                                .withValues(alpha: 0.08),
                                            borderRadius:
                                                const BorderRadius.only(
                                              topLeft: Radius.circular(16),
                                              topRight: Radius.circular(16),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                  _statusIcon(order.status),
                                                  color: statusColor,
                                                  size: 18),
                                              const SizedBox(width: 8),
                                              Text(order.statusText,
                                                  style: TextStyle(
                                                      color: statusColor,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13)),
                                              const Spacer(),
                                              Text(
                                                  _formatDate(
                                                      order.orderedAt),
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Colors.grey[500])),
                                            ],
                                          ),
                                        ),
                                        // Content
                                        Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                              0xFFE0F7FA),
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(12),
                                                    ),
                                                    child: const Icon(
                                                        Icons
                                                            .local_pharmacy_rounded,
                                                        color: Color(
                                                            0xFF00838F),
                                                        size: 22),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                            order.pharmacyName,
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize:
                                                                    15)),
                                                        Text(
                                                            'Order #${order.id.substring(0, 8).toUpperCase()}',
                                                            style: TextStyle(
                                                                fontSize: 11,
                                                                color: Colors
                                                                    .grey[500])),
                                                      ],
                                                    ),
                                                  ),
                                                  Text(
                                                      '₹${order.totalAmount.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 18,
                                                          color: Color(
                                                              0xFF00838F))),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .medication_rounded,
                                                        size: 14,
                                                        color: Colors.grey),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        '${order.items.length} item(s): ${order.items.map((i) => i.medicineName).join(', ')}',
                                                        style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey[700]),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons.payment_rounded,
                                                      size: 13,
                                                      color: Colors.grey),
                                                  const SizedBox(width: 5),
                                                  Text(order.paymentMethod,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey[600])),
                                                  const Spacer(),
                                                  const Icon(
                                                      Icons
                                                          .chevron_right_rounded,
                                                      color: Colors.grey,
                                                      size: 18),
                                                  Text('Track Order',
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: const Color(
                                                              0xFF00838F),
                                                          fontWeight:
                                                              FontWeight
                                                                  .w600)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}';
}
