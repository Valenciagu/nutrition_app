import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The app's single button component (Fichas de componentes > 01 · Button).
///
/// One component, four hierarchies (+ the specialized `aiAction`). A screen
/// never shows two [primary] buttons — if two actions sit at the same
/// level, one must be [secondary] or [neutral]. Never disable on tap: use
/// [isLoading] instead, which keeps the label and never shrinks the button.
enum AppButtonVariant {
  primary,
  secondary,
  neutral,

  /// The lighter indigo pill used to mark an AI-originated action.
  aiAction,

  /// Solid indigo — the main action of an `AISuggestionCard` only (Fase 3 ·
  /// C2, "Recalcular mi día"): on that pale indigo card, [aiAction]'s fill
  /// would disappear. Not a general-purpose primary.
  aiPrimary,
  text,
}

enum AppButtonSize { lg, md, sm }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.lg,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = false,
    this.accentColorOverride,
  });

  final String label;

  /// Null means disabled — never use a separate `enabled` flag.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool isLoading;

  /// Full width is the default in forms/onboarding per the design system,
  /// but this component defaults to `false` so it also works inline
  /// (app bars, cards) — pass `true` explicitly on form screens.
  final bool fullWidth;

  /// Escape hatch for [AppButtonVariant.secondary]/[AppButtonVariant.text]
  /// to borrow this component's anatomy for a non-brand accent (e.g. the
  /// error-colored "Reintentar" action in `AppStateBlock`) without adding a
  /// one-off sixth variant — the fiche is explicit that this is a closed,
  /// four-hierarchy system.
  final Color? accentColorOverride;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _isEnabled => widget.onPressed != null && !widget.isLoading;

  double get _height => switch (widget.size) {
        AppButtonSize.lg => AppSpacing.buttonHeightLg,
        AppButtonSize.md => AppSpacing.buttonHeightMd,
        AppButtonSize.sm => AppSpacing.buttonHeightSm,
      };

  double get _horizontalPadding => switch (widget.size) {
        AppButtonSize.lg => 26,
        AppButtonSize.md => 20,
        AppButtonSize.sm => 16,
      };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = _resolveStyle(colors);

    final content = Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(style.foreground),
            ),
          ),
          const SizedBox(width: 10),
        ] else if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, size: 20, color: style.foreground),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(
              fontSize: widget.size == AppButtonSize.lg ? 15 : 14,
              color: style.foreground,
            ),
          ),
        ),
        if (!widget.isLoading && widget.trailingIcon != null) ...[
          const SizedBox(width: 10),
          Icon(widget.trailingIcon, size: 20, color: style.foreground),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: _isEnabled,
      label: widget.isLoading ? null : widget.label,
      child: GestureDetector(
        onTapDown: _isEnabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: _isEnabled ? () => setState(() => _pressed = false) : null,
        onTapUp: _isEnabled ? (_) => setState(() => _pressed = false) : null,
        onTap: _isEnabled ? widget.onPressed : null,
        child: AnimatedScale(
          // M01 — sin escala con "reducir movimiento"; el cambio de color
          // de `_resolveStyle` sigue dando el feedback.
          scale: _pressed && !AppMotion.reduced(context) ? AppMotion.pressScale : 1,
          duration: AppMotion.instant,
          curve: AppMotion.standard,
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.standard,
            height: _height,
            width: widget.fullWidth ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: style.border,
            ),
            alignment: Alignment.center,
            child: content,
          ),
        ),
      ),
    );
  }

  _ButtonStyle _resolveStyle(AppColorTokens colors) {
    if (!_isEnabled && !widget.isLoading) {
      return _ButtonStyle(background: colors.border, foreground: colors.textDisabled);
    }

    final accent = widget.accentColorOverride;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _ButtonStyle(
          background: _pressed ? colors.actionPrimaryPressed : colors.actionPrimary,
          foreground: colors.onActionPrimary,
        );
      case AppButtonVariant.secondary:
        final accentColor = accent ?? colors.actionPrimary;
        return _ButtonStyle(
          background: _pressed ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
          foreground: accentColor,
          border: Border.all(color: accentColor, width: AppSpacing.borderSelected),
        );
      case AppButtonVariant.neutral:
        return _ButtonStyle(
          background: _pressed ? colors.background : colors.surface,
          foreground: colors.textPrimary,
          border: Border.all(color: colors.border, width: AppSpacing.borderHairline),
        );
      case AppButtonVariant.aiAction:
        return _ButtonStyle(background: colors.aiActionSurface, foreground: colors.onAiAction);
      case AppButtonVariant.aiPrimary:
        return _ButtonStyle(
          background: _pressed ? colors.aiAccent.withValues(alpha: 0.85) : colors.aiAccent,
          foreground: colors.onAiAccent,
        );
      case AppButtonVariant.text:
        final accentColor = accent ?? colors.actionPrimary;
        return _ButtonStyle(background: Colors.transparent, foreground: accentColor);
    }
  }
}

class _ButtonStyle {
  const _ButtonStyle({required this.background, required this.foreground, this.border});

  final Color background;
  final Color foreground;
  final Border? border;
}
