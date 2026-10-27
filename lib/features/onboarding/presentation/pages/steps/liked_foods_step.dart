import '../../../../../core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/localization/app_localizations_ext.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/theme/app_motion.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/motion/app_entrance.dart';
import '../../../../../core/widgets/motion/app_pressable.dart';
import '../../onboarding_catalog.dart';
import '../../providers/onboarding_providers.dart';

const _minLikedFoods = 5;

/// B4 · Alimentos que te gustan, multiselección (mínimo 5). Grid de 3
/// columnas con scroll y CTA anclado abajo — el contador reemplaza a
/// cualquier mensaje de error, tal como especifica el diseño.
class LikedFoodsStep extends ConsumerWidget {
  const LikedFoodsStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final answers = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);
    final selectedCount = answers.likedFoods.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.onboardingLikedFoodsTitle,
                style: AppTypography.display.copyWith(fontSize: 29, color: colors.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingLikedFoodsSubtitle,
                style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textSecondary),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
            child: GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.82,
              children: [
                for (final foodId in likedFoodCatalogIds)
                  _FoodTile(
                    label: foodLabel(l10n, foodId),
                    imageAsset: foodImageAsset(foodId),
                    selected: answers.likedFoods.contains(foodId),
                    onTap: () => controller.toggleLikedFood(foodId),
                  ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space20, 14, AppSpacing.space20, 0),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.border))),
          child: Column(
            children: [
              Text(
                l10n.onboardingLikedFoodsCounter(selectedCount, _minLikedFoods),
                style: AppTypography.label.copyWith(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 10),
              AppButton(
                label: l10n.continueButtonLabel,
                fullWidth: true,
                onPressed: selectedCount >= _minLikedFoods ? onNext : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.label, required this.imageAsset, required this.selected, required this.onTap});

  final String label;

  /// `null` mientras ese alimento no tenga foto (ver `foodImageAsset`).
  final String? imageAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // M01 (presión) + M02 (selección), catálogo "Motion patterns".
    return GestureDetector(
      onTap: onTap,
      child: AppPressable(
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          decoration: BoxDecoration(
            color: selected ? colors.actionPrimarySurface : colors.actionPrimarySurface.withValues(alpha: 0),
            border: Border.all(color: selected ? colors.actionPrimary : colors.border, width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                        child: imageAsset != null
                            ? Image.asset(imageAsset!, fit: BoxFit.cover)
                            : ColoredBox(color: colors.border),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(color: colors.actionPrimary, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Icon(AppIcons.check, size: 12, color: colors.onActionPrimary),
                        ).appPopIn(context),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: AnimatedDefaultTextStyle(
                  duration: AppMotion.fast,
                  curve: AppMotion.standard,
                  textAlign: TextAlign.center,
                  style: AppTypography.label.copyWith(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? colors.onActionPrimarySurface : colors.textPrimary,
                  ),
                  child: Text(label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
