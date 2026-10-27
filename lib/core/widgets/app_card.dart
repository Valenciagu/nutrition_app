import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'motion/app_pressable.dart';

/// The app's generic surface container: white/elevated surface, `xl` radius,
/// hairline border (Fase 1 - Fundamentos > 05). Use this instead of a raw
/// [Container] with an inline `BoxDecoration` for any card-like surface —
/// specialized cards (MealCard, RecipeCard, ...) should wrap this rather
/// than reimplementing the surface/border/radius themselves.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.space16),
    this.onTap,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Whether this card sits above other content (e.g. inside a bottom
  /// sheet) and should use `surfaceElevated` instead of `surface`.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AppPressable(
      enabled: onTap != null,
      child: Material(
        color: elevated ? colors.surfaceElevated : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: colors.border),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
