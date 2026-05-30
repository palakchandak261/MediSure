import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/theme/app_theme.dart';
import '../models/prescription_model.dart';
import '../models/medicine_model.dart';
import '../models/order_model.dart';
import '../services/tts_service.dart';
import '../services/drug_interaction_service.dart';
import '../services/medicine_info_service.dart';
import '../services/reminder_service.dart';
import '../services/analytics_service.dart';
import '../services/qr_sharing_service.dart';
import '../services/expiry_tracking_service.dart';
import '../services/order_service.dart';
import '../services/auth_service.dart';
import '../widgets/medicine_card.dart';
import 'home_screen.dart';
import 'reminders_screen.dart';
import 'analytics_screen.dart';
import 'expiry_tracking_screen.dart';
import 'barcode_scanner_screen.dart';
import 'price_comparison_screen.dart';
import 'nearby_pharmacy_screen.dart';
import 'my_orders_screen.dart';
import 'order_tracking_screen.dart';

/// Simplified Result Screen for MVP
/// Shows extracted medicines with voice support and automatic advanced features
class ResultScreen extends StatefulWidget {
  final PrescriptionModel prescription;

  const ResultScreen({super.key, required this.prescription});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  final _ttsService = TTSService();
  final _interactionService = DrugInteractionService();
  final _medicineInfoService = MedicineInfoService();
  final _reminderService = ReminderService.instance;
  final _analyticsService = AnalyticsService();
  final _qrSharingService = QRSharingService();
  
  List<Map<String, dynamic>> _interactions = [];

  @override
  void initState() {
    super.initState();
    _checkInteractions();
    _trackAnalytics();
  }

  void _checkInteractions() {
    final interactions = _interactionService.checkInteractions(
      widget.prescription.medicines,
    );
    setState(() {
      _interactions = interactions;
    });
  }

  void _trackAnalytics() {
    // Track each medicine usage
    for (var medicine in widget.prescription.medicines) {
      _analyticsService.trackMedicineUsage(medicine.name);
    }
  }

