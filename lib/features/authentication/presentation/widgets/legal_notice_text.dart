import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_typography.dart';

/// Texto legal reutilizado en Welcome ("Al continuar aceptas...") y en el
/// checkbox de registro ("Acepto..."). Los enlaces a Términos/Privacidad
/// son un placeholder por ahora — no hay páginas de contenido legal real
/// todavía (pendiente de contenido del usuario, ver documentation/authentication.md).
class LegalNoticeText extends StatelessWidget {
  const LegalNoticeText({
    super.key,
    required this.prefix,
    this.onTapTerms,
    this.onTapPrivacy,
    this.textAlign = TextAlign.center,
  });

  final String prefix;
  final VoidCallback? onTapTerms;
  final VoidCallback? onTapPrivacy;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;
    final baseStyle = AppTypography.bodyM.copyWith(fontSize: 11.5, color: colors.textSecondary);
    final linkStyle = baseStyle.copyWith(color: colors.actionPrimary, fontWeight: FontWeight.w600);

    return Text.rich(
      TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: prefix),
          TextSpan(
            text: l10n.legalTermsLabel,
            style: linkStyle,
            recognizer: onTapTerms == null ? null : (TapGestureRecognizer()..onTap = onTapTerms),
          ),
          TextSpan(text: l10n.legalMiddleAnd),
          TextSpan(
            text: l10n.legalPrivacyPolicyLabel,
            style: linkStyle,
            recognizer: onTapPrivacy == null ? null : (TapGestureRecognizer()..onTap = onTapPrivacy),
          ),
        ],
      ),
      textAlign: textAlign,
    );
  }
}
