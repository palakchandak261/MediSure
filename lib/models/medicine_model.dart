class MedicineModel {
  final String name;
  final String dosage;
  final String timing;
  final double confidence;
  final String? notes;

  MedicineModel({
    required this.name,
    required this.dosage,
    required this.timing,
    required this.confidence,
    this.notes,
  });

  // Confidence level as string
  String get confidenceLevel {
    if (confidence >= 80) return 'High';
    if (confidence >= 60) return 'Medium';
    return 'Low';
  }

  // Check if verification needed
  bool get needsVerification => confidence < 60;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'timing': timing,
      'confidence': confidence,
      'notes': notes,
    };
  }

  factory MedicineModel.fromMap(Map<String, dynamic> map) {
    return MedicineModel(
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      timing: map['timing'] ?? '',
      confidence: (map['confidence'] ?? 0).toDouble(),
      notes: map['notes'],
    );
  }
}
