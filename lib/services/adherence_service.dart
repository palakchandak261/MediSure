import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/adherence_model.dart';

class AdherenceService {
  static final AdherenceService _instance = AdherenceService._internal();
  static AdherenceService get instance => _instance;
  AdherenceService._internal();

  static const String _key = 'dose_records';

  Future<List<DoseRecord>> getUserRecords(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('${_key}_$userId');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => DoseRecord.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> markDoseTaken(String userId, String reminderId, String medicineName, String dosage) async {
    final records = await getUserRecords(userId);
    final today = DateTime.now();
    final key = '${reminderId}_${today.year}_${today.month}_${today.day}';

    // Check if already recorded today
    final existing = records.where((r) =>
        r.reminderId == reminderId &&
        r.scheduledTime.year == today.year &&
        r.scheduledTime.month == today.month &&
        r.scheduledTime.day == today.day);

    if (existing.isEmpty) {
      records.add(DoseRecord(
        id: const Uuid().v4(),
        userId: userId,
        reminderId: reminderId,
        medicineName: medicineName,
        dosage: dosage,
        scheduledTime: today,
        takenAt: today,
        status: DoseStatus.taken,
      ));
      await _save(userId, records);
    }
    debugPrint('Dose marked taken: $key');
  }

  Future<void> markDoseMissed(String userId, String reminderId, String medicineName, String dosage, DateTime scheduledTime) async {
    final records = await getUserRecords(userId);
    records.add(DoseRecord(
      id: const Uuid().v4(),
      userId: userId,
      reminderId: reminderId,
      medicineName: medicineName,
      dosage: dosage,
      scheduledTime: scheduledTime,
      status: DoseStatus.missed,
    ));
    await _save(userId, records);
  }

  /// Get adherence percentage for last N days
  Future<double> getAdherencePercentage(String userId, {int days = 7}) async {
    final records = await getUserRecords(userId);
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recent = records.where((r) => r.scheduledTime.isAfter(cutoff)).toList();
    if (recent.isEmpty) return 0.0;
    final taken = recent.where((r) => r.status == DoseStatus.taken).length;
    return (taken / recent.length) * 100;
  }

  /// Get streak (consecutive days with 100% adherence)
  Future<int> getCurrentStreak(String userId) async {
    final records = await getUserRecords(userId);
    if (records.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < 30; i++) {
      final day = today.subtract(Duration(days: i));
      final dayRecords = records.where((r) =>
          r.scheduledTime.year == day.year &&
          r.scheduledTime.month == day.month &&
          r.scheduledTime.day == day.day);

      if (dayRecords.isEmpty) break;

      final allTaken = dayRecords.every((r) => r.status == DoseStatus.taken);
      if (allTaken) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Get calendar data for last 30 days
  Future<Map<String, DoseStatus>> getCalendarData(String userId) async {
    final records = await getUserRecords(userId);
    final result = <String, DoseStatus>{};

    for (final record in records) {
      final key = '${record.scheduledTime.year}-${record.scheduledTime.month.toString().padLeft(2, '0')}-${record.scheduledTime.day.toString().padLeft(2, '0')}';
      // If any dose taken that day, mark as taken; if all missed, mark missed
      if (result[key] == null || record.status == DoseStatus.taken) {
        result[key] = record.status;
      }
    }
    return result;
  }

  /// Get missed doses count
  Future<int> getMissedDosesCount(String userId, {int days = 7}) async {
    final records = await getUserRecords(userId);
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return records
        .where((r) => r.scheduledTime.isAfter(cutoff) && r.status == DoseStatus.missed)
        .length;
  }

  Future<void> _save(String userId, List<DoseRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_key}_$userId',
      jsonEncode(records.map((r) => r.toMap()).toList()),
    );
  }
}
