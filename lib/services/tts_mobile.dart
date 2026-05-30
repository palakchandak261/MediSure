import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_tts/flutter_tts.dart';

final FlutterTts _tts = FlutterTts();
String _currentLang = 'en-US';

Future<void> ttsInit() async {
  await _tts.setLanguage(_currentLang);
  await _tts.setSpeechRate(0.9);
  await _tts.setVolume(1.0);
  await _tts.setPitch(1.0);
}

Future<void> ttsSpeak(String text) async {
  try {
    await _tts.speak(text);
  } catch (e) {
    debugPrint('TTS speak error: $e');
  }
}

Future<void> ttsStop() async {
  try {
    await _tts.stop();
  } catch (e) {
    debugPrint('TTS stop error: $e');
  }
}

Future<void> ttsSetLanguage(String code) async {
  if (code == _currentLang) return;
  _currentLang = code;
  try {
    await _tts.setLanguage(code);
  } catch (e) {
    debugPrint('TTS setLanguage error: $e');
    await _tts.setLanguage('en-US');
  }
}

Future<List<String>> ttsGetLanguages() async {
  try {
    final langs = await _tts.getLanguages;
    if (langs == null) return ['en-US'];
    return List<String>.from(langs);
  } catch (e) {
    return ['en-US'];
  }
}
