import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/family_member_model.dart';

class FamilyService {
  static final FamilyService _instance = FamilyService._internal();
  static FamilyService get instance => _instance;
  FamilyService._internal();

  static const String _key = 'family_members';

  Future<List<FamilyMemberModel>> getFamilyMembers(String ownerId) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('${_key}_$ownerId');
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list.map((e) => FamilyMemberModel.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> addFamilyMember(FamilyMemberModel member) async {
    final members = await getFamilyMembers(member.ownerId);
    members.add(member);
    await _save(member.ownerId, members);
  }

  Future<void> updateFamilyMember(FamilyMemberModel updated) async {
    final members = await getFamilyMembers(updated.ownerId);
    final idx = members.indexWhere((m) => m.id == updated.id);
    if (idx != -1) {
      members[idx] = updated;
      await _save(updated.ownerId, members);
    }
  }

  Future<void> deleteFamilyMember(String ownerId, String memberId) async {
    final members = await getFamilyMembers(ownerId);
    members.removeWhere((m) => m.id == memberId);
    await _save(ownerId, members);
  }

  Future<void> _save(String ownerId, List<FamilyMemberModel> members) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '${_key}_$ownerId',
      jsonEncode(members.map((m) => m.toMap()).toList()),
    );
  }

  FamilyMemberModel createMember({
    required String ownerId,
    required String name,
    required String relation,
    required int age,
    required String bloodGroup,
    required List<String> allergies,
    required List<String> chronicConditions,
    required String emergencyContact,
  }) {
    return FamilyMemberModel(
      id: const Uuid().v4(),
      ownerId: ownerId,
      name: name,
      relation: relation,
      age: age,
      bloodGroup: bloodGroup,
      allergies: allergies,
      chronicConditions: chronicConditions,
      emergencyContact: emergencyContact,
      createdAt: DateTime.now(),
    );
  }
}
