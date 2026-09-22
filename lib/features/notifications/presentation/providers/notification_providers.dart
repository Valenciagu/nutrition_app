import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/services/firebase_instances.dart';
import '../../../../core/services/notifications/notification_service.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../../data/repositories/firebase_notification_preferences_repository.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/reminder_builder.dart';
import '../../domain/repositories/notification_preferences_repository.dart';

final notificationPreferencesRepositoryProvider = Provider<NotificationPreferencesRepository>((ref) {
  return FirebaseNotificationPreferencesRepository(ref.watch(firestoreProvider));
});

final notificationPreferencesProvider = FutureProvider.autoDispose<NotificationPreferences>((ref) async {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return const NotificationPreferences();
  return ref.watch(notificationPreferencesRepositoryProvider).get(uid);
});

/// Se ejecuta una vez por sesión autenticada (no `.autoDispose`: cachea su
/// resultado mientras el usuario siga logueado) al montar `MainShell` —
/// mitiga que `zonedSchedule` no sobrevive un reinicio del dispositivo sin
/// un receptor nativo de arranque (no construido en v1, ver
/// `documentation/notifications.md`): reprograma en cada apertura de la app
/// en vez de solo tras guardar en Ajustes.
final notificationBootstrapProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
  if (uid == null) return;

  final prefs = await ref.read(notificationPreferencesRepositoryProvider).get(uid);
  if (!prefs.enabled) return;

  final service = ref.read(notificationServiceProvider);
  final granted = await service.requestPermission();
  if (!granted) return;

  final profile = await ref.read(userProfileProvider.future);
  final specs = buildReminderSpecs(prefs: prefs, mealSlots: profile.mealSlots, l10n: resolveDeviceLocalizations());
  await service.scheduleAll(specs);
});

final notificationSettingsEditControllerProvider =
    NotifierProvider.autoDispose<NotificationSettingsEditController, NotificationPreferences>(
      NotificationSettingsEditController.new,
    );

class NotificationSettingsEditController extends AutoDisposeNotifier<NotificationPreferences> {
  @override
  NotificationPreferences build() => const NotificationPreferences();

  void seed(NotificationPreferences prefs) => state = prefs;

  void setEnabled(bool value) => state = state.copyWith(enabled: value);

  void setMealRemindersEnabled(bool value) => state = state.copyWith(mealRemindersEnabled: value);

  void setPlanReminderEnabled(bool value) => state = state.copyWith(planReminderEnabled: value);

  void setShoppingReminderEnabled(bool value) => state = state.copyWith(shoppingReminderEnabled: value);

  void setHydrationRemindersEnabled(bool value) => state = state.copyWith(hydrationRemindersEnabled: value);

  void setQuietHours({required int startMinute, required int endMinute}) {
    state = state.copyWith(quietHoursStartMinute: startMinute, quietHoursEndMinute: endMinute);
  }
}

/// Guarda las preferencias y (re)programa/cancela los recordatorios acorde.
/// El resultado (`AsyncValue<bool>`) es si el permiso del sistema quedó
/// concedido — `false` significa que las preferencias SÍ se guardaron (la
/// intención del usuario es un dato real) pero nada sonará hasta que
/// conceda el permiso desde los ajustes del sistema; la pantalla usa esto
/// para mostrar un aviso, no un error.
final notificationSettingsSaveControllerProvider =
    AsyncNotifierProvider.autoDispose<NotificationSettingsSaveController, bool>(NotificationSettingsSaveController.new);

class NotificationSettingsSaveController extends AutoDisposeAsyncNotifier<bool> {
  @override
  FutureOr<bool> build() => true;

  Future<void> save() async {
    final uid = ref.read(authStateChangesProvider).valueOrNull?.uid;
    if (uid == null) return;

    final prefs = ref.read(notificationSettingsEditControllerProvider);
    final service = ref.read(notificationServiceProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      var granted = true;
      if (prefs.enabled) granted = await service.requestPermission();

      await ref.read(notificationPreferencesRepositoryProvider).save(uid, prefs);

      if (prefs.enabled && granted) {
        final profile = await ref.read(userProfileProvider.future);
        final specs = buildReminderSpecs(prefs: prefs, mealSlots: profile.mealSlots, l10n: resolveDeviceLocalizations());
        await service.scheduleAll(specs);
      } else {
        await service.cancelAll();
      }
      return granted;
    });
    if (!state.hasError) {
      ref.invalidate(notificationPreferencesProvider);
    }
  }
}
