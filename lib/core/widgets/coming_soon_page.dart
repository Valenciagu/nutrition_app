import 'package:flutter/material.dart';

import '../localization/app_localizations_ext.dart';
import '../theme/app_color_tokens.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Placeholder genérico para tabs cuya feature real todavía no existe (Plan
/// → Épica 6, IA → Épica 5). Reemplaza al viejo `HomePlaceholderPage` de la
/// Épica 1 ahora que Home sí tiene una pantalla real (Épica 4). Borrar el
/// uso de esta página en cada tab cuando su épica correspondiente se
/// construya — no es parte de las 10 fichas base, es un stand-in temporal.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.comingSoonTitle,
                  style: AppTypography.titleM.copyWith(color: colors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space16),
                Text(
                  l10n.comingSoonMessage,
                  style: AppTypography.bodyM.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
