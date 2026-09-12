import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_skeleton.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/progress_ring.dart';
import '../../../../core/widgets/quick_action_tile.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../providers/home_providers.dart';
import '../widgets/camera_action_sheet.dart';

/// C3 · Home, primer día (empty). Es el único estado de Home que se
/// construye por ahora: C1/C2 (anillo poblado, "ahora toca" con la comida
/// real siguiente, sugerencias de la IA) necesitan datos reales de un plan
/// diario (Épica 6, no construida) — mostrarlos con datos inventados sería
/// engañoso. Como hoy nadie tiene todavía seguimiento diario real, esta
/// pantalla es honesta con el estado actual de la app, no una limitación de
/// la Épica 4. Ver `documentation/home.md`.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 19) return l10n.homeGreetingAfternoon;
    return l10n.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final authState = ref.watch(authStateChangesProvider);
    final goalAsync = ref.watch(homeDailyCalorieGoalProvider);

    final user = authState.valueOrNull;
    final displayName = (user?.displayName?.isNotEmpty ?? false)
        ? user!.displayName!
        : (user?.email?.split('@').first ?? l10n.homeGuestName);
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: goalAsync.when(
          loading: () => const _HomeSkeleton(),
          error: (error, _) => Center(
            child: AppStateBlock.error(
              title: l10n.genericErrorTitle,
              message: l10n.genericErrorMessage,
              onAction: () => ref.invalidate(homeDailyCalorieGoalProvider),
            ),
          ),
          data: (dailyGoal) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.space20, AppSpacing.space16, AppSpacing.space20, AppSpacing.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_greeting(l10n), style: AppTypography.bodyM.copyWith(fontSize: 14, color: colors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(displayName, style: AppTypography.titleL.copyWith(fontSize: 24, color: colors.textPrimary)),
                      ],
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.actionPrimarySurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.actionPrimary.withValues(alpha: 0.3)),
                      ),
                      alignment: Alignment.center,
                      child: Text(initial, style: AppTypography.label.copyWith(fontSize: 14, fontWeight: FontWeight.w700, color: colors.actionPrimaryPressed)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(22)),
                  child: Column(
                    children: [
                      ProgressRing(progress: 0, centerValue: '$dailyGoal', centerLabel: l10n.homeCaloriesAheadLabel, dimmed: true),
                      const SizedBox(height: 12),
                      Text(l10n.homeEmptyTitle, style: AppTypography.titleM.copyWith(fontSize: 17, color: colors.textPrimary), textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text(
                        l10n.homeEmptySubtitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodyM.copyWith(fontSize: 13.5, color: colors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      AppButton(label: l10n.homeEmptyCta, onPressed: () => showCameraActionSheet(context)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space20),
                Text(
                  l10n.homeStartHereLabel.toUpperCase(),
                  style: AppTypography.label.copyWith(fontSize: 11.5, letterSpacing: 1, color: colors.textSecondary),
                ),
                const SizedBox(height: 10),
                QuickActionTile(
                  title: l10n.homePlanRowTitle,
                  subtitle: l10n.homePlanRowSubtitle,
                  iconBackgroundColor: colors.actionPrimarySurface,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.comingSoonSnackbarMessage))),
                ),
                const SizedBox(height: 10),
                QuickActionTile(
                  title: l10n.homeGroceryRowTitle,
                  subtitle: l10n.homeGroceryRowSubtitle,
                  iconBackgroundColor: colors.background,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.comingSoonSnackbarMessage))),
                ),
                const SizedBox(height: 10),
                QuickActionTile(
                  title: l10n.homeAiRowTitle,
                  subtitle: l10n.homeAiRowSubtitle,
                  iconBackgroundColor: colors.aiActionSurface,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.comingSoonSnackbarMessage))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// C4 · Home cargando. El esqueleto respeta la silueta real (mismo anillo,
/// misma card) para que nada "salte" al llegar los datos.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20, vertical: AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSkeletonBar(width: 84, height: 14),
          const SizedBox(height: 8),
          const AppSkeletonBar(width: 140, height: 22),
          const SizedBox(height: 20),
          Container(
            height: 190,
            decoration: BoxDecoration(color: Theme.of(context).extension<AppColorTokens>()!.surface, borderRadius: BorderRadius.circular(22)),
          ),
          const SizedBox(height: 20),
          const AppSkeletonBar(width: double.infinity, height: 60),
        ],
      ),
    );
  }
}
