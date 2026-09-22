import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../providers/profile_providers.dart';

/// "Privacidad y datos" — Instrucciones.md §33-34: la app debe comunicar qué
/// datos guarda y dejar eliminar la cuenta. Sin mock propio en el canvas
/// (J1 solo muestra la fila que lleva aquí); construida con los tokens ya
/// sincronizados.
class PrivacyDataPage extends ConsumerWidget {
  const PrivacyDataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final isDeleting = ref.watch(deleteAccountControllerProvider).isLoading;

    ref.listen(deleteAccountControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericErrorMessage)));
      }
      // Al borrar la cuenta con éxito, `signOut()` (dentro del controlador)
      // dispara `authStateChangesProvider` → el `redirect` del router manda
      // a Welcome solo — no hace falta navegar manualmente desde acá.
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.space12, AppSpacing.space8, AppSpacing.space20, AppSpacing.space8),
              child: Row(
                children: [
                  RoundIconButton(icon: Icons.arrow_back, onTap: () => context.pop()),
                  const SizedBox(width: AppSpacing.space12),
                  Text(l10n.profileRowPrivacyTitle, style: AppTypography.titleL.copyWith(fontSize: 20, color: colors.textPrimary)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.profilePrivacyIntro, style: AppTypography.bodyM.copyWith(fontSize: 14, color: colors.textSecondary)),
                    const SizedBox(height: AppSpacing.space24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.space16),
                      decoration: BoxDecoration(
                        color: colors.errorSurface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: colors.error.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.profilePrivacyDeleteAccountTitle,
                            style: AppTypography.titleS.copyWith(fontSize: 15, color: colors.error),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.profilePrivacyDeleteAccountSubtitle,
                            style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: colors.error),
                          ),
                          const SizedBox(height: AppSpacing.space12),
                          AppButton(
                            label: l10n.profilePrivacyDeleteAccountTitle,
                            accentColorOverride: colors.error,
                            isLoading: isDeleting,
                            onPressed: isDeleting
                                ? null
                                : () async {
                                    final confirmed = await showConfirmationDialog(
                                      context,
                                      title: l10n.profilePrivacyDeleteConfirmTitle,
                                      message: l10n.profilePrivacyDeleteConfirmMessage,
                                      confirmLabel: l10n.profilePrivacyDeleteConfirmCta,
                                      cancelLabel: l10n.cancelButtonLabel,
                                      isDestructive: true,
                                    );
                                    if (confirmed && context.mounted) {
                                      await ref.read(deleteAccountControllerProvider.notifier).deleteAccount();
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space24),
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
