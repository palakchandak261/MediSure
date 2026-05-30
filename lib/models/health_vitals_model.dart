class HealthVitalsModel {
  final String id;
  final String userId;
  final DateTime recordedAt;
  final double? bloodPressureSystolic;
  final double? bloodPressureDiastolic;
  final double? bloodSugar;
  final double? weight;
  final double? heartRate;
  final double? temperature;
  final String? notes;

  HealthVitalsModel({
    required this.id,
    required this.userId,
    required this.recordedAt,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.bloodSugar,
    this.weight,
    this.heartRate,
    this.temperature,
    this.notes,
  });

  String get bpStatus {
    if (bloodPressureSystolic == null) return 'N/A';
    if (bloodPressureSystolic! < 120 && bloodPressureDiastolic! < 80) return 'Normal';
    if (bloodPressureSystolic! < 130 && bloodPressureDiastolic! < 80) return 'Elevated';
    if (bloodPressureSystolic! < 140 || bloodPressureDiastolic! < 90) return 'High Stage 1';
    return 'High Stage 2';
  }

  String get sugarStatus {
    if (bloodSugar == null) return 'N/A';
    if (bloodSugar! < 70) return 'Low';
    if (bloodSugar! < 100) return 'Normal';
    if (bloodSugar! < 126) return 'Pre-diabetic';
    return 'High';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'recordedAt': recordedAt.toIso8601String(),
        'bloodPressureSystolic': bloodPressureSystolic,
        'bloodPressureDiastolic': bloodPressureDiastolic,
        'bloodSugar': bloodSugar,
        'weight': weight,
        'heartRate': heartRate,
        'temperature': temperature,
        'notes': notes,
      };

  factory HealthVitalsModel.fromMap(Map<String, dynamic> map) => HealthVitalsModel(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        recordedAt: DateTime.parse(map['recordedAt'] ?? DateTime.now().toIso8601String()),
        bloodPressureSystolic: map['bloodPressureSystolic']?.toDouble(),
        bloodPressureDiastolic: map['bloodPressureDiastolic']?.toDouble(),
        bloodSugar: map['bloodSugar']?.toDouble(),
        weight: map['weight']?.toDouble(),
        heartRate: map['heartRate']?.toDouble(),
        temperature: map['temperature']?.toDouble(),
        notes: map['notes'],
      );
}
