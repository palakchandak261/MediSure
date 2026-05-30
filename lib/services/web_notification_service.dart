import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder_model.dart';

class WebNotificationService {
  static final WebNotificationService _instance = WebNotificationService._internal();
  static WebNotificationService get instance => _instance;

  WebNotificationService._internal();

  Timer? _checkTimer;
  final Set<String> _shownToday = {};
  final List<Function(List<Reminder>)> _notificationCallbacks = [];

  void registerCallback(Function(List<Reminder>) callback) {
    _notificationCallbacks.add(callback);
  }

  void unregisterCallback(Function(List<Reminder>) callback) {
    _notificationCallbacks.remove(callback);
  }

  void startChecking() {
    if (!kIsWeb) return;
    _checkTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkReminders();
    });
    debugPrint('✅ Web notification checker started');
  }

  void stopChecking() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  Future<void> _checkReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getString('reminders');

      if (remindersJson == null) return;

      final now = DateTime.now();
      final currentHour = now.hour;
      final currentMinute = now.minute;

      final remindersList = (jsonDecode(remindersJson) as List)
          .map((e) => Reminder.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      final dueReminders = <Reminder>[];

      for (var reminder in remindersList) {
        if (!reminder.isEnabled) continue;

        // Trigger only at exact minute match
        if (reminder.time.hour == currentHour &&
            reminder.time.minute == currentMinute) {
          final key = [
            reminder.id,
            now.year.toString(),
            now.month.toString(),
            now.day.toString(),
            currentHour.toString(),
            currentMinute.toString(),
          ].join('_');

          if (!_shownToday.contains(key)) {
            _shownToday.add(key);
            dueReminders.add(reminder);
          }
        }
      }

      if (dueReminders.isNotEmpty) {
        debugPrint('🔔 SHOWING ${dueReminders.length} REMINDERS');
        for (var callback in _notificationCallbacks) {
          callback(dueReminders);
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking reminders: $e');
    }
  }
}
