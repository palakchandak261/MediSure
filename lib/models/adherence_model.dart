enum DoseStatus { taken, missed, skipped, pending }

class DoseRecord {
  final String id;
  final String userId;
  final String reminderId;
  final String medicineName;
  final String dosage;
  final DateTime scheduledTime;
  final DateTime? takenAt;
  final DoseStatus status;

  DoseRecord({
    required this.id,
    required this.userId,
    required this.reminderId,
    required this.medicineName,
    required this.dosage,
    required this.scheduledTime,
    this.takenAt,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'reminderId': reminderId,
        'medicineName': medicineName,
        'dosage': dosage,
        'scheduledTime': scheduledTime.toIso8601String(),
        'takenAt': takenAt?.toIso8601String(),
        'status': status.index,
      };

  factory DoseRecord.fromMap(Map<String, dynamic> map) => DoseRecord(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        reminderId: map['reminderId'] ?? '',
        medicineName: map['medicineName'] ?? '',
        dosage: map['dosage'] ?? '',
        scheduledTime: DateTime.parse(map['scheduledTime'] ?? DateTime.now().toIso8601String()),
        takenAt: map['takenAt'] != null ? DateTime.parse(map['takenAt']) : null,
        status: DoseStatus.values[map['status'] ?? 3],
      );
}
