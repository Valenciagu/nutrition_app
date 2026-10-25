import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/core/utils/validators.dart';

void main() {
  group('Validators.isValidEmail', () {
    test('acepta correos normales, ignorando espacios alrededor', () {
      expect(Validators.isValidEmail('ana@correo.com'), isTrue);
      expect(Validators.isValidEmail('  ana@correo.com  '), isTrue);
    });

    test('rechaza correos sin @, sin dominio o con espacios internos', () {
      expect(Validators.isValidEmail('ana.correo.com'), isFalse);
      expect(Validators.isValidEmail('ana@correo'), isFalse);
      expect(Validators.isValidEmail('ana @correo.com'), isFalse);
    });
  });

  group('Validators.passwordStrength', () {
    test('menos de 8 caracteres es débil', () {
      expect(Validators.passwordStrength('Ab1!'), PasswordStrength.weak);
      expect(Validators.isValidPassword('1234567'), isFalse);
    });

    test('número + mayúscula/símbolo es fuerte', () {
      expect(Validators.passwordStrength('clave1234X'), PasswordStrength.strong);
    });

    test('solo letras minúsculas largas es media', () {
      expect(Validators.passwordStrength('clavelarga'), PasswordStrength.medium);
    });
  });
}
