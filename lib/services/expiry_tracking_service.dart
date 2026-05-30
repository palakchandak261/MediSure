import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Medicine Expiry Model
class MedicineExpiry {
  final String id;
  final String medicineName;
  final String batchNumber;
  final DateTime expiryDate;
  final DateTime purchaseDate;
  final int quantity;
  final String notes;

  MedicineExpiry({
    required this.id,
    required this.medicineName,
    required this.batchNumber,
    required this.expiryDate,
    required this.purchaseDate,
    required this.quantity,
    this.notes = '',
  });

  bool get isExpired => DateTime.now().isAfter(expiryDate);

  bool get isExpiringSoon {
    final days = expiryDate.difference(DateTime.now()).inDays;
    return days > 0 && days <= 30;
  }

  int get daysUntilExpiry => expiryDate.difference(DateTime.now()).inDays;

  String get expiryStatus {
    if (isExpired) return 'Expired';
    if (isExpiringSoon) return 'Expiring Soon';
    return 'Valid';
  }

  Color get statusColor {
    if (isExpired) return Colors.red;
    if (isExpiringSoon) return Colors.orange;
    return Colors.green;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'medicineName': medicineName,
        'batchNumber': batchNumber,
        'expiryDate': expiryDate.toIso8601String(),
        'purchaseDate': purchaseDate.toIso8601String(),
        'quantity': quantity,
        'notes': notes,
      };

  factory MedicineExpiry.fromMap(Map<String, dynamic> map) => MedicineExpiry(
        id: map['id'] ?? '',
        medicineName: map['medicineName'] ?? '',
        batchNumber: map['batchNumber'] ?? '',
        expiryDate: DateTime.parse(map['expiryDate']),
        purchaseDate: DateTime.parse(map['purchaseDate']),
        quantity: map['quantity'] ?? 0,
        notes: map['notes'] ?? '',
      );
}

/// Expiry Tracking Service — with real SharedPreferences persistence
class ExpiryTrackingService {
  // Singleton
  static final ExpiryTrackingService _instance =
      ExpiryTrackingService._internal();
  static ExpiryTrackingService get instance => _instance;
  ExpiryTrackingService._internal();

  // Factory constructor returns the singleton instance
  factory ExpiryTrackingService() => _instance;

  static const String _key = 'expiry_medicines';
  List<MedicineExpiry> _medicines = [];
  bool _loaded = false;

  Future<void> _load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_key);
      if (json != null) {
        final list = jsonDecode(json) as List;
        _medicines = list
            .map((e) => MedicineExpiry.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      }
      _loaded = true;
      debugPrint('✅ Loaded ${_medicines.length} expiry medicines');
    } catch (e) {
      debugPrint('❌ Expiry load error: $e');
      _loaded = true;
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(_medicines.map((m) => m.toMap()).toList()),
      );
      debugPrint('✅ Saved ${_medicines.length} expiry medicines');
    } catch (e) {
      debugPrint('❌ Expiry save error: $e');
    }
  }

  Future<void> addMedicine(MedicineExpiry medicine) async {
    await _load();
    // Avoid duplicates by name
    _medicines.removeWhere(
        (m) => m.medicineName.toLowerCase() == medicine.medicineName.toLowerCase());
    _medicines.add(medicine);
    await _save();
  }

  Future<List<MedicineExpiry>> getAllMedicinesAsync() async {
    await _load();
    return List.from(_medicines);
  }

  List<MedicineExpiry> getAllMedicines() => _medicines;
  List<MedicineExpiry> getExpiredMedicines() =>
      _medicines.where((m) => m.isExpired).toList();
  List<MedicineExpiry> getExpiringSoonMedicines() =>
      _medicines.where((m) => m.isExpiringSoon).toList();
  List<MedicineExpiry> getValidMedicines() =>
      _medicines.where((m) => !m.isExpired && !m.isExpiringSoon).toList();

  Map<String, int> getExpirySummary() => {
        'total': _medicines.length,
        'expired': getExpiredMedicines().length,
        'expiringSoon': getExpiringSoonMedicines().length,
        'valid': getValidMedicines().length,
      };

  Future<void> deleteMedicine(String id) async {
    await _load();
    _medicines.removeWhere((m) => m.id == id);
    await _save();
  }

  Future<void> updateQuantity(String id, int qty) async {
    await _load();
    final idx = _medicines.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final m = _medicines[idx];
      _medicines[idx] = MedicineExpiry(
        id: m.id,
        medicineName: m.medicineName,
        batchNumber: m.batchNumber,
        expiryDate: m.expiryDate,
        purchaseDate: m.purchaseDate,
        quantity: qty,
        notes: m.notes,
      );
      await _save();
    }
  }

  bool hasMedicine(String name) => _medicines
      .any((m) => m.medicineName.toLowerCase() == name.toLowerCase());

  // Legacy compat
  void initialize(String userId) {}
}
