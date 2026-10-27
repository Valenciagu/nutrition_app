import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/app_motion.dart';

/// Marca el inicio de una lista para M04 · List entrance stagger
/// (`documentation/design_system.md` → "Motion patterns"). Necesario en
/// listas perezosas (`ListView`, `ListView.builder`): sus ítems se destruyen
/// al salir de pantalla y se vuelven a crear al regresar — sin este scope,
/// cada scroll de vuelta repetiría la entrada. Con el scope, solo los ítems
/// construidos durante la ventana inicial animan; los que se crean después
/// aparecen ya en su estado final.
///
/// En una `Column` (ítems que no se reciclan) no hace falta.
class AppEntranceScope extends StatefulWidget {
  const AppEntranceScope({super.key, required this.child});

  final Widget child;

  /// `true` si ya pasó la ventana de entrada del scope más cercano.
  static bool isSettled(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_AppEntranceScopeData>();
    if (scope == null) return false;
    return DateTime.now().difference(scope.startedAt) > _window;
  }

  // El último ítem escalonado arranca en `stagger * (max - 1)` y dura `base`.
  static final Duration _window = AppMotion.listStagger * (AppMotion.listMaxStaggered - 1) + AppMotion.base;

  @override
  State<AppEntranceScope> createState() => _AppEntranceScopeState();
}

class _AppEntranceScopeState extends State<AppEntranceScope> {
  final DateTime _startedAt = DateTime.now();

  @override
  Widget build(BuildContext context) => _AppEntranceScopeData(startedAt: _startedAt, child: widget.child);
}

class _AppEntranceScopeData extends InheritedWidget {
  const _AppEntranceScopeData({required this.startedAt, required super.child});

  final DateTime startedAt;

  @override
  bool updateShouldNotify(_AppEntranceScopeData oldWidget) => startedAt != oldWidget.startedAt;
}

extension AppEntranceX on Widget {
  /// M04 — el ítem número [index] de una lista entra subiendo
  /// [AppMotion.listEntranceOffset] px con un fade ([AppMotion.base],
  /// `enter`), escalonado [AppMotion.listStagger]; desde el ítem
  /// [AppMotion.listMaxStaggered] en adelante entran junto con el último
  /// escalonado. Solo en la primera construcción, nunca al reconstruir.
  ///
  /// [play] fuerza la decisión cuando quien llama sabe mejor que el scope si
  /// el ítem es nuevo (p. ej. el chat: solo la burbuja recién llegada entra,
  /// una que vuelve a construirse por scroll aparece quieta).
  Widget appListEntrance(int index, {bool? play}) => _ListEntrance(index: index, play: play, child: this);

  /// M02 / M11 — un check o confirmación que aparece: escala desde
  /// [AppMotion.popInScaleFrom] + fade, curva `enter`. [AppMotion.fast] para
  /// selección (M02), [AppMotion.base] para éxito de una acción (M11).
  /// Anima al construirse por primera vez — úsalo en algo que aparece
  /// (condicional o dentro de un `AnimatedSwitcher`), no en algo fijo.
  Widget appPopIn(BuildContext context, {Duration duration = AppMotion.fast}) {
    if (AppMotion.reduced(context)) {
      return animate().fadeIn(duration: AppMotion.fast);
    }
    return animate()
        .fadeIn(duration: duration, curve: AppMotion.enter)
        .scaleXY(begin: AppMotion.popInScaleFrom, end: 1, duration: duration, curve: AppMotion.enter);
  }
}

class _ListEntrance extends StatefulWidget {
  const _ListEntrance({required this.index, required this.play, required this.child});

  final int index;
  final bool? play;
  final Widget child;

  @override
  State<_ListEntrance> createState() => _ListEntranceState();
}

class _ListEntranceState extends State<_ListEntrance> {
  // Se decide una sola vez por ítem: si cambiara entre reconstrucciones,
  // `Animate` reiniciaría la animación (ver `Animate.didUpdateWidget`).
  bool? _play;
  late bool _reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _play ??= widget.play ?? !AppEntranceScope.isSettled(context);
    _reduced = AppMotion.reduced(context);
  }

  @override
  Widget build(BuildContext context) {
    final play = _play!;
    final animate = widget.child.animate(autoPlay: play, value: play ? null : 1);

    if (_reduced) return animate.fadeIn(duration: AppMotion.fast);

    final slot = widget.index.clamp(0, AppMotion.listMaxStaggered - 1);
    return animate
        .fadeIn(delay: AppMotion.listStagger * slot, duration: AppMotion.base, curve: AppMotion.enter)
        .moveY(begin: AppMotion.listEntranceOffset, end: 0, duration: AppMotion.base, curve: AppMotion.enter);
  }
}
