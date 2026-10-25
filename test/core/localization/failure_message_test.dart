import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/core/errors/failure.dart';
import 'package:nutrition_app/core/localization/app_localizations_ext.dart';
import 'package:nutrition_app/core/localization/generated/app_localizations.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('es'));

  test('cada Failure tiene su propio mensaje', () {
    expect(l10n.messageForError(const NetworkFailure()), l10n.failureNetworkMessage);
    expect(l10n.messageForError(const AuthFailure()), l10n.failureAuthMessage);
    expect(l10n.messageForError(const AiQuotaExceededFailure()), l10n.failureQuotaMessage);
    expect(l10n.messageForError(const ServerFailure()), l10n.failureServerMessage);
  });

  test('un error que no es Failure usa el mensaje genérico', () {
    expect(l10n.messageForError(Exception('x')), l10n.genericErrorMessage);
  });
}
