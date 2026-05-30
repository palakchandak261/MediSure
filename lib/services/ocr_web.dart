// Web OCR implementation — calls backend Google Vision API.
// Falls back gracefully if backend is not configured.
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../core/config/app_config.dart';
import '../models/medicine_model.dart';
import '../services/prescription_parser.dart';
import '../services/secure_storage_service.dart';

void disposeRecognizers() {}

Future<Map<String, dynamic>> doExtract(
    XFile imageFile, bool useDevanagari) async {
  debugPrint('🌐 Web OCR: calling backend Vision API...');

  try {
    // Read image bytes
    final Uint8List imageBytes = await imageFile.readAsBytes();
    final String base64Image = base64Encode(imageBytes);

    // Try backend OCR endpoint first
    final backendUrl = AppConfig.backendBaseUrl;
    if (backendUrl.isNotEmpty && AppConfig.enableRemoteBackend) {
      final result = await _callBackendOcr(base64Image, backendUrl);
      if (result != null) return result;
    }

    // Direct Google Vision API call (if OCR_API_KEY is set in .env)
    final ocrApiKey = AppConfig.ocrApiKey;
    if (ocrApiKey.isNotEmpty) {
      final result = await _callGoogleVisionDirect(base64Image, ocrApiKey);
      if (result != null) return result;
    }

    // No OCR available on web
    return {
      'extractedText': '',
      'medicines': <MedicineModel>[],
      'isFallback': true,
      'error':
          'Web OCR requires backend setup. Please:\n'
          '1. Start the backend server (see HOW_TO_RUN.md)\n'
          '2. Set ENABLE_REMOTE_BACKEND=true in .env\n'
          '3. Set OCR_API_KEY=your_google_vision_key in .env\n\n'
          'Or use the Android/iOS app for offline OCR.',
    };
  } catch (e) {
    debugPrint('Web OCR error: $e');
    return {
      'extractedText': '',
      'medicines': <MedicineModel>[],
      'isFallback': true,
      'error': 'OCR failed: $e',
    };
  }
}

/// Call backend /api/ocr/extract-base64 endpoint.
Future<Map<String, dynamic>?> _callBackendOcr(
    String base64Image, String backendUrl) async {
  try {
    final token = await SecureStorageService.instance.read('auth_token');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (AppConfig.backendApiKey.isNotEmpty)
        'X-Api-Key': AppConfig.backendApiKey,
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    final response = await http
        .post(
          Uri.parse('$backendUrl/api/ocr/extract-base64'),
          headers: headers,
          body: jsonEncode({'imageBase64': base64Image}),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final extractedText = data['extractedText'] as String? ?? '';

      if (extractedText.isEmpty) {
        return {
          'extractedText': '',
          'medicines': <MedicineModel>[],
          'isFallback': true,
          'error': data['error'] ?? 'No text detected in image.',
        };
      }

      debugPrint('✅ Backend OCR: ${extractedText.length} chars');
      final medicines = PrescriptionParser.parse(extractedText);

      return {
        'extractedText': extractedText,
        'medicines': medicines,
        'isFallback': medicines.isEmpty,
        if (medicines.isEmpty)
          'error': 'No medicines detected. Please try a clearer image.',
      };
    }

    debugPrint('Backend OCR returned ${response.statusCode}');
    return null;
  } catch (e) {
    debugPrint('Backend OCR call failed: $e');
    return null;
  }
}

/// Direct Google Vision API call from Flutter web (no backend needed).
/// Uses OCR_API_KEY from .env
Future<Map<String, dynamic>?> _callGoogleVisionDirect(
    String base64Image, String apiKey) async {
  try {
    final requestBody = jsonEncode({
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1},
          ],
        }
      ],
    });

    final response = await http
        .post(
          Uri.parse(
              'https://vision.googleapis.com/v1/images:annotate?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final responses = data['responses'] as List?;
      if (responses == null || responses.isEmpty) return null;

      final firstResponse = responses[0] as Map<String, dynamic>;
      final fullText =
          (firstResponse['fullTextAnnotation'] as Map?)?['text'] as String? ??
          (firstResponse['textAnnotations'] as List?)
              ?.firstOrNull?['description'] as String? ??
          '';

      if (fullText.isEmpty) {
        return {
          'extractedText': '',
          'medicines': <MedicineModel>[],
          'isFallback': true,
          'error': 'No text detected. Please use a clearer image.',
        };
      }

      debugPrint('✅ Direct Vision OCR: ${fullText.length} chars');
      final medicines = PrescriptionParser.parse(fullText);

      return {
        'extractedText': fullText,
        'medicines': medicines,
        'isFallback': medicines.isEmpty,
        if (medicines.isEmpty)
          'error': 'No medicines detected. Please try a clearer image.',
      };
    }

    debugPrint('Google Vision API returned ${response.statusCode}: ${response.body}');
    return null;
  } catch (e) {
    debugPrint('Direct Vision API call failed: $e');
    return null;
  }
}
