import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/medicine_info_service.dart';

class MedicineInfoScreen extends StatefulWidget {
  final String? initialSearch;
  
  const MedicineInfoScreen({super.key, this.initialSearch});

  @override
  State<MedicineInfoScreen> createState() => _MedicineInfoScreenState();
}

class _MedicineInfoScreenState extends State<MedicineInfoScreen> {
  final _searchController = TextEditingController();
  final _medicineInfoService = MedicineInfoService();
  Map<String, dynamic>? _medicineInfo;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearch != null && widget.initialSearch!.isNotEmpty) {
      _searchController.text = widget.initialSearch!;
      // Automatically search when screen opens with initial search
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchMedicine();
      });
    }
  }

  void _searchMedicine() {
    if (_searchController.text.trim().isEmpty) return;
    
    setState(() {
      _isSearching = true;
    });

    // Simulate search delay
    Future.delayed(const Duration(milliseconds: 500), () {
      final info = _medicineInfoService.getMedicineInfo(_searchController.text.trim());
      setState(() {
        _medicineInfo = info;
        _isSearching = false;
      });
    });
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
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Medicine Information',
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
                    child: Column(
                      children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medicine name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _medicineInfo = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _searchMedicine(),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Search Button
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSearching ? null : _searchMedicine,
                  icon: _isSearching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isSearching ? 'Searching...' : 'Search'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Results
          Expanded(
            child: _medicineInfo == null
                ? _buildEmptyState()
                : _buildMedicineInfo(),
          ),
                      ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 100, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Search for Medicine',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Enter a medicine name to get detailed information including side effects, prices, and alternatives',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicineInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Medicine Name Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medication, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _medicineInfo!['name'] ?? _searchController.text.trim(),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_medicineInfo!['composition'] != null &&
                      (_medicineInfo!['composition'] as String).isNotEmpty)
                    Text(
                      'Composition: ${_medicineInfo!['composition']}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${_medicineInfo!['category']}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                  if (_medicineInfo!['manufacturer'] != null &&
                      (_medicineInfo!['manufacturer'] as String).isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Manufacturer: ${_medicineInfo!['manufacturer']}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Rating from real reviews
          if (_medicineInfo!['ratingText'] != null)
            _buildInfoSection(
              'User Reviews',
              Icons.star_rounded,
              Colors.amber.shade700,
              [
                Text(
                  _medicineInfo!['ratingText'],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ReviewBar('Excellent', _medicineInfo!['excellentPct'] ?? 0, Colors.green),
                    const SizedBox(width: 8),
                    _ReviewBar('Average', _medicineInfo!['averagePct'] ?? 0, Colors.orange),
                    const SizedBox(width: 8),
                    _ReviewBar('Poor', _medicineInfo!['poorPct'] ?? 0, Colors.red),
                  ],
                ),
              ],
            ),

          // Price
          _buildInfoSection(
            'Estimated Price',
            Icons.currency_rupee_rounded,
            Colors.green,
            [
              Text(
                _medicineInfo!['priceText'] ?? _medicineInfo!['price']?.toString() ?? 'Price varies',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Price may vary by pharmacy and location',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),

          // Uses
          if (_medicineInfo!['usesList'] != null && (_medicineInfo!['usesList'] as List).isNotEmpty)
            _buildInfoSection(
              'Uses',
              Icons.medical_information_rounded,
              Colors.blue,
              (_medicineInfo!['usesList'] as List)
                  .map((use) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(child: Text(use.toString(), style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                      ))
                  .toList(),
            ),

          // Side Effects
          if (_medicineInfo!['sideEffectsList'] != null && (_medicineInfo!['sideEffectsList'] as List).isNotEmpty)
            _buildInfoSection(
              'Side Effects',
              Icons.warning_amber,
              Colors.orange,
              (_medicineInfo!['sideEffectsList'] as List)
                  .map((effect) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(child: Text(effect.toString(), style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                      ))
                  .toList(),
            ),

          // Warnings
          if (_medicineInfo!['warnings'] != null && (_medicineInfo!['warnings'] as List).isNotEmpty)
            _buildInfoSection(
              'Important Warnings',
              Icons.error_outline,
              Colors.red,
              (_medicineInfo!['warnings'] as List)
                  .map((warning) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('⚠️ ', style: TextStyle(fontSize: 16)),
                            Expanded(child: Text(warning, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
                          ],
                        ),
                      ))
                  .toList(),
            ),

          // Alternatives
          if (_medicineInfo!['alternatives'] != null && (_medicineInfo!['alternatives'] as List).isNotEmpty)
            _buildInfoSection(
              'Alternative Brands',
              Icons.swap_horiz,
              Colors.purple,
              (_medicineInfo!['alternatives'] as List)
                  .map((alt) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Text('• ', style: TextStyle(fontSize: 16)),
                            Expanded(child: Text(alt, style: const TextStyle(fontSize: 14))),
                          ],
                        ),
                      ))
                  .toList(),
            ),

          // Expiry Info
          if (_medicineInfo!['expiryMonths'] != null)
            _buildInfoSection(
              'Shelf Life',
              Icons.schedule,
              Colors.teal,
              [Text('${_medicineInfo!['expiryMonths']} months from manufacture date', style: const TextStyle(fontSize: 14))],
            ),
            
          const SizedBox(height: 16),
          
          // Disclaimer
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This information is for reference only. Always consult your doctor or pharmacist.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ── Review Bar Widget ─────────────────────────────────────────────────────────
class _ReviewBar extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;
  const _ReviewBar(this.label, this.percent, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$percent%',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
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
