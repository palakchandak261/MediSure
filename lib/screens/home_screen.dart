import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/advanced_notification_service.dart';
import 'upload_screen.dart';
import 'history_screen.dart';
import 'features_screen.dart';
import 'login_history_screen.dart';
import 'login_screen.dart';
import 'reminders_screen.dart';
import 'medicine_info_screen.dart';
import 'nearby_pharmacy_screen.dart';
import 'my_orders_screen.dart';
import 'notifications_screen.dart';
import 'adherence_screen.dart';
import 'health_vitals_screen.dart';
import 'family_profiles_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    AdvancedNotificationService.instance
        .registerNotificationCallback(_onNewNotification);
  }

  @override
  void dispose() {
    _searchController.dispose();
    AdvancedNotificationService.instance
        .unregisterNotificationCallback(_onNewNotification);
    super.dispose();
  }

  void _onNewNotification(AppNotification _) => _loadUnreadCount();

  Future<void> _loadUnreadCount() async {
    final count =
        await AdvancedNotificationService.instance.getUnreadCount();
    if (mounted) setState(() => _unreadNotifications = count);
  }

  void _searchMedicine() {
    final q = _searchController.text.trim();
    if (q.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MedicineInfoScreen(initialSearch: q)),
      );
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final now = DateTime.now();
    final hour = now.hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

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
              // ── TOP HEADER ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 10),
                child: Row(
                  children: [
                    // Avatar — tappable → Profile
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreen()),
                      ),
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.5),
                              width: 2),
                        ),
                        child: Center(
                          child: Text(
                            (user?.name.isNotEmpty == true)
                                ? user!.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            greeting,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            user?.name ?? 'User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Notification
                    _HeaderBtn(
                      icon: Icons.notifications_outlined,
                      badge: _unreadNotifications,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NotificationsScreen()),
                      ).then((_) => _loadUnreadCount()),
                    ),
                    const SizedBox(width: 6),
                    _HeaderBtn(
                      icon: Icons.manage_history_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LoginHistoryScreen()),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _HeaderBtn(
                      icon: Icons.logout_rounded,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        await authService.signOut();
                        if (!mounted) return;
                        navigator.pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // ── SEARCH BAR ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 14),
                        child: Icon(Icons.search, color: Colors.white70,
                            size: 20),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search medicine, symptoms...',
                            hintStyle: TextStyle(
                                color: Colors.white60, fontSize: 14),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 14),
                          ),
                          onSubmitted: (_) => _searchMedicine(),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.white70, size: 18),
                          onPressed: () =>
                              setState(() => _searchController.clear()),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Search',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── SCROLLABLE CONTENT ──────────────────────────────────
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F2F8),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── UPLOAD PRESCRIPTION (hero card) ─────────────
                        _HeroCard(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const UploadScreen()),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── QUICK ACTIONS ────────────────────────────────
                        _SectionTitle(
                            title: 'Quick Actions',
                            subtitle: 'Tap to get started'),
                        const SizedBox(height: 12),
                        // Quick actions — horizontal scrolling row of compact chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _QuickChip(
                                icon: Icons.location_on_rounded,
                                label: 'Nearby Pharmacy',
                                color: const Color(0xFF1976D2),
                                bgColor: const Color(0xFFE3F2FD),
                                badge: 'NEW',
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const NearbyPharmacyScreen())),
                              ),
                              _QuickChip(
                                icon: Icons.shopping_bag_rounded,
                                label: 'Order Medicines',
                                color: const Color(0xFF2E7D32),
                                bgColor: const Color(0xFFE8F5E9),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const NearbyPharmacyScreen())),
                              ),
                              _QuickChip(
                                icon: Icons.alarm_rounded,
                                label: 'Reminders',
                                color: const Color(0xFF5C6BC0),
                                bgColor: const Color(0xFFEDE7F6),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const RemindersScreen())),
                              ),
                              _QuickChip(
                                icon: Icons.favorite_rounded,
                                label: 'Adherence',
                                color: const Color(0xFF00796B),
                                bgColor: const Color(0xFFE0F2F1),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const AdherenceScreen())),
                              ),
                              _QuickChip(
                                icon: Icons.monitor_heart_rounded,
                                label: 'Health Vitals',
                                color: const Color(0xFFC62828),
                                bgColor: const Color(0xFFFFEBEE),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const HealthVitalsScreen())),
                              ),
                              _QuickChip(
                                icon: Icons.family_restroom_rounded,
                                label: 'Family',
                                color: const Color(0xFFE65100),
                                bgColor: const Color(0xFFFFF3E0),
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) => const FamilyProfilesScreen())),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ── MY HEALTH TODAY ──────────────────────────────
                        _SectionTitle(
                            title: 'My Health Today',
                            subtitle: 'Quick overview'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _StatMiniCard(
                              icon: Icons.medication_rounded,
                              label: 'Reminders',
                              value: 'Set Active',
                              color: const Color(0xFF5C6BC0),
                              bgColor: const Color(0xFFEDE7F6),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const RemindersScreen())),
                            ),
                            const SizedBox(width: 10),
                            _StatMiniCard(
                              icon: Icons.receipt_long_rounded,
                              label: 'My Orders',
                              value: 'Track Now',
                              color: const Color(0xFF00838F),
                              bgColor: const Color(0xFFE0F7FA),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const MyOrdersScreen())),
                            ),
                            const SizedBox(width: 10),
                            _StatMiniCard(
                              icon: Icons.history_edu_rounded,
                              label: 'History',
                              value: 'View All',
                              color: const Color(0xFF6A1B9A),
                              bgColor: const Color(0xFFF3E5F5),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const HistoryScreen())),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),

                        // ── FEATURE HIGHLIGHTS ───────────────────────────
                        _SectionTitle(
                            title: 'Feature Highlights',
                            subtitle: 'Everything you need'),
                        const SizedBox(height: 12),
                        _FeatureHighlightCard(
                          icon: Icons.local_pharmacy_rounded,
                          title: 'Nearby Pharmacies & Price Compare',
                          description:
                              'Find the cheapest medicine near you. Compare prices across Apollo, MedPlus, 1mg & more.',
                          tag: 'Maps + Ordering',
                          tagColor: const Color(0xFF1565C0),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const NearbyPharmacyScreen()),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FeatureHighlightCard(
                          icon: Icons.notifications_active_rounded,
                          title: 'Smart Reminders & Adherence',
                          description:
                              'Never miss a dose. Snooze alerts, track streaks, and view your 30-day adherence calendar.',
                          tag: 'Notifications',
                          tagColor: const Color(0xFF6A1B9A),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A1B9A), Color(0xFF8E24AA)],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const RemindersScreen()),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _FeatureHighlightCard(
                          icon: Icons.auto_awesome_rounded,
                          title: 'All Advanced Features',
                          description:
                              'Drug interactions, health vitals, family profiles, barcode scanner, expiry tracking & more.',
                          tag: '14+ Features',
                          tagColor: const Color(0xFFBF360C),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFBF360C), Color(0xFFE64A19)],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FeaturesScreen()),
                          ),
                        ),
                        const SizedBox(height: 10),
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

