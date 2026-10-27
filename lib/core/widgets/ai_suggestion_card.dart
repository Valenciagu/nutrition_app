import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_typography.dart';
import 'app_button.dart';

/// Propuesta de la IA (Fase 3 · C2, componente nuevo del canvas,
/// "reutilizable en Plan y en el resultado de análisis"). Tarjeta índigo
/// pálida con el punto de estado de la IA, un mensaje y dos acciones: la
/// principal en índigo sólido y "Ahora no". Aparece arriba en Home porque
/// caduca: es contexto, no un aviso permanente.
///
/// Desviación documentada: el canvas pinta "Ahora no" blanco con borde
/// índigo claro y texto índigo; aquí usa la variante `neutral` del sistema
/// cerrado de botones (blanco, borde fino, texto principal) en vez de
/// abrir una sexta variante solo para eso.
class AISuggestionCard extends StatelessWidget {
  const AISuggestionCard({
    super.key,
    required this.message,
    required this.primaryLabel,
    required this.onPrimary,
    required this.dismissLabel,
    required this.onDismiss,
    this.isPrimaryLoading = false,
  });

  final String message;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String dismissLabel;
  final VoidCallback? onDismiss;
  final bool isPrimaryLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: colors.aiSuggestionSurface,
        border: Border.all(color: colors.aiSuggestionBorder),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Punto de estado: "la IA tiene voz" — marca lo generado por IA.
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: colors.aiAccent, shape: BoxShape.circle),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyL.copyWith(fontSize: 14.5, height: 1.5, fontWeight: FontWeight.w500, color: colors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              AppButton(
                label: primaryLabel,
                variant: AppButtonVariant.aiPrimary,
                size: AppButtonSize.md,
                isLoading: isPrimaryLoading,
                onPressed: onPrimary,
              ),
              AppButton(
                label: dismissLabel,
                variant: AppButtonVariant.neutral,
                size: AppButtonSize.md,
                onPressed: isPrimaryLoading ? null : onDismiss,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
