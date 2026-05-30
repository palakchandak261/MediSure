import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/reminder_service.dart';
import '../services/advanced_notification_service.dart';
import '../models/reminder_model.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final ReminderService _reminderService = ReminderService.instance;
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;
    if (userId != null) {
      final reminders = await _reminderService.getUserReminders(userId);
      if (mounted) {
        setState(() {
          _reminders = reminders;
          _isLoading = false;
        });
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleReminder(Reminder reminder) async {
    final updated = Reminder(
      id: reminder.id,
      userId: reminder.userId,
      medicineName: reminder.medicineName,
      dosage: reminder.dosage,
      time: reminder.time,
      isEnabled: !reminder.isEnabled,
      createdAt: reminder.createdAt,
    );
    await _reminderService.updateReminder(updated);
    await _loadReminders();
  }

  Future<void> _deleteReminder(String id) async {
    await _reminderService.deleteReminder(id);
    await _loadReminders();
  }

  void _showAddReminderDialog() {
    final nameController = TextEditingController();
    final dosageController = TextEditingController();
    // Pre-fill with current time so user can adjust to exact desired time
    final now = TimeOfDay.now();
    TimeOfDay selectedTime = now;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New Reminder'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage (e.g. 500mg)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.science),
                  ),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Reminder Time'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedTime.format(ctx),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B7FED),
                        ),
                      ),
                      Text(
                        'Notification fires at exact time set',
                        style: TextStyle(
                            fontSize: 10, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.access_time,
                      color: Color(0xFF6B7FED)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setDialogState(() => selectedTime = time);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                final authService =
                    Provider.of<AuthService>(context, listen: false);
                final userId = authService.currentUser?.uid;
                if (userId != null) {
                  await _reminderService.addReminder(
                    userId: userId,
                    medicineName: nameController.text.trim(),
                    dosage: dosageController.text.trim(),
                    time: selectedTime,
                  );
                  await _loadReminders();
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B7FED),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Add Reminder'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B7FED),
              Color(0xFF9D6FDB),
              Color(0xFFB565C8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Medicine Reminders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Test notification button
                    GestureDetector(
                      onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await AdvancedNotificationService.instance
                          .triggerTestNotification();
                      if (!mounted) return;
                      messenger.showSnackBar(
                          const SnackBar(
                            content: Text('🔔 Test notification triggered!'),
                            backgroundColor: Color(0xFF6B7FED),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.notifications_active,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text('Test',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF6B7FED)))
                      : _reminders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.notifications_off_outlined,
                                      size: 80, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No reminders yet',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap + to add a reminder',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _reminders.length,
                              itemBuilder: (context, index) {
                                final reminder = _reminders[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: reminder.isEnabled
                                                  ? [
                                                      const Color(0xFF6B7FED),
                                                      const Color(0xFF9D6FDB)
                                                    ]
                                                  : [
                                                      Colors.grey.shade400,
                                                      Colors.grey.shade500
                                                    ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.medication,
                                              color: Colors.white, size: 24),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                reminder.medicineName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2D3142),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                reminder.dosage.isNotEmpty
                                                    ? '${reminder.dosage} • ${reminder.time.format(context)}'
                                                    : reminder.time
                                                        .format(context),
                                                style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey[600]),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: reminder.isEnabled,
                                          onChanged: (_) =>
                                              _toggleReminder(reminder),
                                          activeThumbColor: const Color(0xFF6B7FED),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete_outline,
                                              color: Colors.red[400]),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                    'Delete Reminder'),
                                                content: Text(
                                                    'Delete reminder for ${reminder.medicineName}?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(ctx),
                                                    child:
                                                        const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      _deleteReminder(
                                                          reminder.id);
                                                      Navigator.pop(ctx);
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            backgroundColor:
                                                                Colors.red),
                                                    child:
                                                        const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        backgroundColor: const Color(0xFF6B7FED),
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
    );
  }
}
