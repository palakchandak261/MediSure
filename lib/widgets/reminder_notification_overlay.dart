import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../services/web_notification_service.dart';
import '../services/advanced_notification_service.dart';

class ReminderNotificationOverlay extends StatefulWidget {
  final Widget child;

  const ReminderNotificationOverlay({
    super.key,
    required this.child,
  });

  @override
  State<ReminderNotificationOverlay> createState() =>
      _ReminderNotificationOverlayState();
}

class _ReminderNotificationOverlayState
    extends State<ReminderNotificationOverlay>
    with SingleTickerProviderStateMixin {
  List<Reminder> _currentReminders = [];
  late AnimationController _animController;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));

    WebNotificationService.instance.registerCallback(_onNotification);
    AdvancedNotificationService.instance
        .registerReminderCallback(_onNotification);
  }

  @override
  void dispose() {
    WebNotificationService.instance.unregisterCallback(_onNotification);
    AdvancedNotificationService.instance
        .unregisterReminderCallback(_onNotification);
    _animController.dispose();
    super.dispose();
  }

  void _onNotification(List<Reminder> reminders) {
    if (mounted) {
      setState(() => _currentReminders = reminders);
      _animController.forward(from: 0);
    }
  }

  void _dismiss() {
    _animController.reverse().then((_) {
      if (mounted) setState(() => _currentReminders = []);
    });
  }

  void _snooze(int minutes) {
    for (final r in _currentReminders) {
      AdvancedNotificationService.instance.snoozeReminder(r.id, minutes);
    }
    _dismiss();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Snoozed for $minutes minutes'),
        backgroundColor: const Color(0xFF6B7FED),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_currentReminders.isNotEmpty)
          Positioned(
            top: 10,
            left: 16,
            right: 16,
            child: SlideTransition(
              position: _slideAnim,
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6B7FED), Color(0xFF9D6FDB)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.notifications_active,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _currentReminders.length == 1
                                  ? 'Medicine Reminder'
                                  : '${_currentReminders.length} Medicine Reminders',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: _dismiss,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ..._currentReminders.map((reminder) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.medication,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reminder.medicineName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (reminder.dosage.isNotEmpty)
                                        Text(
                                          reminder.dosage,
                                          style: TextStyle(
                                            color:
                                                Colors.white.withValues(alpha: 0.85),
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 8),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _snooze(5),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('Snooze 5m',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _snooze(10),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('Snooze 10m',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _dismiss,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF6B7FED),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('Taken ✓',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
