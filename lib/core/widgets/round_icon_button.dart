import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';

/// Botón circular flotante sobre una foto (back/cerrar en D3 y en el
/// análisis de foto, Épicas 7/8) — extraído al segundo consumidor real,
/// mismo criterio que `MacroStatTile`/`mapFirebaseFunctionsException`.
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: colors.surface.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 20, color: colors.textPrimary),
        ),
      ),
    );
  }
}
