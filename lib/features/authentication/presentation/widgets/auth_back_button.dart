import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';

/// Botón circular de volver usado en Login, registro y recuperar
/// contraseña (A3-A5) — no es uno de los componentes base, pero se repite
/// idéntico en varias pantallas de esta feature.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.commonBackAction,
      child: GestureDetector(
        onTap: () => Navigator.of(context).maybePop(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          child: Icon(Icons.arrow_back, size: 18, color: colors.textSecondary),
        ),
      ),
    );
  }
}
