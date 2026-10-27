import '../constants/app_icons.dart';
import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_motion.dart';
import '../theme/app_typography.dart';
import 'motion/app_pressable.dart';

class BottomNavTab {
  const BottomNavTab({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// 09 · BottomNavigation (Fichas de componentes). Decisión de navegación
/// confirmada con el usuario (2026-09-12): 4 tabs + cámara central en vez
/// de los 5 tabs del brief original — la cámara es la acción más repetida
/// del producto y merece el pulgar en vez de competir por un tab; Progreso
/// deja de ser tab y pasa a abrirse desde el anillo de Home (Épica 6).
class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onCameraTap,
  });

  /// Exactamente 4 — Home, Plan, IA, Perfil.
  final List<BottomNavTab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // `SafeArea` (bottom-only, `top: false`): sin esto, en un dispositivo
    // con barra de navegación de 3 botones (no gestos) el sistema dibuja
    // "atrás/inicio/recientes" encima de los propios íconos/labels de esta
    // barra — bug real reportado 2026-09-29 (el usuario probó en un
    // dispositivo con navegación de botones). `Container` no reserva
    // espacio de sistema por sí solo, a diferencia de un
    // `BottomNavigationBar`/`NavigationBar` de Material.
    return SafeArea(
      top: false,
      child: Container(
        height: 84,
        decoration: BoxDecoration(color: colors.surface, border: Border(top: BorderSide(color: colors.border))),
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          children: [
            _tab(context, 0),
            _tab(context, 1),
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: onCameraTap,
                  // M01 (catálogo "Motion patterns") — la acción más repetida
                  // del producto responde al tacto como cualquier botón.
                  // `Container.margin` no acepta valores negativos (lanza un
                  // assertion error) — el efecto "elevado sobre la barra" del
                  // diseño se logra desplazando el widget con `Transform`
                  // en vez de un margen negativo.
                  child: Transform.translate(
                    offset: const Offset(0, -26),
                    child: AppPressable(child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: colors.actionPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: colors.actionPrimary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      alignment: Alignment.center,
                      child: Icon(AppIcons.camera, color: colors.onActionPrimary, size: 24),
                    )),
                  ),
                ),
              ),
            ),
            _tab(context, 2),
            _tab(context, 3),
          ],
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index) {
    final colors = context.colors;
    final tab = tabs[index];
    final active = index == currentIndex;
    final color = active ? colors.actionPrimary : colors.textDisabled;

    // M02 (selección): el color del tab activo cruza en `fast` en vez de
    // saltar; M01 al presionar.
    return Expanded(
      child: GestureDetector(
        onTap: () => onTabSelected(index),
        behavior: HitTestBehavior.opaque,
        child: AppPressable(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                builder: (context, animatedColor, _) => Icon(tab.icon, color: animatedColor, size: 24),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                style: AppTypography.label.copyWith(fontSize: 10.5, color: color, fontWeight: active ? FontWeight.w600 : FontWeight.w500),
                child: Text(tab.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
