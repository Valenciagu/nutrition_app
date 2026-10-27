import 'package:flutter/widgets.dart';

import '../../theme/app_motion.dart';

/// M08 · Progress fill, parte numérica (`documentation/design_system.md` →
/// "Motion patterns"). Muestra [value] contando desde el valor anterior (o
/// desde 0 la primera vez) en [AppMotion.progress], curva `standard`, en
/// sincronía con `ProgressRing`. Con "reducir movimiento" el número cambia
/// directo, sin conteo.
class AppCountUpText extends StatelessWidget {
  const AppCountUpText({super.key, required this.value, this.style, this.format, this.textAlign});

  final int value;
  final TextStyle? style;

  /// Para componer el número dentro de un texto (p. ej. `'$n%'`); por defecto
  /// solo el número.
  final String Function(int value)? format;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final formatter = format ?? (int n) => '$n';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.progress,
      curve: AppMotion.standard,
      builder: (context, current, _) => Text(formatter(current.round()), style: style, textAlign: textAlign),
    );
  }
}
