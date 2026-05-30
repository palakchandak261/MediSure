import 'medicine_dataset_service.dart';

/// Medicine Information Service — powered by the 11,000-medicine Kaggle dataset.
class MedicineInfoService {

  /// Get full medicine info from dataset.
  Map<String, dynamic>? getMedicineInfo(String medicineName) {
    final entry = MedicineDatasetService.instance.getByName(medicineName);
    if (entry == null) return null;

    return {
      'name':               entry.name,
      'genericName':        entry.genericName,
      'composition':        entry.composition,
      'manufacturer':       entry.manufacturer,
      'category':           entry.category,
      'uses':               entry.uses,
      'usesList':           entry.usesList,
      'sideEffects':        entry.sideEffects,
      'sideEffectsList':    entry.sideEffectsList,
      'imageUrl':           entry.imageUrl,
      'price':              MedicineDatasetService.instance.estimatePrice(medicineName),
      'priceText':          MedicineDatasetService.instance.getPriceRange(medicineName),
      'rating':             entry.ratingScore,
      'ratingText':         entry.ratingText,
      'excellentPct':       entry.excellentPct,
      'averagePct':         entry.averagePct,
      'poorPct':            entry.poorPct,
      'prescriptionNeeded': entry.prescriptionNeeded,
      'alternatives':       MedicineDatasetService.instance.getAlternatives(medicineName),
      'warnings':           _buildWarnings(entry),
    };
  }

  List<String> _buildWarnings(MedicineEntry entry) {
    final warnings = <String>[];
    final lower = entry.composition.toLowerCase() + entry.uses.toLowerCase();

    if (lower.contains('warfarin') || lower.contains('anticoagulant')) {
      warnings.add('Monitor INR regularly');
    }
    if (lower.contains('diabetes') || lower.contains('insulin') || lower.contains('metformin')) {
      warnings.add('Monitor blood sugar levels');
    }
    if (lower.contains('liver') || lower.contains('hepato')) {
      warnings.add('Monitor liver function');
    }
    if (lower.contains('kidney') || lower.contains('renal')) {
      warnings.add('Monitor kidney function');
    }
    if (lower.contains('antibiotic') || lower.contains('bacteria')) {
      warnings.add('Complete the full course even if feeling better');
    }
    if (entry.prescriptionNeeded) {
      warnings.add('Prescription required — take only as directed by doctor');
    }
    if (warnings.isEmpty) {
      warnings.add("Follow doctor's instructions");
    }
    return warnings;
  }

  String getPrice(String medicineName) =>
      MedicineDatasetService.instance.getPriceRange(medicineName);

  List<String> getSideEffects(String medicineName) {
    final entry = MedicineDatasetService.instance.getByName(medicineName);
    return entry?.sideEffectsList ?? ['Consult doctor'];
  }

  List<String> getUses(String medicineName) {
    final entry = MedicineDatasetService.instance.getByName(medicineName);
    return entry?.usesList ?? ['As directed by doctor'];
  }

  List<String> getWarnings(String medicineName) {
    final entry = MedicineDatasetService.instance.getByName(medicineName);
    if (entry == null) return ["Follow doctor's instructions"];
    return _buildWarnings(entry);
  }

  List<String> getAlternatives(String medicineName) =>
      MedicineDatasetService.instance.getAlternatives(medicineName);

  String getManufacturer(String medicineName) {
    final entry = MedicineDatasetService.instance.getByName(medicineName);
    return entry?.manufacturer ?? 'Unknown';
  }

  String getComposition(String medicineName) {
    final entry = MedicineDatasetService.instance.getByName(medicineName);
    return entry?.composition ?? 'Unknown';
  }

  String getRating(String medicineName) {
    final entry = MedicineDatasetService.instance.getByName(medicineName);
    return entry?.ratingText ?? 'No rating available';
  }

  DateTime calculateExpiryDate(String medicineName, DateTime manufactureDate) =>
      manufactureDate.add(const Duration(days: 730));

  bool isExpired(DateTime expiryDate) => DateTime.now().isAfter(expiryDate);

  int daysUntilExpiry(DateTime expiryDate) =>
      expiryDate.difference(DateTime.now()).inDays;
}
