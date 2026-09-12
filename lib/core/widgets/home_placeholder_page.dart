import 'package:flutter/material.dart';

import '../localization/app_localizations_ext.dart';
import '../theme/app_color_tokens.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Temporary landing screen shown until the real Home feature (Epic 4,
/// `features/home`) exists. Replace `RoutePaths.root`'s builder in
/// `app_router.dart` once that feature lands — this file can then be
/// deleted.
class HomePlaceholderPage extends StatelessWidget {
  const HomePlaceholderPage({super.key});

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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
