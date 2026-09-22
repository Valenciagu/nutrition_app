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
import '../../../onboarding/presentation/widgets/wheel_value_field.dart';
import '../providers/profile_providers.dart';

/// Editar "Objetivo y datos" desde Perfil — reusa las piezas de Onboarding
/// (`SelectableChip`, `WheelValueField`) pero con su propio estado
/// (`profileEditControllerProvider`), no el `onboardingControllerProvider`
/// del registro: mezclar ambos ciclos de vida (uno con guardado local
/// automático, este sin él) habría sido un acoplamiento frágil — ver
/// `documentation/profile.md`.
///
/// Sin réplica pixel-perfect de B1/B2/B3 (tarjetas grandes, auto-avance,
/// una pregunta por pantalla): esas fueron decisiones para una conversación
/// de bienvenida de primera vez, no para una pantalla de ajustes densa —
/// diferenciarlas es la elección honesta, no un atajo.
class EditGoalBiometricsPage extends ConsumerStatefulWidget {
  const EditGoalBiometricsPage({super.key});

  @override
  ConsumerState<EditGoalBiometricsPage> createState() => _EditGoalBiometricsPageState();
}

class _EditGoalBiometricsPageState extends ConsumerState<EditGoalBiometricsPage> {
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
          data: (_) => const _EditGoalBiometricsForm(),
        ),
      ),
    );
  }
}

class _EditGoalBiometricsForm extends ConsumerWidget {
  const _EditGoalBiometricsForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final answers = ref.watch(profileEditControllerProvider);
    final controller = ref.read(profileEditControllerProvider.notifier);
    final isSaving = ref.watch(profileSaveControllerProvider).isLoading;
    final isMetric = answers.unitSystem == UnitSystem.metric;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space12, AppSpacing.space8, AppSpacing.space20, AppSpacing.space8),
          child: Row(
            children: [
              RoundIconButton(icon: Icons.arrow_back, onTap: () => context.pop()),
              const SizedBox(width: AppSpacing.space12),
              Text(l10n.profileRowGoalDataTitle, style: AppTypography.titleL.copyWith(fontSize: 20, color: colors.textPrimary)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionLabel(l10n.profileEditGoalSectionTitle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final goal in NutritionGoal.values)
                      SelectableChip(
                        label: goalLabel(l10n, goal),
                        selected: answers.goal == goal,
                        onTap: () => controller.setGoal(goal),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space20),
                _SectionLabel(l10n.profileEditPersonalSectionTitle),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (final sex in Sex.values) ...[
                      Expanded(
                        child: SelectableChip(
                          label: switch (sex) {
                            Sex.male => l10n.onboardingSexMale,
                            Sex.female => l10n.onboardingSexFemale,
                            Sex.other => l10n.onboardingSexOther,
                          },
                          selected: answers.sex == sex,
                          showCheckWhenSelected: false,
                          onTap: () => controller.setPersonalData(sex: sex),
                        ),
                      ),
                      if (sex != Sex.values.last) const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                WheelValueField(
                  label: l10n.onboardingAgeLabel,
                  value: '${answers.age ?? 29}',
                  unit: l10n.onboardingAgeUnit,
                  highlighted: false,
                  onTap: () async {
                    final result = await showIntWheelPicker(context, min: 13, max: 90, step: 1, initialValue: answers.age ?? 29);
                    if (result != null) controller.setPersonalData(age: result);
                  },
                ),
                const SizedBox(height: 12),
                WheelValueField(
                  label: l10n.onboardingHeightLabel,
                  value: isMetric
                      ? (answers.heightCm ?? 170).round().toString()
                      : ((answers.heightCm ?? 170) / 2.54).round().toString(),
                  unit: isMetric ? l10n.onboardingHeightUnitMetric : l10n.onboardingHeightUnitImperial,
                  highlighted: false,
                  onTap: () async {
                    final result = await showIntWheelPicker(
                      context,
                      min: 120,
                      max: 220,
                      step: 1,
                      initialValue: (answers.heightCm ?? 170).round(),
                    );
                    if (result != null) controller.setPersonalData(heightCm: result.toDouble());
                  },
                ),
                const SizedBox(height: 12),
                WheelValueField(
                  label: l10n.onboardingWeightLabel,
                  value: isMetric
                      ? (answers.weightKg ?? 70).toStringAsFixed(1)
                      : ((answers.weightKg ?? 70) * 2.20462).toStringAsFixed(1),
                  unit: isMetric ? l10n.onboardingWeightUnitMetric : l10n.onboardingWeightUnitImperial,
                  highlighted: true,
                  onTap: () async {
                    final result = await showDoubleWheelPicker(
                      context,
                      min: 35,
                      max: 200,
                      step: 0.5,
                      initialValue: answers.weightKg ?? 70,
                    );
                    if (result != null) controller.setPersonalData(weightKg: result);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(l10n.onboardingUnitsLabel, style: AppTypography.label.copyWith(fontSize: 13.5, color: colors.textSecondary)),
                    const Spacer(),
                    SelectableChip(
                      label: l10n.onboardingUnitsMetric,
                      selected: isMetric,
                      showCheckWhenSelected: false,
                      onTap: () => controller.setPersonalData(unitSystem: UnitSystem.metric),
                    ),
                    const SizedBox(width: 8),
                    SelectableChip(
                      label: l10n.onboardingUnitsImperial,
                      selected: !isMetric,
                      showCheckWhenSelected: false,
                      onTap: () => controller.setPersonalData(unitSystem: UnitSystem.imperial),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space20),
                _SectionLabel(l10n.profileEditActivitySectionTitle),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: [
                    for (final level in ActivityLevel.values)
                      SelectableChip(
                        label: activityLevelLabel(l10n, level),
                        selected: answers.activityLevel == level,
                        showCheckWhenSelected: false,
                        onTap: () => controller.setActivityLevel(level),
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
