import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_assets.dart';
import '../localization/app_localizations_ext.dart';
import '../services/app_version/app_update_status.dart';
import '../theme/app_color_tokens.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Bloqueo de "actualización obligatoria" (Épica 17): la versión instalada
/// es menor que `min_app_version` de Remote Config. El `redirect` del router
/// no deja salir de aquí mientras eso siga siendo cierto — no hay "más
/// tarde". El canvas no tiene esta pantalla; se arma solo con tokens y
/// componentes existentes, mismo esquema que `AppStateBlock`.
class UpdateRequiredPage extends ConsumerWidget {
  const UpdateRequiredPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final storeUrl = ref.watch(appUpdateStatusProvider).valueOrNull?.storeUrl;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space24),
            child: Column(
              children: [
                const Spacer(),
                SvgPicture.asset(AppAssets.isotypeColor, width: 72, height: 72),
                const SizedBox(height: AppSpacing.space24),
                Text(
                  l10n.updateRequiredTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleL.copyWith(fontSize: 24, color: colors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.space12),
                Text(
                  l10n.updateRequiredMessage,
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textSecondary),
                ),
                const Spacer(),
                if (storeUrl != null)
                  AppButton(
                    label: l10n.updateRequiredAction,
                    fullWidth: true,
                    onPressed: () => launchUrl(Uri.parse(storeUrl), mode: LaunchMode.externalApplication),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
