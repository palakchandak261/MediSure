class FamilyMemberModel {
  final String id;
  final String ownerId;
  final String name;
  final String relation;
  final int age;
  final String bloodGroup;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String emergencyContact;
  final DateTime createdAt;

  FamilyMemberModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.relation,
    required this.age,
    required this.bloodGroup,
    required this.allergies,
    required this.chronicConditions,
    required this.emergencyContact,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'relation': relation,
      'age': age,
      'bloodGroup': bloodGroup,
      'allergies': allergies,
      'chronicConditions': chronicConditions,
      'emergencyContact': emergencyContact,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FamilyMemberModel.fromMap(Map<String, dynamic> map) {
    return FamilyMemberModel(
      id: map['id'] ?? '',
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      relation: map['relation'] ?? '',
      age: map['age'] ?? 0,
      bloodGroup: map['bloodGroup'] ?? 'Unknown',
      allergies: List<String>.from(map['allergies'] ?? []),
      chronicConditions: List<String>.from(map['chronicConditions'] ?? []),
      emergencyContact: map['emergencyContact'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}
