import '../../../../core/constants/app_icons.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_state_block.dart';
import '../../../../core/widgets/round_icon_button.dart';
import '../../../onboarding/presentation/widgets/wheel_value_field.dart';
import '../providers/notification_providers.dart';

/// Ajustes de recordatorios (Épica 12, Instrucciones.md §40). Sin mock en el
/// canvas de diseño (J1 solo muestra la fila "Recordatorios" de Perfil con
/// un valor de ejemplo, "4 activos", nunca fabricado aquí — ver
/// `activeTypeCount`); construida con los tokens ya sincronizados, mismo
/// criterio que `GroceryListPage` (Épica 10).
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends ConsumerState<NotificationSettingsPage> {
  bool _seeded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final prefsAsync = ref.watch(notificationPreferencesProvider);

    ref.listen(notificationPreferencesProvider, (previous, next) {
      final data = next.valueOrNull;
      if (data != null && !_seeded) {
        _seeded = true;
        ref.read(notificationSettingsEditControllerProvider.notifier).seed(data);
      }
    });

    ref.listen(notificationSettingsSaveControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericErrorMessage)));
      } else if (previous is AsyncLoading && next is AsyncData && context.mounted) {
        if (next.value == false) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.notificationPermissionDeniedMessage)));
        }
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: prefsAsync.when(
          loading: () => const AppStateBlock.loading(),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.space20),
            child: AppStateBlock.error(
              title: l10n.genericErrorTitle,
              message: l10n.genericErrorMessage,
              onAction: () => ref.invalidate(notificationPreferencesProvider),
            ),
          ),
          data: (_) => const _NotificationSettingsForm(),
        ),
      ),
    );
  }
}

class _NotificationSettingsForm extends ConsumerWidget {
  const _NotificationSettingsForm();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.colors;
    final prefs = ref.watch(notificationSettingsEditControllerProvider);
    final controller = ref.read(notificationSettingsEditControllerProvider.notifier);
    final isSaving = ref.watch(notificationSettingsSaveControllerProvider).isLoading;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space12, AppSpacing.space8, AppSpacing.space20, AppSpacing.space8),
          child: Row(
            children: [
              RoundIconButton(icon: AppIcons.back, onTap: () => context.pop()),
              const SizedBox(width: AppSpacing.space12),
              Text(l10n.profileRowRemindersTitle, style: AppTypography.titleL.copyWith(fontSize: 20, color: colors.textPrimary)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kIsWeb) ...[
                  _InfoBanner(text: l10n.notificationWebUnsupportedNotice),
                  const SizedBox(height: AppSpacing.space16),
                ],
                _Group(
                  children: [
                    _ToggleRow(
                      title: l10n.notificationMasterToggleTitle,
                      subtitle: l10n.notificationMasterToggleSubtitle,
                      value: prefs.enabled,
                      onChanged: controller.setEnabled,
                    ),
                  ],
                ),
                if (prefs.enabled) ...[
                  const SizedBox(height: AppSpacing.space16),
                  _Group(
                    children: [
                      _ToggleRow(
                        title: l10n.notificationMealTypeTitle,
                        value: prefs.mealRemindersEnabled,
                        onChanged: controller.setMealRemindersEnabled,
                      ),
                      _ToggleRow(
                        title: l10n.notificationPlanTypeTitle,
                        value: prefs.planReminderEnabled,
                        onChanged: controller.setPlanReminderEnabled,
                      ),
                      _ToggleRow(
                        title: l10n.notificationShoppingTypeTitle,
                        value: prefs.shoppingReminderEnabled,
                        onChanged: controller.setShoppingReminderEnabled,
                      ),
                      _ToggleRow(
                        title: l10n.notificationHydrationTypeTitle,
                        value: prefs.hydrationRemindersEnabled,
                        onChanged: controller.setHydrationRemindersEnabled,
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space20),
                  Text(
                    l10n.notificationQuietHoursSectionTitle.toUpperCase(),
                    style: AppTypography.label.copyWith(fontSize: 11.5, letterSpacing: 1, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.notificationQuietHoursSectionSubtitle,
                    style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _QuietHourField(
                          label: l10n.notificationQuietHoursStartLabel,
                          minuteOfDay: prefs.quietHoursStartMinute,
                          onPick: (v) => controller.setQuietHours(startMinute: v, endMinute: prefs.quietHoursEndMinute),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuietHourField(
                          label: l10n.notificationQuietHoursEndLabel,
                          minuteOfDay: prefs.quietHoursEndMinute,
                          onPick: (v) => controller.setQuietHours(startMinute: prefs.quietHoursStartMinute, endMinute: v),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.space24),
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
          child: AppButton(
            label: l10n.saveButtonLabel,
            fullWidth: true,
            isLoading: isSaving,
            onPressed: isSaving ? null : () => ref.read(notificationSettingsSaveControllerProvider.notifier).save(),
          ),
        ),
      ],
    );
  }
}

class _QuietHourField extends StatelessWidget {
  const _QuietHourField({required this.label, required this.minuteOfDay, required this.onPick});

  final String label;
  final int minuteOfDay;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final time = '${(minuteOfDay ~/ 60).toString().padLeft(2, '0')}:${(minuteOfDay % 60).toString().padLeft(2, '0')}';
    return WheelValueField(
      label: label,
      value: time,
      unit: '',
      highlighted: false,
      onTap: () async {
        final picked = await showIntWheelPicker(
          context,
          min: 0,
          max: 23 * 60 + 45,
          step: 15,
          initialValue: (minuteOfDay ~/ 15) * 15,
          labelBuilder: (v) => '${(v ~/ 60).toString().padLeft(2, '0')}:${(v % 60).toString().padLeft(2, '0')}',
        );
        if (picked != null) onPick(picked);
      },
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(AppRadius.xl)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({required this.title, this.subtitle, required this.value, required this.onChanged, this.isLast = false});

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: isLast ? null : BoxDecoration(border: Border(bottom: BorderSide(color: colors.border))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyM.copyWith(fontSize: 14.5, color: colors.textPrimary)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      subtitle!,
                      style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: colors.textSecondary),
                    ),
                  ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: colors.actionPrimary),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.infoSurface, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Text(text, style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.textPrimary)),
    );
  }
}
