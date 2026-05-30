import 'medicine_model.dart';

/// Simplified Prescription Model for MVP
class PrescriptionModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String extractedText;
  final List<MedicineModel> medicines;
  final String language;
  final DateTime uploadedAt;

  PrescriptionModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.extractedText,
    required this.medicines,
    required this.language,
    required this.uploadedAt,
  });

  // Convert to Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'extractedText': extractedText,
      'medicines': medicines.map((m) => m.toMap()).toList(),
      'language': language,
      'uploadedAt': uploadedAt.toIso8601String(),
    };
  }

  // Create from stored map
  factory PrescriptionModel.fromMap(Map<String, dynamic> map) {
    return PrescriptionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      extractedText: map['extractedText'] ?? '',
      medicines: (map['medicines'] as List<dynamic>?)
              ?.map((m) => MedicineModel.fromMap(m))
              .toList() ??
          [],
      language: map['language'] ?? 'English',
      uploadedAt: map['uploadedAt'] is String
          ? DateTime.parse(map['uploadedAt'])
          : DateTime.now(),
    );
  }
}
