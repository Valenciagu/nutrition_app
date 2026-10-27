import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

import 'app_motion.dart';

/// M05 · Screen transition (`documentation/design_system.md` → "Motion
/// patterns"): shared axis de Material motion (paquete `animations`) en
/// [AppMotion.slow]. Horizontal para un push normal (vía
/// `ThemeData.pageTransitionsTheme`, ver `AppTheme`); vertical para los
/// flujos de pantalla completa (vía `appFlowPage` en `app_router.dart`).
/// Con "reducir movimiento" es solo un fade de [AppMotion.fast].
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder({this.transitionType = SharedAxisTransitionType.horizontal, this.fillColor});

  final SharedAxisTransitionType transitionType;

  /// Fondo durante la transición — el `background` del tema, para que no
  /// destelle el `canvasColor` (blanco) entre dos pantallas grises.
  final Color? fillColor;

  @override
  Duration get transitionDuration => AppMotion.slow;

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildAppTransition(context, animation, secondaryAnimation, child, transitionType, fillColor);
  }
}

/// Compartido por [AppPageTransitionsBuilder] y las `CustomTransitionPage`
/// del router, para que ambos caminos animen exactamente igual.
Widget buildAppTransition(
  BuildContext? context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
  SharedAxisTransitionType transitionType,
  Color? fillColor,
) {
  if (context != null && AppMotion.reduced(context)) {
    // La ruta dura `slow`; el fade ocupa solo su primer tramo (= `fast`).
    final fastShare = AppMotion.fast.inMilliseconds / AppMotion.slow.inMilliseconds;
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Interval(0, fastShare)),
      child: child,
    );
  }

  return SharedAxisTransition(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    transitionType: transitionType,
    fillColor: fillColor,
    child: child,
  );
}
