import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapta un `Stream` a `Listenable` para el `refreshListenable` de GoRouter,
/// de forma que las reglas de `redirect` se re-evalúen cuando el stream
/// emite (p. ej. el estado de autenticación) sin recrear el `GoRouter` ni
/// perder la pila de navegación.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
