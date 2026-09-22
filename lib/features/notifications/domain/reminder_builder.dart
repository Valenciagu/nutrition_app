import '../../../core/localization/generated/app_localizations.dart';
import '../../../core/services/notifications/reminder_spec.dart';
import '../../onboarding/domain/entities/onboarding_answers.dart';
import '../../onboarding/presentation/onboarding_catalog.dart';
import 'entities/notification_preferences.dart';

/// `true` si [minuteOfDay] cae dentro del rango de silencio
/// [startMinute]-[endMinute]. Un rango que cruza medianoche (`start > end`,
/// p. ej. 22:00-08:00, el valor por defecto) se trata como dos tramos:
/// [start, 1440) y [0, end) — pura función, sin estado, fácil de testear.
bool isInQuietHours(int minuteOfDay, int startMinute, int endMinute) {
  if (startMinute == endMinute) return false;
  if (startMinute < endMinute) return minuteOfDay >= startMinute && minuteOfDay < endMinute;
  return minuteOfDay >= startMinute || minuteOfDay < endMinute;
}

/// Horarios fijos para los tipos sin dato propio de dónde tomar una hora
/// (Instrucciones.md §40 pide respetar horas de silencio, no un horario
/// configurable por tipo) — simplificación de v1, documentada en
/// `documentation/notifications.md`, no una limitación oculta.
const _planReminderHour = 20;
const _planReminderMinute = 0;
const _shoppingReminderWeekday = DateTime.sunday;
const _shoppingReminderHour = 18;
const _shoppingReminderMinute = 0;
const _hydrationHours = [10, 13, 16];

const _mealReminderIdBase = 100;
const _planReminderId = 200;
const _shoppingReminderId = 300;
const _hydrationReminderIdBase = 400;

/// Traduce [prefs] + el horario real de comidas del usuario a la lista
/// concreta de recordatorios a programar, filtrando cualquiera que caiga en
/// horas de silencio. Sin efectos secundarios — `NotificationService` es
/// quien realmente programa esto vía `flutter_local_notifications`.
List<ReminderSpec> buildReminderSpecs({
  required NotificationPreferences prefs,
  required List<MealSlot> mealSlots,
  required AppLocalizations l10n,
}) {
  if (!prefs.enabled) return const [];

  bool allowed(int hour, int minute) =>
      !isInQuietHours(hour * 60 + minute, prefs.quietHoursStartMinute, prefs.quietHoursEndMinute);

  final specs = <ReminderSpec>[];

  if (prefs.mealRemindersEnabled) {
    for (var i = 0; i < mealSlots.length; i++) {
      final slot = mealSlots[i];
      if (!allowed(slot.hour, slot.minute)) continue;
      specs.add(
        ReminderSpec(
          id: _mealReminderIdBase + i,
          title: l10n.notificationMealReminderTitle,
          body: l10n.notificationMealReminderBody(mealSlotLabel(l10n, slot.labelKey)),
          hour: slot.hour,
          minute: slot.minute,
        ),
      );
    }
  }

  if (prefs.planReminderEnabled && allowed(_planReminderHour, _planReminderMinute)) {
    specs.add(
      ReminderSpec(
        id: _planReminderId,
        title: l10n.notificationPlanReminderTitle,
        body: l10n.notificationPlanReminderBody,
        hour: _planReminderHour,
        minute: _planReminderMinute,
      ),
    );
  }

  if (prefs.shoppingReminderEnabled && allowed(_shoppingReminderHour, _shoppingReminderMinute)) {
    specs.add(
      ReminderSpec(
        id: _shoppingReminderId,
        title: l10n.notificationShoppingReminderTitle,
        body: l10n.notificationShoppingReminderBody,
        hour: _shoppingReminderHour,
        minute: _shoppingReminderMinute,
        weekday: _shoppingReminderWeekday,
      ),
    );
  }

  if (prefs.hydrationRemindersEnabled) {
    for (var i = 0; i < _hydrationHours.length; i++) {
      final hour = _hydrationHours[i];
      if (!allowed(hour, 0)) continue;
      specs.add(
        ReminderSpec(
          id: _hydrationReminderIdBase + i,
          title: l10n.notificationHydrationReminderTitle,
          body: l10n.notificationHydrationReminderBody,
          hour: hour,
          minute: 0,
        ),
      );
    }
  }

  return specs;
}
