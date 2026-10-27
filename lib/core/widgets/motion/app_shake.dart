import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// M13 · Error feedback (`documentation/design_system.md` → "Motion
/// patterns"). Sacude a [child] en horizontal (±[AppMotion.shakeOffset] px,
/// [AppMotion.shakeCycles] ciclos en [AppMotion.base]) y da una vibración
/// media **cuando [hasError] pasa de `false` a `true`** — no mientras el
/// error sigue presente, ni al construirse ya con error.
///
/// Con "reducir movimiento" no se mueve: el color de error del propio
/// componente y la vibración siguen dando el feedback.
class AppShake extends StatefulWidget {
  const AppShake({super.key, required this.hasError, required this.child});

  final bool hasError;
  final Widget child;

  @override
  State<AppShake> createState() => _AppShakeState();
}

class _AppShakeState extends State<AppShake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: AppMotion.base);

  @override
  void didUpdateWidget(AppShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      HapticFeedback.mediumImpact();
      if (!AppMotion.reduced(context)) _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Seno amortiguado: arranca y termina en 0, así que el cuadro final
        // es exactamente la posición del canvas.
        final t = _controller.value;
        final dx = math.sin(t * AppMotion.shakeCycles * 2 * math.pi) * AppMotion.shakeOffset * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}
