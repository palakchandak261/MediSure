import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration values loaded from runtime environment.
///
/// For development, create a `.env` file or use Dart defines:
/// ```bash
/// flutter run \
///   --dart-define=ENABLE_REMOTE_BACKEND=true \
///   --dart-define=BACKEND_BASE_URL=https://api.medisure.com \
///   --dart-define=BACKEND_API_KEY=your_backend_key \
///   --dart-define=UPI_ID=merchant@bank \
///   --dart-define=UPI_PAYEE_NAME="MediSure Pharmacy"
/// ```
class AppConfig {
  static final Map<String, String> _env = <String, String>{};
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await dotenv.load(fileName: '.env');
      _env.addAll(dotenv.env);
    } catch (_) {
      // Ignore missing .env during production builds.
    }
    _initialized = true;
  }

  static String _compileTimeString(String key) {
    // ignore: prefer_const_constructors
    return String.fromEnvironment(key, defaultValue: '');
  }

  static bool _compileTimeBool(String key, bool defaultValue) {
    // ignore: prefer_const_constructors
    final raw = String.fromEnvironment(key, defaultValue: '');
    if (raw.isEmpty) return defaultValue;
    return raw.toLowerCase() == 'true';
  }

  static String _string(String key, String defaultValue) {
    final runtimeValue = _env[key];
    if (runtimeValue != null && runtimeValue.isNotEmpty) {
      return runtimeValue;
    }
    final compileValue = _compileTimeString(key);
    return compileValue.isNotEmpty ? compileValue : defaultValue;
  }

  static bool _bool(String key, bool defaultValue) {
    final runtimeValue = _env[key];
    if (runtimeValue != null && runtimeValue.isNotEmpty) {
      return runtimeValue.toLowerCase() == 'true';
    }
    return _compileTimeBool(key, defaultValue);
  }

  static bool get isProduction => _bool('IS_PRODUCTION', false);

  static bool get enableRemoteBackend => _bool('ENABLE_REMOTE_BACKEND', false);

  static String get backendBaseUrl => _string(
        'BACKEND_BASE_URL',
        'https://api.medisure.dev',
      ).replaceAll(RegExp(r'/*$'), '');

  static String get backendApiKey => _string('BACKEND_API_KEY', '');

  static String get mapsApiKey => _string('MAPS_API_KEY', '');

  static String get ocrApiKey => _string('OCR_API_KEY', '');

  static String get weatherApiKey => _string('WEATHER_API_KEY', '');

  static String get placesApiKey => _string('PLACES_API_KEY', '');

  static String get upiId => _string('UPI_ID', '');

  static String get upiPayeeName => _string('UPI_PAYEE_NAME', '');

  static String get paymentGatewayApiKey => _string('PAYMENT_GATEWAY_API_KEY', '');

  static String get razorpayKeyId => _string('RAZORPAY_KEY_ID', '');
}
