import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint;
import '../core/config/app_config.dart';
import '../core/network/api_client.dart';
import '../models/order_model.dart';
import '../models/payment_session_model.dart';
import '../models/prescription_model.dart';
import '../models/user_model.dart';
import 'secure_storage_service.dart';

class BackendService {
  BackendService._internal();

  static final BackendService instance = BackendService._internal();
  final ApiClient _client = ApiClient();

  bool get enabled => AppConfig.enableRemoteBackend && AppConfig.backendBaseUrl.isNotEmpty;

  Future<Map<String, String>> _authHeaders() async {
    final token = await getAuthToken();
    return token == null ? {} : {'Authorization': 'Bearer $token'};
  }

  Future<String?> getAuthToken() async {
    return await SecureStorageService.instance.read('auth_token');
  }

  Future<String?> getRefreshToken() async {
    return await SecureStorageService.instance.read('refresh_token');
  }

  Future<void> saveAuthToken(String token) async {
    await SecureStorageService.instance.write('auth_token', token);
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await SecureStorageService.instance.write('refresh_token', refreshToken);
  }

  Future<void> clearAuthToken() async {
    await clearAuthTokens();
  }

  Future<void> clearAuthTokens() async {
    await SecureStorageService.instance.delete('auth_token');
    await SecureStorageService.instance.delete('refresh_token');
  }

  Future<bool> _saveTokensFromResponse(Map<String, dynamic> response) async {
    final token = response['token']?.toString() ?? '';
    final refreshToken = response['refreshToken']?.toString() ?? '';

    if (token.isNotEmpty) {
      await saveAuthToken(token);
    }
    if (refreshToken.isNotEmpty) {
      await saveRefreshToken(refreshToken);
    }

    return token.isNotEmpty;
  }

  Future<bool> refreshAuthToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _client.post(
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
      );
      return await _saveTokensFromResponse(response);
    } catch (_) {
      await clearAuthTokens();
      return false;
    }
  }

  Future<Map<String, dynamic>> _withAuthRetry(
    Future<Map<String, dynamic>> Function(Map<String, String>) request,
  ) async {
    try {
      return await request(await _authHeaders());
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        final refreshed = await refreshAuthToken();
        if (refreshed) {
          return await request(await _authHeaders());
        }
      }
      rethrow;
    }
  }

  Future<UserModel> login(String email, String password) async {
    if (!enabled) {
      throw BackendDisabledException();
    }

    final response = await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });

    await _saveTokensFromResponse(response);

    final userMap = Map<String, dynamic>.from(response['user'] ?? {});
    return UserModel.fromMap(userMap);
  }

  Future<UserModel> register(String name, String email, String password) async {
    if (!enabled) {
      throw BackendDisabledException();
    }

    final response = await _client.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });

    await _saveTokensFromResponse(response);

    final userMap = Map<String, dynamic>.from(response['user'] ?? {});
    return UserModel.fromMap(userMap);
  }

  Future<bool> isBackendReachable() async {
    if (!enabled) return false;

    try {
      final response = await _client.get('/health');
      return response['status']?.toString().toLowerCase() == 'ok';
    } catch (_) {
      return false;
    }
  }

  Future<List<PrescriptionModel>> getPrescriptions(String userId) async {
    if (!enabled) {
      throw BackendDisabledException();
    }

    final response = await _withAuthRetry(
      (headers) => _client.get('/users/$userId/prescriptions', headers: headers),
    );

    final items = response['prescriptions'] as List<dynamic>? ?? [];
    return items
        .map((item) => PrescriptionModel.fromMap(
            Map<String, dynamic>.from(item as Map<String, dynamic>)))
        .toList();
  }

  Future<List<OrderModel>> getOrders(String userId) async {
    if (!enabled) {
      throw BackendDisabledException();
    }

    final response = await _withAuthRetry(
      (headers) => _client.get('/users/$userId/orders', headers: headers),
    );

    final items = response['orders'] as List<dynamic>? ?? [];
    return items
        .map((item) => OrderModel.fromMap(
            Map<String, dynamic>.from(item as Map<String, dynamic>)))
        .toList();
  }

  Future<void> placeOrder(Map<String, dynamic> orderData) async {
    if (!enabled) {
      throw BackendDisabledException();
    }

    await _withAuthRetry(
      (headers) => _client.post(
        '/orders',
        body: orderData,
        headers: headers,
      ),
    );
  }

  Future<void> savePrescription(PrescriptionModel prescription) async {
    if (!enabled) {
      throw BackendDisabledException();
    }

    await _withAuthRetry(
      (headers) => _client.post(
        '/users/${prescription.userId}/prescriptions',
        body: prescription.toMap(),
        headers: headers,
      ),
    );
  }

  Future<void> deletePrescription(String userId, String prescriptionId) async {
    if (!enabled) {
      throw BackendDisabledException();
    }

    await _withAuthRetry(
      (headers) => _client.post(
        '/users/$userId/prescriptions/$prescriptionId/delete',
        body: {},
        headers: headers,
      ),
    );
  }

  Future<PaymentSession> createPaymentSession(Map<String, dynamic> orderData) async {
    if (!enabled) {
      throw BackendDisabledException();
    }

    final response = await _withAuthRetry(
      (headers) => _client.post(
        '/payments/upi-session',
        body: orderData,
        headers: headers,
      ),
    );

    final sessionMap = Map<String, dynamic>.from(response['paymentSession'] ?? {});
    return PaymentSession.fromMap(sessionMap);
  }

  Future<bool> verifyPayment(String paymentReference) async {
    if (!enabled) {
      throw BackendDisabledException();
    }

    final response = await _withAuthRetry(
      (headers) => _client.post(
        '/payments/verify',
        body: {'paymentReference': paymentReference},
        headers: headers,
      ),
    );

    return response['status']?.toString().toLowerCase() == 'success';
  }

  /// Verify a Razorpay payment with full signature validation.
  Future<bool> verifyRazorpayPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    if (!enabled) return true; // Trust client if no backend

    final response = await _withAuthRetry(
      (headers) => _client.post(
        '/payments/verify',
        body: {
          'paymentReference': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
        headers: headers,
      ),
    );

    return response['status']?.toString().toLowerCase() == 'success';
  }

  /// Register FCM token with the backend so server can send push notifications.
  Future<void> registerFcmToken(String userId, String fcmToken, String platform) async {
    if (!enabled) return;
    try {
      await _withAuthRetry(
        (headers) => _client.post(
          '/users/$userId/fcm-token',
          body: {'fcmToken': fcmToken, 'platform': platform},
          headers: headers,
        ),
      );
    } catch (e) {
      // Non-critical — don't throw
      debugPrint('FCM token registration failed: $e');
    }
  }
}

class BackendDisabledException implements Exception {
  @override
  String toString() => 'Remote backend integration is disabled.';
}
