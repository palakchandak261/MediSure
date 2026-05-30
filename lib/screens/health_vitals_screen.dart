import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/health_vitals_service.dart';
import '../models/health_vitals_model.dart';

class HealthVitalsScreen extends StatefulWidget {
  const HealthVitalsScreen({super.key});

  @override
  State<HealthVitalsScreen> createState() => _HealthVitalsScreenState();
}

class _HealthVitalsScreenState extends State<HealthVitalsScreen> {
  final HealthVitalsService _service = HealthVitalsService.instance;
  List<HealthVitalsModel> _vitals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVitals();
  }

  Future<void> _loadVitals() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
    final vitals = await _service.getUserVitals(userId);
    setState(() {
      _vitals = vitals;
      _isLoading = false;
    });
  }

  void _showAddVitalsDialog() {
    final systolicCtrl = TextEditingController();
    final diastolicCtrl = TextEditingController();
    final sugarCtrl = TextEditingController();
    final weightCtrl = TextEditingController();
    final heartRateCtrl = TextEditingController();
    final tempCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    final outerContext = context;
    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.monitor_heart_rounded,
                color: Color(0xFFC62828), size: 26),
            SizedBox(width: 10),
            Text('Log Health Vitals'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Fill in the values you want to record (leave blank to skip)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              _VitalSection(
                label: '❤️ Blood Pressure',
                children: [
                  Expanded(
                      child: _VitalField(
                          ctrl: systolicCtrl,
                          label: 'Systolic',
                          unit: 'mmHg')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _VitalField(
                          ctrl: diastolicCtrl,
                          label: 'Diastolic',
                          unit: 'mmHg')),
                ],
              ),
              const SizedBox(height: 10),
              _VitalSection(
                label: '🩸 Blood Sugar',
                children: [
                  Expanded(
                      child: _VitalField(
                          ctrl: sugarCtrl,
                          label: 'Blood Sugar',
                          unit: 'mg/dL')),
                ],
              ),
              const SizedBox(height: 10),
              _VitalSection(
                label: '⚖️ Body Metrics',
                children: [
                  Expanded(
                      child: _VitalField(
                          ctrl: weightCtrl, label: 'Weight', unit: 'kg')),
                  const SizedBox(width: 10),
                  Expanded(
                      child: _VitalField(
                          ctrl: heartRateCtrl,
                          label: 'Heart Rate',
                          unit: 'bpm')),
                ],
              ),
              const SizedBox(height: 10),
              _VitalSection(
                label: '🌡️ Temperature',
                children: [
                  Expanded(
                      child: _VitalField(
                          ctrl: tempCtrl,
                          label: 'Temperature',
                          unit: '°F')),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Notes (optional)',
                  prefixIcon: const Icon(Icons.notes_rounded,
                      color: Colors.grey, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () async {
              final userId =
                  Provider.of<AuthService>(context, listen: false)
                      .currentUser
                      ?.uid ??
                      '';
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final vitals = _service.createVitals(
                userId: userId,
                systolic: double.tryParse(systolicCtrl.text),
                diastolic: double.tryParse(diastolicCtrl.text),
                bloodSugar: double.tryParse(sugarCtrl.text),
                weight: double.tryParse(weightCtrl.text),
                heartRate: double.tryParse(heartRateCtrl.text),
                temperature: double.tryParse(tempCtrl.text),
                notes: notesCtrl.text.trim().isEmpty
                    ? null
                    : notesCtrl.text.trim(),
              );
              await _service.addVitals(vitals);
              if (!mounted) return;
              navigator.pop();
              // Reload after dialog closes
              await _loadVitals();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('✅ Vitals saved successfully!'),
                  backgroundColor: Color(0xFF2E7D32),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.save_rounded, size: 16),
            label: const Text('Save Vitals'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC62828),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latest = _vitals.isNotEmpty ? _vitals.first : null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB71C1C), Color(0xFFC62828), Color(0xFFD32F2F)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
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
                          Text('Health Vitals',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('Monitor your health metrics',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddVitalsDialog,
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Log Vitals'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFC62828),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
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
                              color: Color(0xFFC62828)))
                      : SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (latest != null) ...[
                                _LatestCard(vitals: latest),
                                const SizedBox(height: 20),
                              ],
                              if (_vitals.isNotEmpty) ...[
                                const Text('History',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Color(0xFF1A1A2E))),
                                const SizedBox(height: 10),
                                ..._vitals.map((v) => _HistoryCard(
                                      vitals: v,
                                      onDelete: () async {
                                        final userId =
                                            Provider.of<AuthService>(context,
                                                    listen: false)
                                                .currentUser
                                                ?.uid ??
                                                '';
                                        await _service.deleteVitals(
                                            userId, v.id);
                                        _loadVitals();
                                      },
                                    )),
                              ] else ...[
                                const SizedBox(height: 60),
                                Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFFEBEE),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                            Icons.monitor_heart_outlined,
                                            size: 52,
                                            color: Color(0xFFC62828)),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text('No vitals recorded yet',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1A1A2E))),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Tap "Log Vitals" to record your\nblood pressure, sugar & more',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[500])),
                                    ],
                                  ),
                                ),
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

