import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/medicine_dataset_service.dart';

/// Price Comparison Screen — uses real 11,000-medicine dataset for prices.
class PriceComparisonScreen extends StatefulWidget {
  const PriceComparisonScreen({super.key});

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  final _searchController = TextEditingController();
  String _selectedMedicine = '';
  bool _isSearching = false;

  // Popular medicines pulled from dataset top-rated list
  List<Map<String, String>> get _popularMedicines {
    final topRated = MedicineDatasetService.instance.getTopRated(limit: 8);
    if (topRated.isNotEmpty) {
      return topRated.map((m) => {
        'name': m.genericName,
        'category': m.category,
      }).toList();
    }
    return [
      {'name': 'Paracetamol 500mg', 'category': 'Pain Relief'},
      {'name': 'Azithromycin 500mg', 'category': 'Antibiotic'},
      {'name': 'Omeprazole 20mg', 'category': 'Acidity'},
      {'name': 'Cetirizine 10mg', 'category': 'Allergy'},
      {'name': 'Metformin 500mg', 'category': 'Diabetes'},
      {'name': 'Atorvastatin 10mg', 'category': 'Cholesterol'},
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getPriceComparison(String medicineName) {
    // Get real base price from dataset
    final basePrice = MedicineDatasetService.instance.estimatePrice(medicineName);

    return [
      {
        'store': 'Apollo Pharmacy',
        'type': 'Retail',
        'price': basePrice.toInt(),
        'discount': 0,
        'distance': '0.5 km',
        'rating': 4.5,
        'available': true,
        'delivery': false,
      },
      {
        'store': 'MedPlus',
        'type': 'Retail',
        'price': (basePrice * 0.92).toInt(),
        'discount': 8,
        'distance': '1.2 km',
        'rating': 4.3,
        'available': true,
        'delivery': false,
      },
      {
        'store': 'Wellness Forever',
        'type': 'Retail',
        'price': (basePrice * 0.95).toInt(),
        'discount': 5,
        'distance': '2.0 km',
        'rating': 4.4,
        'available': true,
        'delivery': false,
      },
      {
        'store': '1mg',
        'type': 'Online',
        'price': (basePrice * 0.85).toInt(),
        'discount': 15,
        'distance': 'Online',
        'rating': 4.6,
        'available': true,
        'delivery': true,
      },
      {
        'store': 'PharmEasy',
        'type': 'Online',
        'price': (basePrice * 0.88).toInt(),
        'discount': 12,
        'distance': 'Online',
        'rating': 4.5,
        'available': true,
        'delivery': true,
      },
      {
        'store': 'Netmeds',
        'type': 'Online',
        'price': (basePrice * 0.90).toInt(),
        'discount': 10,
        'distance': 'Online',
        'rating': 4.4,
        'available': true,
        'delivery': true,
      },
    ];
  }

  void _searchMedicine(String medicineName) {
    if (medicineName.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    // Simulate search delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _selectedMedicine = medicineName;
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final prices = _selectedMedicine.isNotEmpty
        ? _getPriceComparison(_selectedMedicine)
        : [];

    // Find best price
    int? bestPrice;
    if (prices.isNotEmpty) {
      bestPrice = prices.map((p) => p['price'] as int).reduce((a, b) => a < b ? a : b);
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
                      'Price Comparison',
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

                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search medicine name...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _selectedMedicine = '');
                                    },
                                  ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onSubmitted: _searchMedicine,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Popular Medicines
                      if (_selectedMedicine.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Popular Medicines',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: _popularMedicines.length,
                            itemBuilder: (context, index) {
                              final medicine = _popularMedicines[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryPurple.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.medication,
                                      color: AppTheme.primaryPurple,
                                    ),
                                  ),
                                  title: Text(
                                    medicine['name'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(medicine['category'] ?? ''),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    _searchController.text = medicine['name'] ?? '';
                                    _searchMedicine(medicine['name'] ?? '');
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      // Price Comparison Results
                      if (_selectedMedicine.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedMedicine,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${prices.length} stores found',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: prices.length,
                            itemBuilder: (context, index) {
                              final store = prices[index];
                              final isBestPrice = store['price'] == bestPrice;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: isBestPrice ? 4 : 2,
                                color: isBestPrice ? Colors.green.shade50 : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: store['type'] == 'Online'
                                                  ? Colors.blue.shade100
                                                  : Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              store['type'] == 'Online'
                                                  ? Icons.shopping_cart
                                                  : Icons.store,
                                              color: store['type'] == 'Online'
                                                  ? Colors.blue.shade700
                                                  : Colors.orange.shade700,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        store['store'],
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                        ),
                                                      ),
                                                    ),
                                                    if (isBestPrice)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.green.shade700,
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: const Text(
                                                          'BEST PRICE',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.star,
                                                      size: 14,
                                                      color: Colors.amber.shade700,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${store['rating']}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Icon(
                                                      Icons.location_on,
                                                      size: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      store['distance'],
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Text(
                                            '₹${store['price']}',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: isBestPrice
                                                  ? Colors.green.shade700
                                                  : AppTheme.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (store['discount'] > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '${store['discount']}% OFF',
                                                style: TextStyle(
                                                  color: Colors.orange.shade700,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          const Spacer(),
                                          if (store['delivery'])
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.local_shipping,
                                                  size: 16,
                                                  color: Colors.green.shade700,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Delivery',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.green.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Opening ${store['store']}...'),
                                                backgroundColor: AppTheme.successGreen,
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: isBestPrice
                                                ? Colors.green.shade700
                                                : AppTheme.primaryPurple,
                                          ),
                                          child: Text(
                                            store['type'] == 'Online' ? 'Buy Online' : 'Get Directions',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
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
