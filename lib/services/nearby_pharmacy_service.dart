import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class PharmacyModel {
  final String id;
  final String name;
  final String address;
  final String phone;
  final double rating;
  final double distance; // km
  final String distanceText;
  final bool isOpen;
  final bool hasDelivery;
  final String deliveryTime;
  final int deliveryCharge;
  final int minOrder;
  final double lat;
  final double lng;
  final List<String> services;
  final Map<String, String> hours;

  PharmacyModel({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.rating,
    required this.distance,
    required this.distanceText,
    required this.isOpen,
    required this.hasDelivery,
    required this.deliveryTime,
    required this.deliveryCharge,
    required this.minOrder,
    required this.lat,
    required this.lng,
    required this.services,
    required this.hours,
  });
}

class NearbyPharmacyService {
  static final NearbyPharmacyService _instance =
      NearbyPharmacyService._internal();
  static NearbyPharmacyService get instance => _instance;
  NearbyPharmacyService._internal();

  // User's actual location (set when fetched)
  double? _userLat;
  double? _userLng;
  String _userCity = 'your area';

  double? get userLat => _userLat;
  double? get userLng => _userLng;

  // ── GET USER LOCATION ─────────────────────────────────────────────────────
  Future<bool> fetchUserLocation() async {
    if (kIsWeb) {
      return await _fetchLocationByIP();
    } else {
      return await _fetchLocationByGPS();
    }
  }

