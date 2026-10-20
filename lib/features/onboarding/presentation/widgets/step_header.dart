import '../../../../core/constants/app_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_typography.dart';

/// Componente propuesto por el propio diseño ("Notas de sistema" de Fase 2 ·
/// Bloque B): volver + barra de progreso + contador, repetido en los 8
/// pasos. Vive en `features/onboarding/` (no en `core/widgets/`) porque solo
/// este flujo tiene el patrón de wizard por ahora — se promovería a core si
/// otro flujo por pasos lo necesitara (mismo criterio que `AuthBackButton`).
class StepHeader extends StatelessWidget {
  const StepHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  /// 1-indexado para que coincida con el copy ("1/8").
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;
    final progress = currentStep / totalSteps;

    return Semantics(
      label: l10n.onboardingStepAnnouncement(currentStep, totalSteps),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(AppIcons.back),
            color: colors.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation(colors.actionPrimary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.onboardingStepCounter(currentStep, totalSteps),
            style: AppTypography.label.copyWith(fontSize: 12.5, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
