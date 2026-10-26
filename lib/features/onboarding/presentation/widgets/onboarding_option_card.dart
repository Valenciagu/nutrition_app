import '../../../../core/constants/app_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_typography.dart';

/// Tarjeta de opción única usada en B1 (con imagen) y B3 (sin imagen).
/// No es una de las 10 fichas base — es una composición de `AppCard`-like
/// styling específica de este flujo (ver `documentation/onboarding.md`).
class OnboardingOptionCard extends StatelessWidget {
  const OnboardingOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.imageAsset,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// B1 muestra una foto por opción (ancla el significado); B3 no (`null`).
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? colors.actionPrimarySurface : null,
            border: Border.all(color: selected ? colors.actionPrimary : colors.border, width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              if (imageAsset != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(imageAsset!, width: 52, height: 52, fit: BoxFit.cover),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyL.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: selected ? colors.onActionPrimarySurface : colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 12),
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(color: colors.actionPrimary, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(AppIcons.check, size: 14, color: colors.onActionPrimary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
