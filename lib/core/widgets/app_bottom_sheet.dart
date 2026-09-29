import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Standard heights for [showAppBottomSheet] (Fichas de componentes > 08 ·
/// BottomSheet). Never full screen — some of the screen behind must always
/// stay visible so context isn't lost.
enum AppBottomSheetHeight { auto, half, full }

/// Shows the app's single bottom sheet chrome: scrim, `sheet` radius, a
/// centered drag handle, an optional [title], and safe-area-aware bottom
/// padding. Use this for the approved use cases only — the camera capture
/// action, replacing a meal, substituting an ingredient, a contextual
/// paywall, adjusting a quantity. Multi-step flows belong on a pushed
/// screen; destructive confirmations belong in a centered dialog.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  String? title,
  AppBottomSheetHeight height = AppBottomSheetHeight.auto,
}) {
  final colors = context.colors;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: height != AppBottomSheetHeight.auto,
    backgroundColor: colors.surfaceElevated,
    barrierColor: const Color(0x6B101512),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
    ),
    builder: (context) {
      final mediaQuery = MediaQuery.of(context);
      // `SingleChildScrollView`, no `Padding`: con `isScrollControlled:
      // false` (altura `.auto`) el modal no da más alto del que cabe en
      // pantalla, y la reserva de `mediaQuery.padding.bottom` de más abajo
      // varía por dispositivo (barra de navegación de 3 botones vs. gestos)
      // — un contenido que cabía justo en un dispositivo podía desbordar
      // por unos pocos píxeles en otro con más barra de sistema (bug real
      // reportado 2026-09-29, hoja de "Analizar mi comida"). Scroll en vez
      // de overflow es correcto en cualquier dispositivo, sin necesitar
      // ajustar cada hoja individualmente.
      final content = SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.space20,
          right: AppSpacing.space20,
          bottom: mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom + AppSpacing.space20,
          top: AppSpacing.space12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: AppSpacing.space16),
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            if (title != null) ...[
              Text(title, style: AppTypography.titleM.copyWith(fontSize: 19, color: colors.textPrimary)),
              const SizedBox(height: AppSpacing.space16),
            ],
            Builder(builder: builder),
          ],
        ),
      );

      return switch (height) {
        AppBottomSheetHeight.auto => content,
        AppBottomSheetHeight.half => FractionallySizedBox(heightFactor: 0.6, child: content),
        AppBottomSheetHeight.full => FractionallySizedBox(heightFactor: 0.92, child: content),
      };
    },
  );
}
