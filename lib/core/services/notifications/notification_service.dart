import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_spec.dart';

const _channelId = 'reminders_channel';
const _channelName = 'Recordatorios';

/// Envoltura fina sobre `flutter_local_notifications` — programación 100%
/// local, sin push/FCM (Épica 12: todo recordatorio depende del horario
/// propio del usuario o de una cadencia fija, nunca de un evento
/// server-side, así que no hace falta backend). El plugin no tiene
/// implementación web — cada método hace no-op ahí vía el guard `kIsWeb`
/// (Firestore sigue guardando las preferencias igual en web, solo la
/// programación real queda pendiente de abrir la app móvil, ver
/// `documentation/notifications.md`).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _timeZoneReady = false;

  /// Llamar una sola vez al arrancar la app (`main.dart`). NO pide permiso
  /// aquí — `Instrucciones.md` §40 exige opt-in explícito, así que la
  /// solicitud real ocurre solo en [requestPermission], disparada por el
  /// interruptor maestro de la pantalla de Recordatorios.
  Future<void> initializePlugin() async {
    if (kIsWeb) return;
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestSoundPermission: false,
      requestBadgePermission: false,
    );
    await _plugin.initialize(const InitializationSettings(android: androidSettings, iOS: darwinSettings));
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Recordatorios de comidas, plan, compra e hidratación',
          ),
        );
  }

  /// Pide permiso al sistema operativo. Se llama cuando el usuario activa el
  /// interruptor maestro en Ajustes, nunca antes.
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    await _plugin.cancelAll();
  }

  /// Cancela todo lo programado y vuelve a programar [specs] desde cero —
  /// más simple y menos propenso a IDs huérfanos que diffear contra lo ya
  /// programado, y se llama solo tras guardar en Ajustes (no en cada
  /// rebuild), así que el costo es irrelevante.
  Future<void> scheduleAll(List<ReminderSpec> specs) async {
    if (kIsWeb) return;
    await cancelAll();
    if (specs.isEmpty) return;
    await _ensureTimeZone();
    for (final spec in specs) {
      await _plugin.zonedSchedule(
        spec.id,
        spec.title,
        spec.body,
        _nextInstanceOf(spec.hour, spec.minute, spec.weekday),
        const NotificationDetails(
          android: AndroidNotificationDetails(_channelId, _channelName),
          iOS: DarwinNotificationDetails(),
        ),
        // `inexactAllowWhileIdle` evita pedir el permiso extra de alarma
        // exacta (Android 12+) — un recordatorio de comida no necesita
        // precisión al segundo, unos minutos de margen es aceptable.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: spec.weekday == null ? DateTimeComponents.time : DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> _ensureTimeZone() async {
    if (_timeZoneReady) return;
    tz_data.initializeTimeZones();
    final name = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(name));
    _timeZoneReady = true;
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute, int? weekday) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (weekday == null) {
      if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    } else {
      while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }
    return scheduled;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) => NotificationService());
