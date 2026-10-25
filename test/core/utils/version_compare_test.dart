import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/core/utils/version_compare.dart';

void main() {
  group('compareVersions', () {
    test('compara numéricamente, no como texto', () {
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareVersions('1.9.0', '1.10.0'), lessThan(0));
    });

    test('versiones iguales devuelven 0', () {
      expect(compareVersions('0.1.0', '0.1.0'), 0);
    });

    test('segmentos faltantes cuentan como 0', () {
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.2', '1.2.1'), lessThan(0));
    });

    test('ignora sufijos de build y pre-release', () {
      expect(compareVersions('1.2.3+45', '1.2.3'), 0);
      expect(compareVersions('1.2.3-beta', '1.2.3'), 0);
    });

    test('un mínimo vacío o inválido nunca exige actualizar', () {
      expect(compareVersions('0.1.0', ''), greaterThanOrEqualTo(0));
      expect(compareVersions('0.1.0', 'abc'), greaterThanOrEqualTo(0));
    });
  });
}
