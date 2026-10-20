import '../../../../core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../../../core/widgets/selectable_chip.dart';
import '../../../onboarding/domain/entities/onboarding_answers.dart';
import '../../../onboarding/presentation/onboarding_catalog.dart';
import '../providers/profile_providers.dart';

/// Editar "Preferencias y alergias" desde Perfil. Deliberadamente NO incluye
/// el horario de comidas (`mealSlots`) — ese fila del diseño se llama
/// "Preferencias y alergias", no "horarios", y D1/D2 (Plan) ya reflejan el
/// ritmo fijado en Onboarding; editar horarios queda fuera de esta tarea
/// (gap documentado, ver `documentation/profile.md`).
class EditPreferencesPage extends ConsumerStatefulWidget {
  const EditPreferencesPage({super.key});

  @override
  ConsumerState<EditPreferencesPage> createState() => _EditPreferencesPageState();
}

class _EditPreferencesPageState extends ConsumerState<EditPreferencesPage> {
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final profileAsync = ref.watch(userProfileProvider);

    ref.listen(userProfileProvider, (previous, next) {
      final data = next.valueOrNull;
      if (data != null && !_seeded) {
        _seeded = true;
        ref.read(profileEditControllerProvider.notifier).seed(data);
      }
    });

    ref.listen(profileSaveControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericErrorMessage)));
      } else if (previous is AsyncLoading && next is AsyncData && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const AppStateBlock.loading(),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.space20),
            child: AppStateBlock.error(
              title: l10n.genericErrorTitle,
              message: l10n.genericErrorMessage,
              onAction: () => ref.invalidate(userProfileProvider),
            ),
          ),
          data: (_) => const _EditPreferencesForm(),
        ),
      ),
    );
  }
}

class _EditPreferencesForm extends ConsumerWidget {
  const _EditPreferencesForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final answers = ref.watch(profileEditControllerProvider);
    final controller = ref.read(profileEditControllerProvider.notifier);
    final isSaving = ref.watch(profileSaveControllerProvider).isLoading;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space12, AppSpacing.space8, AppSpacing.space20, AppSpacing.space8),
          child: Row(
            children: [
              RoundIconButton(icon: AppIcons.back, onTap: () => context.pop()),
              const SizedBox(width: AppSpacing.space12),
              Text(l10n.profileRowPreferencesTitle, style: AppTypography.titleL.copyWith(fontSize: 20, color: colors.textPrimary)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(l10n.profileEditLikedFoodsSectionTitle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final id in likedFoodCatalogIds)
                      SelectableChip(
                        label: foodLabel(l10n, id),
                        selected: answers.likedFoods.contains(id),
                        onTap: () => controller.toggleLikedFood(id),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space20),
                _SectionLabel(l10n.profileEditAvoidFoodsSectionTitle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final id in allergenCatalogIds)
                      SelectableChip(
                        label: allergenLabel(l10n, id),
                        selected: answers.avoidFoods.contains(id),
                        variant: SelectableChipVariant.negative,
                        onTap: () => controller.toggleAvoidFood(id),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space20),
                _SectionLabel(l10n.profileEditCookingTimeSectionTitle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final value in CookingTimePreference.values)
                      SelectableChip(
                        label: cookingTimeLabel(l10n, value),
                        selected: answers.cookingTimePreference == value,
                        showCheckWhenSelected: false,
                        onTap: () => controller.setCookingTimePreference(value),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space20),
                _SectionLabel(l10n.profileEditBudgetSectionTitle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final value in BudgetLevel.values)
                      SelectableChip(
                        label: budgetLabel(l10n, value),
                        selected: answers.budgetLevel == value,
                        showCheckWhenSelected: false,
                        onTap: () => controller.setBudgetLevel(value),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space24),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.space20,
            AppSpacing.space12,
            AppSpacing.space20,
            AppSpacing.space12 + MediaQuery.of(context).padding.bottom,
          ),
          child: AppButton(
            label: l10n.saveButtonLabel,
            fullWidth: true,
            isLoading: isSaving,
            onPressed: isSaving ? null : () => ref.read(profileSaveControllerProvider.notifier).save(),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text.toUpperCase(),
      style: AppTypography.label.copyWith(fontSize: 11.5, letterSpacing: 1, color: colors.textSecondary),
    );
  }
}
