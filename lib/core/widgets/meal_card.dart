import '../constants/app_icons.dart';
import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_elevation.dart';
import '../theme/app_typography.dart';
import 'hatched_placeholder.dart';

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
    required this.onTap,
  });

  final String overlineText;
  final String title;
  final String detailText;
  final bool isRegistered;
  final bool isElevated;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isElevated && !isRegistered ? AppElevation.e2 : AppElevation.e0,
          ),
          child: Row(
            children: [
              _HatchedThumbnail(dimmed: isRegistered),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      overlineText,
                      style: AppTypography.label.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isRegistered ? colors.actionPrimary : colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: AppTypography.bodyL.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isRegistered ? colors.textSecondary : colors.textPrimary,
                        decoration: isRegistered ? TextDecoration.lineThrough : null,
                        decorationColor: colors.textDisabled,
                      ),
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
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isRegistered ? colors.actionPrimary : null,
                  shape: BoxShape.circle,
                  border: isRegistered ? null : Border.all(color: colors.border, width: 1.5),
                ),
                alignment: Alignment.center,
                child: isRegistered ? Icon(AppIcons.check, size: 16, color: colors.onActionPrimary) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Comidas sin foto real todavía (Épica 7 apenas genera recetas, sin fotos)
/// muestran `HatchedPlaceholder` — nunca un ícono genérico. Tamaño fijo de
/// miniatura (62×62); D3/D5 usan el mismo widget compartido a tamaño de
/// foto completa.
class _HatchedThumbnail extends StatelessWidget {
  const _HatchedThumbnail({required this.dimmed});

  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 62,
      child: HatchedPlaceholder(borderRadius: BorderRadius.circular(12), dimmed: dimmed),
    );
  }
}
