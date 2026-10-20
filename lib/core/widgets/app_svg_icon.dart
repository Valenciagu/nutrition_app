import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icono SVG propio (ver `AppAssets.icon*`) teñido con un solo color — los
/// SVG usan `currentColor`, así que `colorFilter` los pinta completos. Mismo
/// contrato visual que `Icon` (tamaño + color) para poder intercambiarlos.
class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(this.asset, {super.key, this.size = 24, required this.color});

  final String asset;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
