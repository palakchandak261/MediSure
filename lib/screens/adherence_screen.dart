import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/adherence_service.dart';
import '../services/reminder_service.dart';
import '../services/advanced_notification_service.dart';
import '../models/adherence_model.dart';

class AdherenceScreen extends StatefulWidget {
  const AdherenceScreen({super.key});

  @override
  State<AdherenceScreen> createState() => _AdherenceScreenState();
}

class _AdherenceScreenState extends State<AdherenceScreen> {
  final AdherenceService _adherenceService = AdherenceService.instance;
  double _adherence7 = 0;
  double _adherence30 = 0;
  int _streak = 0;
  int _missedCount = 0;
  Map<String, DoseStatus> _calendarData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Register callback to refresh when dose is marked from popup
    AdvancedNotificationService.instance
        .registerNotificationCallback(_onNotification);
  }

  @override
  void dispose() {
    AdvancedNotificationService.instance
        .unregisterNotificationCallback(_onNotification);
    super.dispose();
  }

  void _onNotification(AppNotification notif) {
    // Refresh adherence data when a reminder notification fires
    if (notif.type == NotificationType.reminder) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
    final a7 =
        await _adherenceService.getAdherencePercentage(userId, days: 7);
    final a30 =
        await _adherenceService.getAdherencePercentage(userId, days: 30);
    final streak = await _adherenceService.getCurrentStreak(userId);
    final missed =
        await _adherenceService.getMissedDosesCount(userId, days: 7);
    final calendar = await _adherenceService.getCalendarData(userId);
    setState(() {
      _adherence7 = a7;
      _adherence30 = a30;
      _streak = streak;
      _missedCount = missed;
      _calendarData = calendar;
      _isLoading = false;
    });
  }

  Future<void> _markTaken() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
    final reminders =
        await ReminderService.instance.getUserReminders(userId);
    if (reminders.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('No reminders found. Add reminders first.')));
      }
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: Color(0xFF00796B), size: 26),
            SizedBox(width: 10),
            Text('Mark Dose Taken'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reminders.length,
            itemBuilder: (ctx, i) {
              final r = reminders[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00796B),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.medication_rounded,
                        color: Colors.white, size: 20),
                  ),
                  title: Text(r.medicineName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(r.dosage.isNotEmpty ? r.dosage : 'Tap to mark taken'),
                  onTap: () async {
                    await _adherenceService.markDoseTaken(
                        userId, r.id, r.medicineName, r.dosage);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('✅ ${r.medicineName} marked as taken!'),
                        backgroundColor: const Color(0xFF00796B),
                      ));
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ],
      ),
    );
  }

  Color _adherenceColor(double pct) {
    if (pct >= 80) return const Color(0xFF2E7D32);
    if (pct >= 60) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF00695C), Color(0xFF00796B), Color(0xFF00897B)],
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
                          Text('Medicine Adherence',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('Track your dose compliance',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _markTaken,
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Mark Taken'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00695C),
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
                              color: Color(0xFF00796B)))
                      : SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          child: Column(
                            children: [
                              // Stats grid
                              Row(
                                children: [
                                  _StatBox(
                                    label: '7-Day',
                                    value:
                                        '${_adherence7.toStringAsFixed(0)}%',
                                    sub: 'Adherence',
                                    icon: Icons.trending_up_rounded,
                                    color: _adherenceColor(_adherence7),
                                  ),
                                  const SizedBox(width: 10),
                                  _StatBox(
                                    label: '30-Day',
                                    value:
                                        '${_adherence30.toStringAsFixed(0)}%',
                                    sub: 'Adherence',
                                    icon: Icons.calendar_month_rounded,
                                    color: _adherenceColor(_adherence30),
                                  ),
                                  const SizedBox(width: 10),
                                  _StatBox(
                                    label: 'Streak',
                                    value: '$_streak',
                                    sub: 'Days',
                                    icon: Icons.local_fire_department_rounded,
                                    color: const Color(0xFFE65100),
                                  ),
                                  const SizedBox(width: 10),
                                  _StatBox(
                                    label: 'Missed',
                                    value: '$_missedCount',
                                    sub: 'This Week',
                                    icon: Icons.cancel_rounded,
                                    color: const Color(0xFFC62828),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Progress bars
                              _ProgressCard(
                                  label: 'This Week',
                                  pct: _adherence7,
                                  color: _adherenceColor(_adherence7)),
                              const SizedBox(height: 10),
                              _ProgressCard(
                                  label: 'This Month',
                                  pct: _adherence30,
                                  color: _adherenceColor(_adherence30)),
                              const SizedBox(height: 16),

                              // Calendar
                              _CalendarCard(calendarData: _calendarData),
                              const SizedBox(height: 16),

                              // Tips
                              _TipsCard(adherence: _adherence7),
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

class _StatBox extends StatelessWidget {
  final String label, value, sub;
  final IconData icon;
  final Color color;
  const _StatBox(
      {required this.label,
      required this.value,
      required this.sub,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(sub,
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const _ProgressCard(
      {required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final Map<String, DoseStatus> calendarData;
  const _CalendarCard({required this.calendarData});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days =
        List.generate(30, (i) => now.subtract(Duration(days: 29 - i)));

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
          const Row(
            children: [
              Icon(Icons.calendar_month_rounded,
                  color: Color(0xFF00796B), size: 20),
              SizedBox(width: 8),
              Text('30-Day Adherence Calendar',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: days.map((day) {
              final key =
                  '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
              final status = calendarData[key];
              Color bg;
              if (status == DoseStatus.taken) {
                bg = const Color(0xFF2E7D32);
              } else if (status == DoseStatus.missed) {
                bg = const Color(0xFFC62828);
              } else {
                bg = Colors.grey.shade200;
              }
              return Tooltip(
                message: '${day.day}/${day.month}',
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(7)),
                  child: Center(
                    child: Text('${day.day}',
                        style: TextStyle(
                            fontSize: 10,
                            color: status != null
                                ? Colors.white
                                : Colors.grey[500],
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Legend(color: const Color(0xFF2E7D32), label: 'Taken'),
              const SizedBox(width: 16),
              _Legend(color: const Color(0xFFC62828), label: 'Missed'),
              const SizedBox(width: 16),
              _Legend(color: Colors.grey.shade300, label: 'No data'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class _TipsCard extends StatelessWidget {
  final double adherence;
  const _TipsCard({required this.adherence});

  @override
  Widget build(BuildContext context) {
    final isGood = adherence >= 80;
    final isMid = adherence >= 60;
    final color = isGood
        ? const Color(0xFF2E7D32)
        : isMid
            ? const Color(0xFFE65100)
            : const Color(0xFFC62828);
    final tips = isGood
        ? ['🌟 Excellent adherence! Keep it up.', '💪 You\'re protecting your health effectively.', '📱 Maintain your streak with daily reminders.']
        : isMid
            ? ['👍 Good progress! Try to be more consistent.', '⏰ Use reminders to avoid missing doses.', '📝 Track your doses daily for better results.']
            : ['⚠️ Low adherence detected. Please improve.', '💊 Missing doses reduces treatment effectiveness.', '🏥 Consult your doctor if you have side effects.', '📱 Enable all reminder notifications.'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: color, size: 20),
              const SizedBox(width: 8),
              Text('Health Tips',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
            ],
          ),
          const SizedBox(height: 10),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(tip,
                    style: TextStyle(
                        color: color.withValues(alpha: 0.85),
                        fontSize: 13)),
              )),
        ],
      ),
    );
  }
}
