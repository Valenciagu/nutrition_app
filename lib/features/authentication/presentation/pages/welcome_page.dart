import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_providers.dart';
import '../widgets/legal_notice_text.dart';

/// A2 · Welcome. "Empezar" lleva al Onboarding conversacional (Épica 3),
/// activando [guestModeProvider] para que el router lo deje entrar sin
/// sesión; "Ya tengo cuenta" lleva a Login.
class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Foto de comida a sangre en la mitad superior — placeholder
            // rayado hasta tener el banco de fotografía real (design_system.md).
            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,
                color: colors.background,
              ),
            ),
            Expanded(
              flex: 6,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space20,
                  AppSpacing.space24,
                  AppSpacing.space20,
                  AppSpacing.space20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.authWelcomeHeadline,
                      style: AppTypography.display.copyWith(fontSize: 30, color: colors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    Text(
                      l10n.authWelcomeSubtitle,
                      style: AppTypography.bodyL.copyWith(fontSize: 15.5, color: colors.textSecondary),
                    ),
                    const Spacer(),
                    AppButton(
                      label: l10n.authWelcomeStartButton,
                      fullWidth: true,
                      onPressed: () {
                        ref.read(guestModeProvider.notifier).state = true;
                        context.go(RoutePaths.onboarding);
                      },
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    AppButton(
                      label: l10n.authWelcomeHaveAccountButton,
                      variant: AppButtonVariant.neutral,
                      fullWidth: true,
                      onPressed: () => context.push(RoutePaths.login),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    LegalNoticeText(prefix: l10n.legalAcceptPrefix),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
