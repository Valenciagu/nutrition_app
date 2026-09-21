import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_color_tokens.dart';
import '../../../../core/theme/app_typography.dart';

/// D1/D2 (Fase 4) — selector de 5 días (lun-vie, tal como especifica el
/// diseño; no incluye fin de semana). Específico de esta feature, no una
/// de las 10 fichas base — la lista de días que muestra es una decisión de
/// `PlanPage`, este widget solo la pinta.
class DayStrip extends StatelessWidget {
  const DayStrip({super.key, required this.days, required this.selectedDate, required this.onSelect});

  final List<DateTime> days;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;

    return Row(
      children: [
        for (final day in days) ...[
          Expanded(
            child: _DayPill(
              day: day,
              locale: locale,
              selected: _isSameDay(day, selectedDate),
              onTap: () => onSelect(day),
            ),
          ),
          if (day != days.last) const SizedBox(width: 7),
        ],
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.day, required this.locale, required this.selected, required this.onTap});

  final DateTime day;
  final String locale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final weekday = DateFormat.E(locale).format(day).toUpperCase();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.actionPrimary : colors.surface,
          border: selected ? null : Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              weekday,
              style: AppTypography.label.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: selected ? colors.onActionPrimary.withValues(alpha: 0.85) : colors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${day.day}',
              style: AppTypography.bodyL.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected ? colors.onActionPrimary : colors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
