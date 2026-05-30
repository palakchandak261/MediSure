import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/order_model.dart';

/// MediSure Notification Service
/// Sends order notifications via mailto (opens Gmail/mail client)
/// and WhatsApp via wa.me deep link.
class NotificationDeliveryService {
  static final NotificationDeliveryService _instance =
      NotificationDeliveryService._internal();
  static NotificationDeliveryService get instance => _instance;
  NotificationDeliveryService._internal();

  static const String _senderName = 'MediSure';
  static bool get isConfigured => true;

  // ── PUBLIC API ─────────────────────────────────────────────────────────────

  Future<NotifResult> sendOrderConfirmation(OrderModel order) {
    return _dispatch(
      order: order,
      statusEmoji: '✅',
      statusTitle: 'Order Confirmed',
      statusMessage:
          'Your order from ${order.pharmacyName} has been confirmed and is being prepared.',
    );
  }

  Future<NotifResult> sendStatusUpdate(OrderModel order) {
    String emoji, title, msg;
    switch (order.status) {
      case OrderStatus.processing:
        emoji = '📦'; title = 'Order Processing';
        msg = 'Your medicines are being packed and will be dispatched soon.';
        break;
      case OrderStatus.shipped:
        emoji = '🚚'; title = 'Order Shipped';
        msg = 'Your order is out for delivery. Expect it within the estimated time!';
        break;
      case OrderStatus.delivered:
        emoji = '🏠'; title = 'Order Delivered!';
        msg = 'Your medicines have been delivered successfully. Stay healthy! 💊';
        break;
      case OrderStatus.cancelled:
        emoji = '❌'; title = 'Order Cancelled';
        msg = 'Your order has been cancelled. Refund (if any) will be processed in 3-5 days.';
        break;
      default:
        emoji = '📋'; title = 'Order Update';
        msg = 'Your order status has been updated to ${order.statusText}.';
    }
    return _dispatch(order: order, statusEmoji: emoji,
        statusTitle: title, statusMessage: msg);
  }

  // ── INTERNAL ───────────────────────────────────────────────────────────────

  Future<NotifResult> _dispatch({
    required OrderModel order,
    required String statusEmoji,
    required String statusTitle,
    required String statusMessage,
  }) async {
    final results = <NotifResult>[];

    if (order.contactEmail != null && order.contactEmail!.isNotEmpty) {
      results.add(await _sendEmail(
        order: order,
        toEmail: order.contactEmail!,
        statusEmoji: statusEmoji,
        statusTitle: statusTitle,
        statusMessage: statusMessage,
      ));
    }

    if (order.contactPhone != null && order.contactPhone!.isNotEmpty) {
      results.add(await _sendWhatsApp(
        order: order,
        phone: order.contactPhone!,
        statusEmoji: statusEmoji,
        statusTitle: statusTitle,
        statusMessage: statusMessage,
      ));
    }

    if (results.isEmpty) {
      return NotifResult(success: false, message: 'No contact info provided');
    }
    return NotifResult(
      success: results.any((r) => r.success),
      message: results.map((r) => r.message).join(' | '),
    );
  }

  Future<NotifResult> _sendEmail({
    required OrderModel order,
    required String toEmail,
    required String statusEmoji,
    required String statusTitle,
    required String statusMessage,
  }) async {
    final estDelivery = order.estimatedDelivery != null
        ? _fmt(order.estimatedDelivery!)
        : 'Within 2-3 hours';

    final subject =
        '$statusEmoji $statusTitle — MediSure Order #${order.id.substring(0, 8).toUpperCase()}';

    final medicineList = order.items
        .map((i) =>
            '  • ${i.medicineName} (${i.dosage}) x${i.quantity}  =  Rs.${i.total.toStringAsFixed(0)}')
        .join('\n');

    final body =
        '$statusEmoji $statusTitle\n\n'
        '$statusMessage\n\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '        ORDER DETAILS\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'
        'Order ID      :  #${order.id.substring(0, 8).toUpperCase()}\n'
        'Pharmacy      :  ${order.pharmacyName}\n'
        'Address       :  ${order.pharmacyAddress}\n\n'
        'MEDICINES ORDERED:\n$medicineList\n\n'
        'Total Amount  :  Rs.${order.totalAmount.toStringAsFixed(0)}\n'
        'Delivery To   :  ${order.deliveryAddress}\n'
        'Payment       :  ${order.paymentMethod}\n'
        'Est. Delivery :  $estDelivery\n\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n'
        'Thank you for choosing MediSure! 💊\n'
        'Stay healthy and take your medicines on time.\n\n'
        '— $_senderName Team\n'
        'Your Smart Medicine Companion';

    final mailtoUri = Uri.parse(
        'mailto:$toEmail?subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}');

    try {
      // Try externalApplication mode first (opens Gmail on Android)
      final launched = await launchUrl(
        mailtoUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) {
        debugPrint('✅ Email opened for $toEmail');
        return NotifResult(
            success: true, message: 'Email opened for $toEmail');
      }
      // Fallback — try platformDefault
      final fallback = await launchUrl(mailtoUri);
      if (fallback) {
        return NotifResult(
            success: true, message: 'Email opened for $toEmail');
      }
      debugPrint('❌ Cannot open email client');
      return NotifResult(
          success: false, message: 'Could not open email client');
    } catch (e) {
      debugPrint('❌ Email error: $e');
      return NotifResult(success: false, message: 'Email error: $e');
    }
  }

  Future<NotifResult> _sendWhatsApp({
    required OrderModel order,
    required String phone,
    required String statusEmoji,
    required String statusTitle,
    required String statusMessage,
  }) async {
    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final e164 = clean.startsWith('+')
        ? clean.substring(1)
        : clean.length == 10
            ? '91$clean'
            : clean;

    final medicines = order.items.map((i) => i.medicineName).join(', ');

    final msg = Uri.encodeComponent(
      '$statusEmoji *MediSure Order Update*\n\n'
      '*Status:* $statusTitle\n'
      '$statusMessage\n\n'
      '*Order ID:* #${order.id.substring(0, 8).toUpperCase()}\n'
      '*Pharmacy:* ${order.pharmacyName}\n'
      '*Medicines:* $medicines\n'
      '*Total:* Rs.${order.totalAmount.toStringAsFixed(0)}\n'
      '*Delivery:* ${order.deliveryAddress}\n\n'
      '_— MediSure Team 💊_',
    );

    final uri = Uri.parse('https://wa.me/$e164?text=$msg');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return NotifResult(
            success: true, message: 'WhatsApp opened for $phone');
      }
      return NotifResult(
          success: false, message: 'WhatsApp not available on this device');
    } catch (e) {
      return NotifResult(success: false, message: 'WhatsApp error: $e');
    }
  }

  String _fmt(DateTime dt) {
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month}/${dt.year} $h:$m $ampm';
  }
}

class NotifResult {
  final bool success;
  final String message;
  final bool needsSetup;
  NotifResult({
    required this.success,
    required this.message,
    this.needsSetup = false,
  });
}
