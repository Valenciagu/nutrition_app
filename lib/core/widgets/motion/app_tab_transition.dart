import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// M05 · Screen transition, variante "cambio de tab"
/// (`documentation/design_system.md` → "Motion patterns"). Las tabs del
/// shell viven en un `IndexedStack` (cada una conserva su pila y su estado),
/// así que la tab saliente desaparece en el acto y no se puede animar: se
/// anima solo la mitad entrante del fade-through — aparece con un fade y
/// escala desde [AppMotion.tabEnterScaleFrom], en [AppMotion.base], curva
/// `enter`. Con "reducir movimiento", solo el fade de [AppMotion.fast].
class AppTabTransition extends StatefulWidget {
  const AppTabTransition({super.key, required this.index, required this.child});

  /// La tab activa — cada cambio dispara la entrada.
  final int index;
  final Widget child;

  @override
  State<AppTabTransition> createState() => _AppTabTransitionState();
}

class _AppTabTransitionState extends State<AppTabTransition> with SingleTickerProviderStateMixin {
  // Empieza en 1: la primera tab que se muestra al abrir la app no anima,
  // solo los cambios de tab posteriores.
  late final AnimationController _controller = AnimationController(vsync: this, duration: AppMotion.base, value: 1);
  late final CurvedAnimation _curve = CurvedAnimation(parent: _controller, curve: AppMotion.enter);

  @override
  void didUpdateWidget(AppTabTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.duration = AppMotion.reduced(context) ? AppMotion.fast : AppMotion.base;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = FadeTransition(opacity: _curve, child: widget.child);
    if (AppMotion.reduced(context)) return fade;

    return ScaleTransition(
      scale: Tween<double>(begin: AppMotion.tabEnterScaleFrom, end: 1).animate(_curve),
      child: fade,
    );
  }
}
