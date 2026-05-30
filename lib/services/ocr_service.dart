import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import '../models/medicine_model.dart';

// Conditional import: mobile uses ML Kit, web uses a stub
import 'ocr_mobile.dart' if (dart.library.html) 'ocr_web.dart'
    as ocr_impl;

/// OCR Service — works on both mobile and web.
///
/// Mobile : Google ML Kit (on-device, free, no internet)
/// Web    : Returns a clear message (ML Kit is mobile-only)
class OCRService {
  bool _useDevanagari = false;

  void setLanguage(String language) {
    _useDevanagari = (language == 'Hindi' || language == 'Marathi');
  }

  Future<Map<String, dynamic>> extractPrescriptionDataFromXFile(
      XFile imageFile) async {
    try {
      return await ocr_impl
          .doExtract(imageFile, _useDevanagari)
          .timeout(
        // 60 seconds — ML Kit on first run downloads the model (~5MB)
        // which can take 20-30s on slow connections. Subsequent runs are fast.
        const Duration(seconds: 60),
        onTimeout: () => {
          'extractedText': '',
          'medicines': <MedicineModel>[],
          'isFallback': true,
          'error':
              'Scan timed out. This can happen on first use while the AI model downloads.\n'
              'Please try again — it will be faster next time.',
        },
      );
    } catch (e) {
      debugPrint('OCR Error: $e');
      return {
        'extractedText': '',
        'medicines': <MedicineModel>[],
        'isFallback': true,
        'error': 'Failed to process image: $e',
      };
    }
  }

  void dispose() => ocr_impl.disposeRecognizers();
}
