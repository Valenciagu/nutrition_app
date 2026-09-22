import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/widgets/camera_action_sheet.dart';
import '../../features/notifications/presentation/providers/notification_providers.dart';
import '../localization/app_localizations_ext.dart';
import '../widgets/bottom_navigation.dart';

/// Envuelve las 4 tabs del shell principal (Home, Plan, IA, Perfil) con la
/// barra de navegación + botón de cámara central — un [StatefulShellBranch]
/// por tab mantiene su propia pila de navegación independiente (`app_router.dart`
/// arma las branches; este widget solo dibuja la chrome alrededor del
/// `navigationShell` que GoRouter ya gestiona).
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // Solo lectura del resultado: reprograma recordatorios locales una vez
    // por sesión logueada (Épica 12) — mitiga que `zonedSchedule` no
    // sobrevive un reinicio del dispositivo sin un receptor nativo de
    // arranque (no construido en v1). Se ignora el estado a propósito: un
    // fallo aquí no debe bloquear ni ensuciar la UI del shell principal.
    ref.watch(notificationBootstrapProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onTabSelected: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        onCameraTap: () => showCameraActionSheet(context, ref),
        tabs: [
          BottomNavTab(icon: Icons.home_rounded, label: l10n.bottomNavHomeLabel),
          BottomNavTab(icon: Icons.calendar_today_rounded, label: l10n.bottomNavPlanLabel),
          BottomNavTab(icon: Icons.auto_awesome_rounded, label: l10n.bottomNavAiLabel),
          BottomNavTab(icon: Icons.person_rounded, label: l10n.bottomNavProfileLabel),
        ],
      ),
    );
  }
}
