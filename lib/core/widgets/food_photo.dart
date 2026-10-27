import 'package:flutter/material.dart';

import 'hatched_placeholder.dart';

/// Foto de comida desde los assets de la app, o el `HatchedPlaceholder`
/// rayado cuando no hay ([imageAsset] `null`) o el archivo no carga — la
/// regla del canvas es "receta sin foto: placeholder rayado, nunca un ícono
/// genérico". [dimmed] atenúa igual que el placeholder (comida ya
/// registrada en `MealCard`).
class FoodPhoto extends StatelessWidget {
  const FoodPhoto({
    super.key,
    required this.imageAsset,
    this.borderRadius = BorderRadius.zero,
    this.dimmed = false,
  });

  final String? imageAsset;
  final BorderRadius borderRadius;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final placeholder = HatchedPlaceholder(borderRadius: borderRadius, dimmed: dimmed);
    if (imageAsset == null) return placeholder;

    return ClipRRect(
      borderRadius: borderRadius,
      child: Opacity(
        opacity: dimmed ? 0.6 : 1,
        child: Image.asset(
          imageAsset!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      ),
    );
  }
}
