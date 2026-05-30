import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:ui' show PlatformDispatcher;
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/local_storage_service.dart';
import 'services/web_notification_service.dart';
import 'services/advanced_notification_service.dart';
import 'services/adherence_service.dart';
import 'services/medicine_dataset_service.dart';
import 'services/fcm_service.dart';
import 'models/reminder_model.dart';

// Firebase — only import when not on web stub build
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Global navigator key — shows dialogs on ANY page
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await AppConfig.init();
  await Hive.initFlutter();
  await LocalStorageService.init();

  // ── Firebase init (FCM + Crashlytics) ───────────────────────────────────
  // Only initializes if google-services.json is present.
  // App works fully without Firebase — FCM/Crashlytics are optional.
  try {
    await Firebase.initializeApp();

    // ── Crashlytics: catch all Flutter framework errors ──────────────────
    if (!kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      // Catch errors outside Flutter framework (async, isolates)
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      debugPrint('✅ Firebase Crashlytics initialized');
    }

    // Register background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    debugPrint('✅ Firebase initialized');
    // Initialize FCM service (requests permission, registers token)
    await FcmService.instance.init(null);
  } catch (e) {
    debugPrint('⚠️  Firebase not configured (FCM/Crashlytics disabled): $e');
    debugPrint('   To enable: add google-services.json to android/app/');
  }

  // Load medicine dataset
  await MedicineDatasetService.instance.load();
  debugPrint('📊 Dataset: ${MedicineDatasetService.instance.count} medicines loaded');

  if (kIsWeb) {
    WebNotificationService.instance.startChecking();
  }
  AdvancedNotificationService.instance.startChecking();

  // Register global reminder callback — shows popup on ANY page
  AdvancedNotificationService.instance
      .registerReminderCallback(_showGlobalReminderPopup);
  WebNotificationService.instance.registerCallback(_showGlobalReminderPopup);

  runApp(const MediSureApp());
}

/// Shows reminder popup on top of whatever page is currently open
void _showGlobalReminderPopup(List<Reminder> reminders) {
  if (navigatorKey.currentContext == null) return;
  if (navigatorKey.currentState == null) return;

  showDialog(
    context: navigatorKey.currentContext!,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (_) => _ReminderPopup(reminders: reminders),
  );
}

class MediSureApp extends StatelessWidget {
  const MediSureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'MediSure',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          navigatorKey: navigatorKey,
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

/// Global reminder popup — auto-updates adherence when Taken/Missed
class _ReminderPopup extends StatefulWidget {
  final List<Reminder> reminders;
  const _ReminderPopup({required this.reminders});

  @override
  State<_ReminderPopup> createState() => _ReminderPopupState();
}

class _ReminderPopupState extends State<_ReminderPopup> {
  bool _marking = false;

  String? _getUserId() {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return null;
    try {
      return Provider.of<AuthService>(ctx, listen: false).currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  Future<void> _markTaken() async {
    setState(() => _marking = true);
    final userId = _getUserId();
    if (userId != null) {
      for (final r in widget.reminders) {
        await AdherenceService.instance.markDoseTaken(
          userId, r.id, r.medicineName, r.dosage,
        );
      }
    }
    if (mounted) {
      Navigator.of(context).pop();
      final names = widget.reminders.map((r) => r.medicineName).join(', ');
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('✅ $names marked as taken!',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _markMissed() async {
    final userId = _getUserId();
    if (userId != null) {
      for (final r in widget.reminders) {
        await AdherenceService.instance.markDoseMissed(
          userId, r.id, r.medicineName, r.dosage, DateTime.now(),
        );
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _snooze(int minutes) {
    for (final r in widget.reminders) {
      AdvancedNotificationService.instance.snoozeReminder(r.id, minutes);
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text('⏰ Snoozed for $minutes minutes'),
        backgroundColor: const Color(0xFF6B7FED),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 20,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF5C6BC0), Color(0xFF8E24AA)],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.reminders.length == 1
                              ? '💊 Medicine Reminder'
                              : '💊 ${widget.reminders.length} Reminders',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                        Text('Time to take your medicine',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white70, size: 20),
                    onPressed: _markMissed,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...widget.reminders.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medication_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.medicineName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                              if (r.dosage.isNotEmpty)
                                Text(r.dosage,
                                    style: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.85),
                                        fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          '${r.time.hour.toString().padLeft(2, '0')}:${r.time.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 14),
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
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
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Snooze 10m',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _marking ? null : _markTaken,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF5C6BC0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: _marking
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF5C6BC0)))
                          : const Text('Taken ✓',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _markMissed,
                  child: Text('I missed this dose',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
