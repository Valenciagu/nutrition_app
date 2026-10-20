import '../../../../core/constants/app_icons.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../providers/food_analysis_providers.dart';
import '../widgets/food_analysis_result_card.dart';

/// Pantalla de análisis de foto (Épica 8). Ruta de nivel superior (no
/// anidada bajo ningún tab): el botón de cámara vive en `MainShell`, fuera
/// de las 4 pilas de navegación de las tabs — a diferencia de D3/D5 (Épica
/// 7), que sí pertenecen al tab Plan.
///
/// La foto ya viene tomada/elegida (`imageBytes`, capturados por
/// `camera_action_sheet.dart` antes de navegar aquí) — esta pantalla solo
/// sube y analiza, dispara la subida automáticamente al construirse.
class FoodAnalysisPage extends ConsumerStatefulWidget {
  const FoodAnalysisPage({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  ConsumerState<FoodAnalysisPage> createState() => _FoodAnalysisPageState();
}

class _FoodAnalysisPageState extends ConsumerState<FoodAnalysisPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(foodAnalysisControllerProvider.notifier)
          .analyze(widget.imageBytes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final resultAsync = ref.watch(foodAnalysisControllerProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 300,
                    width: double.infinity,
                    child: Image.memory(widget.imageBytes, fit: BoxFit.cover),
                  ),
                  Transform.translate(
                    // Mismo patrón que D3 (`RecipeDetailPage`) — sheet montada
                    // sobre la foto vía `Transform.translate`, nunca un
                    // `margin` negativo (BUG-H01).
                    offset: const Offset(0, -AppRadius.sheet),
                    child: Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight:
                            MediaQuery.of(context).size.height -
                            300 +
                            AppRadius.sheet,
                      ),
                      decoration: BoxDecoration(
                        color: colors.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(AppRadius.sheet),
                          topRight: Radius.circular(AppRadius.sheet),
                        ),
                      ),
                      child: resultAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpacing.space24),
                          child: AppStateBlock.loading(),
                        ),
                        error: (error, stack) {
                          debugPrint(
                            'analyzeFoodPhoto failed: $error (cause: ${error is Failure ? error.cause : null})',
                          );
                          return Padding(
                            padding: const EdgeInsets.all(AppSpacing.space20),
                            child: AppStateBlock.error(
                              title: l10n.genericErrorTitle,
                              message: l10n.messageForError(error),
                              onAction: () => ref
                                  .read(foodAnalysisControllerProvider.notifier)
                                  .analyze(widget.imageBytes),
                            ),
                          );
                        },
                        data: (result) => result == null
                            ? const SizedBox.shrink()
                            : FoodAnalysisResultCard(result: result),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: AppSpacing.space12,
            left: AppSpacing.space12,
            child: RoundIconButton(
              icon: AppIcons.close,
              onTap: () => context.pop(),
            ),
          ),
        ],
      ),
    );
  }
}
