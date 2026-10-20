import '../constants/app_icons.dart';
import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import 'app_svg_icon.dart';
import '../theme/app_typography.dart';

/// QuickActionTile — uno de los dos componentes nuevos que propone Fase 3 ·
/// Home (el otro, `AISuggestionCard`, se difiere junto con `MacroBar` hasta
/// que exista seguimiento real de macros, Épica 6/7). Fila: icono + título +
/// subtítulo opcional + chevron. El diseño también muestra una variante en
/// grid 2x2 sin subtítulo/chevron (Home · estado poblado) — no se construye
/// todavía porque no tiene un segundo consumidor real que la justifique (ver
/// `documentation/home.md`). `subtitle` es opcional desde la Épica 6 — la
/// fila "Generar lista de compra" de D1 (Plan) es de una sola línea, sin
/// forzar un subtítulo vacío ni crear una fila casi-duplicada. `trailingText`
/// es opcional desde la Épica 11 (Perfil, J1): un valor actual a la derecha
/// ("Automático", "Español") en vez del chevron — el mock nunca muestra
/// ambos a la vez, uno reemplaza al otro.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingText,
    this.icon,
    this.svgIcon,
    required this.iconBackgroundColor,
    required this.onTap,
  }) : assert((icon == null) != (svgIcon == null), 'Pass exactly one of icon / svgIcon');

  final String title;
  final String? subtitle;
  final String? trailingText;
  /// Exactamente uno: `icon` (set Phosphor vía `AppIcons`) o `svgIcon`
  /// (icono propio, `AppAssets.icon*`).
  final IconData? icon;
  final String? svgIcon;
  final Color iconBackgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: iconBackgroundColor, borderRadius: BorderRadius.circular(11)),
                child: svgIcon != null
                    ? AppSvgIcon(svgIcon!, size: 20, color: colors.textPrimary)
                    : Icon(icon, size: 20, color: colors.textPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.bodyM.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.bodyM.copyWith(fontSize: 12.5, color: colors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailingText != null)
                Text(trailingText!, style: AppTypography.bodyM.copyWith(fontSize: 13, color: colors.textDisabled))
              else
                Icon(AppIcons.chevronRight, color: colors.textDisabled),
            ],
          ),
        ),
      ),
    );
  }
}
