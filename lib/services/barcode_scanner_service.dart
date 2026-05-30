import 'dart:math';

/// Medicine Barcode Data Model
class MedicineBarcodeData {
  final String barcode;
  final String medicineName;
  final String manufacturer;
  final String batchNumber;
  final DateTime expiryDate;
  final DateTime mfgDate;
  final String mrp;
  final bool isAuthentic;
  final String packSize;

  MedicineBarcodeData({
    required this.barcode,
    required this.medicineName,
    required this.manufacturer,
    required this.batchNumber,
    required this.expiryDate,
    required this.mfgDate,
    required this.mrp,
    required this.isAuthentic,
    required this.packSize,
  });
}

/// Barcode Scanner Service - Scan and verify medicine barcodes
class BarcodeScannerService {
  final Random _random = Random();

  /// Simulate barcode scanning (in production, use mobile_scanner package)
  Future<MedicineBarcodeData> scanBarcode(String barcode) async {
    // Simulate scanning delay
    await Future.delayed(const Duration(seconds: 2));

    // Generate mock data based on barcode
    return _generateMockBarcodeData(barcode);
  }

  /// Generate mock barcode data for demo
  MedicineBarcodeData _generateMockBarcodeData(String barcode) {
    final medicines = [
      {'name': 'Paracetamol 500mg', 'manufacturer': 'GlaxoSmithKline', 'mrp': '₹25', 'pack': '10 Tablets'},
      {'name': 'Azithromycin 500mg', 'manufacturer': 'Cipla Ltd', 'mrp': '₹120', 'pack': '6 Tablets'},
      {'name': 'Omeprazole 20mg', 'manufacturer': 'Dr. Reddy\'s', 'mrp': '₹45', 'pack': '15 Capsules'},
      {'name': 'Cetirizine 10mg', 'manufacturer': 'Sun Pharma', 'mrp': '₹18', 'pack': '10 Tablets'},
      {'name': 'Amoxicillin 500mg', 'manufacturer': 'Lupin Ltd', 'mrp': '₹85', 'pack': '10 Capsules'},
      {'name': 'Metformin 500mg', 'manufacturer': 'USV Ltd', 'mrp': '₹35', 'pack': '20 Tablets'},
      {'name': 'Atorvastatin 10mg', 'manufacturer': 'Ranbaxy', 'mrp': '₹95', 'pack': '10 Tablets'},
      {'name': 'Vitamin D3 60000 IU', 'manufacturer': 'Mankind Pharma', 'mrp': '₹55', 'pack': '4 Capsules'},
    ];

    final medicine = medicines[_random.nextInt(medicines.length)];
    final now = DateTime.now();
    final isAuthentic = _random.nextDouble() > 0.1; // 90% authentic

    return MedicineBarcodeData(
      barcode: barcode,
      medicineName: medicine['name']!,
      manufacturer: medicine['manufacturer']!,
      batchNumber: 'BN${_random.nextInt(999999).toString().padLeft(6, '0')}',
      expiryDate: now.add(Duration(days: 180 + _random.nextInt(540))),
      mfgDate: now.subtract(Duration(days: 30 + _random.nextInt(150))),
      mrp: medicine['mrp']!,
      isAuthentic: isAuthentic,
      packSize: medicine['pack']!,
    );
  }

  /// Verify medicine authenticity
  bool verifyAuthenticity(String barcode) {
    // In production, verify against government database
    return _random.nextDouble() > 0.1; // 90% authentic
  }

  /// Get medicine details by barcode
  Future<Map<String, dynamic>> getMedicineDetails(String barcode) async {
    await Future.delayed(const Duration(seconds: 1));

    final data = _generateMockBarcodeData(barcode);

    return {
      'name': data.medicineName,
      'manufacturer': data.manufacturer,
      'batchNumber': data.batchNumber,
      'expiryDate': data.expiryDate,
      'mfgDate': data.mfgDate,
      'mrp': data.mrp,
      'isAuthentic': data.isAuthentic,
      'packSize': data.packSize,
    };
  }

  /// Generate random barcode for demo
  String generateRandomBarcode() {
    final prefix = ['890', '891', '893']; // Indian barcode prefixes
    final randomPrefix = prefix[_random.nextInt(prefix.length)];
    final randomNumber = _random.nextInt(9999999999).toString().padLeft(10, '0');
    return '$randomPrefix$randomNumber';
  }

  /// Check if barcode is valid format
  bool isValidBarcode(String barcode) {
    // Check if barcode is 13 digits (EAN-13 format)
    return barcode.length == 13 && int.tryParse(barcode) != null;
  }

  /// Get barcode format
  String getBarcodeFormat(String barcode) {
    if (barcode.length == 13) return 'EAN-13';
    if (barcode.length == 12) return 'UPC-A';
    if (barcode.length == 8) return 'EAN-8';
    return 'Unknown';
  }
}
