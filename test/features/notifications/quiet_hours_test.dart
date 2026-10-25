import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/features/notifications/domain/reminder_builder.dart';

void main() {
  const h = 60;

  test('rango dentro del mismo día', () {
    expect(isInQuietHours(14 * h, 13 * h, 15 * h), isTrue);
    expect(isInQuietHours(15 * h, 13 * h, 15 * h), isFalse, reason: 'el fin es exclusivo');
    expect(isInQuietHours(12 * h, 13 * h, 15 * h), isFalse);
  });

  test('rango que cruza medianoche (22:00-08:00)', () {
    expect(isInQuietHours(23 * h, 22 * h, 8 * h), isTrue);
    expect(isInQuietHours(2 * h, 22 * h, 8 * h), isTrue);
    expect(isInQuietHours(8 * h, 22 * h, 8 * h), isFalse);
    expect(isInQuietHours(13 * h, 22 * h, 8 * h), isFalse);
  });

  test('inicio igual a fin desactiva el silencio', () {
    expect(isInQuietHours(10 * h, 9 * h, 9 * h), isFalse);
  });
}
