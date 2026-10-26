import '../../../../core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../../plan/presentation/providers/plan_providers.dart';
import '../../domain/entities/recipe.dart';
import '../providers/recipe_providers.dart';
import '../widgets/recipe_detail_body.dart';

/// D3 · Detalle de receta (Fase 4). Anidada bajo el tab Plan
/// (`RoutePaths.recipeDetailPath`), no una tab propia. Ver
/// `documentation/design_screens_plan.md` y `documentation/recipes.md`.
///
/// Usa `mealRegistrationControllerProvider` de `features/plan` directo
/// (import cruzado deliberado, presentación-a-presentación) — mismo
/// precedente que `plan_page.dart` importando `onboarding_catalog.dart`: D3
/// opera sobre una comida que sigue siendo del dominio de Plan, no tendría
/// sentido duplicar ese controlador aquí.
///
/// Sin botón de favorito (♡ en el mock): no existe ningún concepto de
/// "favorito" en el backend/dominio hoy — agregar el botón sin persistencia
/// real sería una función que aparenta hacer algo y no hace nada,
/// exactamente lo que este proyecto evita (ver notas de alcance en
/// `documentation/recipes.md`).
class RecipeDetailPage extends ConsumerWidget {
  const RecipeDetailPage({super.key, required this.date, required this.mealId});

  final String date;
  final String mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = context.l10n;
    final recipeAsync = ref.watch(recipeProvider((date: date, mealId: mealId)));

    ref.listen(mealRegistrationControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericErrorMessage)));
      } else if (previous is AsyncLoading && next is AsyncData && context.mounted) {
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: recipeAsync.when(
              loading: () => const AppStateBlock.loading(),
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.space20),
                child: AppStateBlock.error(
                  title: l10n.genericErrorTitle,
                  message: l10n.genericErrorMessage,
                  onAction: () => ref.invalidate(recipeProvider((date: date, mealId: mealId))),
                ),
              ),
              data: (recipe) => _RecipeDetailContent(recipe: recipe, date: date, mealId: mealId),
            ),
          ),
          Positioned(
            top: AppSpacing.space12,
            left: AppSpacing.space12,
            child: RoundIconButton(icon: AppIcons.back, onTap: () => context.pop()),
          ),
        ],
      ),
    );
  }
}

class _RecipeDetailContent extends ConsumerWidget {
  const _RecipeDetailContent({required this.recipe, required this.date, required this.mealId});

  final Recipe recipe;
  final String date;
  final String mealId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRegistering = ref.watch(mealRegistrationControllerProvider).isLoading;

    return Column(
      children: [
        Expanded(child: RecipeDetailBody(recipe: recipe)),
        _RecipeFooter(
          isRegistering: isRegistering,
          onStartCooking: recipe.steps.isEmpty
              ? null
              : () => context.push(RoutePaths.cookingModePath(date, mealId), extra: recipe),
          onRegister: () => ref.read(mealRegistrationControllerProvider.notifier).setRegistered(mealId, registered: true),
        ),
      ],
    );
  }
}

class _RecipeFooter extends StatelessWidget {
  const _RecipeFooter({required this.isRegistering, required this.onStartCooking, required this.onRegister});

  final bool isRegistering;
  final VoidCallback? onStartCooking;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space20,
        AppSpacing.space12,
        AppSpacing.space20,
        AppSpacing.space12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.border))),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: l10n.recipeStartCookingCta,
              onPressed: isRegistering ? null : onStartCooking,
              fullWidth: true,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: AppButton(
              label: l10n.recipeRegisterCta,
              onPressed: isRegistering ? null : onRegister,
              variant: AppButtonVariant.secondary,
              isLoading: isRegistering,
              fullWidth: true,
            ),
          ),
        ],
      ),
    );
  }
}
