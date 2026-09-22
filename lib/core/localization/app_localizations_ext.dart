import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

/// The single access point for user-facing strings across the app.
///
/// Usage: `context.l10n.retryButtonLabel`. Never hardcode user-facing text
/// directly in a widget — add a key to `lib/core/localization/l10n/app_es.arb`
/// (and its `app_en.arb` counterpart) and consume it through here instead.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Resuelve `AppLocalizations` sin un `BuildContext` — necesario para textos
/// de notificaciones locales (Épica 12), que se programan desde un
/// `Provider`/al arrancar la app, no desde un `build()`. Usa el idioma del
/// dispositivo (lo mismo que ve el usuario hoy: Perfil todavía no permite
/// cambiar el idioma dentro de la app, ver `documentation/profile.md`), con
/// `es` como respaldo si el dispositivo tiene un idioma no soportado.
AppLocalizations resolveDeviceLocalizations() {
  final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
  for (final supported in AppLocalizations.supportedLocales) {
    if (supported.languageCode == deviceLocale.languageCode) return lookupAppLocalizations(supported);
  }
  return lookupAppLocalizations(AppLocalizations.supportedLocales.first);
}
