import 'package:flutter/material.dart';

class Reminder {
  final String id;
  final String userId;
  final String medicineName;
  final String dosage;
  final TimeOfDay time;
  final bool isEnabled;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.userId,
    required this.medicineName,
    required this.dosage,
    required this.time,
    this.isEnabled = true,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'medicineName': medicineName,
      'dosage': dosage,
      'timeHour': time.hour,
      'timeMinute': time.minute,
      'isEnabled': isEnabled,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      medicineName: map['medicineName'] ?? '',
      dosage: map['dosage'] ?? '',
      time: TimeOfDay(
        hour: map['timeHour'] ?? 0,
        minute: map['timeMinute'] ?? 0,
      ),
      isEnabled: map['isEnabled'] ?? true,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
