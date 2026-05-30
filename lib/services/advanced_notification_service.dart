import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';

enum NotificationType { reminder, missedDose, refill, expiry, adherence }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic>? data;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.data,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type.index,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
        'data': data,
      };

  factory AppNotification.fromMap(Map<String, dynamic> map) => AppNotification(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        body: map['body'] ?? '',
        type: NotificationType.values[map['type'] ?? 0],
        createdAt:
            DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
        isRead: map['isRead'] ?? false,
        data: map['data'] != null ? Map<String, dynamic>.from(map['data']) : null,
      );
}

class AdvancedNotificationService {
  static final AdvancedNotificationService _instance =
      AdvancedNotificationService._internal();
  static AdvancedNotificationService get instance => _instance;
  AdvancedNotificationService._internal();

  Timer? _checkTimer;
  final Set<String> _shownToday = {};
  final List<Function(List<Reminder>)> _reminderCallbacks = [];
  final List<Function(AppNotification)> _notificationCallbacks = [];
  final Map<String, DateTime> _snoozedReminders = {};

  static const String _notifKey = 'app_notifications';

  void registerReminderCallback(Function(List<Reminder>) cb) =>
      _reminderCallbacks.add(cb);
  void unregisterReminderCallback(Function(List<Reminder>) cb) =>
      _reminderCallbacks.remove(cb);
  void registerNotificationCallback(Function(AppNotification) cb) =>
      _notificationCallbacks.add(cb);
  void unregisterNotificationCallback(Function(AppNotification) cb) =>
      _notificationCallbacks.remove(cb);

