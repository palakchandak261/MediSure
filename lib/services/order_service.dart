import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../core/config/app_config.dart';
import '../models/order_model.dart';
import 'backend_service.dart';
import 'notification_delivery_service.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  static OrderService get instance => _instance;
  OrderService._internal();

  static const String _key = 'medicine_orders';

  // Active timers for auto-progression: orderId -> Timer
  final Map<String, Timer> _progressionTimers = {};

  // Callbacks for status change notifications
  final Map<String, List<Function(OrderModel)>> _statusCallbacks = {};

  void registerStatusCallback(String orderId, Function(OrderModel) cb) {
    _statusCallbacks[orderId] ??= [];
    _statusCallbacks[orderId]!.add(cb);
  }

  void unregisterStatusCallbacks(String orderId) {
    _statusCallbacks.remove(orderId);
  }

  // ── PHARMACY CATALOG ───────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> pharmacyCatalog = [
    {
      'name': 'Apollo Pharmacy',
      'address': 'MG Road, Near City Mall',
      'phone': '+91-9876543210',
      'rating': 4.5,
      'distance': '0.5 km',
      'deliveryTime': '2-3 hours',
      'deliveryCharge': 30,
      'minOrder': 200,
      'hasDelivery': true,
      'isOpen': true,
    },
    {
      'name': 'MedPlus',
      'address': 'Brigade Road, Opp. Forum Mall',
      'phone': '+91-9876543211',
      'rating': 4.3,
      'distance': '1.2 km',
      'deliveryTime': '3-4 hours',
      'deliveryCharge': 25,
      'minOrder': 150,
      'hasDelivery': true,
      'isOpen': true,
    },
    {
      'name': 'Wellness Forever',
      'address': 'Koramangala, 5th Block',
      'phone': '+91-9876543212',
      'rating': 4.4,
      'distance': '2.0 km',
      'deliveryTime': '4-5 hours',
      'deliveryCharge': 20,
      'minOrder': 100,
      'hasDelivery': true,
      'isOpen': true,
    },
    {
      'name': 'Netmeds',
      'address': 'Online Pharmacy',
      'phone': '+91-1800-103-0304',
      'rating': 4.4,
      'distance': 'Online',
      'deliveryTime': '1-2 days',
      'deliveryCharge': 0,
      'minOrder': 500,
      'hasDelivery': true,
      'isOpen': true,
    },
    {
      'name': '1mg',
      'address': 'Online Pharmacy',
      'phone': '+91-1800-843-0001',
      'rating': 4.6,
      'distance': 'Online',
      'deliveryTime': '1-2 days',
      'deliveryCharge': 0,
      'minOrder': 300,
      'hasDelivery': true,
      'isOpen': true,
    },
    {
      'name': 'PharmEasy',
      'address': 'Online Pharmacy',
      'phone': '+91-1800-120-0230',
      'rating': 4.5,
      'distance': 'Online',
      'deliveryTime': '1-2 days',
      'deliveryCharge': 0,
      'minOrder': 250,
      'hasDelivery': true,
      'isOpen': true,
    },
  ];

  // ── PRICING ────────────────────────────────────────────────────────────────
  double getMedicinePrice(String medicineName, String pharmacyName) {
    final base = _getBasePrice(medicineName);
    const discounts = {
      'Apollo Pharmacy': 0.0,
      'MedPlus': 0.08,
      'Wellness Forever': 0.05,
      'Netmeds': 0.10,
      '1mg': 0.15,
      'PharmEasy': 0.12,
    };
    return base * (1 - (discounts[pharmacyName] ?? 0.0));
  }

  double _getBasePrice(String name) {
    const prices = {
      'paracetamol': 25.0, 'dolo': 30.0, 'azithromycin': 120.0,
      'cetirizine': 20.0, 'omeprazole': 45.0, 'metformin': 35.0,
      'atorvastatin': 95.0, 'pantoprazole': 55.0, 'augmentin': 180.0,
      'amoxicillin': 85.0, 'ibuprofen': 40.0, 'aspirin': 15.0,
    };
    final lower = name.toLowerCase();
    for (final e in prices.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    return 50.0 + (name.length * 3.0);
  }

  // ── CRUD ───────────────────────────────────────────────────────────────────
  Future<List<OrderModel>> getUserOrders(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('${_key}_$userId');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return (list
        .map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.orderedAt.compareTo(a.orderedAt)));
  }

  Future<OrderModel?> getOrder(String userId, String orderId) async {
    final orders = await getUserOrders(userId);
    try {
      return orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      return null;
    }
  }

  Future<OrderModel> placeOrder({
    required String userId,
    required String pharmacyName,
    required String pharmacyAddress,
    required List<OrderItem> items,
    required String deliveryAddress,
    required String paymentMethod,
    String? contactEmail,
    String? contactPhone,
    String contactType = 'email',
  }) async {
    final total = items.fold<double>(0, (s, i) => s + i.total);
    final now = DateTime.now();

    final order = OrderModel(
      id: const Uuid().v4(),
      userId: userId,
      pharmacyName: pharmacyName,
      pharmacyAddress: pharmacyAddress,
      items: items,
      status: OrderStatus.confirmed,
      orderedAt: now,
      estimatedDelivery: now.add(const Duration(hours: 3)),
      totalAmount: total,
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      isPaid: paymentMethod != 'Cash on Delivery',
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      contactType: contactType,
      statusTimestamps: {
        'confirmed': now.toIso8601String(),
      },
    );

    final orders = await getUserOrders(userId);
    orders.insert(0, order);
    await _save(userId, orders);

    if (AppConfig.enableRemoteBackend) {
      try {
        await BackendService.instance.placeOrder(order.toMap());
      } catch (e) {
        debugPrint('⚠️ Remote order sync failed: $e');
      }
    }

    // Start auto-progression simulation
    _startAutoProgression(userId, order.id);

    // Send confirmation email only
    NotificationDeliveryService.instance.sendOrderConfirmation(order).then((r) {
      debugPrint('📧 Confirmation notif: ${r.message}');
    });

    return order;
  }

  /// Simulate realistic order status progression
  void _startAutoProgression(String userId, String orderId) {
    // Cancel any existing timer for this order
    _progressionTimers[orderId]?.cancel();

    // Progression delays (in seconds) — realistic simulation
    // Confirmed → Processing: 30s
    // Processing → Shipped: 60s
    // Shipped → Delivered: 90s
    const delays = [30, 60, 90];
    const nextStatuses = [
      OrderStatus.processing,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];

    for (int i = 0; i < delays.length; i++) {
      final delay = delays[i];
      final nextStatus = nextStatuses[i];

      Timer(Duration(seconds: delay), () async {
        // Check if order was cancelled before progressing
        final current = await getOrder(userId, orderId);
        if (current == null || current.status == OrderStatus.cancelled) {
          return; // Stop progression if cancelled
        }
        // Only progress if still in expected state
        if (current.status.index < nextStatus.index) {
          await _updateStatus(userId, orderId, nextStatus);
        }
      });
    }
  }

  Future<void> _updateStatus(
      String userId, String orderId, OrderStatus newStatus) async {
    final orders = await getUserOrders(userId);
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;

    final old = orders[idx];
    if (old.status == OrderStatus.cancelled) return; // Never update cancelled

    final timestamps = Map<String, String>.from(old.statusTimestamps);
    timestamps[newStatus.name] = DateTime.now().toIso8601String();

    final updated = old.copyWith(
      status: newStatus,
      statusTimestamps: timestamps,
    );
    orders[idx] = updated;
    await _save(userId, orders);

    // Notify callbacks
    final cbs = _statusCallbacks[orderId];
    if (cbs != null) {
      for (final cb in cbs) {
        cb(updated);
      }
    }

    // Send email ONLY on delivered status
    if (newStatus == OrderStatus.delivered) {
      NotificationDeliveryService.instance.sendStatusUpdate(updated).then((r) {
        debugPrint('📧 Delivery notif: ${r.message}');
      });
    }

    debugPrint('📦 Order $orderId → ${newStatus.name}');
  }

  Future<void> cancelOrder(String userId, String orderId) async {
    // Cancel progression timer
    _progressionTimers[orderId]?.cancel();
    _progressionTimers.remove(orderId);

    final orders = await getUserOrders(userId);
    final idx = orders.indexWhere((o) => o.id == orderId);
    if (idx == -1) return;

    final old = orders[idx];
    // Can only cancel if not yet shipped/delivered
    if (old.status == OrderStatus.shipped ||
        old.status == OrderStatus.delivered) {
      return;
    }

    final timestamps = Map<String, String>.from(old.statusTimestamps);
    timestamps['cancelled'] = DateTime.now().toIso8601String();

    orders[idx] = old.copyWith(
      status: OrderStatus.cancelled,
      statusTimestamps: timestamps,
    );
    await _save(userId, orders);

    // Notify callbacks
    final cbs = _statusCallbacks[orderId];
    if (cbs != null) {
      for (final cb in cbs) {
        cb(orders[idx]);
      }
    }
  }

  Future<void> _save(String userId, List<OrderModel> orders) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_key}_$userId',
      jsonEncode(orders.map((o) => o.toMap()).toList()),
    );
  }
}
