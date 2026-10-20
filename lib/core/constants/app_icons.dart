import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Único punto que conoce el paquete de iconos (Phosphor, elegido
/// 2026-10-05). Los widgets usan `AppIcons.x`, nunca `Icons.x` ni
/// `PhosphorIcons*` directo — cambiar de set es editar solo este archivo.
abstract final class AppIcons {
  static const IconData home = PhosphorIconsRegular.house;
  static const IconData plan = PhosphorIconsRegular.calendarBlank;
  static const IconData ai = PhosphorIconsRegular.sparkle;
  static const IconData profile = PhosphorIconsRegular.user;
  static const IconData camera = PhosphorIconsRegular.camera;

  static const IconData back = PhosphorIconsRegular.arrowLeft;
  static const IconData close = PhosphorIconsRegular.x;
  static const IconData chevronRight = PhosphorIconsRegular.caretRight;
  static const IconData search = PhosphorIconsRegular.magnifyingGlass;
  static const IconData check = PhosphorIconsBold.check;
  static const IconData error = PhosphorIconsRegular.warningCircle;
  static const IconData send = PhosphorIconsBold.arrowUp;

  static const IconData gallery = PhosphorIconsRegular.image;
  static const IconData manualLog = PhosphorIconsRegular.pencilSimple;
  static const IconData groceryList = PhosphorIconsRegular.shoppingCart;
  static const IconData recipe = PhosphorIconsRegular.cookingPot;
  static const IconData swap = PhosphorIconsRegular.arrowsLeftRight;
  static const IconData goal = PhosphorIconsRegular.target;
  static const IconData preferences = PhosphorIconsRegular.forkKnife;
  static const IconData bookmark = PhosphorIconsRegular.bookmarkSimple;
  static const IconData bell = PhosphorIconsRegular.bell;
  static const IconData theme = PhosphorIconsRegular.circleHalf;
  static const IconData language = PhosphorIconsRegular.translate;
  static const IconData privacy = PhosphorIconsRegular.lockSimple;
}
