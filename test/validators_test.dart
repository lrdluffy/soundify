import 'package:flutter_test/flutter_test.dart';
import 'package:soundify/core/util/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty and malformed', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('abc'), isNotNull);
      expect(Validators.email('a@b'), isNotNull);
    });
    test('accepts valid', () {
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email(' first.last+tag@mail.example.ir '), isNull);
    });
  });

  group('Validators.password', () {
    test('requires 8+ chars', () {
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });
  });

  test('confirmPassword compares against original', () {
    final v = Validators.confirmPassword(() => 'secret123');
    expect(v('secret123'), isNull);
    expect(v('other'), isNotNull);
  });

  test('otp needs digits', () {
    expect(Validators.otp('12ab'), isNotNull);
    expect(Validators.otp('123456'), isNull);
  });
}
