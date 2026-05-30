import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prescription_model.dart';
import '../models/user_model.dart';
import 'secure_storage_service.dart';

/// Local Storage Service - Replaces Firebase
/// Uses Hive for structured data and SharedPreferences for simple key-value storage
class LocalStorageService {
  static late Box<Map> _userBox;
  static late Box<Map> _prescriptionBox;
  static late SharedPreferences _prefs;

  // Box names
  static const String _userBoxName = 'users';
  static const String _prescriptionBoxName = 'prescriptions';

  /// Initialize local storage
  static Future<void> init() async {
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Open Hive boxes
    _userBox = await Hive.openBox<Map>(_userBoxName);
    _prescriptionBox = await Hive.openBox<Map>(_prescriptionBoxName);
    
    // Restore from backup first
    await _restoreUsersFromBackup();
    await _restorePrescriptionsFromBackup();
    
    // Create default test user if not exists
    await _createDefaultTestUser();
    
    // Print all users for debugging
    printAllUsers();
  }
  
  /// Restore users from SharedPreferences backup
  static Future<void> _restoreUsersFromBackup() async {
    try {
      final usersBackup = _prefs.getString('medisure_users_permanent_backup');
      if (usersBackup != null && usersBackup.isNotEmpty) {
        final usersList = (jsonDecode(usersBackup) as List);
        
        debugPrint('🔄 Restoring ${usersList.length} users from permanent backup...');
        
        for (var userData in usersList) {
          final userMap = Map<String, dynamic>.from(userData);
          final uid = userMap['uid'];
          
          // Always restore from backup to ensure data persistence
          await _userBox.put(uid, userMap);
          debugPrint('   ✅ Restored user: ${userMap['email']}');
        }
        
        debugPrint('✅ Successfully restored ${usersList.length} users');
      } else {
        debugPrint('ℹ️ No backup found to restore');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to restore users from backup: $e');
    }
  }
  
  /// Backup all users to SharedPreferences
  static Future<void> _backupUsers() async {
    try {
      final usersList = _userBox.values.toList();
      final sanitized = usersList.map((userData) {
        final map = Map<String, dynamic>.from(userData);
        map.remove('passwordHash');
        map.remove('passwordSalt');
        return map;
      }).toList();
      final backupJson = jsonEncode(sanitized);
      
      // Save to permanent backup key
      await _prefs.setString('medisure_users_permanent_backup', backupJson);
      
      debugPrint('💾 Backed up ${sanitized.length} users to permanent storage');
      debugPrint('📦 Backup size: ${backupJson.length} characters');
    } catch (e) {
      debugPrint('⚠️ Failed to backup users: $e');
    }
  }
  
  /// Backup all prescriptions to SharedPreferences
  static Future<void> _backupPrescriptions() async {
    try {
      final prescriptionsList = _prescriptionBox.values.toList();
      final backupJson = jsonEncode(prescriptionsList);
      
      // Save to permanent backup key
      await _prefs.setString('medisure_prescriptions_permanent_backup', backupJson);
      
      debugPrint('💾 Backed up ${prescriptionsList.length} prescriptions to permanent storage');
    } catch (e) {
      debugPrint('⚠️ Failed to backup prescriptions: $e');
    }
  }
  
  /// Restore prescriptions from SharedPreferences backup
  static Future<void> _restorePrescriptionsFromBackup() async {
    try {
      final prescriptionsBackup = _prefs.getString('medisure_prescriptions_permanent_backup');
      if (prescriptionsBackup != null && prescriptionsBackup.isNotEmpty) {
        final prescriptionsList = (jsonDecode(prescriptionsBackup) as List);
        
        debugPrint('🔄 Restoring ${prescriptionsList.length} prescriptions from permanent backup...');
        
        for (var prescriptionData in prescriptionsList) {
          final prescriptionMap = Map<String, dynamic>.from(prescriptionData);
          final id = prescriptionMap['id'];
          
          // Always restore from backup
          await _prescriptionBox.put(id, prescriptionMap);
        }
        
        debugPrint('✅ Successfully restored ${prescriptionsList.length} prescriptions');
      } else {
        debugPrint('ℹ️ No prescription backup found to restore');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to restore prescriptions from backup: $e');
    }
  }
  
  /// Create a default test user for easy testing
  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  static String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password:$salt');
    return sha256.convert(bytes).toString();
  }

  static Future<void> _createDefaultTestUser() async {
    const testEmail = 'test@medisure.com';
    const ankitaEmail = 'ankita@medisure.com';
    const defaultPassword = 'MediSure@123';

    debugPrint('🔍 Checking for default users...');
    debugPrint('📦 Current users in box: ${_userBox.length}');

    for (var entry in _userBox.toMap().entries) {
      final userData = entry.value;
      final user = UserModel.fromMap(Map<String, dynamic>.from(userData));
      debugPrint('   - User: ${user.email} (UID: ${user.uid})');
    }

    bool testExists = false;
    bool ankitaExists = false;
    for (var userData in _userBox.values) {
      final user = UserModel.fromMap(Map<String, dynamic>.from(userData));
      if (user.email.toLowerCase() == testEmail.toLowerCase()) {
        testExists = true;
      }
      if (user.email.toLowerCase() == ankitaEmail.toLowerCase()) {
        ankitaExists = true;
      }
    }

    if (!testExists) {
      final salt = _generateSalt();
      final passwordHash = _hashPassword(defaultPassword, salt);
      final testUser = UserModel(
        uid: 'test-user-123',
        email: testEmail,
        name: 'Test User',
        passwordHash: passwordHash,
        passwordSalt: salt,
        createdAt: DateTime.now(),
      );
      await saveUser(testUser);
      debugPrint('✅ Default test user created: $testEmail');
    } else {
      final existing = getUserByEmail(testEmail);
      if (existing != null && await getUserCredentials(existing.uid) == null) {
        final salt = _generateSalt();
        final passwordHash = _hashPassword(defaultPassword, salt);
        await saveUserCredentials(existing.uid, passwordHash, salt);
      }
      debugPrint('✅ Test user already exists');
    }

    if (!ankitaExists) {
      final salt = _generateSalt();
      final passwordHash = _hashPassword(defaultPassword, salt);
      final ankitaUser = UserModel(
        uid: 'ankita-user-456',
        email: ankitaEmail,
        name: 'Ankita',
        passwordHash: passwordHash,
        passwordSalt: salt,
        createdAt: DateTime.now(),
      );
      await saveUser(ankitaUser);
      debugPrint('✅ Default ankita user created: $ankitaEmail');
    } else {
      final existing = getUserByEmail(ankitaEmail);
      if (existing != null && await getUserCredentials(existing.uid) == null) {
        final salt = _generateSalt();
        final passwordHash = _hashPassword(defaultPassword, salt);
        await saveUserCredentials(existing.uid, passwordHash, salt);
      }
      debugPrint('✅ Ankita user already exists');
    }

    debugPrint('📦 Total users after check: ${_userBox.length}');
  }

  // ==================== USER MANAGEMENT ====================

  /// Save user data
  static Future<void> saveUser(UserModel user) async {
    final userMap = Map<String, dynamic>.from(user.toMap());
    userMap.remove('passwordHash');
    userMap.remove('passwordSalt');

    await _userBox.put(user.uid, userMap);
    await _prefs.setString('current_user_id', user.uid);

    if (user.passwordHash.isNotEmpty && user.passwordSalt.isNotEmpty) {
      await saveUserCredentials(user.uid, user.passwordHash, user.passwordSalt);
    }

    // Backup users to SharedPreferences
    await _backupUsers();

    debugPrint('✅ User saved to Hive: ${user.email} (UID: ${user.uid})');
    debugPrint('📦 Total users in box: ${_userBox.length}');
  }

  /// Save user credentials in secure storage
  static Future<void> saveUserCredentials(
    String userId,
    String passwordHash,
    String passwordSalt,
  ) async {
    await SecureStorageService.instance.write('user_credential_${userId}_hash', passwordHash);
    await SecureStorageService.instance.write('user_credential_${userId}_salt', passwordSalt);
  }

  /// Get user credentials from secure storage
  static Future<Map<String, String>?> getUserCredentials(String userId) async {
    final hash = await SecureStorageService.instance.read('user_credential_${userId}_hash');
    final salt = await SecureStorageService.instance.read('user_credential_${userId}_salt');
    if (hash == null || salt == null) return null;
    return {'hash': hash, 'salt': salt};
  }

  /// Remove credentials from secure storage
  static Future<void> deleteUserCredentials(String userId) async {
    await SecureStorageService.instance.delete('user_credential_${userId}_hash');
    await SecureStorageService.instance.delete('user_credential_${userId}_salt');
  }

  /// Get user by ID
  static UserModel? getUser(String uid) {
    final userData = _userBox.get(uid);
    if (userData == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(userData));
  }

  /// Get current logged-in user
  static UserModel? getCurrentUser() {
    final uid = _prefs.getString('current_user_id');
    if (uid == null) return null;
    return getUser(uid);
  }

  /// Check if user exists by email
  static bool userExistsByEmail(String email) {
    debugPrint('🔍 Checking if user exists: $email');
    debugPrint('📦 Total users in box: ${_userBox.length}');
    
    for (var userData in _userBox.values) {
      final user = UserModel.fromMap(Map<String, dynamic>.from(userData));
      debugPrint('   - Found user: ${user.email}');
      if (user.email.toLowerCase() == email.toLowerCase()) {
        debugPrint('✅ User exists!');
        return true;
      }
    }
    debugPrint('❌ User not found');
    return false;
  }

  /// Get user by email
  static UserModel? getUserByEmail(String email) {
    debugPrint('🔍 Getting user by email: $email');
    debugPrint('📦 Total users in box: ${_userBox.length}');
    
    for (var userData in _userBox.values) {
      final user = UserModel.fromMap(Map<String, dynamic>.from(userData));
      debugPrint('   - Checking user: ${user.email}');
      if (user.email.toLowerCase() == email.toLowerCase()) {
        debugPrint('✅ User found!');
        return user;
      }
    }
    debugPrint('❌ User not found');
    return null;
  }

  /// Logout current user
  static Future<void> logout() async {
    await _prefs.remove('current_user_id');
  }

  // ==================== PRESCRIPTION MANAGEMENT ====================

  /// Save prescription
  static Future<void> savePrescription(PrescriptionModel prescription) async {
    // Limit extracted text to prevent size issues (max 5000 characters)
    final limitedPrescription = PrescriptionModel(
      id: prescription.id,
      userId: prescription.userId,
      imageUrl: prescription.imageUrl,
      extractedText: prescription.extractedText.length > 5000 
          ? '${prescription.extractedText.substring(0, 5000)}...[truncated]'
          : prescription.extractedText,
      medicines: prescription.medicines,
      language: prescription.language,
      uploadedAt: prescription.uploadedAt,
    );
    
    await _prescriptionBox.put(limitedPrescription.id, limitedPrescription.toMap());
    
    // Backup prescriptions to SharedPreferences
    await _backupPrescriptions();
    
    debugPrint('💾 Saved prescription to Hive: ${limitedPrescription.id}');
    debugPrint('📦 Total prescriptions in box: ${_prescriptionBox.length}');
  }

  /// Get all prescriptions for a user
  static List<PrescriptionModel> getUserPrescriptions(String userId) {
    final prescriptions = <PrescriptionModel>[];
    
    debugPrint('🔍 Searching prescriptions for user: $userId');
    debugPrint('📦 Total prescriptions in box: ${_prescriptionBox.length}');
    
    for (var prescriptionData in _prescriptionBox.values) {
      final prescription = PrescriptionModel.fromMap(
        Map<String, dynamic>.from(prescriptionData),
      );
      debugPrint('   - Found prescription: ${prescription.id} for user: ${prescription.userId}');
      if (prescription.userId == userId) {
        prescriptions.add(prescription);
      }
    }

    // Sort by date (newest first)
    prescriptions.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    
    debugPrint('✅ Found ${prescriptions.length} prescriptions for user $userId');
    return prescriptions;
  }

  /// Get prescription by ID
  static PrescriptionModel? getPrescription(String id) {
    final prescriptionData = _prescriptionBox.get(id);
    if (prescriptionData == null) return null;
    return PrescriptionModel.fromMap(
      Map<String, dynamic>.from(prescriptionData),
    );
  }

  /// Delete prescription
  static Future<void> deletePrescription(String id) async {
    await _prescriptionBox.delete(id);
  }

  /// Get total prescription count for user
  static int getUserPrescriptionCount(String userId) {
    return getUserPrescriptions(userId).length;
  }

  // ==================== SETTINGS ====================

  /// Save app language
  static Future<void> saveLanguage(String languageCode) async {
    await _prefs.setString('app_language', languageCode);
  }

  /// Get app language
  static String getLanguage() {
    return _prefs.getString('app_language') ?? 'en';
  }

  /// Save theme mode
  static Future<void> saveThemeMode(String mode) async {
    await _prefs.setString('theme_mode', mode);
  }

  /// Get theme mode
  static String getThemeMode() {
    return _prefs.getString('theme_mode') ?? 'light';
  }

  /// Save a boolean setting
  static Future<void> saveBoolSetting(String key, bool value) async {
    await _prefs.setBool('setting_$key', value);
  }

  /// Get a boolean setting with a default value
  static bool getSetting(String key, bool defaultValue) {
    return _prefs.getBool('setting_$key') ?? defaultValue;
  }

  // ==================== LOGIN CREDENTIALS ====================

  /// Save last login email for autofill
  static Future<void> saveLastLoginEmail(String email) async {
    await _prefs.setString('last_login_email', email);
  }

  /// Get last login email
  static String? getLastLoginEmail() {
    return _prefs.getString('last_login_email');
  }

  /// Get recent login emails (for suggestions)
  static List<String> getRecentLoginEmails() {
    final history = getLoginHistory();
    final emails = history.map((e) => e['email']!).toSet().toList();
    return emails.take(5).toList(); // Return last 5 unique emails
  }

  // ==================== LOGIN HISTORY ====================

  /// Track login history
  static Future<void> trackLogin(String userId, String email) async {
    final loginHistory = getLoginHistory();
    
    final loginEntry = {
      'userId': userId,
      'email': email,
      'timestamp': DateTime.now().toIso8601String(),
      'device': 'Web', // Can be enhanced to detect actual device
    };
    
    loginHistory.insert(0, loginEntry);
    
    // Keep only last 50 logins
    if (loginHistory.length > 50) {
      loginHistory.removeRange(50, loginHistory.length);
    }
    
    await _prefs.setString('login_history', loginHistory.map((e) => 
      '${e['userId']}|${e['email']}|${e['timestamp']}|${e['device']}'
    ).join(';;'));
  }

  /// Get login history
  static List<Map<String, String>> getLoginHistory() {
    final historyString = _prefs.getString('login_history');
    if (historyString == null || historyString.isEmpty) return [];
    
    return historyString.split(';;').map((entry) {
      final parts = entry.split('|');
      if (parts.length >= 4) {
        return {
          'userId': parts[0],
          'email': parts[1],
          'timestamp': parts[2],
          'device': parts[3],
        };
      }
      return <String, String>{};
    }).where((e) => e.isNotEmpty).toList();
  }

  /// Get user's login count
  static int getUserLoginCount(String userId) {
    final history = getLoginHistory();
    return history.where((e) => e['userId'] == userId).length;
  }

  /// Get last login time for user
  static DateTime? getLastLoginTime(String userId) {
    final history = getLoginHistory();
    final userLogins = history.where((e) => e['userId'] == userId).toList();
    
    if (userLogins.isEmpty) return null;
    
    try {
      return DateTime.parse(userLogins.first['timestamp']!);
    } catch (e) {
      return null;
    }
  }

  // ==================== EXPIRY TRACKING ====================

  /// Save expiry tracking data
  static Future<void> saveExpiryData(String userId, List<Map<String, dynamic>> medicines) async {
    await _prefs.setString('expiry_data_$userId', medicines.map((m) => 
      '${m['id']}|${m['medicineName']}|${m['batchNumber']}|${m['expiryDate']}|${m['purchaseDate']}|${m['quantity']}|${m['notes']}'
    ).join(';;'));
  }

  /// Get expiry tracking data
  static List<Map<String, dynamic>> getExpiryData(String userId) {
    final dataString = _prefs.getString('expiry_data_$userId');
    if (dataString == null || dataString.isEmpty) return [];
    
    return dataString.split(';;').map((entry) {
      final parts = entry.split('|');
      if (parts.length >= 7) {
        return {
          'id': parts[0],
          'medicineName': parts[1],
          'batchNumber': parts[2],
          'expiryDate': parts[3],
          'purchaseDate': parts[4],
          'quantity': parts[5],
          'notes': parts[6],
        };
      }
      return <String, dynamic>{};
    }).where((e) => e.isNotEmpty).toList();
  }

  // ==================== UTILITY ====================

  /// Get all users (for debugging)
  static List<UserModel> getAllUsers() {
    final users = <UserModel>[];
    for (var userData in _userBox.values) {
      users.add(UserModel.fromMap(Map<String, dynamic>.from(userData)));
    }
    return users;
  }

  /// Print all users (for debugging)
  static void printAllUsers() {
    debugPrint('📋 All registered users:');
    debugPrint('📦 Total users: ${_userBox.length}');
    for (var entry in _userBox.toMap().entries) {
      final userData = entry.value;
      final user = UserModel.fromMap(Map<String, dynamic>.from(userData));
      debugPrint('   - ${user.email} (${user.name}) - UID: ${user.uid}');
    }
  }

  /// Clear all data (for testing/reset)
  static Future<void> clearAll() async {
    await _userBox.clear();
    await _prescriptionBox.clear();
    await _prefs.clear();
    debugPrint('🗑️ All data cleared');
  }

  /// Get storage statistics
  static Map<String, int> getStats() {
    return {
      'total_users': _userBox.length,
      'total_prescriptions': _prescriptionBox.length,
    };
  }
}
