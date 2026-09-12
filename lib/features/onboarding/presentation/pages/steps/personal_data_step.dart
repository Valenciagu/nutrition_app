import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/localization/app_localizations_ext.dart';
import '../../../../../core/theme/app_color_tokens.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../domain/entities/onboarding_answers.dart';
import '../../providers/onboarding_providers.dart';
import '../../widgets/wheel_value_field.dart';

/// B2 · Datos personales. Único paso con "teclado" — en realidad son
/// selectores de rueda (`WheelValueField`), no el teclado numérico, tal
/// como especifica el diseño.
class PersonalDataStep extends ConsumerWidget {
  const PersonalDataStep({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final answers = ref.watch(onboardingControllerProvider);
    final controller = ref.read(onboardingControllerProvider.notifier);

    final isMetric = answers.unitSystem == UnitSystem.metric;
    final age = answers.age ?? 29;
    final heightCm = answers.heightCm ?? 170;
    final weightKg = answers.weightKg ?? 70;

    final isValid = answers.sex != null && answers.age != null && answers.heightCm != null && answers.weightKg != null;

    String heightDisplay() => isMetric ? heightCm.round().toString() : (heightCm / 2.54).round().toString();
    String weightDisplay() => isMetric ? weightKg.toStringAsFixed(1) : (weightKg * 2.20462).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingPersonalTitle,
            style: AppTypography.display.copyWith(fontSize: 29, color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingPersonalSubtitle,
            style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final sex in Sex.values) ...[
                Expanded(
                  child: _SexOption(
                    label: switch (sex) {
                      Sex.male => l10n.onboardingSexMale,
                      Sex.female => l10n.onboardingSexFemale,
                      Sex.other => l10n.onboardingSexOther,
                    },
                    selected: answers.sex == sex,
                    onTap: () => controller.setPersonalData(sex: sex),
                  ),
                ),
                if (sex != Sex.values.last) const SizedBox(width: 10),
              ],
            ],
          ),
          const SizedBox(height: 14),
          WheelValueField(
            label: l10n.onboardingAgeLabel,
            value: '$age',
            unit: l10n.onboardingAgeUnit,
            highlighted: false,
            onTap: () async {
              final result = await showIntWheelPicker(context, min: 13, max: 90, step: 1, initialValue: age);
              if (result != null) controller.setPersonalData(age: result);
            },
          ),
          const SizedBox(height: 14),
          WheelValueField(
            label: l10n.onboardingHeightLabel,
            value: heightDisplay(),
            unit: isMetric ? l10n.onboardingHeightUnitMetric : l10n.onboardingHeightUnitImperial,
            highlighted: false,
            onTap: () async {
              final result = await showIntWheelPicker(context, min: 120, max: 220, step: 1, initialValue: heightCm.round());
              if (result != null) controller.setPersonalData(heightCm: result.toDouble());
            },
          ),
          const SizedBox(height: 14),
          WheelValueField(
            label: l10n.onboardingWeightLabel,
            value: weightDisplay(),
            unit: isMetric ? l10n.onboardingWeightUnitMetric : l10n.onboardingWeightUnitImperial,
            highlighted: true,
            onTap: () async {
              final result = await showDoubleWheelPicker(context, min: 35, max: 200, step: 0.5, initialValue: weightKg);
              if (result != null) controller.setPersonalData(weightKg: result);
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(14)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.onboardingUnitsLabel, style: AppTypography.label.copyWith(fontSize: 13.5, color: colors.textSecondary)),
                _UnitsToggle(
                  isMetric: isMetric,
                  metricLabel: l10n.onboardingUnitsMetric,
                  imperialLabel: l10n.onboardingUnitsImperial,
                  onChanged: (metric) =>
                      controller.setPersonalData(unitSystem: metric ? UnitSystem.metric : UnitSystem.imperial),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton(label: l10n.continueButtonLabel, fullWidth: true, onPressed: isValid ? onNext : null),
        ],
      ),
    );
  }
}

class _SexOption extends StatelessWidget {
  const _SexOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.actionPrimarySurface : null,
          border: Border.all(color: selected ? colors.actionPrimary : colors.border, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            fontSize: 14.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? colors.actionPrimaryPressed : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _UnitsToggle extends StatelessWidget {
  const _UnitsToggle({
    required this.isMetric,
    required this.metricLabel,
    required this.imperialLabel,
    required this.onChanged,
  });

  final bool isMetric;
  final String metricLabel;
  final String imperialLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: colors.border, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(context, metricLabel, isMetric, () => onChanged(true)),
          _segment(context, imperialLabel, !isMetric, () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, String label, bool active, VoidCallback onTap) {
    final colors = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: active ? colors.surface : null, borderRadius: BorderRadius.circular(999)),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            fontSize: 12.5,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? colors.textPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
