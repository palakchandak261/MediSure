import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/health_vitals_model.dart';

class HealthVitalsService {
  static final HealthVitalsService _instance = HealthVitalsService._internal();
  static HealthVitalsService get instance => _instance;
  HealthVitalsService._internal();

  static const String _key = 'health_vitals';

  Future<List<HealthVitalsModel>> getUserVitals(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('${_key}_$userId');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return (list
        .map((e) => HealthVitalsModel.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt)));
  }

  Future<void> addVitals(HealthVitalsModel vitals) async {
    final list = await getUserVitals(vitals.userId);
    list.insert(0, vitals);
    await _save(vitals.userId, list);
  }

  Future<void> deleteVitals(String userId, String vitalsId) async {
    final list = await getUserVitals(userId);
    list.removeWhere((v) => v.id == vitalsId);
    await _save(userId, list);
  }

  HealthVitalsModel createVitals({
    required String userId,
    double? systolic,
    double? diastolic,
    double? bloodSugar,
    double? weight,
    double? heartRate,
    double? temperature,
    String? notes,
  }) {
    return HealthVitalsModel(
      id: const Uuid().v4(),
      userId: userId,
      recordedAt: DateTime.now(),
      bloodPressureSystolic: systolic,
      bloodPressureDiastolic: diastolic,
      bloodSugar: bloodSugar,
      weight: weight,
      heartRate: heartRate,
      temperature: temperature,
      notes: notes,
    );
  }

  /// Get latest vitals
  Future<HealthVitalsModel?> getLatestVitals(String userId) async {
    final list = await getUserVitals(userId);
    return list.isEmpty ? null : list.first;
  }

  /// Get BP trend for last 7 readings
  Future<List<Map<String, dynamic>>> getBPTrend(String userId) async {
    final list = await getUserVitals(userId);
    return list
        .where((v) => v.bloodPressureSystolic != null)
        .take(7)
        .map((v) => {
              'date': v.recordedAt,
              'systolic': v.bloodPressureSystolic,
              'diastolic': v.bloodPressureDiastolic,
            })
        .toList();
  }

  /// Get sugar trend
  Future<List<Map<String, dynamic>>> getSugarTrend(String userId) async {
    final list = await getUserVitals(userId);
    return list
        .where((v) => v.bloodSugar != null)
        .take(7)
        .map((v) => {
              'date': v.recordedAt,
              'sugar': v.bloodSugar,
            })
        .toList();
  }

  Future<void> _save(String userId, List<HealthVitalsModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_key}_$userId',
      jsonEncode(list.map((v) => v.toMap()).toList()),
    );
  }
}
