import '../core/config/app_config.dart';
import '../models/prescription_model.dart';
import 'backend_service.dart';
import 'local_storage_service.dart';

/// Prescription data service with backend integration fallback.
class FirestoreService {
  // Save prescription to local storage
  Future<void> savePrescription(PrescriptionModel prescription) async {
    try {
      if (AppConfig.enableRemoteBackend) {
        await BackendService.instance.savePrescription(prescription);
        return;
      }
      await LocalStorageService.savePrescription(prescription);
    } catch (e) {
      throw 'Failed to save prescription: $e';
    }
  }

  // Get all prescriptions for a user
  Future<List<PrescriptionModel>> getPrescriptions(String userId) async {
    try {
      if (AppConfig.enableRemoteBackend) {
        return await BackendService.instance.getPrescriptions(userId);
      }
      return LocalStorageService.getUserPrescriptions(userId);
    } catch (e) {
      throw 'Failed to get prescriptions: $e';
    }
  }

  // Get single prescription
  Future<PrescriptionModel?> getPrescription(
    String userId,
    String prescriptionId,
  ) async {
    try {
      final prescription = LocalStorageService.getPrescription(prescriptionId);
      
      // Verify it belongs to the user
      if (prescription != null && prescription.userId == userId) {
        return prescription;
      }
      return null;
    } catch (e) {
      throw 'Failed to get prescription: $e';
    }
  }

  // Delete prescription
  Future<void> deletePrescription(String userId, String prescriptionId) async {
    try {
      if (AppConfig.enableRemoteBackend) {
        await BackendService.instance.deletePrescription(userId, prescriptionId);
        return;
      }

      // Verify ownership before deleting
      final prescription = LocalStorageService.getPrescription(prescriptionId);
      if (prescription != null && prescription.userId == userId) {
        await LocalStorageService.deletePrescription(prescriptionId);
        return;
      }
      throw 'Prescription not found or access denied';
    } catch (e) {
      throw 'Failed to delete prescription: $e';
    }
  }

  // Update prescription
  Future<void> updatePrescription(PrescriptionModel prescription) async {
    try {
      if (AppConfig.enableRemoteBackend) {
        await LocalStorageService.savePrescription(prescription);
        return;
      }
      await LocalStorageService.savePrescription(prescription);
    } catch (e) {
      throw 'Failed to update prescription: $e';
    }
  }

  // Get prescription count for user
  Future<int> getPrescriptionCount(String userId) async {
    try {
      return LocalStorageService.getUserPrescriptionCount(userId);
    } catch (e) {
      return 0;
    }
  }
}
