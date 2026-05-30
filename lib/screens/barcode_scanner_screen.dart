import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../services/barcode_scanner_service.dart';
import '../services/expiry_tracking_service.dart';

/// Barcode Scanner Screen - Scan and verify medicine barcodes
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final _barcodeService = BarcodeScannerService();
  final _barcodeController = TextEditingController();
  
  bool _isScanning = false;
  MedicineBarcodeData? _scannedData;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    // Generate random barcode for demo
    final barcode = _barcodeService.generateRandomBarcode();
    _barcodeController.text = barcode;
    await _processBarcode(barcode);
  }

  Future<void> _processBarcode(String barcode) async {
    if (barcode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a barcode'),
          backgroundColor: AppTheme.dangerRed,
        ),
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _scannedData = null;
    });

    try {
      final data = await _barcodeService.scanBarcode(barcode);
      setState(() {
        _scannedData = data;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning barcode: $e'),
            backgroundColor: AppTheme.dangerRed,
          ),
        );
      }
    }
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
              // Custom AppBar
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Barcode Scanner',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Scanner Area
                        Card(
                          elevation: 4,
                          child: Container(
                            height: 250,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue.shade50,
                                  Colors.purple.shade50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _isScanning
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const CircularProgressIndicator(),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Scanning barcode...',
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.qr_code_scanner,
                                          size: 100,
                                          color: AppTheme.primaryPurple.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Tap button below to scan',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Manual Entry
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Or Enter Barcode Manually',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _barcodeController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: 'Enter 13-digit barcode',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(Icons.search),
                                      onPressed: () => _processBarcode(_barcodeController.text),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Scan Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isScanning ? null : _scanBarcode,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan Barcode (Demo)'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primaryPurple,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Scanned Data Display
                        if (_scannedData != null) _buildScannedDataCard(),
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

  Widget _buildScannedDataCard() {
    final data = _scannedData!;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Authenticity Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Scan Results',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: data.isAuthentic
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data.isAuthentic ? Icons.verified : Icons.warning,
                        size: 16,
                        color: data.isAuthentic
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        data.isAuthentic ? 'AUTHENTIC' : 'SUSPICIOUS',
                        style: TextStyle(
                          color: data.isAuthentic
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildDetailRow('Medicine', data.medicineName, Icons.medication),
            _buildDetailRow('Manufacturer', data.manufacturer, Icons.business),
            _buildDetailRow('Batch Number', data.batchNumber, Icons.numbers),
            _buildDetailRow('Pack Size', data.packSize, Icons.inventory_2),
            _buildDetailRow('MRP', data.mrp, Icons.attach_money),
            _buildDetailRow(
              'Mfg Date',
              _formatDate(data.mfgDate),
              Icons.calendar_today,
            ),
            _buildDetailRow(
              'Expiry Date',
              _formatDate(data.expiryDate),
              Icons.event_busy,
            ),
            _buildDetailRow('Barcode', data.barcode, Icons.qr_code),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final medicine = MedicineExpiry(
                        id: const Uuid().v4(),
                        medicineName: data.medicineName,
                        batchNumber: data.batchNumber,
                        expiryDate: data.expiryDate,
                        purchaseDate: data.mfgDate,
                        quantity: 1,
                        notes: 'Added via barcode scan',
                      );
                      await ExpiryTrackingService.instance
                          .addMedicine(medicine);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '✅ ${data.medicineName} added to expiry tracker!'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_alert, size: 18),
                    label: const Text('Track Expiry'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Report fake medicine
                      _showReportDialog();
                    },
                    icon: const Icon(Icons.report, size: 18),
                    label: const Text('Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.report_problem, color: Colors.red.shade700),
            const SizedBox(width: 12),
            const Text('Report Medicine'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report this medicine to authorities if you suspect:'),
            const SizedBox(height: 12),
            _buildReportOption('Counterfeit/Fake medicine'),
            _buildReportOption('Expired product'),
            _buildReportOption('Damaged packaging'),
            _buildReportOption('Wrong information'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted to authorities'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
