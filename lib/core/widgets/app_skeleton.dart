import 'package:flutter/material.dart';

import '../theme/app_color_tokens.dart';

/// A single shimmering skeleton bar, matching the loading silhouette from
/// Fichas de componentes > 10 · StateBlock (shimmer sweep, 1.3s loop).
/// Compose several with a real content silhouette (e.g. a `MealCard`-shaped
/// skeleton) rather than inventing a generic spinner for list/card loading.
class AppSkeletonBar extends StatefulWidget {
  const AppSkeletonBar({super.key, this.width, this.height = 11});

  final double? width;
  final double height;

  @override
  State<AppSkeletonBar> createState() => _AppSkeletonBarState();
}

class _AppSkeletonBarState extends State<AppSkeletonBar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = colors.border.withValues(alpha: 0.6);
    final highlight = colors.surface;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              final dx = bounds.width * (_controller.value * 3 - 1);
              return LinearGradient(
                colors: [base, highlight, base],
                stops: const [0.35, 0.5, 0.65],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                transform: _SlidingGradientTransform(dx),
              ).createShader(bounds);
            },
            child: DecoratedBox(
              decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(999)),
            ),
          );
        },
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(dx, 0, 0);
}
