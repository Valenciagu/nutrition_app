import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';

/// Indicador de fuerza de contraseña de la pantalla de registro (A4): 3
/// segmentos + un mensaje de apoyo. Es solo una guía visual — la regla de
/// seguridad real (mínimo de caracteres) vive en [Validators] y en las
/// reglas del propio Firebase Auth.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final colors = context.colors;
    final strength = Validators.passwordStrength(password);
    final filledSegments = switch (strength) {
      PasswordStrength.weak => 1,
      PasswordStrength.medium => 2,
      PasswordStrength.strong => 3,
    };
    final message = switch (strength) {
      PasswordStrength.weak => context.l10n.authPasswordStrengthWeak,
      PasswordStrength.medium => context.l10n.authPasswordStrengthMedium,
      PasswordStrength.strong => context.l10n.authPasswordStrengthStrong,
    };

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(3, (index) {
              final filled = index < filledSegments;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: filled ? colors.actionPrimary : colors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTypography.bodyM.copyWith(fontSize: 12, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
