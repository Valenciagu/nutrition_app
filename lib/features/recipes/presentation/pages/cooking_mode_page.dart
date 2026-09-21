import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/hatched_placeholder.dart';
import '../../../plan/presentation/providers/plan_providers.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/recipe_step.dart';

/// D5 · Modo cocina — paso a paso (Fase 4, aprobado por el usuario
/// 2026-09-20, ver `documentation/design_screens_plan.md`). Recibe la
/// [Recipe] ya cargada por D3 vía `extra` de GoRouter en vez de volver a
/// pedirla — evita depender de que el provider de D3 siga vivo/cacheado al
/// navegar (es `.autoDispose`).
///
/// Al terminar el último paso, registra la comida directamente (mismo
/// controlador que "Registrar" en D3) y vuelve al plan — nota del diseño:
/// "lleva a registrar la comida directamente".
class CookingModePage extends ConsumerStatefulWidget {
  const CookingModePage({super.key, required this.recipe, required this.date, required this.mealId});

  final Recipe recipe;
  final String date;
  final String mealId;

  @override
  ConsumerState<CookingModePage> createState() => _CookingModePageState();
}

class _CookingModePageState extends ConsumerState<CookingModePage> {
  int _stepIndex = 0;
  Timer? _ticker;
  int _remainingSeconds = 0;
  bool _timerRunning = false;

  RecipeStep get _currentStep => widget.recipe.steps[_stepIndex];
  bool get _isLastStep => _stepIndex == widget.recipe.steps.length - 1;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = _currentStep.timerSeconds ?? 0;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _goToStep(int index) {
    _ticker?.cancel();
    setState(() {
      _stepIndex = index;
      _timerRunning = false;
      _remainingSeconds = _currentStep.timerSeconds ?? 0;
    });
  }

  void _startTimer() {
    if (_timerRunning || _currentStep.timerSeconds == null) return;
    setState(() => _timerRunning = true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _timerRunning = false;
        });
      } else {
        setState(() => _remainingSeconds -= 1);
      }
    });
  }

  Future<void> _handleNext() async {
    if (!_isLastStep) {
      _goToStep(_stepIndex + 1);
      return;
    }
    await ref.read(mealRegistrationControllerProvider.notifier).setRegistered(widget.mealId, registered: true);
    if (mounted) context.go(RoutePaths.plan);
  }

  String _formattedTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final totalSteps = widget.recipe.steps.length;
    final isRegistering = ref.watch(mealRegistrationControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space16,
                AppSpacing.space12,
                AppSpacing.space16,
                AppSpacing.space8,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(Icons.close, size: 22, color: colors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: (_stepIndex + 1) / totalSteps,
                        minHeight: 6,
                        backgroundColor: colors.border,
                        color: colors.actionPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Text(
                    l10n.cookingStepCounter(_stepIndex + 1, totalSteps),
                    style: AppTypography.label.copyWith(fontSize: 13, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space20,
                  AppSpacing.space16,
                  AppSpacing.space20,
                  AppSpacing.space16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: const SizedBox(height: 220, width: double.infinity, child: HatchedPlaceholder()),
                    ),
                    const SizedBox(height: AppSpacing.space20),
                    Text(
                      l10n.cookingStepLabel(_stepIndex + 1),
                      style: AppTypography.label.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.actionPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      _currentStep.instruction,
                      style: AppTypography.titleM.copyWith(fontSize: 26, color: colors.textPrimary),
                    ),
                    if (_currentStep.timerSeconds != null) ...[
                      const SizedBox(height: AppSpacing.space24),
                      _TimerWidget(
                        remainingSeconds: _remainingSeconds,
                        isRunning: _timerRunning,
                        formattedTime: _formattedTime(_remainingSeconds),
                        onStart: _startTimer,
                        startLabel: l10n.cookingTimerStart,
                      ),
                    ],
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
              child: Row(
                children: [
                  AppButton(
                    label: l10n.cookingPreviousAction,
                    onPressed: _stepIndex == 0 ? null : () => _goToStep(_stepIndex - 1),
                    variant: AppButtonVariant.secondary,
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: AppButton(
                      label: _isLastStep ? l10n.cookingFinishAction : l10n.cookingNextAction,
                      onPressed: isRegistering ? null : _handleNext,
                      isLoading: isRegistering,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerWidget extends StatelessWidget {
  const _TimerWidget({
    required this.remainingSeconds,
    required this.isRunning,
    required this.formattedTime,
    required this.onStart,
    required this.startLabel,
  });

  final int remainingSeconds;
  final bool isRunning;
  final String formattedTime;
  final VoidCallback onStart;
  final String startLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            formattedTime,
            style: AppTypography.numericM.copyWith(fontSize: 34, color: colors.textPrimary),
          ),
          AppButton(
            label: startLabel,
            onPressed: isRunning || remainingSeconds == 0 ? null : onStart,
            size: AppButtonSize.sm,
          ),
        ],
      ),
    );
  }
}
