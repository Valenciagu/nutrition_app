import 'package:flutter/material.dart';

import '../localization/app_localizations_ext.dart';
import '../theme/app_color_tokens.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Placeholder de la tab Perfil (Épica 11, no construida todavía). Aloja el
/// botón de cerrar sesión mientras tanto — antes vivía en
/// `HomePlaceholderPage`, movido aquí porque semánticamente es una acción
/// de cuenta, no de Home. [onSignOut] llega desde `main_shell.dart` (la
/// composición no importa `features/` aquí — mismo criterio documentado en
/// `documentation/authentication.md`).
class ProfilePlaceholderPage extends StatelessWidget {
  const ProfilePlaceholderPage({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.profileTitle, style: AppTypography.titleL.copyWith(color: colors.textPrimary)),
              const SizedBox(height: AppSpacing.space16),
              Text(l10n.comingSoonMessage, style: AppTypography.bodyM.copyWith(color: colors.textSecondary)),
              const Spacer(),
              if (onSignOut != null)
                AppButton(label: l10n.signOutButtonLabel, variant: AppButtonVariant.neutral, fullWidth: true, onPressed: onSignOut),
            ],
          ),
        ),
      ),
    );
  }
}
