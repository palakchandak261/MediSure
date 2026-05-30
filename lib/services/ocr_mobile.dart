import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../models/medicine_model.dart';
import 'prescription_parser.dart';

// Single Latin recognizer — works for ALL Indian prescriptions.
// Medicine names on Indian prescriptions (even Hindi/Marathi ones)
// are always written in English/Latin script (e.g. Pan-40, Augmentin).
// Devanagari pass is skipped entirely to avoid model download crashes.
TextRecognizer? _latinRecognizer;

TextRecognizer _getRecognizer() {
  _latinRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
  return _latinRecognizer!;
}

void disposeRecognizers() {
  try {
    _latinRecognizer?.close();
  } catch (_) {}
  _latinRecognizer = null;
}

Future<Map<String, dynamic>> doExtract(
    XFile imageFile, bool useDevanagari) async {
  debugPrint('📱 ML Kit scanning (Latin)...');
  String rawText = '';

  try {
    final result = await _getRecognizer()
        .processImage(InputImage.fromFilePath(imageFile.path));
    rawText = result.text;
    debugPrint('ML Kit: ${rawText.length} chars extracted');
  } catch (e) {
    debugPrint('ML Kit error: $e — retrying with fresh recognizer');
    try {
      _latinRecognizer?.close();
      _latinRecognizer = null;
      final result = await _getRecognizer()
          .processImage(InputImage.fromFilePath(imageFile.path));
      rawText = result.text;
      debugPrint('ML Kit retry: ${rawText.length} chars');
    } catch (e2) {
      debugPrint('ML Kit retry failed: $e2');
      return {
        'extractedText': '',
        'medicines': <MedicineModel>[],
        'isFallback': true,
        'error': 'Could not read image. Please ensure good lighting.',
      };
    }
  }

  if (rawText.trim().isEmpty) {
    return {
      'extractedText': '',
      'medicines': <MedicineModel>[],
      'isFallback': true,
      'error':
          'Could not read text from image. Please ensure good lighting and a clear, flat prescription.',
    };
  }

  debugPrint('🔍 Parsing prescription text...');
  final medicines = PrescriptionParser.parse(rawText);
  debugPrint('✅ Found ${medicines.length} medicines');

  if (medicines.isEmpty) {
    return {
      'extractedText': rawText,
      'medicines': <MedicineModel>[],
      'isFallback': true,
      'error':
          'No medicines detected. Please ensure the prescription is clear and well-lit.',
    };
  }

  return {
    'extractedText': rawText,
    'medicines': medicines,
    'isFallback': false,
  };
}
