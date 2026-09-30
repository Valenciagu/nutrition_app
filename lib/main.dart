import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/generated/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/services/notifications/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/firebase_setup_required_page.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registra el plugin de notificaciones locales (Épica 12) — no pide
  // permiso todavía, solo lo deja listo para que `notificationServiceProvider`
  // lo use; no-op en web (ver `NotificationService`).
  await NotificationService().initializePlugin();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await _setupCrashlytics();
    await _setupAppCheck();
    runApp(const ProviderScope(child: NutritionApp()));
  } catch (error) {
    // Ya no debería pasar (FOUND-009 resuelto, ver TASKS.md), pero se deja
    // el manejo por si el proyecto de Firebase se desconecta o cambia.
    runApp(FirebaseSetupRequiredPage(error: error));
  }
}

/// Épica 14 (Instrucciones.md §48: "Use appropriate Crashlytics"). Sin
/// implementación web (paquete Android/iOS/macOS únicamente) — no-op ahí,
/// igual que `NotificationService`. Desactivado en modo debug (los crashes
/// del propio desarrollo no deben ensuciar el dashboard del proyecto
/// compartido) — se activa solo en release.
Future<void> _setupCrashlytics() async {
  if (kIsWeb) return;
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Épica 15 (Instrucciones.md §80): activa App Check con el proveedor de
/// **depuración** — a diferencia de Play Integrity/App Attest, no necesita
/// que la app ya esté publicada en Play Console/tenga cuenta de Apple
/// Developer, así que puede cerrarse ahora en vez de esperar a la Épica 17
/// (release). Cada instalación de debug (`flutter run`) imprime un token
/// nuevo en la consola/logcat la primera vez — hay que registrarlo a mano en
/// Firebase Console > App Check > (app) > "Manage debug tokens" para que esa
/// instalación pase la verificación. Los proveedores de producción (Play
/// Integrity/App Attest) quedan para la Épica 17, junto con el cambio de
/// package name (`android/app/build.gradle.kts` sigue en el
/// `com.example.nutrition_app` por defecto de Flutter). Sin implementación
/// web todavía (requiere reCAPTCHA + un flag JS aparte, sin consumidor real
/// hoy — mismo criterio que `NotificationService`/Crashlytics).
Future<void> _setupAppCheck() async {
  if (kIsWeb) return;
  await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.debug, appleProvider: AppleProvider.debug);
}

class NutritionApp extends ConsumerWidget {
  const NutritionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
