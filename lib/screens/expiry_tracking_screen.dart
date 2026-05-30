import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../core/theme/app_theme.dart';
import '../services/expiry_tracking_service.dart';

/// Expiry Tracking Screen - Manage medicine expiry dates
class ExpiryTrackingScreen extends StatefulWidget {
  const ExpiryTrackingScreen({super.key});

  @override
  State<ExpiryTrackingScreen> createState() => _ExpiryTrackingScreenState();
}

class _ExpiryTrackingScreenState extends State<ExpiryTrackingScreen> {
  final _expiryService = ExpiryTrackingService.instance;
  String _selectedFilter = 'all';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _expiryService.getAllMedicinesAsync(); // triggers load
    if (mounted) setState(() => _isLoading = false);
  }

  List<MedicineExpiry> _getFilteredMedicines() {
    switch (_selectedFilter) {
      case 'expired':
        return _expiryService.getExpiredMedicines();
      case 'expiring':
        return _expiryService.getExpiringSoonMedicines();
      case 'valid':
        return _expiryService.getValidMedicines();
      default:
        return _expiryService.getAllMedicines();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _expiryService.getExpirySummary();
    final medicines = _getFilteredMedicines();

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6B7FED), Color(0xFFAD65C8)],
            ),
          ),
          child: const Center(
              child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

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
                      'Expiry Tracking',
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
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Summary Cards
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Total',
                                summary['total']!,
                                Colors.blue,
                                Icons.medication,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Expired',
                                summary['expired']!,
                                Colors.red,
                                Icons.warning_amber_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildSummaryCard(
                                'Expiring Soon',
                                summary['expiringSoon']!,
                                Colors.orange,
                                Icons.schedule,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildSummaryCard(
                                'Valid',
                                summary['valid']!,
                                Colors.green,
                                Icons.check_circle,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Filter Chips
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', 'all'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Expired', 'expired'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Expiring Soon', 'expiring'),
                              const SizedBox(width: 8),
                              _buildFilterChip('Valid', 'valid'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Medicine List
                      Expanded(
                        child: medicines.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 80,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No medicines found',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: medicines.length,
                                itemBuilder: (context, index) {
                                  return _buildMedicineCard(medicines[index]);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicineDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Medicine'),
        backgroundColor: AppTheme.primaryPurple,
      ),
    );
  }

  Widget _buildSummaryCard(String label, int count, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: AppTheme.primaryPurple.withValues(alpha: 0.2),
      checkmarkColor: AppTheme.primaryPurple,
    );
  }

  Widget _buildMedicineCard(MedicineExpiry medicine) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: medicine.statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            medicine.isExpired
                ? Icons.dangerous
                : medicine.isExpiringSoon
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle,
            color: medicine.statusColor,
          ),
        ),
        title: Text(
          medicine.medicineName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Batch: ${medicine.batchNumber}'),
            Text('Expires: ${_formatDate(medicine.expiryDate)}'),
            Text('Quantity: ${medicine.quantity}'),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: medicine.statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            medicine.expiryStatus,
            style: TextStyle(
              color: medicine.statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        isThreeLine: true,
        onTap: () => _showMedicineDetails(medicine),
      ),
    );
  }

  void _showAddMedicineDialog() {
    final nameController = TextEditingController();
    final batchController = TextEditingController();
    final quantityController = TextEditingController(text: '10');
    DateTime selectedDate = DateTime.now().add(const Duration(days: 365));
    final outerContext = context;

    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Medicine'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: batchController,
                decoration: const InputDecoration(
                  labelText: 'Batch Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Expiry Date'),
                subtitle: Text(_formatDate(selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    selectedDate = date;
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && batchController.text.isNotEmpty) {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final medicine = MedicineExpiry(
                  id: const Uuid().v4(),
                  medicineName: nameController.text,
                  batchNumber: batchController.text,
                  expiryDate: selectedDate,
                  purchaseDate: DateTime.now(),
                  quantity: int.tryParse(quantityController.text) ?? 10,
                );
                await _expiryService.addMedicine(medicine);
                if (!mounted) return;
                setState(() {});
                navigator.pop();
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('${nameController.text} added to tracker'),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showMedicineDetails(MedicineExpiry medicine) {
    final outerContext = context;
    showDialog(
      context: outerContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(medicine.medicineName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Batch Number', medicine.batchNumber),
            _buildDetailRow('Expiry Date', _formatDate(medicine.expiryDate)),
            _buildDetailRow('Purchase Date', _formatDate(medicine.purchaseDate)),
            _buildDetailRow('Quantity', medicine.quantity.toString()),
            _buildDetailRow('Days Until Expiry', medicine.daysUntilExpiry.toString()),
            _buildDetailRow('Status', medicine.expiryStatus),
            if (medicine.notes.isNotEmpty)
              _buildDetailRow('Notes', medicine.notes),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              await _expiryService.deleteMedicine(medicine.id);
              if (!mounted) return;
              setState(() {});
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${medicine.medicineName} deleted'),
                  backgroundColor: AppTheme.dangerRed,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
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
