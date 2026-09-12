import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/localization/generated/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

// NOTE(FOUND-009): Firebase.initializeApp() intentionally isn't wired up
// yet — it needs `flutterfire configure` run against a real Firebase
// project first (see TASKS.md > FOUND-009, PROJECT_CONTEXT.md > Known
// blockers). Add it here, before runApp(), once that's done.
void main() {
  runApp(const ProviderScope(child: NutritionApp()));
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