  void startChecking() {
    _checkTimer?.cancel();
    // Check every 10 seconds for responsive triggering
    _checkTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _checkReminders());
    // Check immediately on start
    Future.delayed(const Duration(seconds: 1), _checkReminders);
    debugPrint('✅ Advanced notification service started');
  }

  void stopChecking() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Force-trigger a test notification immediately (for testing)
  Future<void> triggerTestNotification() async {
    final prefs = await SharedPreferences.getInstance();
    final remindersJson = prefs.getString('reminders');
    if (remindersJson == null || remindersJson == '[]') {
      // Create a test notification even without reminders
      final testReminder = Reminder(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'test',
        medicineName: 'Test Medicine',
        dosage: '1 tablet',
        time: TimeOfDay.now(),
        isEnabled: true,
        createdAt: DateTime.now(),
      );
      _fireReminderCallbacks([testReminder]);
      await _saveReminderNotification([testReminder]);
      return;
    }

    final list = (jsonDecode(remindersJson) as List)
        .map((e) => Reminder.fromMap(Map<String, dynamic>.from(e)))
        .where((r) => r.isEnabled)
        .toList();

    if (list.isNotEmpty) {
      _fireReminderCallbacks(list.take(3).toList());
      await _saveReminderNotification(list.take(3).toList());
    }
  }

  Future<void> _checkReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getString('reminders');
      if (remindersJson == null) return;

      final now = DateTime.now();
      final remindersList = (jsonDecode(remindersJson) as List)
          .map((e) => Reminder.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      final dueReminders = <Reminder>[];

      for (final reminder in remindersList) {
        if (!reminder.isEnabled) continue;

        // Check snooze
        if (_snoozedReminders.containsKey(reminder.id)) {
          if (now.isBefore(_snoozedReminders[reminder.id]!)) continue;
          _snoozedReminders.remove(reminder.id);
        }

        // Trigger only at exact minute match
        if (reminder.time.hour == now.hour && reminder.time.minute == now.minute) {
          final key =
              '${reminder.id}_${now.year}_${now.month}_${now.day}_${reminder.time.hour}_${reminder.time.minute}';
          if (!_shownToday.contains(key)) {
            _shownToday.add(key);
            dueReminders.add(reminder);
          }
        }
      }

      if (dueReminders.isNotEmpty) {
        debugPrint('🔔 Firing ${dueReminders.length} reminder(s)');
        _fireReminderCallbacks(dueReminders);
        await _saveReminderNotification(dueReminders);
      }
    } catch (e) {
      debugPrint('❌ Error checking reminders: $e');
    }
  }

  void _fireReminderCallbacks(List<Reminder> reminders) {
    for (final cb in _reminderCallbacks) {
      cb(reminders);
    }
  }

  Future<void> _saveReminderNotification(List<Reminder> reminders) async {
    final names = reminders.map((r) => r.medicineName).join(', ');
    final notif = AppNotification(
      id: 'reminder_${DateTime.now().millisecondsSinceEpoch}',
      title: '💊 Medicine Reminder',
      body: reminders.length == 1
          ? 'Time to take ${reminders.first.medicineName} (${reminders.first.dosage})'
          : 'Time to take: $names',
      type: NotificationType.reminder,
      createdAt: DateTime.now(),
      data: {'medicines': names},
    );
    await saveNotification(notif);
    for (final cb in _notificationCallbacks) {
      cb(notif);
    }
  }

  void snoozeReminder(String reminderId, int minutes) {
    _snoozedReminders[reminderId] =
        DateTime.now().add(Duration(minutes: minutes));
    _shownToday.removeWhere((k) => k.startsWith(reminderId));
    debugPrint('⏰ Snoozed $reminderId for $minutes min');
  }

  // ── NOTIFICATION STORE ─────────────────────────────────────────────────────

  Future<void> saveNotification(AppNotification notification) async {
    final notifications = await getNotifications();
    notifications.insert(0, notification);
    if (notifications.length > 100) {
      notifications.removeRange(100, notifications.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _notifKey,
      jsonEncode(notifications.map((n) => n.toMap()).toList()),
    );
  }

  Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_notifKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => AppNotification.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> markAsRead(String notificationId) async {
    final notifications = await getNotifications();
    final idx = notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      notifications[idx].isRead = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _notifKey,
        jsonEncode(notifications.map((n) => n.toMap()).toList()),
      );
    }
  }

  Future<int> getUnreadCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_notifKey);
  }

  // ── ALERT CREATORS ─────────────────────────────────────────────────────────

  Future<void> createRefillAlert(String medicineName, int daysLeft) async {
    final notif = AppNotification(
      id: '${medicineName}_refill_${DateTime.now().millisecondsSinceEpoch}',
      title: '💊 Refill Reminder',
      body:
          '$medicineName is running low. Only $daysLeft days of supply left. Order now!',
      type: NotificationType.refill,
      createdAt: DateTime.now(),
      data: {'medicine': medicineName, 'daysLeft': daysLeft},
    );
    await saveNotification(notif);
    for (final cb in _notificationCallbacks) {
      cb(notif);
    }
  }

  Future<void> createMissedDoseAlert(String medicineName) async {
    final notif = AppNotification(
      id: '${medicineName}_missed_${DateTime.now().millisecondsSinceEpoch}',
      title: '⚠️ Missed Dose',
      body:
          'You missed your $medicineName dose. Please take it as soon as possible.',
      type: NotificationType.missedDose,
      createdAt: DateTime.now(),
      data: {'medicine': medicineName},
    );
    await saveNotification(notif);
    for (final cb in _notificationCallbacks) {
      cb(notif);
    }
  }

  Future<void> createAdherenceReport(double percentage) async {
    String message;
    if (percentage >= 90) {
      message =
          '🌟 Excellent! You took ${percentage.toStringAsFixed(0)}% of your medicines this week!';
    } else if (percentage >= 70) {
      message =
          '👍 Good job! ${percentage.toStringAsFixed(0)}% adherence this week. Keep it up!';
    } else {
      message =
          '⚠️ Only ${percentage.toStringAsFixed(0)}% adherence this week. Try to be more consistent.';
    }
    final notif = AppNotification(
      id: 'adherence_${DateTime.now().millisecondsSinceEpoch}',
      title: '📊 Weekly Adherence Report',
      body: message,
      type: NotificationType.adherence,
      createdAt: DateTime.now(),
      data: {'percentage': percentage},
    );
    await saveNotification(notif);
  }
}
