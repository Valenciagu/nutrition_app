import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

/// A1 · Splash. Puramente visual: la decisión de a dónde navegar (Home si
/// hay sesión, Welcome si no) la toma el `redirect` del router en cuanto
/// `authStateChangesProvider` resuelve — esta pantalla nunca navega sola.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: colors.actionPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space32, vertical: AppSpacing.space64),
          // `SizedBox(width: infinity)` fuerza que la Column ocupe todo el
          // ancho disponible — sin esto, Column se encoge al ancho de su
          // hijo más ancho y `crossAxisAlignment.center` no tiene espacio
          // real donde centrar (bug visto en pantalla: contenido pegado a
          // la izquierda).
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  alignment: Alignment.center,
                  // TODO(design-sync): reemplazar por el isotipo real
                  // cuando exista (pendiente set de iconos/wordmark, ver
                  // design_system.md).
                  child: Text(
                    'N',
                    style: AppTypography.titleL.copyWith(fontSize: 30, color: Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.space16),
                Text(
                  l10n.appTitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.titleL.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  l10n.authSplashTagline,
                  textAlign: TextAlign.center,
                  style: AppTypography.label.copyWith(fontSize: 14.5, color: Colors.white.withValues(alpha: 0.82)),
                ),
                const Spacer(),
                Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.85)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
