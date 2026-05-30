import 'package:flutter_test/flutter_test.dart';
import 'package:medisure/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('validateEmail returns error for empty email', () {
      expect(Validators.validateEmail(''), 'Email is required');
    });

    test('validateEmail returns error for invalid email', () {
      expect(Validators.validateEmail('invalid-email'), 'Enter a valid email');
    });

    test('validateEmail returns null for valid email', () {
      expect(Validators.validateEmail('user@example.com'), null);
    });

    test('validatePassword requires at least 6 characters', () {
      expect(Validators.validatePassword('12345'), 'Password must be at least 6 characters');
      expect(Validators.validatePassword('123456'), null);
    });

    test('validateName requires at least 2 characters', () {
      expect(Validators.validateName(''), 'Name is required');
      expect(Validators.validateName('A'), 'Name must be at least 2 characters');
      expect(Validators.validateName('Alex'), null);
    });
  });
}
