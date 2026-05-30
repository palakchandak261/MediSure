import 'package:flutter_test/flutter_test.dart';
import 'package:medisure/models/user_model.dart';

void main() {
  test('UserModel serialization and deserialization preserves data', () {
    final user = UserModel(
      uid: 'uid-123',
      name: 'Test User',
      email: 'test@example.com',
      passwordHash: 'hash-value',
      passwordSalt: 'salt-value',
      createdAt: DateTime.parse('2026-01-01T12:00:00Z'),
    );

    final map = user.toMap();
    final restored = UserModel.fromMap(map);

    expect(restored.uid, user.uid);
    expect(restored.name, user.name);
    expect(restored.email, user.email);
    expect(restored.passwordHash, user.passwordHash);
    expect(restored.passwordSalt, user.passwordSalt);
    expect(restored.createdAt.toUtc(), user.createdAt.toUtc());
  });
}
