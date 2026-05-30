import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/reminder_model.dart';
import '../models/medicine_model.dart';

/// Extension for TimeOfDay formatting
extension TimeOfDayExtension on TimeOfDay {
  String get format {
    final hour = this.hour.toString().padLeft(2, '0');
    final minute = this.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

/// Reminder Service - Manages medicine reminders
class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  static ReminderService get instance => _instance;
  
  final List<Reminder> _reminders = [];
  bool _isLoaded = false;
  
  ReminderService._internal();

  /// Load reminders from storage
  Future<void> _loadReminders() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getString('reminders');
      
      if (remindersJson != null) {
        final List<dynamic> remindersList = json.decode(remindersJson);
        _reminders.clear();
        
        for (var reminderMap in remindersList) {
          _reminders.add(Reminder.fromMap(Map<String, dynamic>.from(reminderMap)));
        }
        
        debugPrint('✅ Loaded ${_reminders.length} reminders from storage');
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('❌ Failed to load reminders: $e');
    }
  }

  /// Save reminders to storage
  Future<void> _saveReminders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersList = _reminders.map((r) => r.toMap()).toList();
      await prefs.setString('reminders', json.encode(remindersList));
      debugPrint('✅ Saved ${_reminders.length} reminders to storage');
    } catch (e) {
      debugPrint('❌ Failed to save reminders: $e');
    }
  }

  /// Add reminder
  Future<void> addReminder({
    required String userId,
    required String medicineName,
    required String dosage,
    required TimeOfDay time,
  }) async {
    await _loadReminders(); // Ensure loaded
    
    final reminder = Reminder(
      id: const Uuid().v4(),
      userId: userId,
      medicineName: medicineName,
      dosage: dosage,
      time: time,
      isEnabled: true,
      createdAt: DateTime.now(),
    );
    
    _reminders.add(reminder);
    await _saveReminders();
    
    debugPrint('✅ Reminder added: $medicineName at ${time.format}');
  }

  /// Get user reminders
  Future<List<Reminder>> getUserReminders(String userId) async {
    await _loadReminders(); // Ensure loaded
    return _reminders.where((r) => r.userId == userId).toList();
  }

  /// Update reminder
  Future<void> updateReminder(Reminder reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index != -1) {
      _reminders[index] = reminder;
      await _saveReminders();
      debugPrint('✅ Reminder updated: ${reminder.medicineName}');
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    await _saveReminders();
    debugPrint('✅ Reminder deleted: $id');
  }

  /// Create reminders from prescription medicines
  Future<void> createRemindersFromMedicines(
    String userId,
    List<MedicineModel> medicines,
  ) async {
    for (final medicine in medicines) {
      final times = _parseTimingToTimes(medicine.timing);
      
      for (final time in times) {
        await addReminder(
          userId: userId,
          medicineName: medicine.name,
          dosage: medicine.dosage,
          time: time,
        );
      }
    }
  }

  /// Create reminder from single medicine
  Future<void> createReminderFromMedicine(String userId, MedicineModel medicine) async {
    final times = _parseTimingToTimes(medicine.timing);
    
    for (final time in times) {
      await addReminder(
        userId: userId,
        medicineName: medicine.name,
        dosage: medicine.dosage,
        time: time,
      );
    }
  }

  /// Parse timing text to TimeOfDay list
  List<TimeOfDay> _parseTimingToTimes(String timing) {
    final times = <TimeOfDay>[];
    final lower = timing.toLowerCase();

    // Check for specific times mentioned
    if (lower.contains('morning') || lower.contains('breakfast')) {
      times.add(const TimeOfDay(hour: 8, minute: 0));
    }
    
    if (lower.contains('afternoon') || lower.contains('lunch')) {
      times.add(const TimeOfDay(hour: 13, minute: 0));
    }
    
    if (lower.contains('evening') || lower.contains('dinner')) {
      times.add(const TimeOfDay(hour: 19, minute: 0));
    }
    
    if (lower.contains('night') || lower.contains('bedtime') || lower.contains('bed')) {
      times.add(const TimeOfDay(hour: 22, minute: 0));
    }

    // If specific times were found, return them
    if (times.isNotEmpty) {
      return times;
    }

    // Otherwise, check for frequency
    if (lower.contains('once')) {
      if (lower.contains('morning')) {
        times.add(const TimeOfDay(hour: 8, minute: 0));
      } else if (lower.contains('night') || lower.contains('bedtime')) {
        times.add(const TimeOfDay(hour: 22, minute: 0));
      } else if (lower.contains('afternoon')) {
        times.add(const TimeOfDay(hour: 13, minute: 0));
      } else if (lower.contains('evening')) {
        times.add(const TimeOfDay(hour: 19, minute: 0));
      } else {
        // Default once daily - morning
        times.add(const TimeOfDay(hour: 9, minute: 0));
      }
    } else if (lower.contains('twice') || lower.contains('two times') || lower.contains('2 times')) {
      // Twice daily - morning and night
      times.add(const TimeOfDay(hour: 8, minute: 0));
      times.add(const TimeOfDay(hour: 21, minute: 0));
    } else if (lower.contains('three') || lower.contains('thrice') || lower.contains('3 times')) {
      // Three times daily - morning, afternoon, night
      times.add(const TimeOfDay(hour: 8, minute: 0));
      times.add(const TimeOfDay(hour: 14, minute: 0));
      times.add(const TimeOfDay(hour: 21, minute: 0));
    } else if (lower.contains('four') || lower.contains('4 times')) {
      // Four times daily - morning, lunch, evening, night
      times.add(const TimeOfDay(hour: 8, minute: 0));
      times.add(const TimeOfDay(hour: 13, minute: 0));
      times.add(const TimeOfDay(hour: 18, minute: 0));
      times.add(const TimeOfDay(hour: 22, minute: 0));
    } else if (lower.contains('every 6 hours') || lower.contains('6 hourly')) {
      // Every 6 hours
      times.add(const TimeOfDay(hour: 6, minute: 0));
      times.add(const TimeOfDay(hour: 12, minute: 0));
      times.add(const TimeOfDay(hour: 18, minute: 0));
      times.add(const TimeOfDay(hour: 24, minute: 0));
    } else if (lower.contains('every 8 hours') || lower.contains('8 hourly')) {
      // Every 8 hours
      times.add(const TimeOfDay(hour: 8, minute: 0));
      times.add(const TimeOfDay(hour: 16, minute: 0));
      times.add(const TimeOfDay(hour: 24, minute: 0));
    } else if (lower.contains('before meal') || lower.contains('before food')) {
      // Before meals - 30 min before breakfast, lunch, dinner
      times.add(const TimeOfDay(hour: 7, minute: 30));
      times.add(const TimeOfDay(hour: 12, minute: 30));
      times.add(const TimeOfDay(hour: 18, minute: 30));
    } else if (lower.contains('after meal') || lower.contains('after food')) {
      // After meals - 30 min after breakfast, lunch, dinner
      times.add(const TimeOfDay(hour: 9, minute: 0));
      times.add(const TimeOfDay(hour: 14, minute: 0));
      times.add(const TimeOfDay(hour: 20, minute: 0));
    } else {
      // Default: once daily at 9 AM
      times.add(const TimeOfDay(hour: 9, minute: 0));
    }

    return times;
  }
}
