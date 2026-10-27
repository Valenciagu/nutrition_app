import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// M01 · Press feedback (`documentation/design_system.md` → "Motion
/// patterns"). Envuelve cualquier cosa tocable y la escala a
/// [AppMotion.pressScale] mientras el dedo está abajo.
///
/// Usa un [Listener] (eventos de puntero crudos), no un `GestureDetector`:
/// así no compite con el `InkWell`/`GestureDetector` que ya maneja el tap
/// dentro del hijo — el tap, la tinta y la semántica siguen siendo del hijo.
/// Con "reducir movimiento" no escala: la tinta/color del propio componente
/// siguen dando el feedback, así que nunca se queda sin respuesta visual.
class AppPressable extends StatefulWidget {
  const AppPressable({super.key, required this.child, this.enabled = true});

  final Widget child;

  /// `false` para un componente deshabilitado — no debe "responder" al tacto.
  final bool enabled;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && !AppMotion.reduced(context);

    return Listener(
      onPointerDown: active ? (_) => _setPressed(true) : null,
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: active && _pressed ? AppMotion.pressScale : 1,
        duration: AppMotion.instant,
        curve: AppMotion.standard,
        child: widget.child,
      ),
    );
  }
}
