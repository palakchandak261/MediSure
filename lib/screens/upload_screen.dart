import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../services/ocr_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/prescription_model.dart';
import '../models/medicine_model.dart';
import 'result_screen.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _picker = ImagePicker();
  final _ocrService = OCRService();
  final _firestoreService = FirestoreService();
  
  XFile? _selectedImage;
  Uint8List? _webImageBytes; // cached bytes for web preview
  bool _isProcessing = false;
  String _processingStatus = 'Analyzing...';
  String _selectedLanguage = 'English';

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1280,   // reduced from 1920 — faster ML Kit processing
        maxHeight: 720,   // reduced from 1080
        imageQuality: 75, // reduced from 85 — still clear enough for OCR
      );

      if (image != null) {
        // Pre-load bytes on web so the preview works (blob URLs can't be
        // loaded by Image.network on web).
        Uint8List? bytes;
        if (kIsWeb) {
          bytes = await image.readAsBytes();
        }
        setState(() {
          _selectedImage = image;
          _webImageBytes = bytes;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _processImage() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStatus = 'Reading prescription...';
    });

    // Update status messages so the user knows progress
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isProcessing) {
        setState(() => _processingStatus = 'Loading AI model...');
      }
    });
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted && _isProcessing) {
        setState(() => _processingStatus = 'Identifying medicines...');
      }
    });
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && _isProcessing) {
        setState(() => _processingStatus = 'Almost done...');
      }
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // Pass the selected language so ML Kit uses the right script
      _ocrService.setLanguage(_selectedLanguage);

      // Use XFile-based method for proper web support
      final ocrResult = await _ocrService.extractPrescriptionDataFromXFile(
        _selectedImage!,
      );

      final isFallback = ocrResult['isFallback'] == true;
      final error = ocrResult['error'] as String?;
      final medicines = ocrResult['medicines'] as List;

      if (medicines.isEmpty) {
        // No medicines found — do NOT save, just show error
        setState(() => _isProcessing = false);
        _showError(
          error ?? 'No medicines detected. Please try a clearer image.',
        );
        return;
      }

      // Only save when we actually have results
      final imageUrl = _buildImageUrl(_selectedImage!);

      final prescription = PrescriptionModel(
        id: const Uuid().v4(),
        userId: authService.currentUser!.uid,
        imageUrl: imageUrl,
        extractedText: ocrResult['extractedText'] as String? ?? '',
        medicines: List<MedicineModel>.from(ocrResult['medicines'] as List),
        language: _selectedLanguage,
        uploadedAt: DateTime.now(),
      );

      await _firestoreService.savePrescription(prescription);

      if (mounted) {
        if (isFallback && error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ $error'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultScreen(prescription: prescription),
          ),
        );
      }
    } catch (e) {
      _showError('Failed to process prescription: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  /// Returns a stable image URL/path for storage.
  String _buildImageUrl(XFile image) {
    if (kIsWeb) {
      return 'local://prescription_${const Uuid().v4()}.jpg';
    } else {
      return image.path;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6B7FED),
              Color(0xFF8B6FDB),
              Color(0xFFAD65C8),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Decorative particles
            ...List.generate(30, (index) {
              return Positioned(
                left: (index * 37.0) % MediaQuery.of(context).size.width,
                top: (index * 53.0) % MediaQuery.of(context).size.height,
                child: Container(
                  width: 4 + (index % 4) * 3,
                  height: 4 + (index % 4) * 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
            
            // Wave decoration at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 200),
                painter: WavePainter(),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Upload Prescription',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Warning banner
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Ensure prescription is clear and readable',
                                      style: TextStyle(
                                        color: Colors.orange.shade900,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Image preview or placeholder
                            Container(
                              height: 300,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _selectedImage == null
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.image_outlined,
                                            size: 80,
                                            color: Colors.grey.shade400,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'No image selected',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: kIsWeb && _webImageBytes != null
                                          ? Image.memory(
                                              _webImageBytes!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            )
                                          : !kIsWeb
                                              ? Image.file(
                                                  File(_selectedImage!.path),
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                )
                                              : const Center(
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 60,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                    ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Camera'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6B7FED),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isProcessing ? null : () => _pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Gallery'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF6B7FED),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(color: Color(0xFF6B7FED)),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Language selector
                            const Text(
                              'Select Language',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedLanguage,
                                  isExpanded: true,
                                  items: ['English', 'Hindi', 'Marathi', 'Tamil', 'Telugu', 'Kannada', 'Malayalam']
                                      .map((lang) => DropdownMenuItem(
                                            value: lang,
                                            child: Text(lang),
                                          ))
                                      .toList(),
                                  onChanged: _isProcessing
                                      ? null
                                      : (value) {
                                          if (value != null) {
                                            setState(() => _selectedLanguage = value);
                                          }
                                        },
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Process button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isProcessing || _selectedImage == null
                                    ? null
                                    : _processImage,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: _isProcessing
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            _processingStatus,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      )
                                    : const Text(
                                        'Analyze Prescription',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Tips section
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Tips for best results:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTip('Ensure good lighting'),
                                  _buildTip('Keep prescription flat'),
                                  _buildTip('Avoid shadows and glare'),
                                  _buildTip('Capture entire prescription'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
          ),
        ],
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.5,
    );
    
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.5,
    );
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}