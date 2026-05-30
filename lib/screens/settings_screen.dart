import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/local_storage_service.dart';
import '../services/auth_service.dart';
import '../core/theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedLanguage;
  late bool _notificationsEnabled;
  late bool _reminderSoundEnabled;
  late bool _expiryAlertsEnabled;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = LocalStorageService.getLanguage();
    _notificationsEnabled =
        LocalStorageService.getSetting('notifications_enabled', true);
    _reminderSoundEnabled =
        LocalStorageService.getSetting('reminder_sound', true);
    _expiryAlertsEnabled =
        LocalStorageService.getSetting('expiry_alerts', true);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF1A1A2E),
                    const Color(0xFF16213E),
                    const Color(0xFF0F3460),
                  ]
                : [
                    const Color(0xFF5C6BC0),
                    const Color(0xFF8E24AA),
                    const Color(0xFFAD1457),
                  ],
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
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text('Settings',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E2E)
                        : const Color(0xFFF0F2F8),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // ── APPEARANCE ──────────────────────────────────────
                      _SectionHeader(
                          title: 'Appearance', icon: Icons.palette_rounded),
                      const SizedBox(height: 10),
                      _SettingCard(
                        children: [
                          _SwitchTile(
                            icon: isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            iconColor: isDark
                                ? const Color(0xFF7986CB)
                                : const Color(0xFFFFA726),
                            title: 'Dark Mode',
                            subtitle: isDark ? 'Dark theme active' : 'Light theme active',
                            value: isDark,
                            onChanged: (val) {
                              themeProvider.toggleTheme();
                              LocalStorageService.saveThemeMode(
                                  val ? 'dark' : 'light');
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── LANGUAGE ─────────────────────────────────────────
                      _SectionHeader(
                          title: 'Language', icon: Icons.language_rounded),
                      const SizedBox(height: 10),
                      _SettingCard(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5C6BC0)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.translate_rounded,
                                      color: Color(0xFF5C6BC0), size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('App Language',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14)),
                                      Text(
                                          _languageLabel(_selectedLanguage),
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500])),
                                    ],
                                  ),
                                ),
                                DropdownButton<String>(
                                  value: _selectedLanguage,
                                  underline: const SizedBox.shrink(),
                                  items: const [
                                    DropdownMenuItem(
                                        value: 'en',
                                        child: Text('English')),
                                    DropdownMenuItem(
                                        value: 'hi',
                                        child: Text('हिंदी')),
                                    DropdownMenuItem(
                                        value: 'mr',
                                        child: Text('मराठी')),
                                    DropdownMenuItem(
                                        value: 'ta',
                                        child: Text('தமிழ்')),
                                    DropdownMenuItem(
                                        value: 'te',
                                        child: Text('తెలుగు')),
                                  ],
                                  onChanged: (val) async {
                                    setState(() => _selectedLanguage = val!);
                                    await LocalStorageService.saveLanguage(val!);
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text(
                                          'Language changed to ${_languageLabel(val)}'),
                                      behavior:
                                          SnackBarBehavior.floating,
                                    ));
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── NOTIFICATIONS ────────────────────────────────────
                      _SectionHeader(
                          title: 'Notifications',
                          icon: Icons.notifications_rounded),
                      const SizedBox(height: 10),
                      _SettingCard(
                        children: [
                          _SwitchTile(
                            icon: Icons.notifications_active_rounded,
                            iconColor: const Color(0xFF5C6BC0),
                            title: 'Push Notifications',
                            subtitle: 'Medicine reminders & alerts',
                            value: _notificationsEnabled,
                            onChanged: (val) async {
                              setState(() => _notificationsEnabled = val);
                              await LocalStorageService.saveBoolSetting(
                                  'notifications_enabled', val);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _SwitchTile(
                            icon: Icons.volume_up_rounded,
                            iconColor: const Color(0xFF00838F),
                            title: 'Reminder Sound',
                            subtitle: 'Play sound for medicine reminders',
                            value: _reminderSoundEnabled,
                            onChanged: (val) async {
                              setState(() => _reminderSoundEnabled = val);
                              await LocalStorageService.saveBoolSetting(
                                  'reminder_sound', val);
                            },
                          ),
                          const Divider(height: 1, indent: 56),
                          _SwitchTile(
                            icon: Icons.calendar_month_rounded,
                            iconColor: const Color(0xFFE65100),
                            title: 'Expiry Alerts',
                            subtitle: 'Notify when medicines are expiring',
                            value: _expiryAlertsEnabled,
                            onChanged: (val) async {
                              setState(() => _expiryAlertsEnabled = val);
                              await LocalStorageService.saveBoolSetting(
                                  'expiry_alerts', val);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── ABOUT ────────────────────────────────────────────
                      _SectionHeader(
                          title: 'About', icon: Icons.info_rounded),
                      const SizedBox(height: 10),
                      _SettingCard(
                        children: [
                          _InfoTile(
                            icon: Icons.medical_services_rounded,
                            iconColor: const Color(0xFF5C6BC0),
                            title: 'MediSure',
                            subtitle: 'Version 1.0.0',
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoTile(
                            icon: Icons.code_rounded,
                            iconColor: const Color(0xFF2E7D32),
                            title: 'Built with Flutter',
                            subtitle: 'AI-powered prescription management',
                          ),
                          const Divider(height: 1, indent: 56),
                          _InfoTile(
                            icon: Icons.security_rounded,
                            iconColor: const Color(0xFF880E4F),
                            title: 'Privacy & Security',
                            subtitle:
                                'Data stored locally on your device',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── DANGER ZONE ──────────────────────────────────────
                      _SectionHeader(
                          title: 'Data Management',
                          icon: Icons.storage_rounded),
                      const SizedBox(height: 10),
                      _SettingCard(
                        children: [
                          _ActionTile(
                            icon: Icons.delete_sweep_rounded,
                            iconColor: Colors.red,
                            title: 'Clear All Data',
                            subtitle:
                                'Delete all prescriptions and history',
                            onTap: () => _confirmClearData(context),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),
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

  String _languageLabel(String code) {
    const labels = {
      'en': 'English',
      'hi': 'Hindi (हिंदी)',
      'mr': 'Marathi (मराठी)',
      'ta': 'Tamil (தமிழ்)',
      'te': 'Telugu (తెలుగు)',
    };
    return labels[code] ?? code;
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Data'),
        content: const Text(
            'This will delete all your prescriptions, reminders, and history. Your account will remain. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            child: const Text('Clear Data'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final userId =
          Provider.of<AuthService>(context, listen: false).currentUser?.uid;
      if (userId != null) {
        final prescriptions =
            LocalStorageService.getUserPrescriptions(userId);
        for (final p in prescriptions) {
          await LocalStorageService.deletePrescription(p.id);
        }
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ All data cleared'),
          backgroundColor: Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Text(title.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
                letterSpacing: 1.2)),
      ],
    );
  }
}

class _SettingCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF5C6BC0),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  const _InfoTile(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle,
                  style:
                      TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}
