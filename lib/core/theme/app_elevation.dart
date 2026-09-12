import 'package:flutter/painting.dart';

/// Elevation scale (Fase 1 - Fundamentos > 05). Light mode expresses
/// elevation with shadow; dark mode expresses it with surface color + a 1px
/// border instead (shadows barely read on dark backgrounds) — see
/// [AppColorTokens.surface]/[AppColorTokens.surfaceElevated].
abstract final class AppElevation {
  static const List<BoxShadow> e0 = [];

  static const List<BoxShadow> e1 = [
    BoxShadow(color: Color(0x0F101512), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0A101512), offset: Offset(0, 1), blurRadius: 3),
  ];

  static const List<BoxShadow> e2 = [
    BoxShadow(color: Color(0x29101512), offset: Offset(0, 6), blurRadius: 18, spreadRadius: -6),
  ];

  static const List<BoxShadow> e3 = [
    BoxShadow(color: Color(0x38101512), offset: Offset(0, 12), blurRadius: 32, spreadRadius: -10),
  ];

  static const List<BoxShadow> e4 = [
    BoxShadow(color: Color(0x4D101512), offset: Offset(0, 20), blurRadius: 48, spreadRadius: -12),
  ];
}
