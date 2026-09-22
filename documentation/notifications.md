# Épica 12 — Recordatorios

Estado: **completa** (2026-09-21).

## Diseño

Sin mock propio en el canvas: `Fases 5-12 - Entrega final.dc.html` (leído en la Épica 11) solo muestra la fila "Recordatorios" de J1 (Perfil) con un valor de ejemplo, "4 activos" — ningún bloque "Fase 11/12" del canvas cubre una pantalla de ajustes de notificaciones. Construida con los tokens ya sincronizados, mismo criterio que `GroceryListPage` (Épica 10): sin mock, sin inventar diseño, reusando lo existente (contenedor tipo `_SettingsGroup`, `WheelValueField`/`showIntWheelPicker` de Onboarding para las horas de silencio, `Switch` de Material ya que el sistema de 10 componentes no define un toggle).

## Por qué local, no push/FCM

Instrucciones.md §40 pide recordatorios de comida/plan/compra/progreso e hidratación, respetando preferencia del usuario, timezone, horas de silencio, permisos y opt-in — nada de esto exige que el servidor dispare la notificación en tiempo real. Todos los tipos v1 dependen de un dato que el propio dispositivo ya conoce (el horario de comidas del usuario) o de una cadencia fija (revisar el plan, la compra semanal, hidratación) — programación 100% local vía `flutter_local_notifications` + `timezone`/`flutter_timezone` (nuevas dependencias), sin ninguna Cloud Function nueva, sin FCM, sin necesitar el deploy pendiente del backend para funcionar. Recordatorio de "Progreso" (el quinto tipo que menciona §40) **no se construyó** — Progreso (I1 del mock) no existe todavía (gap ya documentado en la Épica 11), y un recordatorio sin una pantalla real detrás sería la misma clase de feature fabricada que este proyecto evita en todos lados.

## Arquitectura

- `NotificationPreferences` (`features/notifications/domain/entities/`) — interruptor maestro (`enabled`, **por defecto `false`**: Instrucciones.md §40 exige opt-in explícito, así que nunca se activa solo), 4 sub-toggles (comidas/plan/compra/hidratación), horas de silencio (`quietHoursStartMinute`/`quietHoursEndMinute`, minutos desde medianoche — un rango que cruza medianoche como el valor por defecto 22:00-08:00 se interpreta como dos tramos). `activeTypeCount` es la cuenta REAL de tipos activos, usada por la fila "Recordatorios" de Perfil — nunca el "4 activos" fijo del mock.
- `reminder_builder.dart` — función pura `buildReminderSpecs(prefs, mealSlots, l10n) -> List<ReminderSpec>`: traduce preferencias + el horario real de comidas del usuario a la lista concreta a programar, filtrando cualquiera que caiga en horas de silencio vía `isInQuietHours` (también pura, fácil de testear cuando llegue la Épica 16). Sin ningún efecto secundario ni dependencia de Flutter/el plugin — separación deliberada entre "qué programar" (dominio) y "cómo programarlo" (`NotificationService`, infraestructura).
- `NotificationService` (`core/services/notifications/`) — envoltura fina y genérica sobre `flutter_local_notifications` (nada de nutrición aquí, solo `id`/`title`/`body`/`hour`/`minute`/`weekday` vía `ReminderSpec`). `initializePlugin()` se llama una vez en `main.dart`, **sin pedir permiso todavía** (los `request*Permission` del `DarwinInitializationSettings` se dejan en `false` a propósito — pedir permiso al arrancar violaría el opt-in explícito que pide la especificación). `requestPermission()` solo se llama cuando el usuario activa el interruptor maestro (en Ajustes o en el bootstrap de arranque, ver abajo). `scheduleAll` cancela todo y reprograma desde cero (más simple que diffear contra lo ya programado; el costo es irrelevante porque solo se llama tras guardar o al abrir la app, no en cada rebuild).
- Horarios fijos para plan/compra/hidratación (sin dato propio de dónde tomar una hora): plan 20:00 diario, compra domingo 18:00, hidratación 10:00/13:00/16:00 — simplificación de v1 documentada aquí, no oculta; §40 no pide horario configurable por tipo.
- `FirebaseNotificationPreferencesRepository` — mismo patrón que `OnboardingRepository.updateProfile` (Épica 11): escritura directa del cliente a `users/{uid}.notificationPreferences` (merge). Es preferencia propia del usuario, no contenido generado por IA, así que no necesita Cloud Function — la regla amplia `allow read, write: if request.auth.uid == userId` de `firestore.rules` ya lo cubre, sin cambios de reglas.
- `resolveDeviceLocalizations()` (`core/localization/app_localizations_ext.dart`) — resuelve `AppLocalizations` sin `BuildContext` vía el `lookupAppLocalizations(Locale)` que genera `flutter gen-l10n`, necesario porque los recordatorios se arman desde un `Provider`/al arrancar la app, no desde un `build()`. Usa el idioma del dispositivo (lo mismo que ve el usuario hoy — Perfil todavía no permite cambiar idioma dentro de la app).

## Pantalla — `NotificationSettingsPage`

Reemplaza el "coming soon" de la fila "Recordatorios" de Perfil. Interruptor maestro arriba; si está activo, muestra los 4 sub-toggles + las dos horas de silencio (reusando `WheelValueField`/`showIntWheelPicker` de Onboarding, mismo patrón de reuso que ya usa Perfil desde la Épica 11). Guardar: pide permiso al sistema operativo solo si el interruptor maestro quedó activo, guarda las preferencias en Firestore siempre (la intención del usuario es un dato real aunque el permiso se niegue), y reprograma/cancela acorde. Si el permiso fue denegado, el guardado NO se bloquea ni se revierte — se avisa con un snackbar ("actívalos desde los ajustes del sistema") en vez de fingir que quedó todo listo.

## Web

`flutter_local_notifications` no tiene implementación web. `NotificationService` hace no-op en cada método (`kIsWeb`) — las preferencias SÍ se guardan en Firestore igual (dato real, útil cross-plataforma), pero nada suena hasta abrir la app en el móvil. La pantalla muestra un aviso inline en vez de dejar que el usuario crea que activó algo que no puede funcionar ahí.

## Gaps documentados, no ocultos

- **No sobrevive un reinicio del dispositivo sin abrir la app**: `zonedSchedule` en Android necesita un `ScheduledNotificationBootReceiver` + `RECEIVE_BOOT_COMPLETED` para reprogramar tras un reboot — deliberadamente NO agregado en v1 (agregar el receiver sin la lógica de reprogramación que lo acompaña sería peor que no tenerlo). Mitigado, no resuelto: `notificationBootstrapProvider` reprograma cada vez que `MainShell` se monta (cada apertura de la app con sesión activa), así que basta con abrir la app una vez después de un reinicio para que los recordatorios vuelvan.
- **Sin recordatorio de "Progreso"** — depende de una pantalla de Progreso real que no existe (ver arriba).
- **Sin horario configurable por tipo** (plan/compra/hidratación son horas fijas) — solo horas de silencio son configurables, ver arriba.
- **Hidratación es un recordatorio genérico**, no ligado a ningún dato de consumo de agua — no existe esa feature en la app; simplemente son 3 avisos/día fuera de horas de silencio, no "quedan calculados según cuánto has bebido".
- Sí requiere que el usuario abra la app manualmente para ver el efecto de una preferencia (no hay indicador de "notificación programada con éxito" más allá del guardado).

`flutter analyze` y `flutter build web --debug` limpios. Sin cambios en `functions/` — esta épica nunca toca el backend, 9 Cloud Functions siguen siendo el total.
