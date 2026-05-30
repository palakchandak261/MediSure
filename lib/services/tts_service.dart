import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import: flutter_tts only on mobile
import 'tts_mobile.dart' if (dart.library.html) 'tts_stub.dart' as tts_impl;

/// Text-to-Speech Service.
/// Mobile: uses flutter_tts. Web: all calls silently ignored.
class TTSService {
  bool _initialized = false;

  static const Map<String, String> languageCodes = {
    'English': 'en-US',
    'Hindi': 'hi-IN',
    'Marathi': 'mr-IN',
    'Tamil': 'ta-IN',
    'Telugu': 'te-IN',
    'Kannada': 'kn-IN',
    'Malayalam': 'ml-IN',
  };

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    await tts_impl.ttsInit();
    _initialized = true;
  }

  Future<void> speak(String text) async {
    if (kIsWeb) return;
    await initialize();
    await tts_impl.ttsSpeak(text);
  }

  Future<void> stop() async {
    if (kIsWeb) return;
    await tts_impl.ttsStop();
  }

  Future<void> setLanguage(String language) async {
    if (kIsWeb) return;
    final code = languageCodes[language] ?? 'en-US';
    await tts_impl.ttsSetLanguage(code);
  }

  Future<void> speakMedicineInstructions({
    required String medicineName,
    required String dosage,
    required String timing,
    String language = 'English',
    String? notes,
    String? price,
    List<String>? sideEffects,
    List<String>? warnings,
  }) async {
    if (kIsWeb) return;
    await initialize();
    await setLanguage(language);
    final text =
        'Medicine: $medicineName. Dosage: $dosage. Timing: $timing.'
        '${notes != null ? " Note: $notes." : ""}'
        '${price != null ? " Price: $price." : ""}';
    await speak(text);
  }

  Future<List<String>> getAvailableLanguages() async {
    if (kIsWeb) return ['en-US'];
    return tts_impl.ttsGetLanguages();
  }
}
