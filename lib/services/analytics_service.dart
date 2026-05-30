import 'package:flutter/foundation.dart';
import '../models/prescription_model.dart';
import '../models/medicine_model.dart';

/// Analytics Service - Provides health insights and statistics
class AnalyticsService {
  final Map<String, int> _medicineUsageTracker = {};

  /// Track medicine usage
  void trackMedicineUsage(String medicineName) {
    _medicineUsageTracker[medicineName] = 
        (_medicineUsageTracker[medicineName] ?? 0) + 1;
    debugPrint('Tracked usage: $medicineName (${_medicineUsageTracker[medicineName]} times)');
  }

  /// Get medicine usage tracker
  Map<String, int> getMedicineUsageTracker() {
    return Map.from(_medicineUsageTracker);
  }

  /// Get medicine usage statistics
  Map<String, dynamic> getMedicineStats(List<PrescriptionModel> prescriptions) {
    final allMedicines = <MedicineModel>[];
    final medicineCount = <String, int>{};
    final categoryCount = <String, int>{};

    for (final prescription in prescriptions) {
      allMedicines.addAll(prescription.medicines);
      
      for (final medicine in prescription.medicines) {
        // Count medicine frequency
        medicineCount[medicine.name] = (medicineCount[medicine.name] ?? 0) + 1;
        
        // Count by category
        final category = _getMedicineCategory(medicine.name);
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
    }

    // Find most prescribed medicine
    String? mostPrescribed;
    int maxCount = 0;
    medicineCount.forEach((name, count) {
      if (count > maxCount) {
        maxCount = count;
        mostPrescribed = name;
      }
    });

    return {
      'totalPrescriptions': prescriptions.length,
      'totalMedicines': allMedicines.length,
      'uniqueMedicines': medicineCount.length,
      'mostPrescribed': mostPrescribed ?? 'None',
      'prescriptionFrequency': maxCount,
      'medicineCount': medicineCount,
      'categoryCount': categoryCount,
    };
  }

  /// Get monthly prescription trend
  Map<String, int> getMonthlyTrend(List<PrescriptionModel> prescriptions) {
    final monthlyCount = <String, int>{};

    for (final prescription in prescriptions) {
      final month = '${prescription.uploadedAt.year}-${prescription.uploadedAt.month.toString().padLeft(2, '0')}';
      monthlyCount[month] = (monthlyCount[month] ?? 0) + 1;
    }

    return monthlyCount;
  }

  /// Get medicine category distribution
  Map<String, int> getCategoryDistribution(List<PrescriptionModel> prescriptions) {
    final categoryCount = <String, int>{};

    for (final prescription in prescriptions) {
      for (final medicine in prescription.medicines) {
        final category = _getMedicineCategory(medicine.name);
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }
    }

    return categoryCount;
  }

  /// Get average confidence score
  double getAverageConfidence(List<PrescriptionModel> prescriptions) {
    if (prescriptions.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int count = 0;

    for (final prescription in prescriptions) {
      for (final medicine in prescription.medicines) {
        totalConfidence += medicine.confidence;
        count++;
      }
    }

    return count > 0 ? totalConfidence / count : 0.0;
  }

  /// Get health insights
  List<String> getHealthInsights(List<PrescriptionModel> prescriptions) {
    final insights = <String>[];
    final stats = getMedicineStats(prescriptions);

    // Insight 1: Prescription frequency
    if (stats['totalPrescriptions'] > 5) {
      insights.add('You have ${stats['totalPrescriptions']} prescriptions. Regular health monitoring is important.');
    }

    // Insight 2: Most prescribed medicine
    if (stats['mostPrescribed'] != 'None') {
      insights.add('${stats['mostPrescribed']} is your most prescribed medicine (${stats['prescriptionFrequency']} times).');
    }

    // Insight 3: Medicine variety
    if (stats['uniqueMedicines'] > 10) {
      insights.add('You\'re taking ${stats['uniqueMedicines']} different medicines. Consult your doctor about simplifying your regimen.');
    }

    // Insight 4: Recent activity
    if (prescriptions.isNotEmpty) {
      final lastPrescription = prescriptions.first;
      final daysSince = DateTime.now().difference(lastPrescription.uploadedAt).inDays;
      
      if (daysSince > 30) {
        insights.add('Last prescription was $daysSince days ago. Consider a health checkup.');
      }
    }

    return insights;
  }

  /// Categorize medicine
  String _getMedicineCategory(String medicineName) {
    final name = medicineName.toLowerCase();

    if (name.contains('paracetamol') || name.contains('dolo') || 
        name.contains('ibuprofen') || name.contains('aspirin')) {
      return 'Pain Relief';
    } else if (name.contains('amoxicillin') || name.contains('azithromycin') || 
               name.contains('cipro')) {
      return 'Antibiotics';
    } else if (name.contains('cetirizine') || name.contains('levocet')) {
      return 'Allergy';
    } else if (name.contains('omeprazole') || name.contains('pantoprazole')) {
      return 'Acidity';
    } else if (name.contains('metformin') || name.contains('glimepiride')) {
      return 'Diabetes';
    } else if (name.contains('amlodipine') || name.contains('telmisartan')) {
      return 'Blood Pressure';
    } else if (name.contains('atorvastatin') || name.contains('rosuvastatin')) {
      return 'Cholesterol';
    } else if (name.contains('vitamin') || name.contains('calcium')) {
      return 'Supplements';
    }

    return 'Other';
  }
}