  /// Real GPS location — Android/iOS
  Future<bool> _fetchLocationByGPS() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('❌ Location services disabled');
        return await _fetchLocationByIP();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('❌ Location permission denied');
        return await _fetchLocationByIP();
      }

      // Get GPS position with timeout
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );

      _userLat = position.latitude;
      _userLng = position.longitude;

      // Get city name via reverse geocoding
      await _reverseGeocode(_userLat!, _userLng!);
      debugPrint('📍 GPS: $_userLat, $_userLng ($_userCity)');
      return true;
    } catch (e) {
      debugPrint('❌ GPS error: $e');
      return await _fetchLocationByIP();
    }
  }

  /// Get city name from coordinates (free, no key)
  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final res = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json'),
        headers: {'User-Agent': 'MediSure/1.0'},
      ).timeout(const Duration(seconds: 6));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final address = data['address'] as Map<String, dynamic>? ?? {};
        _userCity = address['city'] ??
            address['town'] ??
            address['village'] ??
            address['county'] ??
            'your area';
        debugPrint('📍 City: $_userCity');
      }
    } catch (e) {
      debugPrint('❌ Reverse geocode error: $e');
    }
  }

  /// IP-based location fallback — Web
  Future<bool> _fetchLocationByIP() async {
    try {
      final res = await http
          .get(Uri.parse('https://ip-api.com/json?fields=status,lat,lon,city'))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          _userLat = (data['lat'] as num).toDouble();
          _userLng = (data['lon'] as num).toDouble();
          _userCity = data['city'] ?? 'your area';
          debugPrint('📍 IP location: $_userLat, $_userLng ($_userCity)');
          return true;
        }
      }
    } catch (e) {
      debugPrint('❌ IP location error: $e');
    }
    // Final fallback — Pune
    _userLat = 18.5204;
    _userLng = 73.8567;
    _userCity = 'your area';
    return false;
  }

  String get userCity => _userCity;

  // ── CALCULATE DISTANCE (Haversine formula) ─────────────────────────────────
  double _calcDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0; // Earth radius km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRad(double deg) => deg * pi / 180;

  String _distanceText(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  String _deliveryTime(double km) {
    if (km < 1) return '15-20 min';
    if (km < 3) return '20-30 min';
    if (km < 5) return '30-45 min';
    if (km < 10) return '45-60 min';
    return '1-2 hours';
  }

  int _deliveryCharge(double km) {
    if (km < 2) return 0;
    if (km < 5) return 20;
    if (km < 10) return 30;
    return 40;
  }

  // ── FETCH REAL PHARMACIES from OpenStreetMap (Overpass API) ──────────────
  Future<List<PharmacyModel>> _fetchRealPharmacies(
      double lat, double lng) async {
    try {
      // Overpass API — free, no key needed, returns real OSM pharmacy data
      final query = '''
[out:json][timeout:10];
(
  node["amenity"="pharmacy"](around:3000,$lat,$lng);
  way["amenity"="pharmacy"](around:3000,$lat,$lng);
);
out center 20;
''';

      final res = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final elements = data['elements'] as List;

        if (elements.isNotEmpty) {
          final pharmacies = <PharmacyModel>[];
          int idx = 0;

          for (final el in elements.take(8)) {
            final tags = el['tags'] as Map<String, dynamic>? ?? {};
            final pLat = (el['lat'] ?? el['center']?['lat'] ?? lat) as double;
            final pLng = (el['lon'] ?? el['center']?['lon'] ?? lng) as double;
            final dist = _calcDistance(lat, lng, pLat, pLng);

            final name = tags['name'] ??
                tags['name:en'] ??
                'Pharmacy ${idx + 1}';

            // Build address from OSM tags
            final parts = <String>[];
            if (tags['addr:housenumber'] != null) {
              parts.add(tags['addr:housenumber']);
            }
            if (tags['addr:street'] != null) parts.add(tags['addr:street']);
            if (tags['addr:suburb'] != null) parts.add(tags['addr:suburb']);
            if (parts.isEmpty) parts.add('Near $_userCity');
            final address = parts.join(', ');

            final phone = tags['phone'] ??
                tags['contact:phone'] ??
                '+91-XXXXXXXXXX';

            final now = DateTime.now();
            final hour = now.hour;
            // Use opening_hours tag if available, else assume standard hours
            final openHours = tags['opening_hours'] ?? '08:00-22:00';
            final isOpen = hour >= 8 && hour < 22;

            pharmacies.add(PharmacyModel(
              id: 'osm_${el['id']}',
              name: name,
              address: address,
              phone: phone,
              rating: 4.0 + (idx % 6) * 0.1,
              distance: dist,
              distanceText: _distanceText(dist),
              isOpen: isOpen,
              hasDelivery: dist < 5,
              deliveryTime: _deliveryTime(dist),
              deliveryCharge: _deliveryCharge(dist),
              minOrder: dist < 2 ? 100 : 200,
              lat: pLat,
              lng: pLng,
              services: [
                'Prescription Medicines',
                'OTC Medicines',
                if (tags['dispensing'] == 'yes') 'Dispensing',
              ],
              hours: {'Hours': openHours},
            ));
            idx++;
          }

          pharmacies.sort((a, b) => a.distance.compareTo(b.distance));
          debugPrint('✅ Found ${pharmacies.length} real pharmacies via OSM');
          return pharmacies;
        }
      }
    } catch (e) {
      debugPrint('❌ OSM pharmacy fetch error: $e');
    }
    return []; // fallback to generated
  }
  List<PharmacyModel> _generateNearbyPharmacies() {
    final lat = _userLat ?? 18.5204; // fallback: Pune
    final lng = _userLng ?? 73.8567;

    // Offsets in degrees (~100m to ~3km radius)
    final offsets = [
      {'name': 'Apollo Pharmacy', 'dLat': 0.0012, 'dLng': 0.0015},
      {'name': 'MedPlus', 'dLat': -0.0025, 'dLng': 0.0030},
      {'name': 'Wellness Forever', 'dLat': 0.0040, 'dLng': -0.0020},
      {'name': 'Sanjivini Medical', 'dLat': -0.0060, 'dLng': 0.0045},
      {'name': 'LifeCare Pharmacy', 'dLat': 0.0080, 'dLng': 0.0060},
      {'name': 'Jan Aushadhi Kendra', 'dLat': -0.0035, 'dLng': -0.0050},
    ];

    final phones = [
      '+91-1800-419-0000', // Apollo helpline
      '+91-1800-425-0025', // MedPlus helpline
      '+91-9876543212',
      '+91-9876543213',
      '+91-9876543214',
      '+91-9876543215',
    ];

    final ratings = [4.5, 4.3, 4.4, 4.2, 4.6, 4.1];

    final servicesList = [
      ['Prescription Medicines', 'OTC Medicines', 'Health Devices', 'Vitamins'],
      ['Prescription Medicines', 'OTC Medicines', 'Baby Care', 'Cosmetics'],
      ['Prescription Medicines', 'Wellness Products', 'Diagnostics', 'Nutrition'],
      ['Prescription Medicines', 'OTC Medicines', 'Surgical Items'],
      ['Prescription Medicines', 'Homeopathy', 'Ayurveda', 'Vitamins'],
      ['Generic Medicines', 'Jan Aushadhi', 'Affordable Medicines'],
    ];

    final hoursList = [
      {'Mon-Sat': '8:00 AM - 10:00 PM', 'Sun': '9:00 AM - 9:00 PM'},
      {'Mon-Sat': '7:30 AM - 11:00 PM', 'Sun': '8:00 AM - 10:00 PM'},
      {'Mon-Sun': '8:00 AM - 10:30 PM'},
      {'Mon-Sat': '9:00 AM - 9:00 PM', 'Sun': 'Closed'},
      {'Mon-Sat': '8:00 AM - 8:00 PM', 'Sun': '10:00 AM - 6:00 PM'},
      {'Mon-Sat': '9:00 AM - 7:00 PM', 'Sun': '10:00 AM - 5:00 PM'},
    ];

    final now = DateTime.now();
    final hour = now.hour;

    final pharmacies = <PharmacyModel>[];

    for (int i = 0; i < offsets.length; i++) {
      final pLat = lat + (offsets[i]['dLat'] as double);
      final pLng = lng + (offsets[i]['dLng'] as double);
      final dist = _calcDistance(lat, lng, pLat, pLng);
      final isOpen = hour >= 8 && hour < 22;

      pharmacies.add(PharmacyModel(
        id: 'ph${i + 1}',
        name: offsets[i]['name'] as String,
        address: _userCity,
        phone: phones[i],
        rating: ratings[i],
        distance: dist,
        distanceText: _distanceText(dist),
        isOpen: isOpen,
        hasDelivery: dist < 8,
        deliveryTime: _deliveryTime(dist),
        deliveryCharge: _deliveryCharge(dist),
        minOrder: dist < 2 ? 100 : 200,
        lat: pLat,
        lng: pLng,
        services: servicesList[i],
        hours: hoursList[i],
      ));
    }

    // Sort by distance
    pharmacies.sort((a, b) => a.distance.compareTo(b.distance));
    return pharmacies;
  }

  // ── PUBLIC API ─────────────────────────────────────────────────────────────

  Future<List<PharmacyModel>> getNearbyPharmacies({
    bool openOnly = false,
  }) async {
    if (_userLat == null) await fetchUserLocation();

    List<PharmacyModel> pharmacies = [];
    if (_userLat != null && _userLng != null) {
      pharmacies = await _fetchRealPharmacies(_userLat!, _userLng!);
    }
    if (pharmacies.isEmpty) {
      pharmacies = _generateNearbyPharmacies();
    }
    pharmacies.addAll(_onlinePharmacies());

    if (openOnly) {
      pharmacies = pharmacies.where((p) => p.isOpen).toList();
    }
    return pharmacies;
  }

  List<PharmacyModel> _onlinePharmacies() {
    return [
      PharmacyModel(
        id: 'online1',
        name: 'Netmeds',
        address: 'Online Pharmacy — Pan India Delivery',
        phone: '+91-1800-103-0304',
        rating: 4.4,
        distance: 0,
        distanceText: 'Online',
        isOpen: true,
        hasDelivery: true,
        deliveryTime: '1-2 days',
        deliveryCharge: 0,
        minOrder: 500,
        lat: 0,
        lng: 0,
        services: ['All Medicines', 'Lab Tests', 'Health Packages'],
        hours: {'24/7': 'Always Open'},
      ),
      PharmacyModel(
        id: 'online2',
        name: '1mg',
        address: 'Online Pharmacy — Pan India Delivery',
        phone: '+91-1800-843-0001',
        rating: 4.6,
        distance: 0,
        distanceText: 'Online',
        isOpen: true,
        hasDelivery: true,
        deliveryTime: '1-2 days',
        deliveryCharge: 0,
        minOrder: 300,
        lat: 0,
        lng: 0,
        services: ['All Medicines', 'Doctor Consultation', 'Lab Tests'],
        hours: {'24/7': 'Always Open'},
      ),
      PharmacyModel(
        id: 'online3',
        name: 'PharmEasy',
        address: 'Online Pharmacy — Pan India Delivery',
        phone: '+91-1800-120-0230',
        rating: 4.5,
        distance: 0,
        distanceText: 'Online',
        isOpen: true,
        hasDelivery: true,
        deliveryTime: '1-2 days',
        deliveryCharge: 0,
        minOrder: 250,
        lat: 0,
        lng: 0,
        services: ['All Medicines', 'Diagnostics', 'Subscription'],
        hours: {'24/7': 'Always Open'},
      ),
    ];
  }

  Future<List<Map<String, dynamic>>> getPharmaciesWithMedicine(
      String medicineName) async {
    if (_userLat == null) await fetchUserLocation();
    await Future.delayed(const Duration(milliseconds: 500));

    final pharmacies = await getNearbyPharmacies();
    final rng = Random(medicineName.hashCode);

    return pharmacies.map((p) {
      final inStock = rng.nextDouble() > 0.2;
      final basePrice = _getBasePrice(medicineName);
      final discountPct = rng.nextInt(20);
      final price = basePrice * (1 - discountPct / 100);
      return {
        'pharmacy': p,
        'inStock': inStock,
        'price': price,
        'discount': discountPct,
        'quantity': inStock ? (rng.nextInt(50) + 5) : 0,
      };
    }).toList();
  }

  double _getBasePrice(String name) {
    const prices = {
      'paracetamol': 25.0, 'dolo': 30.0, 'azithromycin': 120.0,
      'cetirizine': 20.0, 'omeprazole': 45.0, 'metformin': 35.0,
      'atorvastatin': 95.0, 'pantoprazole': 55.0, 'augmentin': 180.0,
      'amoxicillin': 85.0,
    };
    final lower = name.toLowerCase();
    for (final e in prices.entries) {
      if (lower.contains(e.key)) return e.value;
    }
    return 50.0 + (name.length * 3.0);
  }

  /// Opens Google Maps directions from user's location to pharmacy
  String getDirectionsUrl(PharmacyModel pharmacy) {
    if (pharmacy.lat == 0 && pharmacy.lng == 0) {
      return 'https://www.google.com/search?q=${Uri.encodeComponent('${pharmacy.name} pharmacy')}';
    }

    if (_userLat != null && _userLng != null) {
      // Directions from user's actual GPS to pharmacy's exact coordinates
      return 'https://www.google.com/maps/dir/?api=1'
          '&origin=$_userLat,$_userLng'
          '&destination=${pharmacy.lat},${pharmacy.lng}'
          '&destination_place_name=${Uri.encodeComponent(pharmacy.name)}'
          '&travelmode=driving';
    }

    // Fallback — search pharmacy by name near user city
    return 'https://www.google.com/maps/search/?api=1'
        '&query=${Uri.encodeComponent('${pharmacy.name} pharmacy $_userCity')}';
  }

  /// Opens Google Maps to show pharmacy on map
  String getMapUrl(PharmacyModel pharmacy) {
    if (pharmacy.lat == 0) return '';
    return 'https://www.google.com/maps/search/?api=1&query=${pharmacy.lat},${pharmacy.lng}';
  }
}
