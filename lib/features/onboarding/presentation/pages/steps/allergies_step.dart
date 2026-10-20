import '../../../../../core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/localization/app_localizations_ext.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/selectable_chip.dart';
import '../../onboarding_catalog.dart';
import '../../providers/onboarding_providers.dart';

/// B5 · Alergias e intolerancias. Único sitio donde el rojo aparece por
/// selección (exclusión, no error) — usa `SelectableChipVariant.negative`.
/// "No tengo ninguna" limpia la selección y avanza, evitando respuestas
/// falsas por inercia.
class AllergiesStep extends ConsumerWidget {
  const AllergiesStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final answers = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingAllergiesTitle,
            style: AppTypography.display.copyWith(fontSize: 29, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingAllergiesSubtitle,
            style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textSecondary),
          ),
          const SizedBox(height: 18),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(999)),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Icon(AppIcons.search, size: 16, color: colors.textDisabled),
                const SizedBox(width: 10),
                Text(
                  l10n.onboardingAllergiesSearchHint,
                  style: AppTypography.bodyM.copyWith(fontSize: 14.5, color: colors.textDisabled),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final allergenId in allergenCatalogIds)
                SelectableChip(
                  label: allergenLabel(l10n, allergenId),
                  selected: answers.avoidFoods.contains(allergenId),
                  variant: SelectableChipVariant.negative,
                  onTap: () => controller.toggleAvoidFood(allergenId),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: colors.errorSurface, borderRadius: BorderRadius.circular(16)),
            child: Text(
              l10n.onboardingAllergiesBanner,
              style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.error),
            ),
          ),
          const SizedBox(height: 20),
          AppButton(label: l10n.continueButtonLabel, fullWidth: true, onPressed: onNext),
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: () {
                controller.clearAvoidFoods();
                onNext();
              },
              child: Text(
                l10n.onboardingAllergiesNoneAction,
                style: AppTypography.label.copyWith(fontSize: 13.5, color: colors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
