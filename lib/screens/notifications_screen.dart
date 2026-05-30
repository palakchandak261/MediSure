import 'package:flutter/material.dart';
import '../services/advanced_notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AdvancedNotificationService _service =
      AdvancedNotificationService.instance;
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final notifications = await _service.getNotifications();
    setState(() {
      _notifications = notifications;
      _isLoading = false;
    });
  }

  Future<void> _clearAll() async {
    await _service.clearAll();
    _loadNotifications();
  }

  IconData _icon(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return Icons.alarm_rounded;
      case NotificationType.missedDose:
        return Icons.warning_amber_rounded;
      case NotificationType.refill:
        return Icons.shopping_cart_rounded;
      case NotificationType.expiry:
        return Icons.calendar_today_rounded;
      case NotificationType.adherence:
        return Icons.bar_chart_rounded;
    }
  }

  Color _color(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return const Color(0xFF5C6BC0);
      case NotificationType.missedDose:
        return const Color(0xFFC62828);
      case NotificationType.refill:
        return const Color(0xFF2E7D32);
      case NotificationType.expiry:
        return const Color(0xFFE65100);
      case NotificationType.adherence:
        return const Color(0xFF6A1B9A);
    }
  }

  String _typeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.missedDose:
        return 'Missed Dose';
      case NotificationType.refill:
        return 'Refill';
      case NotificationType.expiry:
        return 'Expiry';
      case NotificationType.adherence:
        return 'Adherence';
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5C6BC0), Color(0xFF7986CB), Color(0xFF9575CD)],
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Notifications',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              unread > 0
                                  ? '$unread unread notification${unread > 1 ? 's' : ''}'
                                  : 'All caught up!',
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    if (_notifications.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearAll,
                        icon: const Icon(Icons.delete_sweep_rounded,
                            color: Colors.white70, size: 18),
                        label: const Text('Clear All',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
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
                              color: Color(0xFF5C6BC0)))
                      : _notifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFEDE7F6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.notifications_none_rounded,
                                        size: 52,
                                        color: Color(0xFF5C6BC0)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('No notifications yet',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A2E))),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Reminders, missed doses & alerts\nwill appear here',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500])),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await AdvancedNotificationService
                                          .instance
                                          .triggerTestNotification();
                                      await Future.delayed(
                                          const Duration(milliseconds: 500));
                                      _loadNotifications();
                                    },
                                    icon: const Icon(
                                        Icons.notifications_active_rounded,
                                        size: 18),
                                    label: const Text('Send Test Notification'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF5C6BC0),
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
                              itemCount: _notifications.length,
                              itemBuilder: (ctx, i) {
                                final notif = _notifications[i];
                                final color = _color(notif.type);
                                return Dismissible(
                                  key: Key(notif.id),
                                  direction:
                                      DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(
                                        right: 20),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade400,
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                        Icons.delete_rounded,
                                        color: Colors.white),
                                  ),
                                  onDismissed: (_) async {
                                    await _service
                                        .markAsRead(notif.id);
                                    _loadNotifications();
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                        bottom: 10),
                                    decoration: BoxDecoration(
                                      color: notif.isRead
                                          ? Colors.white
                                          : color
                                              .withValues(alpha: 0.05),
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      border: notif.isRead
                                          ? null
                                          : Border.all(
                                              color: color.withValues(
                                                  alpha: 0.25)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: InkWell(
                                      onTap: () async {
                                        await _service
                                            .markAsRead(notif.id);
                                        _loadNotifications();
                                      },
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                color: color.withValues(
                                                    alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        12),
                                              ),
                                              child: Icon(
                                                  _icon(notif.type),
                                                  color: color,
                                                  size: 22),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          notif.title,
                                                          style: TextStyle(
                                                            fontWeight: notif
                                                                    .isRead
                                                                ? FontWeight
                                                                    .normal
                                                                : FontWeight
                                                                    .bold,
                                                            fontSize: 14,
                                                            color: const Color(
                                                                0xFF1A1A2E),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal: 7,
                                                            vertical: 3),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: color
                                                              .withValues(
                                                                  alpha:
                                                                      0.12),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      6),
                                                        ),
                                                        child: Text(
                                                          _typeLabel(
                                                              notif.type),
                                                          style: TextStyle(
                                                              color: color,
                                                              fontSize: 9,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(notif.body,
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors
                                                              .grey[600],
                                                          height: 1.4)),
                                                  const SizedBox(height: 5),
                                                  Text(
                                                      _formatTime(
                                                          notif.createdAt),
                                                      style: TextStyle(
                                                          fontSize: 11,
                                                          color: Colors
                                                              .grey[400])),
                                                ],
                                              ),
                                            ),
                                            if (!notif.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                margin: const EdgeInsets
                                                    .only(top: 4, left: 6),
                                                decoration: BoxDecoration(
                                                    color: color,
                                                    shape: BoxShape.circle),
                                              ),
                                          ],
                                        ),
                                      ),
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

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
