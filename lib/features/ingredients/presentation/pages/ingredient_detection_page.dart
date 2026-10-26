import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/route_paths.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../providers/ingredient_analysis_providers.dart';
import '../widgets/ingredient_chip.dart';

/// F1 · Ingredientes detectados (Fase 6 · "Tengo ingredientes",
/// `documentation/ingredients.md`). La foto arriba (270 de alto) y debajo la
/// lista EDITABLE de lo que se vio: quitar (✕), confirmar dudosos (borde
/// punteado) y "+ Añadir". "Ver recetas posibles" pasa a F2 solo con los
/// confirmados. La foto ya viene tomada (`imageBytes`, desde la hoja de
/// cámara o Home) y el análisis arranca solo.
class IngredientDetectionPage extends ConsumerStatefulWidget {
  const IngredientDetectionPage({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  ConsumerState<IngredientDetectionPage> createState() => _IngredientDetectionPageState();
}

class _IngredientDetectionPageState extends ConsumerState<IngredientDetectionPage> {
  static const _photoHeight = 270.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _detect());
  }

  void _detect() => ref.read(ingredientDetectionControllerProvider.notifier).detect(widget.imageBytes);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final detectionAsync = ref.watch(ingredientDetectionControllerProvider);
    final hasConfirmed = ref.watch(ingredientListProvider).any((item) => item.confident);
    final showCta = detectionAsync.valueOrNull?.isIngredientPhoto ?? false;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          SizedBox(
            height: _photoHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(widget.imageBytes, fit: BoxFit.cover),
                Positioned(
                  top: MediaQuery.of(context).padding.top + AppSpacing.space12,
                  left: AppSpacing.space16,
                  child: RoundIconButton(icon: AppIcons.back, onTap: () => context.pop()),
                ),
              ],
            ),
          ),
          Expanded(
            child: detectionAsync.when(
              loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.space20), child: AppStateBlock.loading()),
              error: (error, _) {
                debugPrint('detectIngredients failed: $error (cause: ${error is Failure ? error.cause : null})');
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.space20),
                  child: AppStateBlock.error(
                    title: l10n.genericErrorTitle,
                    message: l10n.messageForError(error),
                    onAction: _detect,
                  ),
                );
              },
              data: (detection) {
                if (detection == null) return const SizedBox.shrink();
                if (!detection.isIngredientPhoto) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.space20),
                    child: AppStateBlock.empty(
                      title: l10n.ingredientsNotDetectedTitle,
                      message: l10n.ingredientsNotDetectedMessage,
                      actionLabel: l10n.ingredientsCloseAction,
                      onAction: () => context.pop(),
                    ),
                  );
                }
                return const _EditableIngredientList();
              },
            ),
          ),
          if (showCta)
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.space20,
                14,
                AppSpacing.space20,
                AppSpacing.space20 + MediaQuery.of(context).padding.bottom,
              ),
              child: AppButton(
                label: l10n.ingredientsSeeRecipesCta,
                fullWidth: true,
                onPressed: hasConfirmed ? () => context.push(RoutePaths.ingredientRecipes) : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _EditableIngredientList extends ConsumerWidget {
  const _EditableIngredientList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final items = ref.watch(ingredientListProvider);
    final controller = ref.read(ingredientListProvider.notifier);
    final hasDoubtful = items.any((item) => !item.confident);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.space20, AppSpacing.space20, AppSpacing.space20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.ingredientsFoundTitle(items.length),
            style: AppTypography.display.copyWith(fontSize: 23, color: colors.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.ingredientsFoundSubtitle,
            style: AppTypography.bodyL.copyWith(fontSize: 14, color: colors.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final item in items)
                IngredientChip(
                  name: item.name,
                  confident: item.confident,
                  onRemove: () => controller.remove(item.name),
                  onConfirm: () => controller.confirm(item.name),
                ),
              _AddChip(onTap: () => _showAddSheet(context, ref)),
            ],
          ),
          if (hasDoubtful) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(16)),
              child: Text(
                l10n.ingredientsDoubtfulNote,
                style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.textSecondary),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space20),
        ],
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final textController = TextEditingController();

    void submit(BuildContext sheetContext) {
      ref.read(ingredientListProvider.notifier).add(textController.text);
      Navigator.of(sheetContext).pop();
    }

    // Sin `dispose()` explícito: la hoja todavía lo usa durante su animación
    // de cierre, y un controller sin listeners propios no retiene nada.
    await showAppBottomSheet<void>(
      context,
      title: l10n.ingredientsAddSheetTitle,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: l10n.ingredientsAddSheetTitle,
              controller: textController,
              hintText: l10n.ingredientsAddFieldHint,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => submit(sheetContext),
            ),
            const SizedBox(height: AppSpacing.space16),
            AppButton(label: l10n.ingredientsAddConfirm, fullWidth: true, onPressed: () => submit(sheetContext)),
          ],
        ),
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            context.l10n.ingredientsAddChip,
            style: AppTypography.label.copyWith(fontSize: 14, fontWeight: FontWeight.w600, color: colors.actionPrimary),
          ),
        ),
      ),
    );
  }
}
