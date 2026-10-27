import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// M03 · Content swap (`documentation/design_system.md` → "Motion
/// patterns"). Reemplaza contenido en el mismo lugar: el saliente se
/// desvanece ([AppMotion.fast], `exit`) y el entrante aparece subiendo
/// [AppMotion.contentSwapOffset] px ([AppMotion.base], `enter`). Con
/// "reducir movimiento" ambos son solo un fade de [AppMotion.fast].
///
/// Igual que un `AnimatedSwitcher`: el hijo necesita una `key` distinta por
/// cada contenido (p. ej. `ValueKey(stepIndex)`) para que se note el cambio.
class AppContentSwitcher extends StatelessWidget {
  const AppContentSwitcher({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);

    return AnimatedSwitcher(
      duration: reduced ? AppMotion.fast : AppMotion.base,
      reverseDuration: AppMotion.fast,
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (transitionChild, animation) {
        final fade = FadeTransition(opacity: animation, child: transitionChild);
        // Solo el entrante se mueve; el saliente (misma `key` que el hijo
        // anterior, animación en reversa) solo se desvanece.
        final isIncoming = transitionChild.key == child.key;
        if (reduced || !isIncoming) return fade;

        return AnimatedBuilder(
          animation: animation,
          builder: (context, faded) => Transform.translate(
            offset: Offset(0, (1 - animation.value) * AppMotion.contentSwapOffset),
            child: faded,
          ),
          child: fade,
        );
      },
      child: child,
    );
  }
}
