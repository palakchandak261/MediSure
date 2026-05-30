import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../models/family_member_model.dart';

class FamilyProfilesScreen extends StatefulWidget {
  const FamilyProfilesScreen({super.key});

  @override
  State<FamilyProfilesScreen> createState() => _FamilyProfilesScreenState();
}

class _FamilyProfilesScreenState extends State<FamilyProfilesScreen> {
  final FamilyService _service = FamilyService.instance;
  List<FamilyMemberModel> _members = [];
  bool _isLoading = true;

  final List<String> _relations = [
    'Spouse', 'Parent', 'Child', 'Sibling', 'Grandparent', 'Other'
  ];
  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'
  ];

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final userId =
        Provider.of<AuthService>(context, listen: false).currentUser?.uid ?? '';
    final members = await _service.getFamilyMembers(userId);
    setState(() {
      _members = members;
      _isLoading = false;
    });
  }

  void _showAddMemberDialog([FamilyMemberModel? existing]) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final ageCtrl =
        TextEditingController(text: existing?.age.toString() ?? '');
    final emergencyCtrl =
        TextEditingController(text: existing?.emergencyContact ?? '');
    final allergiesCtrl =
        TextEditingController(text: existing?.allergies.join(', ') ?? '');
    final conditionsCtrl = TextEditingController(
        text: existing?.chronicConditions.join(', ') ?? '');
    String selectedRelation = existing?.relation ?? _relations.first;
    String selectedBloodGroup = existing?.bloodGroup ?? _bloodGroups.last;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_rounded,
                    color: Color(0xFFE65100), size: 22),
              ),
              const SizedBox(width: 10),
              Text(existing == null ? 'Add Family Member' : 'Edit Member'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(ctrl: nameCtrl, label: 'Full Name', icon: Icons.person_rounded),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedRelation,
                        decoration: InputDecoration(
                          labelText: 'Relation',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                        ),
                        items: _relations
                            .map((r) =>
                                DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => selectedRelation = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Field(
                          ctrl: ageCtrl,
                          label: 'Age',
                          icon: Icons.cake_rounded,
                          type: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedBloodGroup,
                  decoration: InputDecoration(
                    labelText: 'Blood Group',
                    prefixIcon: const Icon(Icons.bloodtype_rounded,
                        color: Colors.red, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  items: _bloodGroups
                      .map((b) =>
                          DropdownMenuItem(value: b, child: Text(b)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedBloodGroup = v!),
                ),
                const SizedBox(height: 10),
                _Field(
                    ctrl: emergencyCtrl,
                    label: 'Emergency Contact',
                    icon: Icons.phone_rounded),
                const SizedBox(height: 10),
                _Field(
                    ctrl: allergiesCtrl,
                    label: 'Allergies (comma separated)',
                    icon: Icons.warning_amber_rounded),
                const SizedBox(height: 10),
                _Field(
                    ctrl: conditionsCtrl,
                    label: 'Chronic Conditions (comma separated)',
                    icon: Icons.medical_services_rounded),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton.icon(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final userId =
                    Provider.of<AuthService>(context, listen: false)
                        .currentUser
                        ?.uid ??
                        '';
                final member = FamilyMemberModel(
                  id: existing?.id ?? const Uuid().v4(),
                  ownerId: userId,
                  name: nameCtrl.text.trim(),
                  relation: selectedRelation,
                  age: int.tryParse(ageCtrl.text) ?? 0,
                  bloodGroup: selectedBloodGroup,
                  allergies: allergiesCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList(),
                  chronicConditions: conditionsCtrl.text
                      .split(',')
                      .map((s) => s.trim())
                      .where((s) => s.isNotEmpty)
                      .toList(),
                  emergencyContact: emergencyCtrl.text.trim(),
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );
                if (existing == null) {
                  await _service.addFamilyMember(member);
                } else {
                  await _service.updateFamilyMember(member);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadMembers();
              },
              icon: const Icon(Icons.save_rounded, size: 16),
              label: Text(existing == null ? 'Add Member' : 'Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
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
            colors: [Color(0xFFBF360C), Color(0xFFE64A19), Color(0xFFF4511E)],
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
                          Text('Family Profiles',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          Text('Manage health for your loved ones',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddMemberDialog(),
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFE64A19),
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
                              color: Color(0xFFE64A19)))
                      : _members.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFF3E0),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                        Icons.family_restroom_rounded,
                                        size: 52,
                                        color: Color(0xFFE64A19)),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('No family members added',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A1A2E))),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Add family members to manage\ntheir medicines and health',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[500])),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 16, 16, 20),
                              itemCount: _members.length,
                              itemBuilder: (ctx, i) => _MemberCard(
                                member: _members[i],
                                onEdit: () =>
                                    _showAddMemberDialog(_members[i]),
                                onDelete: () async {
                                  final userId =
                                      Provider.of<AuthService>(context,
                                              listen: false)
                                          .currentUser
                                          ?.uid ??
                                          '';
                                  await _service.deleteFamilyMember(
                                      userId, _members[i].id);
                                  _loadMembers();
                                },
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

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final TextInputType type;
  const _Field(
      {required this.ctrl,
      required this.label,
      required this.icon,
      this.type = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey[600]),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final FamilyMemberModel member;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _MemberCard(
      {required this.member, required this.onEdit, required this.onDelete});

  Color get _relationColor {
    switch (member.relation) {
      case 'Spouse':
        return const Color(0xFFE91E63);
      case 'Parent':
        return const Color(0xFFE65100);
      case 'Child':
        return const Color(0xFF1565C0);
      case 'Sibling':
        return const Color(0xFF2E7D32);
      case 'Grandparent':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF5C6BC0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: _relationColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _relationColor.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: _relationColor.withValues(alpha: 0.15),
                  child: Text(
                    member.name.isNotEmpty
                        ? member.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _relationColor),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _relationColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(member.relation,
                                style: TextStyle(
                                    color: _relationColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Text('${member.age} yrs',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 12)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(member.bloodGroup,
                                style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_rounded,
                      color: Color(0xFF5C6BC0), size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(Icons.delete_rounded,
                      color: Colors.red[400], size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Column(
              children: [
                if (member.allergies.isNotEmpty)
                  _InfoRow(
                      icon: Icons.warning_amber_rounded,
                      label: 'Allergies',
                      value: member.allergies.join(', '),
                      color: Colors.orange.shade700),
                if (member.chronicConditions.isNotEmpty)
                  _InfoRow(
                      icon: Icons.medical_services_rounded,
                      label: 'Conditions',
                      value: member.chronicConditions.join(', '),
                      color: Colors.red.shade600),
                if (member.emergencyContact.isNotEmpty) ...[
                  _InfoRow(
                      icon: Icons.phone_rounded,
                      label: 'Emergency',
                      value: member.emergencyContact,
                      color: Colors.green.shade700),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final uri = Uri.parse(
                                'tel:${member.emergencyContact.replaceAll(' ', '')}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.call_rounded, size: 15),
                          label: const Text('Call'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final phone = member.emergencyContact
                                .replaceAll(RegExp(r'[\s\-\(\)]'), '');
                            final e164 = phone.startsWith('+')
                                ? phone.substring(1)
                                : phone.length == 10
                                    ? '91$phone'
                                    : phone;
                            final msg = Uri.encodeComponent(
                                'Hi ${member.name}, checking in from MediSure. Please respond when you can.');
                            final waUri =
                                Uri.parse('https://wa.me/$e164?text=$msg');
                            if (await canLaunchUrl(waUri)) {
                              await launchUrl(waUri,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              final smsUri =
                                  Uri.parse('sms:${member.emergencyContact}');
                              if (await canLaunchUrl(smsUri)) {
                                await launchUrl(smsUri,
                                    mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                          icon: const Icon(Icons.message_rounded, size: 15),
                          label: const Text('Message'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (member.allergies.isEmpty &&
                    member.chronicConditions.isEmpty &&
                    member.emergencyContact.isEmpty)
                  Text('No health details added yet',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text('$label: ',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color)),
          Expanded(
            child: Text(value,
                style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          ),
        ],
      ),
    );
  }
}
