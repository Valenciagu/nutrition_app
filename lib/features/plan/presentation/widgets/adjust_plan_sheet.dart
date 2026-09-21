import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/plan_providers.dart';

/// PLAN-004 (Instrucciones.md §9) — "no tengo pollo" / "ya comí una
/// hamburguesa" en texto libre. No es parte del diseño de Fase 4 (esa fase
/// no mock-ea esta interacción); es la superficie mínima honesta para
/// exponer una capacidad de backend real (`adjustDailyPlan`) sin inventar
/// una UI de chat completa — ver `documentation/plan.md`.
Future<void> showAdjustPlanSheet(BuildContext context) {
  return showAppBottomSheet<void>(
    context,
    title: context.l10n.planAdjustTitle,
    builder: (sheetContext) => const _AdjustPlanSheetContent(),
  );
}

class _AdjustPlanSheetContent extends ConsumerStatefulWidget {
  const _AdjustPlanSheetContent();

  @override
  ConsumerState<_AdjustPlanSheetContent> createState() => _AdjustPlanSheetContentState();
}

class _AdjustPlanSheetContentState extends ConsumerState<_AdjustPlanSheetContent> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final adjustState = ref.watch(adjustPlanControllerProvider);

    ref.listen(adjustPlanControllerProvider, (previous, next) {
      if (next.hasValue && !next.isLoading && previous?.isLoading == true) {
        Navigator.of(context).pop();
      }
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.planAdjustSubtitle, style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.textSecondary)),
        const SizedBox(height: AppSpacing.space16),
        AppTextField(controller: _controller, label: l10n.planAdjustHint),
        if (adjustState.hasError) ...[
          const SizedBox(height: AppSpacing.space8),
          Text(l10n.genericErrorMessage, style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: colors.error)),
        ],
        const SizedBox(height: AppSpacing.space16),
        AppButton(
          label: l10n.planAdjustCta,
          fullWidth: true,
          isLoading: adjustState.isLoading,
          onPressed: adjustState.isLoading
              ? null
              : () {
                  final message = _controller.text.trim();
                  if (message.isEmpty) return;
                  ref.read(adjustPlanControllerProvider.notifier).adjustForSelectedDate(message);
                },
        ),
      ],
    );
  }
}
