import 'package:flutter/material.dart';

import '../localization/app_localizations_ext.dart';
import '../theme/app_color_tokens.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';
import 'app_skeleton.dart';

/// One component, three modes (Fichas de componentes > 10 · StateBlock).
/// Covers every non-happy-path screen state — never build an ad-hoc "no
/// data" text or a bespoke error card elsewhere; extend this instead.
///
/// - [AppStateBlock.empty]: centered, no illustration, always paired with
///   the action that resolves it.
/// - [AppStateBlock.loading]: a real content silhouette, not a spinner
///   (spinners only live inside [AppButton]). Pass [skeleton] with a
///   shape matching the content being loaded; falls back to a generic
///   3-line skeleton if omitted.
/// - [AppStateBlock.error]: cause in plain language + what to do + a
///   retry action. Never a status code or service name.
enum _AppStateBlockMode { empty, loading, error }

class AppStateBlock extends StatelessWidget {
  const AppStateBlock.empty({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  })  : _mode = _AppStateBlockMode.empty,
        skeleton = null;

  const AppStateBlock.error({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  })  : _mode = _AppStateBlockMode.error,
        skeleton = null;

  const AppStateBlock.loading({super.key, this.skeleton})
      : _mode = _AppStateBlockMode.loading,
        title = null,
        message = null,
        actionLabel = null,
        onAction = null;

  final _AppStateBlockMode _mode;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Custom loading silhouette. Only meaningful with `.loading`.
  final Widget? skeleton;

  @override
  Widget build(BuildContext context) {
    return switch (_mode) {
      _AppStateBlockMode.loading => skeleton ?? _defaultSkeleton(),
      _AppStateBlockMode.empty => _buildMessageBlock(context, isError: false),
      _AppStateBlockMode.error => _buildMessageBlock(context, isError: true),
    };
  }

  Widget _defaultSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppSkeletonBar(width: 160),
          SizedBox(height: AppSpacing.space12),
          AppSkeletonBar(width: 260),
          SizedBox(height: AppSpacing.space12),
          AppSkeletonBar(width: 200),
        ],
      ),
    );
  }

  Widget _buildMessageBlock(BuildContext context, {required bool isError}) {
    final colors = context.colors;
    final l10n = context.l10n;
    final resolvedLabel = actionLabel ?? l10n.retryButtonLabel;

    if (isError) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          color: colors.errorSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title!, style: AppTypography.titleS.copyWith(fontSize: 14, color: colors.error)),
            const SizedBox(height: AppSpacing.space8),
            Text(message!, style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.error)),
            if (onAction != null) ...[
              const SizedBox(height: AppSpacing.space4),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  label: resolvedLabel,
                  onPressed: onAction,
                  variant: AppButtonVariant.secondary,
                  size: AppButtonSize.sm,
                  accentColorOverride: colors.error,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              title!,
              textAlign: TextAlign.center,
              style: AppTypography.titleS.copyWith(fontSize: 15, color: colors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.space4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.textSecondary),
              ),
            ),
            if (onAction != null) ...[
              const SizedBox(height: AppSpacing.space12),
              AppButton(label: resolvedLabel, onPressed: onAction, size: AppButtonSize.md),
            ],
          ],
        ),
      ),
    );
  }
}
