import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/nearby_pharmacy_service.dart';
import 'order_screen.dart';

class NearbyPharmacyScreen extends StatefulWidget {
  final String? searchMedicine;
  const NearbyPharmacyScreen({super.key, this.searchMedicine});

  @override
  State<NearbyPharmacyScreen> createState() => _NearbyPharmacyScreenState();
}

class _NearbyPharmacyScreenState extends State<NearbyPharmacyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NearbyPharmacyService _service = NearbyPharmacyService.instance;
  List<PharmacyModel> _pharmacies = [];
  List<Map<String, dynamic>> _medicineResults = [];
  bool _isLoading = true;
  bool _openOnly = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.searchMedicine != null) {
      _searchController.text = widget.searchMedicine!;
      _searchQuery = widget.searchMedicine!;
    }
    _loadPharmacies();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacies() async {
    setState(() => _isLoading = true);

    // Fetch user location first
    await _service.fetchUserLocation();

    final pharmacies =
        await _service.getNearbyPharmacies(openOnly: _openOnly);
    setState(() {
      _pharmacies = pharmacies;
      _isLoading = false;
    });
    if (_searchQuery.isNotEmpty) _searchMedicine(_searchQuery);
  }

  Future<void> _searchMedicine(String medicine) async {
    if (medicine.isEmpty) return;
    setState(() => _isLoading = true);
    final results = await _service.getPharmaciesWithMedicine(medicine);
    setState(() {
      _medicineResults = results;
      _searchQuery = medicine;
      _isLoading = false;
    });
    _tabController.animateTo(1);
  }

  Future<void> _openDirections(PharmacyModel pharmacy) async {
    final url = _service.getDirectionsUrl(pharmacy);
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening ${pharmacy.name} on Maps...'),
            backgroundColor: const Color(0xFF1565C0),
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1565C0), Color(0xFF1976D2), Color(0xFF0288D1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nearby Pharmacies',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white70, size: 13),
                              const SizedBox(width: 3),
                              Text(
                                _service.userLat != null
                                    ? 'Near ${_service.userCity}'
                                    : 'Detecting your location...',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() => _openOnly = !_openOnly);
                        _loadPharmacies();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _openOnly
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.store_rounded,
                                size: 14,
                                color: _openOnly
                                    ? const Color(0xFF1565C0)
                                    : Colors.white),
                            const SizedBox(width: 4),
                            Text('Open Only',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _openOnly
                                        ? const Color(0xFF1565C0)
                                        : Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search medicine availability & price...',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 13),
                      prefixIcon: const Icon(Icons.medication_rounded,
                          color: Color(0xFF1565C0), size: 22),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear,
                                  color: Colors.grey, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _medicineResults = [];
                                });
                                _tabController.animateTo(0);
                              },
                            )
                          : IconButton(
                              icon: const Icon(Icons.search_rounded,
                                  color: Color(0xFF1565C0)),
                              onPressed: () =>
                                  _searchMedicine(_searchController.text),
                            ),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: _searchMedicine,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),

              // Tabs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: const Color(0xFF1565C0),
                    unselectedLabelColor: Colors.white,
                    labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    tabs: const [
                      Tab(text: '🗺️  All Pharmacies'),
                      Tab(text: '💊  Medicine Search'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F2F8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF1565C0)))
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPharmacyList(),
                            _buildMedicineResults(),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPharmacyList() {
    if (_pharmacies.isEmpty) {
      return _EmptyState(
          icon: Icons.local_pharmacy_outlined,
          message: 'No pharmacies found',
          sub: 'Try disabling the "Open Only" filter');
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      itemCount: _pharmacies.length,
      itemBuilder: (context, index) {
        final p = _pharmacies[index];
        return _PharmacyCard(
          pharmacy: p,
          onDirections: () => _openDirections(p),
          onOrder: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => OrderScreen(pharmacy: p)),
          ),
        );
      },
    );
  }

  Widget _buildMedicineResults() {
    if (_searchQuery.isEmpty) {
      return _EmptyState(
        icon: Icons.search_rounded,
        message: 'Search a medicine',
        sub: 'Type a medicine name above to check\navailability & compare prices',
      );
    }
    if (_medicineResults.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF1565C0)));
    }

    final inStock =
        _medicineResults.where((r) => r['inStock'] == true).toList();
    double? bestPrice;
    if (inStock.isNotEmpty) {
      bestPrice = inStock
          .map((r) => r['price'] as double)
          .reduce((a, b) => a < b ? a : b);
    }

    return Column(
      children: [
        // Summary banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medication_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_searchQuery,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    Text(
                        '${inStock.length}/${_medicineResults.length} pharmacies have it in stock',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              if (bestPrice != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Best Price',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 11)),
                    Text('₹${bestPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22)),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: _medicineResults.length,
            itemBuilder: (context, index) {
              final result = _medicineResults[index];
              final pharmacy = result['pharmacy'] as PharmacyModel;
              final inStockItem = result['inStock'] as bool;
              final price = result['price'] as double;
              final discount = result['discount'] as int;
              final isBest = bestPrice != null &&
                  (price - bestPrice).abs() < 0.01 &&
                  inStockItem;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: isBest
                      ? Border.all(
                          color: Colors.green.shade400, width: 1.5)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: inStockItem
                                  ? Colors.green.shade50
                                  : Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              inStockItem
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: inStockItem
                                  ? Colors.green.shade600
                                  : Colors.red.shade600,
                              size: 24,
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
                                      child: Text(pharmacy.name,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14)),
                                    ),
                                    if (isBest)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade600,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text('BEST DEAL',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight:
                                                    FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Icon(Icons.star_rounded,
                                        size: 13,
                                        color: Colors.amber.shade600),
                                    const SizedBox(width: 3),
                                    Text('${pharmacy.rating}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600])),
                                    const SizedBox(width: 10),
                                    Icon(Icons.location_on_rounded,
                                        size: 13,
                                        color: Colors.grey[500]),
                                    const SizedBox(width: 2),
                                    Text(pharmacy.distanceText,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600])),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (inStockItem) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text('₹${price.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isBest
                                        ? Colors.green.shade700
                                        : const Color(0xFF1A1A2E))),
                            const SizedBox(width: 8),
                            if (discount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('$discount% OFF',
                                    style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => OrderScreen(
                                    pharmacy: pharmacy,
                                    prefilledMedicine: _searchQuery,
                                    prefilledPrice: price,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.shopping_cart_rounded,
                                  size: 15),
                              label: const Text('Order'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBest
                                    ? Colors.green.shade600
                                    : const Color(0xFF1565C0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Out of Stock',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── PHARMACY CARD ─────────────────────────────────────────────────────────────
class _PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  final VoidCallback onDirections;
  final VoidCallback onOrder;

  const _PharmacyCard(
      {required this.pharmacy,
      required this.onDirections,
      required this.onOrder});

  @override
  Widget build(BuildContext context) {
    final isOnline = pharmacy.distance == 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top row
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isOnline
                          ? [const Color(0xFF1565C0), const Color(0xFF1976D2)]
                          : [const Color(0xFF2E7D32), const Color(0xFF388E3C)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isOnline
                        ? Icons.language_rounded
                        : Icons.local_pharmacy_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pharmacy.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 2),
                      Text(pharmacy.address,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: pharmacy.isOpen
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: pharmacy.isOpen
                          ? Colors.green.shade300
                          : Colors.red.shade300,
                    ),
                  ),
                  child: Text(
                    pharmacy.isOpen ? '● Open' : '● Closed',
                    style: TextStyle(
                        color: pharmacy.isOpen
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Info chips
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                _Chip(
                    icon: Icons.star_rounded,
                    label: '${pharmacy.rating}',
                    color: Colors.amber.shade700),
                const SizedBox(width: 8),
                _Chip(
                    icon: Icons.location_on_rounded,
                    label: pharmacy.distanceText,
                    color: Colors.blue.shade700),
                const SizedBox(width: 8),
                if (pharmacy.hasDelivery)
                  _Chip(
                      icon: Icons.delivery_dining_rounded,
                      label: pharmacy.deliveryTime,
                      color: Colors.green.shade700),
                if (pharmacy.deliveryCharge == 0 && pharmacy.hasDelivery) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('FREE Delivery',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),

          // Services
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: pharmacy.services
                  .take(3)
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(s,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF1565C0),
                                fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDirections,
                    icon: const Icon(Icons.directions_rounded, size: 16),
                    label: const Text('Directions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1565C0),
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: pharmacy.hasDelivery ? onOrder : null,
                    icon: const Icon(Icons.shopping_cart_rounded, size: 16),
                    label: Text(
                        pharmacy.hasDelivery ? 'Order Now' : 'No Delivery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyState(
      {required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 52, color: const Color(0xFF1565C0)),
            ),
            const SizedBox(height: 20),
            Text(message,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 8),
            Text(sub,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}
