import '../constants/app_icons.dart';
import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_elevation.dart';
import '../theme/app_motion.dart';
import '../theme/app_typography.dart';
import 'food_photo.dart';
import 'motion/app_entrance.dart';
import 'motion/app_pressable.dart';

/// 06/10 de las fichas base — última en construirse porque necesitaba un
/// consumidor real con datos de un plan (Épica 6, ver `documentation/home.md`
/// y `documentation/plan.md`). Una fila de comida dentro de un plan diario,
/// con dos estados visuales (Fase 4 · D1):
/// - **Registrada** (`isRegistered: true`): foto atenuada, overline verde,
///   título tachado, sin elevación.
/// - **Pendiente** (`isRegistered: false`): foto sin atenuar, overline gris,
///   título normal; `isElevated` agrega la sombra "próxima comida" (D1) —
///   es solo tratamiento visual, no cambia el estado guardado de la comida
///   (ver `MealStatus` en `lib/features/plan/domain/entities/planned_meal.dart`).
///
/// Todo el texto llega ya compuesto por quien la usa (ver `PlanPage`) — este
/// widget no conoce `AppLocalizations` ni el vocabulario `slotLabelKey` de
/// Onboarding, para poder reusarse igual en D2/D4 más adelante.
class MealCard extends StatelessWidget {
  const MealCard({
    super.key,
    required this.overlineText,
    required this.title,
    required this.detailText,
    required this.isRegistered,
    this.isElevated = false,
    this.imageAsset,
    required this.onTap,
  });

  final String overlineText;
  final String title;
  final String detailText;
  final bool isRegistered;
  final bool isElevated;

  /// Foto ilustrativa del plato (RECIPE-101); `null` → placeholder rayado.
  final String? imageAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // M01 (presión) + M11 (registrar = éxito), catálogo "Motion patterns":
    // sombra, colores y el círculo de estado cruzan en `base`; el check
    // entra con pop-in. El estado final es exactamente el de D1.
    return AppPressable(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.standard,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: isElevated && !isRegistered ? AppElevation.e2 : AppElevation.e0,
            ),
            child: Row(
              children: [
                _Thumbnail(imageAsset: imageAsset, dimmed: isRegistered),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: AppMotion.base,
                        curve: AppMotion.standard,
                        style: AppTypography.label.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isRegistered ? colors.actionPrimary : colors.textSecondary,
                        ),
                        child: Text(overlineText),
                      ),
                      const SizedBox(height: 3),
                      AnimatedDefaultTextStyle(
                        duration: AppMotion.base,
                        curve: AppMotion.standard,
                        style: AppTypography.bodyL.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isRegistered ? colors.textSecondary : colors.textPrimary,
                          decoration: isRegistered ? TextDecoration.lineThrough : null,
                          decorationColor: colors.textDisabled,
                        ),
                        child: Text(title),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detailText,
                        style: AppTypography.bodyM.copyWith(fontSize: 12, color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: AppMotion.base,
                  curve: AppMotion.standard,
                  width: 32,
                  height: 32,
                  // Borde siempre presente (transparente al registrar) para que
                  // la decoración interpole en vez de saltar.
                  decoration: BoxDecoration(
                    color: isRegistered ? colors.actionPrimary : colors.actionPrimary.withValues(alpha: 0),
                    shape: BoxShape.circle,
                    border: Border.all(color: isRegistered ? colors.actionPrimary : colors.border, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: isRegistered
                      ? Icon(AppIcons.check, size: 16, color: colors.onActionPrimary).appPopIn(context, duration: AppMotion.base)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Miniatura de 62×62: la foto del tipo de plato si existe, si no
/// `HatchedPlaceholder` — nunca un ícono genérico (ver `FoodPhoto`).
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.imageAsset, required this.dimmed});

  final String? imageAsset;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 62,
      child: FoodPhoto(imageAsset: imageAsset, borderRadius: BorderRadius.circular(12), dimmed: dimmed),
    );
  }
}
