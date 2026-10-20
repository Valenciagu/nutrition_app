import '../../../../core/constants/app_icons.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import 'legal_notice_text.dart';

/// Checkbox de aceptación de Términos/Privacidad del registro (A4). No es
/// parte de las 10 fichas base — es un compuesto específico de este
/// formulario; si otro formulario necesita algo similar, se evalúa
/// extraerlo a `core/widgets` en ese momento (regla de reuso).
class LegalAcceptanceCheckbox extends StatelessWidget {
  const LegalAcceptanceCheckbox({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: value ? colors.actionPrimary : Colors.transparent,
              border: Border.all(
                color: value ? colors.actionPrimary : colors.border,
                width: AppSpacing.borderSelected,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xs + 3),
            ),
            child: value ? Icon(AppIcons.check, size: 14, color: colors.onActionPrimary) : null,
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: LegalNoticeText(
              prefix: context.l10n.legalCheckboxPrefix,
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}
