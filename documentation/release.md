# Épica 17 — Preparación de release (parcial)

Lo que ya existe para publicar, construido el 2026-10-19 sin necesitar las consolas de pago (Play Console / Apple Developer).

## Versión mínima obligatoria

Bloquea la app entera cuando la versión instalada es menor que un mínimo controlado desde el servidor, para que clientes viejos no sigan usando `functions/` tras un cambio incompatible.

- `lib/core/services/app_version/app_update_status.dart` — `appUpdateStatusProvider`: lee la versión instalada (`package_info_plus`) y `min_app_version` de **Firebase Remote Config** (no un documento de Firestore: el cliente no puede manipularlo y trae caché/valores por defecto).
- `lib/core/utils/version_compare.dart` — `compareVersions`, comparación numérica (`1.10.0` > `1.9.0`), ignora `+build`/`-beta`.
- `lib/core/widgets/update_required_page.dart` — pantalla de bloqueo, sin "más tarde" (`PopScope(canPop: false)`), botón a la tienda si hay URL configurada.
- `lib/core/router/app_router.dart` — la regla va **primero** en `redirect`; el router se refresca cuando el provider resuelve.

**Falla abierto**: sin red o si Remote Config falla, se usan los últimos valores activados o los por defecto (`0.0.0`): nunca se bloquea a alguien por no poder consultar. En web no aplica.

**Para activarlo** (Firebase Console → Remote Config), crear 3 parámetros de tipo texto:

| Parámetro | Ejemplo | Para qué |
|---|---|---|
| `min_app_version` | `0.2.0` | Versiones menores a esta quedan bloqueadas |
| `update_store_url_android` | `https://play.google.com/store/apps/details?id=…` | Botón "Actualizar ahora" en Android |
| `update_store_url_ios` | `https://apps.apple.com/app/id…` | Ídem en iOS |

Sin publicarlos, nada cambia. `minimumFetchInterval` es 1 h: un cambio tarda hasta una hora en llegar a una app ya abierta.

## R8 / ofuscación (Android)

- El plugin de Gradle de Flutter **ya activa** R8 y la reducción de recursos en release, e incluye `android/app/proguard-rules.pro` automáticamente si existe. No hace falta tocar `build.gradle.kts`.
- `android/app/proguard-rules.pro` — reglas de Gson para `flutter_local_notifications` (su v18 no trae reglas propias; sin ellas los recordatorios programados fallan solo en release).
- `android/app/src/main/res/raw/keep.xml` — conserva `ic_stat_notification`, que solo se referencia por nombre desde Dart.
- Ofuscación del código Dart: es una bandera de build, no de Gradle:
  `flutter build apk --release --obfuscate --split-debug-info=build/debug-info`
  Guardar la carpeta `debug-info/` de cada versión publicada: sin ella, los stack traces de Crashlytics quedan ilegibles.
- Bug encontrado al verificar: `flutter_native_splash` estaba en `dev_dependencies` y rompía **todo** build de release (su plugin nativo queda en `GeneratedPluginRegistrant`). Movido a `dependencies`.

## Pendiente de la épica

Nombre de paquete real (sigue `com.example.nutrition_app`), firma de release propia (hoy firma con la clave de debug), App Check con proveedores reales, fichas de tienda — todo atado a las consolas de pago.

## Qué testear

`compareVersions` ya tiene tests. Falta un test del `redirect` con el estado de actualización (necesita mockear Remote Config) y probar en un release real que los recordatorios se programan sin crash.
