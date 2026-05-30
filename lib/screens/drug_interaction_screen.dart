import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/drug_interaction_service.dart';
import '../models/medicine_model.dart';

class DrugInteractionScreen extends StatefulWidget {
  const DrugInteractionScreen({super.key});

  @override
  State<DrugInteractionScreen> createState() => _DrugInteractionScreenState();
}

class _DrugInteractionScreenState extends State<DrugInteractionScreen> {
  final _interactionService = DrugInteractionService();
  List<Map<String, dynamic>> _interactions = [];
  List<MedicineModel> _currentMedicines = [];
  bool _isLoading = true;
  bool _useCustom = false;

  // For manual medicine entry
  final _med1Ctrl = TextEditingController();
  final _med2Ctrl = TextEditingController();

  // Sample demo medicines for testing
  static const List<Map<String, String>> _sampleCombinations = [
    {'m1': 'Aspirin', 'm2': 'Ibuprofen', 'label': 'Aspirin + Ibuprofen'},
    {'m1': 'Aspirin', 'm2': 'Warfarin', 'label': 'Aspirin + Warfarin'},
    {'m1': 'Cetirizine', 'm2': 'Alcohol', 'label': 'Cetirizine + Alcohol'},
    {'m1': 'Omeprazole', 'm2': 'Clopidogrel', 'label': 'Omeprazole + Clopidogrel'},
    {'m1': 'Paracetamol', 'm2': 'Alcohol', 'label': 'Paracetamol + Alcohol'},
    {'m1': 'Metformin', 'm2': 'Alcohol', 'label': 'Metformin + Alcohol'},
  ];

  @override
  void initState() {
    super.initState();
    _loadFromPrescription();
  }

  @override
  void dispose() {
    _med1Ctrl.dispose();
    _med2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadFromPrescription() async {
    setState(() => _isLoading = true);
    try {
      final userId =
          Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
      final prescriptions = LocalStorageService.getUserPrescriptions(userId);

      if (prescriptions.isNotEmpty) {
        final medicines = prescriptions.first.medicines;
        final interactions = _interactionService.checkInteractions(medicines);
        setState(() {
          _currentMedicines = medicines;
          _interactions = interactions;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _checkCustom() {
    final m1 = _med1Ctrl.text.trim();
    final m2 = _med2Ctrl.text.trim();
    if (m1.isEmpty || m2.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both medicine names')),
      );
      return;
    }
    final meds = [
      MedicineModel(name: m1, dosage: '', timing: '', confidence: 90),
      MedicineModel(name: m2, dosage: '', timing: '', confidence: 90),
    ];
    final interactions = _interactionService.checkInteractions(meds);
    setState(() {
      _interactions = interactions;
      _useCustom = true;
    });
  }

  void _checkSample(String m1, String m2) {
    final meds = [
      MedicineModel(name: m1, dosage: '', timing: '', confidence: 90),
      MedicineModel(name: m2, dosage: '', timing: '', confidence: 90),
    ];
    setState(() {
      _interactions = _interactionService.checkInteractions(meds);
      _useCustom = true;
    });
  }

  Color _severityColor(String s) {
    switch (s.toLowerCase()) {
      case 'critical': return Colors.red.shade700;
      case 'high': return Colors.orange.shade700;
      case 'medium': return Colors.amber.shade700;
      default: return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB71C1C), Color(0xFFE53935), Color(0xFFFF7043)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Drug Interaction Checker',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text('Check medicine safety',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      onPressed: _loadFromPrescription,
                      tooltip: 'Reload from prescription',
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F2F8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFB71C1C)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Manual check section
                              _CheckCard(
                                med1Ctrl: _med1Ctrl,
                                med2Ctrl: _med2Ctrl,
                                onCheck: _checkCustom,
                              ),
                              const SizedBox(height: 16),

                              // Sample combinations
                              const Text('🧪 Try Sample Combinations',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1A1A2E))),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _sampleCombinations
                                    .map((s) => GestureDetector(
                                          onTap: () => _checkSample(
                                              s['m1']!, s['m2']!),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12, vertical: 7),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: const Color(0xFFB71C1C)
                                                      .withValues(alpha: 0.3)),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.05),
                                                    blurRadius: 4)
                                              ],
                                            ),
                                            child: Text(s['label']!,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFFB71C1C),
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ),
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 20),

                              // Current prescription medicines
                              if (_currentMedicines.isNotEmpty &&
                                  !_useCustom) ...[
                                Text(
                                  '📋 From Your Latest Prescription (${_currentMedicines.length} medicines)',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF1A1A2E)),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: _currentMedicines
                                      .map((m) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE3F2FD),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(m.name,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF1565C0),
                                                    fontWeight:
                                                        FontWeight.w600)),
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Results
                              if (_interactions.isEmpty) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: Colors.green.shade200),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          color: Colors.green.shade600,
                                          size: 48),
                                      const SizedBox(height: 10),
                                      Text(
                                        _currentMedicines.isEmpty && !_useCustom
                                            ? 'No prescription found.\nTap a sample above to test.'
                                            : '✅ No Interactions Found!\nYour medicines are safe to take together.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded,
                                          color: Colors.red.shade700, size: 24),
                                      const SizedBox(width: 10),
                                      Text(
                                        '⚠️ ${_interactions.length} interaction(s) detected!',
                                        style: TextStyle(
                                            color: Colors.red.shade800,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._interactions.map((i) {
                                  final color = _severityColor(i['severity']);
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: color.withValues(alpha: 0.3)),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.05),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3))
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: color
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  i['severity']
                                                      .toString()
                                                      .toUpperCase(),
                                                  style: TextStyle(
                                                      color: color,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11),
                                                ),
                                              ),
                                              const Spacer(),
                                              Icon(Icons.warning_rounded,
                                                  color: color, size: 20),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                        0xFFE3F2FD),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    i['medicine1'],
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8),
                                                child: Icon(Icons.close,
                                                    color: color, size: 20),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                        0xFFFFEBEE),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    i['medicine2'],
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.orange.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(Icons.info_rounded,
                                                    color:
                                                        Colors.orange.shade700,
                                                    size: 16),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    i['warning'],
                                                    style: TextStyle(
                                                        color: Colors
                                                            .orange.shade900,
                                                        fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckCard extends StatelessWidget {
  final TextEditingController med1Ctrl;
  final TextEditingController med2Ctrl;
  final VoidCallback onCheck;

  const _CheckCard({
    required this.med1Ctrl,
    required this.med2Ctrl,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔍 Check Any Two Medicines',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: med1Ctrl,
                  decoration: InputDecoration(
                    hintText: 'Medicine 1',
                    prefixIcon: const Icon(Icons.medication_rounded,
                        color: Color(0xFFB71C1C), size: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('+',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: TextField(
                  controller: med2Ctrl,
                  decoration: InputDecoration(
                    hintText: 'Medicine 2',
                    prefixIcon: const Icon(Icons.medication_rounded,
                        color: Color(0xFFB71C1C), size: 18),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCheck,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Check Interaction'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
