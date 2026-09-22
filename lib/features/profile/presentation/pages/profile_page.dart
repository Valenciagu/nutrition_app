import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_paths.dart';
import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/localization/generated/app_localizations.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/quick_action_tile.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../notifications/presentation/providers/notification_providers.dart';
import '../../../onboarding/domain/entities/onboarding_answers.dart';
import '../../../onboarding/presentation/onboarding_catalog.dart';
import '../providers/profile_providers.dart';

/// J1 · Perfil (canvas "Fases 5-12 - Entrega final", bloque Fase 9-10).
/// Header (avatar + objetivo/kcal) + tarjeta Premium + dos grupos de filas
/// ("Mi alimentación"/"Ajustes"). Reemplaza `ProfilePlaceholderPage`.
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key, this.onSignOut});

  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;

    if (uid == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space20),
              child: AppStateBlock.empty(
                title: l10n.profileGuestTitle,
                message: l10n.profileGuestMessage,
                actionLabel: l10n.profileGuestCta,
                onAction: () => context.go(RoutePaths.signUp),
              ),
            ),
          ),
        ),
      );
    }

    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: profileAsync.when(
          loading: () => const AppStateBlock.loading(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space20),
              child: AppStateBlock.error(
                title: l10n.genericErrorTitle,
                message: l10n.genericErrorMessage,
                onAction: () => ref.invalidate(userProfileProvider),
              ),
            ),
          ),
          data: (profile) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.space20, AppSpacing.space16, AppSpacing.space20, AppSpacing.space24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(displayName: _displayName(ref, l10n), goal: profile.goal),
                const SizedBox(height: AppSpacing.space16),
                const _PremiumBanner(),
                const SizedBox(height: AppSpacing.space16),
                _SettingsGroup(
                  title: l10n.profileSectionFoodTitle,
                  rows: [
                    QuickActionTile(
                      title: l10n.profileRowGoalDataTitle,
                      iconBackgroundColor: colors.background,
                      onTap: () => context.push(RoutePaths.profileEditGoalPath()),
                    ),
                    QuickActionTile(
                      title: l10n.profileRowPreferencesTitle,
                      iconBackgroundColor: colors.background,
                      onTap: () => context.push(RoutePaths.profileEditPreferencesPath()),
                    ),
                    QuickActionTile(
                      title: l10n.profileRowSavedRecipesTitle,
                      iconBackgroundColor: colors.background,
                      onTap: () => _showComingSoon(context, l10n),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space16),
                _SettingsGroup(
                  title: l10n.profileSectionSettingsTitle,
                  rows: [
                    QuickActionTile(
                      title: l10n.profileRowRemindersTitle,
                      trailingText: _remindersSummary(ref, l10n),
                      iconBackgroundColor: colors.background,
                      onTap: () => context.push(RoutePaths.profileNotificationsPath()),
                    ),
                    QuickActionTile(
                      title: l10n.profileRowThemeTitle,
                      trailingText: l10n.profileThemeAutomaticValue,
                      iconBackgroundColor: colors.background,
                      onTap: () => _showComingSoon(context, l10n),
                    ),
                    QuickActionTile(
                      title: l10n.profileRowLanguageTitle,
                      trailingText: _languageName(context),
                      iconBackgroundColor: colors.background,
                      onTap: () => _showComingSoon(context, l10n),
                    ),
                    QuickActionTile(
                      title: l10n.profileRowPrivacyTitle,
                      iconBackgroundColor: colors.background,
                      onTap: () => context.push(RoutePaths.profilePrivacyPath()),
                    ),
                  ],
                ),
                if (onSignOut != null) ...[
                  const SizedBox(height: AppSpacing.space16),
                  AppButton(label: l10n.signOutButtonLabel, variant: AppButtonVariant.neutral, fullWidth: true, onPressed: onSignOut),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _displayName(WidgetRef ref, AppLocalizations l10n) {
    final user = ref.watch(authStateChangesProvider).valueOrNull;
    if (user?.displayName?.isNotEmpty ?? false) return user!.displayName!;
    return user?.email?.split('@').first ?? l10n.homeGuestName;
  }

  /// `null` mientras carga/falla (la fila simplemente no muestra valor
  /// todavía, igual que el chevron por defecto de `QuickActionTile`) — nunca
  /// el "4 activos" fijo del mock del diseño.
  String? _remindersSummary(WidgetRef ref, AppLocalizations l10n) {
    final count = ref.watch(notificationPreferencesProvider).valueOrNull?.activeTypeCount;
    if (count == null) return null;
    return l10n.profileRowRemindersActiveCount(count);
  }

  String _languageName(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'es' ? 'Español' : 'English';
  }

  void _showComingSoon(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.comingSoonSnackbarMessage)));
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.displayName, required this.goal});

  final String displayName;
  final NutritionGoal? goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final calorieGoalAsync = ref.watch(homeDailyCalorieGoalProvider);

    return Row(
      children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: colors.actionPrimarySurface,
            shape: BoxShape.circle,
            border: Border.all(color: colors.actionPrimary.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text(initial, style: AppTypography.titleM.copyWith(fontSize: 21, color: colors.onActionPrimarySurface)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(displayName, style: AppTypography.titleL.copyWith(fontSize: 21, color: colors.textPrimary)),
              if (goal != null)
                calorieGoalAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, _) => const SizedBox.shrink(),
                  data: (calories) => Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      l10n.profileHeaderSubtitle(goalLabel(l10n, goal!), calories),
                      style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.textSecondary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF101512), Color(0xFF1F3129)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.profilePremiumTitle, style: AppTypography.titleS.copyWith(fontSize: 15.5, color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                  l10n.profilePremiumSubtitle,
                  style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
            decoration: BoxDecoration(color: const Color(0xFF3ED98C), borderRadius: BorderRadius.circular(AppRadius.full)),
            child: Text(l10n.profilePremiumCta, style: AppTypography.label.copyWith(fontSize: 13, color: const Color(0xFF06301D))),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title.toUpperCase(),
              style: AppTypography.label.copyWith(fontSize: 11, letterSpacing: 0.8, color: colors.textSecondary),
            ),
          ),
          for (final row in rows) row,
        ],
      ),
    );
  }
}
