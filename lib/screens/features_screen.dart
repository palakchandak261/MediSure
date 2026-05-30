import 'package:flutter/material.dart';
import 'drug_interaction_screen.dart';
import 'reminders_screen.dart';
import 'analytics_screen.dart';
import 'medicine_info_screen.dart';
import 'expiry_tracking_screen.dart';
import 'barcode_scanner_screen.dart';
import 'price_comparison_screen.dart';
import 'nearby_pharmacy_screen.dart';
import 'my_orders_screen.dart';
import 'family_profiles_screen.dart';
import 'adherence_screen.dart';
import 'health_vitals_screen.dart';
import 'nearby_doctor_screen.dart';
import 'notifications_screen.dart';

class FeaturesScreen extends StatelessWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5C6BC0), Color(0xFF8E24AA), Color(0xFFAD1457)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
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
                          Text('All Features',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                          Text('Everything MediSure offers',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('14+ Features',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F2F8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    children: [
                      // ── PHARMACY & ORDERING ──────────────────────────
                      _SectionHeader(
                        icon: Icons.local_pharmacy_rounded,
                        title: 'Pharmacy & Ordering',
                        color: const Color(0xFF1565C0),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.location_on_rounded,
                        title: 'Nearby Pharmacies',
                        description:
                            'Find pharmacies near your location with distance, ratings, open/closed status & Google Maps directions.',
                        tag: 'Maps',
                        gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF1976D2)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NearbyPharmacyScreen())),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.shopping_bag_rounded,
                        title: 'Order Medicines Online',
                        description:
                            'Order from Apollo, MedPlus, 1mg & more. Add to cart, choose delivery address & payment method.',
                        tag: 'Delivery',
                        gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF388E3C)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NearbyPharmacyScreen())),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.receipt_long_rounded,
                        title: 'My Orders',
                        description:
                            'Track all your medicine orders. View status: Confirmed → Processing → Shipped → Delivered.',
                        tag: 'Tracking',
                        gradient: const LinearGradient(
                            colors: [Color(0xFF00838F), Color(0xFF0097A7)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const MyOrdersScreen())),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.compare_arrows_rounded,
                        title: 'Price Comparison',
                        description:
                            'Compare medicine prices across pharmacies. Find best deals with discount % and delivery options.',
                        tag: 'Save Money',
                        gradient: const LinearGradient(
                            colors: [Color(0xFF6A1B9A), Color(0xFF7B1FA2)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const PriceComparisonScreen())),
                      ),

                      const SizedBox(height: 22),
                      // ── REMINDERS & NOTIFICATIONS ────────────────────
                      _SectionHeader(
                        icon: Icons.notifications_active_rounded,
                        title: 'Reminders & Notifications',
                        color: const Color(0xFF5C6BC0),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.alarm_rounded,
                        title: 'Medicine Reminders',
                        description:
                            'Set smart reminders with snooze (5/10/30 min), missed dose tracking & sound alerts.',
                        tag: 'Smart',
                        gradient: const LinearGradient(
                            colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const RemindersScreen())),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.notifications_rounded,
                        title: 'Notification Center',
                        description:
                            'View all alerts — missed doses, refill reminders, adherence reports & expiry warnings.',
                        tag: 'Alerts',
                        gradient: const LinearGradient(
                            colors: [Color(0xFFE65100), Color(0xFFF4511E)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NotificationsScreen())),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.favorite_rounded,
                        title: 'Medicine Adherence',
                        description:
                            'Track doses taken vs missed. View streaks, 30-day calendar & weekly adherence percentage.',
                        tag: 'Streaks',
                        gradient: const LinearGradient(
                            colors: [Color(0xFF00695C), Color(0xFF00796B)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const AdherenceScreen())),
                      ),

                      const SizedBox(height: 22),
                      // ── HEALTH TRACKING ──────────────────────────────
                      _SectionHeader(
                        icon: Icons.monitor_heart_rounded,
                        title: 'Health Tracking',
                        color: const Color(0xFFC62828),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.monitor_heart_rounded,
                        title: 'Health Vitals',
                        description:
                            'Log blood pressure, blood sugar, weight, heart rate & temperature. View history & trends.',
                        tag: 'Vitals',
                        gradient: const LinearGradient(
                            colors: [Color(0xFFC62828), Color(0xFFD32F2F)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const HealthVitalsScreen())),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.bar_chart_rounded,
                        title: 'Health Analytics',
                        description:
                            'Visualize medicine usage trends, most prescribed medicines & monthly prescription frequency.',
                        tag: 'Insights',
                        gradient: const LinearGradient(
                            colors: [Color(0xFF2E7D32), Color(0xFF388E3C)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) => const AnalyticsScreen())),
                      ),

                      const SizedBox(height: 22),
                      // ── FAMILY ───────────────────────────────────────
                      _SectionHeader(
                        icon: Icons.family_restroom_rounded,
                        title: 'Family & Caregiving',
                        color: const Color(0xFFE65100),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.family_restroom_rounded,
                        title: 'Family Profiles',
                        description:
                            'Add spouse, parents, kids. Store blood group, allergies, chronic conditions & emergency contacts.',
                        tag: 'Caregiver',
                        gradient: const LinearGradient(
                            colors: [Color(0xFFE65100), Color(0xFFF4511E)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const FamilyProfilesScreen())),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.medical_services_rounded,
                        title: 'Nearby Doctors',
                        description:
                            'Find doctors near you by specialty. Call, WhatsApp or get directions instantly.',
                        tag: 'Consult',
                        gradient: const LinearGradient(
                            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NearbyDoctorScreen())),
                      ),

                      const SizedBox(height: 22),
                      // ── MEDICINE TOOLS ───────────────────────────────
                      _SectionHeader(
                        icon: Icons.medication_rounded,
                        title: 'Medicine Tools',
                        color: const Color(0xFF880E4F),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.warning_amber_rounded,
                        title: 'Drug Interaction Checker',
                        description:
                            'Check dangerous combinations. Severity levels: Critical, High, Medium with clinical warnings.',
                        tag: 'Safety',
                        gradient: const LinearGradient(
                            colors: [Color(0xFFB71C1C), Color(0xFFC62828)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const DrugInteractionScreen())),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.info_rounded,
                        title: 'Medicine Information',
                        description:
                            'Side effects, dosage warnings, price range & cheaper alternatives for 50+ medicines.',
                        tag: 'Database',
                        gradient: const LinearGradient(
                            colors: [Color(0xFFE65100), Color(0xFFBF360C)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const MedicineInfoScreen())),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Expiry Tracking',
                        description:
                            'Track medicine expiry dates & batch numbers. Get alerts for expired or expiring-soon medicines.',
                        tag: 'Alerts',
                        gradient: const LinearGradient(
                            colors: [Color(0xFF880E4F), Color(0xFFAD1457)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const ExpiryTrackingScreen())),
                      ),
                      const SizedBox(height: 10),
                      _FeatureCard(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Barcode Scanner',
                        description:
                            'Scan medicine barcodes to verify authenticity, check expiry date, MRP & manufacturer details.',
                        tag: 'Verify',
                        gradient: const LinearGradient(
                            colors: [Color(0xFF006064), Color(0xFF00838F)]),
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const BarcodeScannerScreen())),
                      ),
                      const SizedBox(height: 10),
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
}

// ── SECTION HEADER ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  const _SectionHeader(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}

// ── FEATURE CARD ──────────────────────────────────────────────────────────────
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String tag;
  final Gradient gradient;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            // Left gradient icon panel
            Container(
              width: 72,
              height: 90,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A2E))),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(tag,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(description,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                            height: 1.45),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Icon(Icons.chevron_right_rounded,
                  color: Colors.grey[400], size: 20),
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
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.3,
          size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.7,
          size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
