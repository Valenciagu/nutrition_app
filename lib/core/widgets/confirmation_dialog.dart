import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Confirmación centrada para acciones destructivas — `app_bottom_sheet.dart`
/// ya documentaba esto como el patrón correcto ("destructive confirmations
/// belong in a centered dialog") pero no existía todavía ningún consumidor
/// real. Primer uso: eliminar cuenta (Perfil, Épica 11). Sin ficha propia en
/// "Fichas de componentes" (no es uno de los 10 componentes base) — construido
/// con los tokens ya sincronizados, mismo criterio que otras pantallas sin
/// mock propio en el canvas.
///
/// Devuelve `true` solo si el usuario tocó el botón de confirmar.
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool isDestructive = false,
}) async {
  final colors = context.colors;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: colors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleM.copyWith(fontSize: 18, color: colors.textPrimary)),
              const SizedBox(height: AppSpacing.space8),
              Text(message, style: AppTypography.bodyM.copyWith(fontSize: 14, color: colors.textSecondary)),
              const SizedBox(height: AppSpacing.space20),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: cancelLabel,
                      variant: AppButtonVariant.neutral,
                      fullWidth: true,
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: AppButton(
                      label: confirmLabel,
                      fullWidth: true,
                      accentColorOverride: isDestructive ? colors.error : null,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return result ?? false;
}
