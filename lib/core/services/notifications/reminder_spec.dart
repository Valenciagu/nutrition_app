/// Un recordatorio local a programar — genérico, sin nada específico de
/// nutrición (eso vive en `features/notifications/domain/reminder_builder.dart`).
/// `weekday` sigue la convención de `DateTime` (1 = lunes … 7 = domingo);
/// `null` significa "todos los días".
class ReminderSpec {
  const ReminderSpec({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.weekday,
  });

  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final int? weekday;
}
