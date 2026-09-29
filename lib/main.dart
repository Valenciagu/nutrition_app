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