  void _setRemindersForAllMedicines() async {
    int count = 0;
    for (var medicine in widget.prescription.medicines) {
      await _reminderService.createReminderFromMedicine(widget.prescription.userId, medicine);
      count++;
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count reminder(s) set successfully!'),
          backgroundColor: AppTheme.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
            
            Column(
              children: [
                // Custom AppBar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => HomeScreen()),
                              (route) => false,
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Analysis Results',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
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
            // Success Card
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Prescription Analyzed Successfully',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.prescription.medicines.length} medicines found',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Drug Interactions Warning (if any)
            if (_interactions.isNotEmpty) ...[
              _buildInteractionsSection(),
              const SizedBox(height: 24),
            ],

            // Medicines Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Prescribed Medicines',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: AppTheme.primaryPurple,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'AI Enhanced',
                        style: TextStyle(
                          color: AppTheme.primaryPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Medicine Cards with Enhanced Info
            ...widget.prescription.medicines.map((medicine) {
              final medicineInfo = _medicineInfoService.getMedicineInfo(medicine.name);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildEnhancedMedicineCard(medicine, medicineInfo),
              );
            }),

            const SizedBox(height: 30),

            // Quick Actions Section
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Action Buttons Grid
            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.alarm,
                    label: 'Set Reminders',
                    color: Colors.blue,
                    onTap: () {
                      _setRemindersForAllMedicines();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => RemindersScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.analytics,
                    label: 'View Analytics',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.qr_code_scanner,
                    label: 'Share QR',
                    color: Colors.orange,
                    onTap: () {
                      _showQRCode();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.calendar_today,
                    label: 'Expiry Tracker',
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ExpiryTrackingScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.qr_code_scanner,
                    label: 'Scan Barcode',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.compare_arrows,
                    label: 'Compare Price',
                    color: Colors.indigo,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PriceComparisonScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.local_pharmacy_rounded,
                    label: 'Nearby Pharmacy',
                    color: Colors.blue.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NearbyPharmacyScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionCard(
                    icon: Icons.receipt_long_rounded,
                    label: 'My Orders',
                    color: Colors.teal.shade700,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Back to Home Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => HomeScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF6B7FED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
                        ],
                      ),
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

  Widget _buildInteractionsSection() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Drug Interaction Warning!',
                    style: TextStyle(
                      color: Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${_interactions.length} potential interaction(s) detected',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ..._interactions.map((interaction) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${interaction['medicine1']} + ${interaction['medicine2']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getSeverityColor(interaction['severity']).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            interaction['severity'].toUpperCase(),
                            style: TextStyle(
                              color: _getSeverityColor(interaction['severity']),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      interaction['warning'],
                      style: TextStyle(
                        color: Colors.red.shade900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedMedicineCard(medicine, Map<String, dynamic>? info) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Original Medicine Card
          MedicineCard(
            medicine: medicine,
            onTap: () async {
              await _ttsService.speakMedicineInstructions(
                medicineName: medicine.name,
                dosage: medicine.dosage,
                timing: medicine.timing,
                language: widget.prescription.language,
                notes: medicine.notes,
                sideEffects: info?['sideEffects'] != null 
                    ? List<String>.from(info!['sideEffects']) 
                    : null,
                warnings: info?['warnings'] != null 
                    ? List<String>.from(info!['warnings']) 
                    : null,
                price: info?['price'],
              );
            },
          ),
          
          // Enhanced Information Section
          if (info != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  Row(
                    children: [
                      Icon(Icons.attach_money, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Price: ${info['price']}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const Spacer(),
                      if (info['alternatives'] != null)
                        TextButton(
                          onPressed: () {
                            final alts = info['alternatives'];
                            final altsList = alts is List ? alts : alts is String ? [alts] : [];
                            if (altsList.isNotEmpty) {
                              _showAlternatives(context, medicine.name, altsList);
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                          ),
                          child: Text(
                            'Alternatives',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Side Effects
                  ..._buildSideEffectsSection(info),

                  // Quick Action Buttons for this medicine
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            await _reminderService.createReminderFromMedicine(widget.prescription.userId, medicine);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Reminder(s) set for ${medicine.name}'),
                                  backgroundColor: AppTheme.successGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: Icon(Icons.alarm, size: 16),
                          label: Text('Reminder', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _showOrderOptions(context, medicine.name);
                          },
                          icon: Icon(Icons.shopping_cart, size: 16),
                          label: Text('Order', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _addToExpiryTracker(medicine);
                          },
                          icon: Icon(Icons.calendar_today, size: 16),
                          label: Text('Track Expiry', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PriceComparisonScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.compare_arrows, size: 16),
                          label: Text('Compare', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQRCode() {
    final shareText = _qrSharingService.generateShareableText(widget.prescription);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code, color: AppTheme.primaryPurple),
            const SizedBox(width: 12),
            Text('Share Prescription'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // QR Code — real QR using qr_flutter
              Container(
                height: 200,
                width: 200,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: QrImageView(
                  data: shareText,
                  version: QrVersions.auto,
                  size: 176,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Scan this QR code to share prescription',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: shareText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard!'),
                          backgroundColor: AppTheme.successGreen,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(Icons.copy, size: 16),
                    label: Text('Copy'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // In production, use share package
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Share feature coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(Icons.share, size: 16),
                    label: Text('Share'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'QR Code Features:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Share with doctors\n• Emergency access\n• Family members\n• Pharmacy verification',
                      style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showOrderOptions(BuildContext context, String medicineName) {
    final pharmacies = OrderService.pharmacyCatalog;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        builder: (_, controller) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medication_rounded,
                        color: Color(0xFF1565C0), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(medicineName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        const Text('Select pharmacy to order from',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(16),
                itemCount: pharmacies.length,
                itemBuilder: (_, i) {
                  final p = pharmacies[i];
                  final price = OrderService.instance
                      .getMedicinePrice(medicineName, p['name']);
                  final isOnline = p['distance'] == 'Online';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? const Color(0xFFE3F2FD)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isOnline
                              ? Icons.language_rounded
                              : Icons.local_pharmacy_rounded,
                          color: isOnline
                              ? const Color(0xFF1565C0)
                              : const Color(0xFF2E7D32),
                          size: 22,
                        ),
                      ),
                      title: Text(p['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        '${p['distance']} • ${p['deliveryTime']}${p['deliveryCharge'] == 0 ? ' • FREE delivery' : ' • ₹${p['deliveryCharge']} delivery'}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[600]),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1565C0))),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${((1 - price / (price / 0.85)) * 100).abs().toStringAsFixed(0)}% off',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.pop(ctx);
                        _placeOrderReal(medicineName, p, price);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrderReal(
      String medicineName, Map<String, dynamic> pharmacy, double price) async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';

    final addressCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    String paymentMethod = 'Cash on Delivery';
    String contactType = 'email';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.shopping_cart_rounded,
                  color: Color(0xFF1565C0)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Order from ${pharmacy['name']}',
                      style: const TextStyle(fontSize: 16))),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.medication_rounded,
                          color: Color(0xFF1565C0), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(medicineName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            Text(
                                '₹${price.toStringAsFixed(0)} + ₹${pharmacy['deliveryCharge']} delivery',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Delivery Address',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: addressCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Enter your full delivery address...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Payment Method',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['Cash on Delivery', 'UPI', 'Card'].map((m) {
                    final isSelected = paymentMethod == m;
                    return ChoiceChip(
                      label: Text(m, style: const TextStyle(fontSize: 13)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1565C0),
                      onSelected: (_) => setS(() => paymentMethod = m),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Get Updates Via',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setS(() => contactType = 'email'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: contactType == 'email'
                                ? const Color(0xFF1565C0)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.email_rounded,
                                  size: 15,
                                  color: contactType == 'email'
                                      ? Colors.white
                                      : Colors.grey),
                              const SizedBox(width: 5),
                              Text('Email',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: contactType == 'email'
                                          ? Colors.white
                                          : Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setS(() => contactType = 'whatsapp'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: contactType == 'whatsapp'
                                ? const Color(0xFF2E7D32)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_rounded,
                                  size: 15,
                                  color: contactType == 'whatsapp'
                                      ? Colors.white
                                      : Colors.grey),
                              const SizedBox(width: 5),
                              Text('WhatsApp',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: contactType == 'whatsapp'
                                          ? Colors.white
                                          : Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contactCtrl,
                  keyboardType: contactType == 'email'
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: contactType == 'email'
                        ? 'your@email.com'
                        : '+91 9876543210',
                    prefixIcon: Icon(
                      contactType == 'email'
                          ? Icons.email_rounded
                          : Icons.chat_rounded,
                      size: 18,
                      color: contactType == 'email'
                          ? const Color(0xFF1565C0)
                          : const Color(0xFF2E7D32),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contactType == 'email'
                      ? '📧 Confirmation, shipping & delivery updates sent to email'
                      : '💬 WhatsApp messages for all order updates',
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () {
                if (addressCtrl.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Place Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    final contact = contactCtrl.text.trim();

    // Save real order to OrderService
    final order = await OrderService.instance.placeOrder(
      userId: userId,
      pharmacyName: pharmacy['name'],
      pharmacyAddress: pharmacy['address'],
      items: [
        OrderItem(
          medicineName: medicineName,
          quantity: 1,
          price: price,
          dosage: 'As prescribed',
        ),
      ],
      deliveryAddress: addressCtrl.text.trim(),
      paymentMethod: paymentMethod,
      contactEmail:
          contactType == 'email' && contact.isNotEmpty ? contact : null,
      contactPhone:
          contactType == 'whatsapp' && contact.isNotEmpty ? contact : null,
      contactType: contactType,
    );

    if (!mounted) return;

    // Show success + navigate to tracking
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF2E7D32), size: 52),
            ),
            const SizedBox(height: 16),
            const Text('Order Placed!',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 6),
            Text(
              'Order #${order.id.substring(0, 8).toUpperCase()}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'from ${pharmacy['name']}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Est. delivery: ${pharmacy['deliveryTime']}',
              style: const TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay Here'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => OrderTrackingScreen(order: order)),
              );
            },
            icon: const Icon(Icons.local_shipping_rounded, size: 16),
            label: const Text('Track Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
  void _addToExpiryTracker(MedicineModel medicine) {
    final outerContext = context;
    showDialog(
      context: outerContext,
      builder: (dialogContext) {
        DateTime selectedDate = DateTime.now().add(const Duration(days: 365));
        final quantityController = TextEditingController(text: '10');
        final batchController = TextEditingController(
            text: 'BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Color(0xFF6B7FED), size: 22),
                const SizedBox(width: 10),
                Text('Track Expiry — ${medicine.name}'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: batchController,
                    decoration: const InputDecoration(
                        labelText: 'Batch Number',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expiry Date'),
                    subtitle: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B7FED))),
                    trailing: const Icon(Icons.calendar_today,
                        color: Color(0xFF6B7FED)),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) setState(() => selectedDate = date);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel')),
              ElevatedButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  final expiryMedicine = MedicineExpiry(
                    id: const Uuid().v4(),
                    medicineName: medicine.name,
                    batchNumber: batchController.text,
                    expiryDate: selectedDate,
                    purchaseDate: DateTime.now(),
                    quantity: int.tryParse(quantityController.text) ?? 10,
                  );
                  // Use singleton — persists to SharedPreferences
                  await ExpiryTrackingService.instance
                      .addMedicine(expiryMedicine);
                  if (!mounted) return;
                  navigator.pop();
                  messenger.showSnackBar(SnackBar(
                    content: Text(
                        '✅ ${medicine.name} added to expiry tracker!'),
                    backgroundColor: AppTheme.successGreen,
                  ));
                },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Add to Tracker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B7FED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAlternatives(
      BuildContext context, String medicineName, List alternatives) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alternatives for $medicineName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: alternatives
              .map((alt) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.medication,
                            size: 16, color: AppTheme.primaryPurple),
                        const SizedBox(width: 8),
                        Text(alt.toString()),
                      ],
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.yellow.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  List<Widget> _buildSideEffectsSection(Map<String, dynamic> info) {
    if (info['sideEffects'] == null) return [];
    
    final sideEffects = info['sideEffects'];
    final sideEffectsList = sideEffects is List 
        ? sideEffects.cast<String>()
        : sideEffects is String 
            ? [sideEffects]
            : <String>[];
    
    if (sideEffectsList.isEmpty) return [];
    
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.orange.shade700),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Side effects: ${sideEffectsList.join(", ")}',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
    ];
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






