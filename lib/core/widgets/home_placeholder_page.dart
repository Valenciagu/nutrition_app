import 'package:flutter/material.dart';

import '../localization/app_localizations_ext.dart';
import '../theme/app_color_tokens.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Temporary landing screen shown until the real Home feature (Epic 4,
/// `features/home`) exists. Replace `RoutePaths.root`'s builder in
/// `app_router.dart` once that feature lands — this file can then be
/// deleted.
///
/// [onSignOut] se recibe desde `app_router.dart` (no se importa el
/// provider de auth aquí directamente: `core/` nunca depende de
/// `features/`, ver skill `nutrition-app-architecture`).
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.homePlaceholderTitle,
                  style: AppTypography.titleM.copyWith(color: colors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.space16),
                Text(
                  l10n.homePlaceholderMessage,
                  style: AppTypography.bodyM.copyWith(color: colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                if (onSignOut != null) ...[
                  const SizedBox(height: AppSpacing.space24),
                  AppButton(
                    label: l10n.signOutButtonLabel,
                    variant: AppButtonVariant.text,
                    size: AppButtonSize.sm,
                    onPressed: onSignOut,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