// ── HEADER BUTTON ────────────────────────────────────────────────────────────
class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  const _HeaderBtn(
      {required this.icon, this.badge = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
        if (badge > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 15,
              height: 15,
              decoration: const BoxDecoration(
                  color: Color(0xFFFF1744), shape: BoxShape.circle),
              child: Center(
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  }
}

// ── HERO UPLOAD CARD ─────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5C6BC0), Color(0xFF8E24AA)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5C6BC0).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.document_scanner_rounded,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text('AI POWERED',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(height: 5),
                  const Text('Upload Prescription',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  Text(
                    'Scan & extract medicines with OCR\nin 7 Indian languages',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SECTION TITLE ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E))),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 12, color: Colors.grey[500])),
          ],
        ),
      ],
    );
  }
}

// ── QUICK CHIP (horizontal scroll item) ──────────────────────────────────────
class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final String? badge;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[800],
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(badge!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── STAT MINI CARD ────────────────────────────────────────────────────────────
class _StatMiniCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _StatMiniCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: color)),
                    Text(label,
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey[500])),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── FEATURE HIGHLIGHT CARD ────────────────────────────────────────────────────
class _FeatureHighlightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String tag;
  final Color tagColor;
  final Gradient gradient;
  final VoidCallback onTap;

  const _FeatureHighlightCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.tag,
    required this.tagColor,
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
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: tagColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left colored strip with icon
            Container(
              width: 64,
              height: 80,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: tagColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(tag,
                              style: TextStyle(
                                  color: tagColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            color: Colors.grey[400], size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E))),
                    const SizedBox(height: 3),
                    Text(description,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            height: 1.35),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
