import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_ext.dart';
import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_typography.dart';

/// Campo "Edad/Altura/Peso" de B2: al tocarlo abre un selector de rueda
/// (`CupertinoPicker`) en vez del teclado numérico — así lo especifica el
/// diseño ("menos errores, se mantiene el pulgar abajo"). No es parte de las
/// 10 fichas base; es específico de este paso del Onboarding.
class WheelValueField extends StatelessWidget {
  const WheelValueField({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.highlighted,
    required this.onTap,
  });

  final String label;
  final String value;
  final String unit;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.label.copyWith(
              fontSize: 12.5,
              color: highlighted ? colors.actionPrimary : colors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: highlighted ? colors.actionPrimary : colors.border, width: highlighted ? 2 : 1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: AppTypography.bodyL.copyWith(fontSize: 16, fontWeight: FontWeight.w600)),
                Text(unit, style: AppTypography.label.copyWith(fontSize: 14, color: colors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Abre el selector de rueda para elegir un entero en `[min, max]` con `step`.
Future<int?> showIntWheelPicker(
  BuildContext context, {
  required int min,
  required int max,
  required int step,
  required int initialValue,
  String Function(int)? labelBuilder,
}) async {
  final values = [for (var v = min; v <= max; v += step) v];
  var selectedIndex = values.indexOf(initialValue).clamp(0, values.length - 1);

  return showModalBottomSheet<int>(
    context: context,
    builder: (context) => _WheelPickerSheet<int>(
      values: values,
      initialIndex: selectedIndex,
      labelBuilder: labelBuilder ?? (v) => '$v',
      onDone: (index) => Navigator.of(context).pop(values[index]),
    ),
  );
}

/// Abre el selector de rueda para elegir un decimal en `[min, max]` con un
/// paso (p. ej. 0.5 para el peso).
Future<double?> showDoubleWheelPicker(
  BuildContext context, {
  required double min,
  required double max,
  required double step,
  required double initialValue,
}) async {
  final steps = ((max - min) / step).round();
  final values = [for (var i = 0; i <= steps; i++) min + (i * step)];
  var closestIndex = 0;
  var closestDiff = double.infinity;
  for (var i = 0; i < values.length; i++) {
    final diff = (values[i] - initialValue).abs();
    if (diff < closestDiff) {
      closestDiff = diff;
      closestIndex = i;
    }
  }

  return showModalBottomSheet<double>(
    context: context,
    builder: (context) => _WheelPickerSheet<double>(
      values: values,
      initialIndex: closestIndex,
      labelBuilder: (v) => v.toStringAsFixed(1),
      onDone: (index) => Navigator.of(context).pop(values[index]),
    ),
  );
}

class _WheelPickerSheet<T> extends StatefulWidget {
  const _WheelPickerSheet({required this.values, required this.initialIndex, required this.labelBuilder, required this.onDone});

  final List<T> values;
  final int initialIndex;
  final String Function(T) labelBuilder;
  final void Function(int index) onDone;

  @override
  State<_WheelPickerSheet<T>> createState() => _WheelPickerSheetState<T>();
}

class _WheelPickerSheetState<T> extends State<_WheelPickerSheet<T>> {
  late int _selectedIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = context.l10n;

    return SafeArea(
      child: SizedBox(
        height: 260,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => widget.onDone(_selectedIndex),
                child: Text(l10n.onboardingWheelPickerDoneAction),
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: widget.initialIndex),
                itemExtent: 40,
                onSelectedItemChanged: (index) => _selectedIndex = index,
                children: [
                  for (final value in widget.values)
                    Center(
                      child: Text(
                        widget.labelBuilder(value),
                        style: AppTypography.bodyL.copyWith(fontSize: 18, color: colors.textPrimary),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
