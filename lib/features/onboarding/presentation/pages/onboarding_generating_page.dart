import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../providers/plan_generation_providers.dart';

/// B8 · Generando tu plan (Fase 2 · Bloque B). Única pantalla de todo el
/// onboarding sin el header de progreso/volver — el diseño la trata como un
/// estado de espera de ancho completo, no como un paso más del stepper (por
/// eso vive en su propia ruta, no como un índice más de `OnboardingPage`).
///
/// El checklist de 4 pasos y el avance del anillo son una coreografía fija
/// por tiempo, no un progreso real reportado por el backend — `generateDailyPlan`
/// es una sola llamada atómica, sin pasos intermedios que reportar. Es la
/// misma categoría de decisión que B3 (estimación de calorías "en vivo"):
/// comunica "esto está vivo" durante una espera corta y real, nunca afirma
/// un dato verificable que no exista — por eso el anillo nunca llega a 100%
/// hasta que la llamada real termina. Documentado explícitamente, no un
/// progreso fabricado y escondido.
class OnboardingGeneratingPage extends ConsumerStatefulWidget {
  const OnboardingGeneratingPage({super.key});

  @override
  ConsumerState<OnboardingGeneratingPage> createState() => _OnboardingGeneratingPageState();
}

class _OnboardingGeneratingPageState extends ConsumerState<OnboardingGeneratingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _choreography = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5600),
  )..repeat();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() => ref.read(planGenerationControllerProvider.notifier).generate();

  @override
  void dispose() {
    _choreography.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    ref.listen(planGenerationControllerProvider, (previous, next) {
      final plan = next.value;
      if (next.hasValue && plan != null) {
        context.go(RoutePaths.onboardingPlanReady, extra: plan);
      }
    });

    final state = ref.watch(planGenerationControllerProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space20,
            AppSpacing.space24,
            AppSpacing.space20,
            AppSpacing.space20,
          ),
          child: state.hasError
              ? _ErrorState(onRetry: _generate)
              : AnimatedBuilder(
                  animation: _choreography,
                  builder: (context, _) {
                    // Tope en 90%: nunca comunica "listo" antes de que la
                    // llamada real termine (ver doc de la clase).
                    final progress = (_choreography.value * 1.15).clamp(0, 0.9).toDouble();
                    final activeStep = (_choreography.value * 4).floor().clamp(0, 3);
                    return Column(
                      children: [
                        const Spacer(),
                        ProgressRing(
                          progress: progress,
                          centerValue: '${(progress * 100).round()}%',
                          centerLabel: '',
                          size: 118,
                          strokeWidth: 10,
                          color: colors.macroFat,
                        ),
                        const SizedBox(height: AppSpacing.space20),
                        Text(
                          l10n.onboardingGeneratingTitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.display.copyWith(fontSize: 25, color: colors.textPrimary),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.onboardingGeneratingSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyL.copyWith(fontSize: 14.5, color: colors.textSecondary),
                        ),
                        const SizedBox(height: 26),
                        _ChecklistRow(label: l10n.onboardingGeneratingStep1, state: _rowState(0, activeStep)),
                        const SizedBox(height: 12),
                        _ChecklistRow(label: l10n.onboardingGeneratingStep2, state: _rowState(1, activeStep)),
                        const SizedBox(height: 12),
                        _ChecklistRow(label: l10n.onboardingGeneratingStep3, state: _rowState(2, activeStep)),
                        const SizedBox(height: 12),
                        _ChecklistRow(label: l10n.onboardingGeneratingStep4, state: _rowState(3, activeStep)),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(border: Border.all(color: colors.border), borderRadius: BorderRadius.circular(16)),
                          child: Column(
                            children: [
                              FractionallySizedBox(widthFactor: 0.52, child: AppSkeletonBar(height: 11)),
                              const SizedBox(height: 10),
                              FractionallySizedBox(widthFactor: 0.84, child: AppSkeletonBar(height: 11)),
                              const SizedBox(height: 10),
                              FractionallySizedBox(widthFactor: 0.66, child: AppSkeletonBar(height: 11)),
                            ],
                          ),
                        ),
                        const Spacer(),
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }

  _RowState _rowState(int index, int activeStep) {
    if (index < activeStep) return _RowState.done;
    if (index == activeStep) return _RowState.active;
    return _RowState.pending;
  }
}

enum _RowState { done, active, pending }

class _ChecklistRow extends StatelessWidget {
  const _ChecklistRow({required this.label, required this.state});

  final String label;
  final _RowState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: switch (state) {
            _RowState.done => DecoratedBox(
                decoration: BoxDecoration(color: colors.actionPrimary, shape: BoxShape.circle),
                child: Icon(Icons.check, size: 13, color: colors.onActionPrimary),
              ),
            _RowState.active => CircularProgressIndicator(strokeWidth: 2, color: colors.macroFat),
            _RowState.pending => DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: colors.border, width: 2)),
              ),
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyM.copyWith(
              fontSize: 14.5,
              fontWeight: state == _RowState.active ? FontWeight.w600 : FontWeight.w500,
              color: state == _RowState.pending ? colors.textDisabled : colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Icon(Icons.error_outline, size: 48, color: colors.error),
        const SizedBox(height: 16),
        Text(
          l10n.onboardingGeneratingErrorMessage,
          textAlign: TextAlign.center,
          style: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textSecondary),
        ),
        const Spacer(),
        AppButton(label: l10n.onboardingGeneratingRetryButton, fullWidth: true, onPressed: onRetry),
      ],
    );
  }
}
