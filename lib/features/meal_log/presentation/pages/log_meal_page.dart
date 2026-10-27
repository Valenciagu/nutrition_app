import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../providers/extra_meal_providers.dart';

/// "Registrar sin foto" (LOG-105) — una comida fuera del plan escrita a
/// mano, que suma al día de hoy (LOG-101). El canvas no tiene un mock de
/// este formulario (Fase 5 solo nombra la salida "Escribir qué comí" en E3)
/// — se arma con `AppTextField`/`AppButton`, mismo criterio que
/// `GroceryListPage`. Solo las kcal son obligatorias: pedirle a alguien
/// los gramos de grasa de lo que comió en la calle sería un muro.
class LogMealPage extends ConsumerStatefulWidget {
  const LogMealPage({super.key});

  @override
  ConsumerState<LogMealPage> createState() => _LogMealPageState();
}

class _LogMealPageState extends ConsumerState<LogMealPage> {
  final _name = TextEditingController();
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();

  /// Los errores se muestran tras el primer intento de guardar, no mientras
  /// el usuario todavía escribe (regla de `AppTextField`).
  bool _submitted = false;

  @override
  void dispose() {
    for (final controller in [_name, _calories, _protein, _carbs, _fat]) {
      controller.dispose();
    }
    super.dispose();
  }

  String get _trimmedName => _name.text.trim();
  int? get _caloriesValue => int.tryParse(_calories.text.trim());
  bool get _nameValid => _trimmedName.length >= 2 && _trimmedName.length <= 80;
  bool get _caloriesValid => (_caloriesValue ?? 0) > 0 && _caloriesValue! <= 5000;

  int? _optional(TextEditingController controller) => int.tryParse(controller.text.trim());

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_nameValid || !_caloriesValid) return;

    final logged = await ref.read(extraMealControllerProvider.notifier).logManual(
          date: DateTime.now(),
          name: _trimmedName,
          calories: _caloriesValue!,
          proteinGrams: _optional(_protein),
          carbsGrams: _optional(_carbs),
          fatGrams: _optional(_fat),
        );
    if (!mounted) return;
    final l10n = context.l10n;
    if (logged) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.logMealSuccess)));
      context.pop();
    } else {
      final error = ref.read(extraMealControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error == null ? l10n.genericErrorMessage : l10n.messageForError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final isSaving = ref.watch(extraMealControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.space12, AppSpacing.space8, AppSpacing.space20, AppSpacing.space8),
              child: Row(
                children: [
                  RoundIconButton(icon: AppIcons.back, onTap: () => context.pop()),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: Text(
                      l10n.cameraSheetLogManualTitle,
                      style: AppTypography.titleL.copyWith(fontSize: 20, color: colors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.space20, AppSpacing.space8, AppSpacing.space20, AppSpacing.space24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.logMealIntro, style: AppTypography.bodyM.copyWith(fontSize: 14, color: colors.textSecondary)),
                    const SizedBox(height: AppSpacing.space20),
                    AppTextField(
                      label: l10n.logMealNameLabel,
                      hintText: l10n.logMealNameHint,
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      errorText: _submitted && !_nameValid ? l10n.logMealNameError : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    AppTextField(
                      label: l10n.logMealCaloriesLabel,
                      kind: AppTextFieldKind.numeric,
                      unitLabel: l10n.recipeMacroKcalLabel,
                      controller: _calories,
                      textInputAction: TextInputAction.next,
                      helperText: l10n.logMealCaloriesHelper,
                      errorText: _submitted && !_caloriesValid ? l10n.logMealCaloriesError : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    AppTextField(
                      label: l10n.logMealProteinLabel,
                      kind: AppTextFieldKind.numeric,
                      unitLabel: l10n.logMealGramsUnit,
                      controller: _protein,
                      textInputAction: TextInputAction.next,
                      helperText: l10n.logMealOptionalHelper,
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: l10n.logMealCarbsLabel,
                            kind: AppTextFieldKind.numeric,
                            unitLabel: l10n.logMealGramsUnit,
                            controller: _carbs,
                            textInputAction: TextInputAction.next,
                            helperText: l10n.logMealOptionalHelper,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        Expanded(
                          child: AppTextField(
                            label: l10n.logMealFatLabel,
                            kind: AppTextFieldKind.numeric,
                            unitLabel: l10n.logMealGramsUnit,
                            controller: _fat,
                            textInputAction: TextInputAction.done,
                            helperText: l10n.logMealOptionalHelper,
                            onSubmitted: (_) => _submit(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.space20, AppSpacing.space8, AppSpacing.space20, AppSpacing.space16),
              child: AppButton(
                label: l10n.logMealSubmit,
                fullWidth: true,
                isLoading: isSaving,
                onPressed: isSaving ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