class _VitalSection extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _VitalSection({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey)),
        const SizedBox(height: 6),
        Row(children: children),
      ],
    );
  }
}

class _VitalField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String unit;
  const _VitalField(
      {required this.ctrl, required this.label, required this.unit});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: unit,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
    );
  }
}

class _LatestCard extends StatelessWidget {
  final HealthVitalsModel vitals;
  const _LatestCard({required this.vitals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFC62828).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.monitor_heart_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Latest Reading',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (vitals.bloodPressureSystolic != null)
                _VitalChip(
                    emoji: '❤️',
                    label: 'BP',
                    value:
                        '${vitals.bloodPressureSystolic!.toInt()}/${vitals.bloodPressureDiastolic!.toInt()} mmHg',
                    status: vitals.bpStatus),
              if (vitals.bloodSugar != null)
                _VitalChip(
                    emoji: '🩸',
                    label: 'Sugar',
                    value:
                        '${vitals.bloodSugar!.toStringAsFixed(0)} mg/dL',
                    status: vitals.sugarStatus),
              if (vitals.weight != null)
                _VitalChip(
                    emoji: '⚖️',
                    label: 'Weight',
                    value: '${vitals.weight!.toStringAsFixed(1)} kg'),
              if (vitals.heartRate != null)
                _VitalChip(
                    emoji: '💓',
                    label: 'Heart Rate',
                    value:
                        '${vitals.heartRate!.toStringAsFixed(0)} bpm'),
              if (vitals.temperature != null)
                _VitalChip(
                    emoji: '🌡️',
                    label: 'Temp',
                    value:
                        '${vitals.temperature!.toStringAsFixed(1)}°F'),
            ],
          ),
        ],
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String emoji, label, value;
  final String? status;
  const _VitalChip(
      {required this.emoji,
      required this.label,
      required this.value,
      this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji $label',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          if (status != null)
            Text(status!,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HealthVitalsModel vitals;
  final VoidCallback onDelete;
  const _HistoryCard({required this.vitals, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dt = vitals.recordedAt;
    final dateStr =
        '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: Colors.grey),
                  const SizedBox(width: 5),
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500)),
                ],
              ),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.delete_outline_rounded,
                      color: Colors.red[400], size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (vitals.bloodPressureSystolic != null)
                _Tag(
                    '❤️ ${vitals.bloodPressureSystolic!.toInt()}/${vitals.bloodPressureDiastolic!.toInt()} mmHg',
                    Colors.red.shade50,
                    Colors.red.shade700),
              if (vitals.bloodSugar != null)
                _Tag(
                    '🩸 ${vitals.bloodSugar!.toStringAsFixed(0)} mg/dL',
                    Colors.orange.shade50,
                    Colors.orange.shade700),
              if (vitals.weight != null)
                _Tag('⚖️ ${vitals.weight!.toStringAsFixed(1)} kg',
                    Colors.blue.shade50, Colors.blue.shade700),
              if (vitals.heartRate != null)
                _Tag(
                    '💓 ${vitals.heartRate!.toStringAsFixed(0)} bpm',
                    Colors.pink.shade50,
                    Colors.pink.shade700),
              if (vitals.temperature != null)
                _Tag(
                    '🌡️ ${vitals.temperature!.toStringAsFixed(1)}°F',
                    Colors.yellow.shade50,
                    Colors.yellow.shade800),
            ],
          ),
          if (vitals.notes != null && vitals.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.notes_rounded,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(vitals.notes!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color bg, fg;
  const _Tag(this.text, this.bg, this.fg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(7)),
      child: Text(text, style: TextStyle(fontSize: 12, color: fg)),
    );
  }
}
