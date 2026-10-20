import '../constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// The app's single text field (Fichas de componentes > 02 · TextField).
///
/// The label always sits above the field and is always visible — never use
/// [hintText] as a substitute label. Validation is a blur-time concern: the
/// caller should only pass [errorText] once the field has lost focus (e.g.
/// from a form controller's `onFocusChange`), not on every keystroke.
enum AppTextFieldKind { text, numeric, search, password }

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.kind = AppTextFieldKind.text,
    this.unitLabel,
    this.hintText,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.showPasswordActionLabel,
    this.hidePasswordActionLabel,
  });

  final String label;
  final TextEditingController? controller;
  final AppTextFieldKind kind;

  /// Shown docked at the end of the field for [AppTextFieldKind.numeric]
  /// (e.g. "kg", "cm") — never bake the unit into the value itself.
  final String? unitLabel;
  final String? hintText;

  /// Replaces [helperText] when non-null — the two never stack.
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  /// Etiquetas del toggle de visibilidad para [AppTextFieldKind.password]
  /// (la pantalla de Login muestra texto "Ver"/"Ocultar", no un ícono).
  /// Deben venir de `context.l10n` — nunca un literal en el llamador.
  final String? showPasswordActionLabel;
  final String? hidePasswordActionLabel;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _obscure = true;

  bool get _ownsFocusNode => widget.focusNode == null;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: AppTypography.bodyM.copyWith(
            fontSize: 12.5,
            color: hasError ? colors.error : colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: AppSpacing.fieldHeight,
          decoration: BoxDecoration(
            color: !widget.enabled
                ? colors.background
                : hasError
                    ? colors.errorSurface
                    : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: !widget.enabled
                  ? colors.border.withValues(alpha: 0.6)
                  : hasError
                      ? colors.error
                      : _focusNode.hasFocus
                          ? colors.actionPrimary
                          : colors.border,
              width: hasError
                  ? AppSpacing.borderSelected
                  : _focusNode.hasFocus
                      ? AppSpacing.borderFocus
                      : AppSpacing.borderHairline,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  obscureText: widget.kind == AppTextFieldKind.password && _obscure,
                  keyboardType: widget.kind == AppTextFieldKind.numeric
                      ? const TextInputType.numberWithOptions(decimal: true)
                      : TextInputType.text,
                  inputFormatters: widget.kind == AppTextFieldKind.numeric
                      ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))]
                      : null,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  style: AppTypography.bodyL.copyWith(
                    fontSize: 15,
                    height: 1,
                    fontWeight: widget.kind == AppTextFieldKind.numeric ? FontWeight.w600 : FontWeight.w400,
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: widget.hintText,
                    hintStyle: AppTypography.bodyL.copyWith(fontSize: 15, color: colors.textDisabled),
                  ),
                ),
              ),
              if (widget.kind == AppTextFieldKind.numeric && widget.unitLabel != null)
                Text(
                  widget.unitLabel!,
                  style: AppTypography.label.copyWith(fontSize: 14, color: colors.textSecondary),
                ),
              if (widget.kind == AppTextFieldKind.search)
                Icon(AppIcons.search, size: 20, color: colors.textSecondary),
              if (widget.kind == AppTextFieldKind.password)
                GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Text(
                    (_obscure ? widget.showPasswordActionLabel : widget.hidePasswordActionLabel) ?? '',
                    style: AppTypography.label.copyWith(fontSize: 12.5, color: colors.actionPrimary),
                  ),
                ),
            ],
          ),
        ),
        if (widget.errorText != null || widget.helperText != null) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasError) ...[
                Icon(AppIcons.error, size: 14, color: colors.error),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  widget.errorText ?? widget.helperText!,
                  style: AppTypography.bodyM.copyWith(
                    fontSize: 12.5,
                    color: hasError ? colors.error : colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
