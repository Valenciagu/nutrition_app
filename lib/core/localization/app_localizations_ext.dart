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
