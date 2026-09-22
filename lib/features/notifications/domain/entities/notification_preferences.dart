/// Preferencias de recordatorios (Épica 12, Instrucciones.md §40). `enabled`
/// es el interruptor maestro y por defecto es `false` — la especificación
/// exige opt-in explícito, así que nunca se activa solo. Los sub-toggles
/// arrancan en `true` para que, cuando el usuario SÍ activa el maestro, los
/// tres tipos con datos reales detrás queden encendidos por defecto;
/// `hydrationRemindersEnabled` arranca en `false` porque no depende de
/// ningún dato del usuario (ver `reminder_builder.dart`) y no debería
/// asumirse deseado.
class NotificationPreferences {
  const NotificationPreferences({
    this.enabled = false,
    this.mealRemindersEnabled = true,
    this.planReminderEnabled = true,
    this.shoppingReminderEnabled = true,
    this.hydrationRemindersEnabled = false,
    this.quietHoursStartMinute = 22 * 60,
    this.quietHoursEndMinute = 8 * 60,
  });

  final bool enabled;
  final bool mealRemindersEnabled;
  final bool planReminderEnabled;
  final bool shoppingReminderEnabled;
  final bool hydrationRemindersEnabled;

  /// Minutos desde medianoche (0-1439). Un rango que cruza medianoche (p. ej.
  /// 22:00 a 08:00, el valor por defecto) es válido: `start > end` se
  /// interpreta como "hasta medianoche + desde medianoche" (ver
  /// `isInQuietHours` en `reminder_builder.dart`).
  final int quietHoursStartMinute;
  final int quietHoursEndMinute;

  /// Cuántos tipos de recordatorio están realmente activos — usado por la
  /// fila "Recordatorios" de Perfil para mostrar un valor real, nunca
  /// fabricado (a diferencia del mock del diseño, que muestra "4 activos"
  /// sin datos detrás).
  int get activeTypeCount {
    if (!enabled) return 0;
    return [mealRemindersEnabled, planReminderEnabled, shoppingReminderEnabled, hydrationRemindersEnabled]
        .where((v) => v)
        .length;
  }

  NotificationPreferences copyWith({
    bool? enabled,
    bool? mealRemindersEnabled,
    bool? planReminderEnabled,
    bool? shoppingReminderEnabled,
    bool? hydrationRemindersEnabled,
    int? quietHoursStartMinute,
    int? quietHoursEndMinute,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      mealRemindersEnabled: mealRemindersEnabled ?? this.mealRemindersEnabled,
      planReminderEnabled: planReminderEnabled ?? this.planReminderEnabled,
      shoppingReminderEnabled: shoppingReminderEnabled ?? this.shoppingReminderEnabled,
      hydrationRemindersEnabled: hydrationRemindersEnabled ?? this.hydrationRemindersEnabled,
      quietHoursStartMinute: quietHoursStartMinute ?? this.quietHoursStartMinute,
      quietHoursEndMinute: quietHoursEndMinute ?? this.quietHoursEndMinute,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'mealRemindersEnabled': mealRemindersEnabled,
    'planReminderEnabled': planReminderEnabled,
    'shoppingReminderEnabled': shoppingReminderEnabled,
    'hydrationRemindersEnabled': hydrationRemindersEnabled,
    'quietHoursStartMinute': quietHoursStartMinute,
    'quietHoursEndMinute': quietHoursEndMinute,
  };

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    const fallback = NotificationPreferences();
    return NotificationPreferences(
      enabled: json['enabled'] as bool? ?? fallback.enabled,
      mealRemindersEnabled: json['mealRemindersEnabled'] as bool? ?? fallback.mealRemindersEnabled,
      planReminderEnabled: json['planReminderEnabled'] as bool? ?? fallback.planReminderEnabled,
      shoppingReminderEnabled: json['shoppingReminderEnabled'] as bool? ?? fallback.shoppingReminderEnabled,
      hydrationRemindersEnabled: json['hydrationRemindersEnabled'] as bool? ?? fallback.hydrationRemindersEnabled,
      quietHoursStartMinute: json['quietHoursStartMinute'] as int? ?? fallback.quietHoursStartMinute,
      quietHoursEndMinute: json['quietHoursEndMinute'] as int? ?? fallback.quietHoursEndMinute,
    );
  }
}
