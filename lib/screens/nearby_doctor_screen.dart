import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/nearby_pharmacy_service.dart';

class NearbyDoctorScreen extends StatefulWidget {
  const NearbyDoctorScreen({super.key});

  @override
  State<NearbyDoctorScreen> createState() => _NearbyDoctorScreenState();
}

class _NearbyDoctorScreenState extends State<NearbyDoctorScreen> {
  final NearbyPharmacyService _locationService = NearbyPharmacyService.instance;
  bool _isLoading = true;
  String _selectedSpecialty = 'All';
  List<_DoctorModel> _doctors = [];

  final List<String> _specialties = [
    'All', 'General Physician', 'Cardiologist', 'Diabetologist',
    'Dermatologist', 'ENT', 'Orthopedic', 'Pediatrician', 'Gynecologist',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    if (_locationService.userLat == null) {
      await _locationService.fetchUserLocation();
    }
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _doctors = _generateDoctors();
      _isLoading = false;
    });
  }

  List<_DoctorModel> _generateDoctors() {
    final lat = _locationService.userLat ?? 18.5204;
    final lng = _locationService.userLng ?? 73.8567;

    final data = [
      _DoctorModel(
        id: 'd1', name: 'Dr. Rajesh Kumar', specialty: 'General Physician',
        qualification: 'MBBS, MD', experience: '15 years',
        address: 'Near $_city', phone: '+91-9876543001',
        rating: 4.7, distance: 0.4, isAvailable: true,
        consultFee: 300, lat: lat + 0.003, lng: lng + 0.002,
        timings: 'Mon-Sat: 9AM-1PM, 5PM-8PM',
      ),
      _DoctorModel(
        id: 'd2', name: 'Dr. Priya Sharma', specialty: 'Diabetologist',
        qualification: 'MBBS, MD (Medicine)', experience: '12 years',
        address: 'Near $_city', phone: '+91-9876543002',
        rating: 4.8, distance: 0.8, isAvailable: true,
        consultFee: 500, lat: lat - 0.004, lng: lng + 0.005,
        timings: 'Mon-Fri: 10AM-2PM, 6PM-9PM',
      ),
      _DoctorModel(
        id: 'd3', name: 'Dr. Amit Patel', specialty: 'Cardiologist',
        qualification: 'MBBS, MD, DM (Cardiology)', experience: '20 years',
        address: 'Near $_city', phone: '+91-9876543003',
        rating: 4.9, distance: 1.2, isAvailable: false,
        consultFee: 800, lat: lat + 0.006, lng: lng - 0.003,
        timings: 'Mon-Wed-Fri: 11AM-3PM',
      ),
      _DoctorModel(
        id: 'd4', name: 'Dr. Sunita Rao', specialty: 'Gynecologist',
        qualification: 'MBBS, MS (OBG)', experience: '18 years',
        address: 'Near $_city', phone: '+91-9876543004',
        rating: 4.6, distance: 1.5, isAvailable: true,
        consultFee: 600, lat: lat - 0.007, lng: lng - 0.004,
        timings: 'Mon-Sat: 9AM-12PM, 4PM-7PM',
      ),
      _DoctorModel(
        id: 'd5', name: 'Dr. Vikram Singh', specialty: 'Orthopedic',
        qualification: 'MBBS, MS (Ortho)', experience: '10 years',
        address: 'Near $_city', phone: '+91-9876543005',
        rating: 4.5, distance: 2.0, isAvailable: true,
        consultFee: 500, lat: lat + 0.009, lng: lng + 0.007,
        timings: 'Mon-Sat: 10AM-2PM, 5PM-8PM',
      ),
      _DoctorModel(
        id: 'd6', name: 'Dr. Meera Joshi', specialty: 'Pediatrician',
        qualification: 'MBBS, MD (Pediatrics)', experience: '8 years',
        address: 'Near $_city', phone: '+91-9876543006',
        rating: 4.7, distance: 2.3, isAvailable: true,
        consultFee: 400, lat: lat - 0.010, lng: lng + 0.008,
        timings: 'Mon-Sat: 9AM-1PM, 5PM-8PM',
      ),
      _DoctorModel(
        id: 'd7', name: 'Dr. Arun Nair', specialty: 'Dermatologist',
        qualification: 'MBBS, MD (Dermatology)', experience: '14 years',
        address: 'Near $_city', phone: '+91-9876543007',
        rating: 4.6, distance: 2.8, isAvailable: false,
        consultFee: 600, lat: lat + 0.012, lng: lng - 0.009,
        timings: 'Tue-Thu-Sat: 10AM-2PM, 5PM-7PM',
      ),
      _DoctorModel(
        id: 'd8', name: 'Dr. Kavita Desai', specialty: 'ENT',
        qualification: 'MBBS, MS (ENT)', experience: '11 years',
        address: 'Near $_city', phone: '+91-9876543008',
        rating: 4.5, distance: 3.1, isAvailable: true,
        consultFee: 450, lat: lat - 0.013, lng: lng - 0.010,
        timings: 'Mon-Fri: 9AM-1PM, 4PM-7PM',
      ),
    ];

    data.sort((a, b) => a.distance.compareTo(b.distance));
    return data;
  }

  String get _city => _locationService.userCity;

  List<_DoctorModel> get _filtered {
    if (_selectedSpecialty == 'All') return _doctors;
    return _doctors
        .where((d) => d.specialty == _selectedSpecialty)
        .toList();
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _message(String phone, String doctorName) async {
    final clean = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final e164 = clean.startsWith('+') ? clean.substring(1)
        : clean.length == 10 ? '91$clean' : clean;
    final msg = Uri.encodeComponent(
        'Hello Dr. $doctorName, I would like to book an appointment. I am a MediSure user.');
    final waUri = Uri.parse('https://wa.me/$e164?text=$msg');
    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } else {
      final smsUri = Uri.parse('sms:$phone');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _directions(double lat, double lng, String name) async {
    final uLat = _locationService.userLat;
    final uLng = _locationService.userLng;
    String url;
    if (uLat != null && uLng != null) {
      url = 'https://www.google.com/maps/dir/?api=1'
          '&origin=$uLat,$uLng&destination=$lat,$lng&travelmode=driving';
    } else {
      url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF388E3C)],
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
                          const Text('Nearby Doctors',
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
                                _locationService.userLat != null
                                    ? 'Near ${_locationService.userCity}'
                                    : 'Detecting location...',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      onPressed: _loadDoctors,
                    ),
                  ],
                ),
              ),

              // Specialty filter
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _specialties.length,
                  itemBuilder: (_, i) {
                    final s = _specialties[i];
                    final sel = s == _selectedSpecialty;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSpecialty = s),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(s,
                            style: TextStyle(
                                color: sel
                                    ? const Color(0xFF2E7D32)
                                    : Colors.white,
                                fontSize: 12,
                                fontWeight: sel
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                      ),
                    );
                  },
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
                              color: Color(0xFF2E7D32)))
                      : _filtered.isEmpty
                          ? Center(
                              child: Text(
                                'No $_selectedSpecialty found nearby',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 15),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 16, 16, 20),
                              itemCount: _filtered.length,
                              itemBuilder: (_, i) => _DoctorCard(
                                doctor: _filtered[i],
                                onCall: () => _call(_filtered[i].phone),
                                onMessage: () => _message(
                                    _filtered[i].phone,
                                    _filtered[i].name),
                                onDirections: () => _directions(
                                    _filtered[i].lat,
                                    _filtered[i].lng,
                                    _filtered[i].name),
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

class _DoctorModel {
  final String id, name, specialty, qualification, experience;
  final String address, phone, timings;
  final double rating, distance, lat, lng;
  final bool isAvailable;
  final int consultFee;

  _DoctorModel({
    required this.id, required this.name, required this.specialty,
    required this.qualification, required this.experience,
    required this.address, required this.phone, required this.timings,
    required this.rating, required this.distance,
    required this.lat, required this.lng,
    required this.isAvailable, required this.consultFee,
  });
}

class _DoctorCard extends StatelessWidget {
  final _DoctorModel doctor;
  final VoidCallback onCall, onMessage, onDirections;

  const _DoctorCard({
    required this.doctor,
    required this.onCall,
    required this.onMessage,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      doctor.name.split(' ').last[0],
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 2),
                      Text(doctor.specialty,
                          style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                              fontSize: 12)),
                      Text(doctor.qualification,
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: doctor.isAvailable
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: doctor.isAvailable
                            ? Colors.green.shade300
                            : Colors.red.shade300),
                  ),
                  child: Text(
                    doctor.isAvailable ? '● Available' : '● Busy',
                    style: TextStyle(
                        color: doctor.isAvailable
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                        fontSize: 10,
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
                _Chip(Icons.star_rounded, '${doctor.rating}',
                    Colors.amber.shade700),
                const SizedBox(width: 10),
                _Chip(Icons.location_on_rounded,
                    '${doctor.distance.toStringAsFixed(1)} km',
                    Colors.blue.shade700),
                const SizedBox(width: 10),
                _Chip(Icons.work_history_rounded, doctor.experience,
                    Colors.purple.shade700),
                const SizedBox(width: 10),
                _Chip(Icons.currency_rupee_rounded,
                    '${doctor.consultFee}', Colors.green.shade700),
              ],
            ),
          ),

          // Timings
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(doctor.timings,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[600])),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCall,
                    icon: const Icon(Icons.call_rounded, size: 15),
                    label: const Text('Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.message_rounded, size: 15),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: onDirections,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D32),
                    side: const BorderSide(color: Color(0xFF2E7D32)),
                    padding: const EdgeInsets.symmetric(
                        vertical: 9, horizontal: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Icon(Icons.directions_rounded, size: 18),
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
  const _Chip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey[700])),
      ],
    );
  }
}
