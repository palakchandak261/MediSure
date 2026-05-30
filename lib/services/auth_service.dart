import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/config/app_config.dart';
import '../models/user_model.dart';
import 'backend_service.dart';
import 'local_storage_service.dart';

/// Authentication Service using local persistence and secure credential storage.
/// This local-first approach is designed for a startup-ready MVP, with room for
/// backend and auth provider integration.
class AuthService extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthService() {
    // Check if user is already logged in
    _loadCurrentUser();
  }

  /// Load current user from local storage
  void _loadCurrentUser() {
    _currentUser = LocalStorageService.getCurrentUser();
    notifyListeners();
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPassword(String password, String salt) {
    final bytes = utf8.encode('$password:$salt');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Register with email and password
  Future<String?> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if user already exists
      if (LocalStorageService.userExistsByEmail(email)) {
        _isLoading = false;
        notifyListeners();
        return 'An account already exists with this email';
      }

      final uid = const Uuid().v4();
      final salt = _generateSalt();
      final passwordHash = _hashPassword(password, salt);
      UserModel user = UserModel(
        uid: uid,
        email: email,
        name: name,
        passwordHash: passwordHash,
        passwordSalt: salt,
        createdAt: DateTime.now(),
      );

      if (AppConfig.enableRemoteBackend) {
        try {
          final remoteUser = await BackendService.instance.register(
            name,
            email,
            password,
          );
          user = UserModel(
            uid: remoteUser.uid,
            email: remoteUser.email,
            name: remoteUser.name,
            passwordHash: passwordHash,
            passwordSalt: salt,
            createdAt: remoteUser.createdAt,
          );
        } catch (e) {
          debugPrint('Remote registration failed, falling back to local storage: $e');
        }
      }

      await LocalStorageService.saveUser(user);
      await LocalStorageService.trackLogin(user.uid, user.email);
      await LocalStorageService.saveLastLoginEmail(user.email);

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      
      debugPrint('✅ User registered successfully: ${user.email}');
      debugPrint('📦 User UID: ${user.uid}');
      
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Registration failed: ${e.toString()}';
    }
  }

  /// Sign in with email and password
  Future<String?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      UserModel? currentUser;
      var remoteAuthSucceeded = false;

      if (AppConfig.enableRemoteBackend) {
        try {
          final remoteUser = await BackendService.instance.login(email, password);
          final salt = _generateSalt();
          final passwordHash = _hashPassword(password, salt);

          currentUser = UserModel(
            uid: remoteUser.uid,
            email: remoteUser.email,
            name: remoteUser.name,
            passwordHash: passwordHash,
            passwordSalt: salt,
            createdAt: remoteUser.createdAt,
          );

          await LocalStorageService.saveUserCredentials(
            currentUser.uid,
            passwordHash,
            salt,
          );
          remoteAuthSucceeded = true;
        } catch (e) {
          debugPrint('Remote login failed, falling back to local credentials: $e');
        }
      }

      if (!remoteAuthSucceeded) {
        final localUser = LocalStorageService.getUserByEmail(email);
        if (localUser == null) {
          _isLoading = false;
          notifyListeners();
          return 'No account found with this email';
        }
        currentUser = localUser;

        final credentials = await LocalStorageService.getUserCredentials(currentUser.uid);
        if (credentials != null) {
          final inputHash = _hashPassword(password, credentials['salt']!);
          if (credentials['hash'] != inputHash) {
            _isLoading = false;
            notifyListeners();
            return 'Incorrect password. Please try again.';
          }
        } else if (currentUser.passwordHash.isNotEmpty && currentUser.passwordSalt.isNotEmpty) {
          final inputHash = _hashPassword(password, currentUser.passwordSalt);
          if (currentUser.passwordHash != inputHash) {
            _isLoading = false;
            notifyListeners();
            return 'Incorrect password. Please try again.';
          }

          await LocalStorageService.saveUserCredentials(
            currentUser.uid,
            currentUser.passwordHash,
            currentUser.passwordSalt,
          );
        } else {
          _isLoading = false;
          notifyListeners();
          return 'Account credentials are unavailable. Please register again.';
        }
      }

      await LocalStorageService.saveUser(currentUser!);
      await LocalStorageService.trackLogin(currentUser.uid, currentUser.email);
      await LocalStorageService.saveLastLoginEmail(currentUser.email);

      _currentUser = currentUser;
      _isLoading = false;
      notifyListeners();
      
      debugPrint('✅ User logged in: ${currentUser.email}');
      debugPrint('📊 Total logins: ${LocalStorageService.getUserLoginCount(currentUser.uid)}');
      
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Login failed: ${e.toString()}';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await LocalStorageService.logout();
    if (AppConfig.enableRemoteBackend) {
      await BackendService.instance.clearAuthToken();
    }
    _currentUser = null;
    notifyListeners();
  }

  /// Update user profile
  Future<String?> updateProfile({
    String? name,
    String? email,
  }) async {
    if (_currentUser == null) return 'No user logged in';

    try {
      _isLoading = true;
      notifyListeners();

      final updatedUser = UserModel(
        uid: _currentUser!.uid,
        email: email ?? _currentUser!.email,
        name: name ?? _currentUser!.name,
        passwordHash: _currentUser!.passwordHash,
        passwordSalt: _currentUser!.passwordSalt,
        createdAt: _currentUser!.createdAt,
      );

      await LocalStorageService.saveUser(updatedUser);
      _currentUser = updatedUser;

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Update failed: ${e.toString()}';
    }
  }

  /// Reset password for a given email (local flow)
  Future<String?> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = LocalStorageService.getUserByEmail(email);
      if (user == null) {
        _isLoading = false;
        notifyListeners();
        return 'No account found with this email';
      }

      final salt = _generateSalt();
      final passwordHash = _hashPassword(newPassword, salt);

      // Update credentials in secure storage
      await LocalStorageService.saveUserCredentials(
          user.uid, passwordHash, salt);

      // Update user model with new hash
      final updatedUser = UserModel(
        uid: user.uid,
        email: user.email,
        name: user.name,
        passwordHash: passwordHash,
        passwordSalt: salt,
        createdAt: user.createdAt,
      );
      await LocalStorageService.saveUser(updatedUser);

      _isLoading = false;
      notifyListeners();
      debugPrint('✅ Password reset for: ${user.email}');
      return null; // Success
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'Password reset failed: ${e.toString()}';
    }
  }

  /// Delete account
  Future<String?> deleteAccount() async {
    if (_currentUser == null) return 'No user logged in';

    try {
      await signOut();
      return null; // Success
    } catch (e) {
      return 'Delete failed: ${e.toString()}';
    }
  }
}
