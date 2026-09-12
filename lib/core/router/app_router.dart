import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../constants/route_paths.dart';
import '../widgets/home_placeholder_page.dart';

/// The single [GoRouter] instance for the app. Do not create additional
/// routers or navigate with raw `Navigator` calls — extend this instead.
///
/// Each feature contributes its own routes here as it's built (auth guards,
/// onboarding gating, etc. will live in `redirect` once Epic 2/3 exist).
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.root,
    routes: [
      GoRoute(
        path: RoutePaths.root,
        builder: (BuildContext context, GoRouterState state) {
          return const HomePlaceholderPage();
        },
      ),
    ],
  );
});
