import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/greeting.dart';
import '../design/design.dart';
import 'app_widgets.dart' show AppTintIconButton;

/// One bar per category (e.g. a month), height proportional to a 0-100 value. Wraps the kit's [EmBarChart].
class AppBarChart extends StatelessWidget {
  final List<(String label, double value)> data;
  const AppBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) => EmBarChart(data: [
        for (final d in data) EmBarDatum(d.$1, d.$2.clamp(0, 100).toDouble())
      ]);
}

/// Matches the mockup's `lineChart()` — a smoothed line + gradient area
/// fill over 0-100 values, one point per label (e.g. a term/assessment).
class AppLineChart extends StatelessWidget {
  final List<(String label, double value)> points;
  const AppLineChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) {
      return const SizedBox(height: 150);
    }
    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].$2)
    ];
    return LayoutBuilder(builder: (context, constraints) {
      // each x label gets its own slot of the chart width, so long titles ellipsise instead of overlapping
      final slot = constraints.maxWidth.isFinite
          ? constraints.maxWidth / points.length
          : 80.0;
      final halfSlot = slot / 2;
      return SizedBox(
        height: 150,
        // inset by half a label slot so the first and last labels are centred under their points without clipping
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(halfSlot, EmSpacing.s8, halfSlot, 0),
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: 100,
              // the kit chart look (as `EmBarChart`): dashed horizontal guides at 0 / 50 / 100 in the border colour, no frame
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 50,
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: EmColors.border, strokeWidth: 1, dashArray: [4, 4]),
              ),
              borderData: FlBorderData(show: false),
              backgroundColor: Colors.transparent,
              lineTouchData: const LineTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 50,
                    reservedSize: 40,
                    getTitlesWidget: (v, meta) => Padding(
                      padding:
                          const EdgeInsetsDirectional.only(end: EmSpacing.s4),
                      child: Text('${v.round()}',
                          textAlign: TextAlign.end,
                          style: EmType.caption
                              .copyWith(color: EmColors.textSecondary)),
                    ),
                  ),
                ),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 28,
                    getTitlesWidget: (v, meta) {
                      if (v != v.roundToDouble()) {
                        return const SizedBox.shrink(); // one label per point
                      }
                      final i = v.toInt();
                      if (i < 0 || i >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: EmSpacing.s4),
                        child: SizedBox(
                            width: slot,
                            child: Text(points[i].$1,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: EmType.caption
                                    .copyWith(color: EmColors.textSecondary))),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.3,
                  isStrokeCapRound: true,
                  color: EmColors.primary,
                  barWidth: 3,
                  // the points: filled primary with a surface ring, so they read on the tinted area
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, bar, index) =>
                        FlDotCirclePainter(
                            radius: 5,
                            color: EmColors.primary,
                            strokeColor: EmColors.surface,
                            strokeWidth: 2),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        EmColors.primaryMid.withAlpha(71),
                        EmColors.primaryMid.withAlpha(0)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

/// A month grid (Monday first) with the day numbers, today ringed, the selected day filled and a dot on days with
/// events; swipe or the arrows change month. Drawn from kit tokens (the teacher app uses `table_calendar`, which is
/// also a dependency here, but this grid's behaviour - swipe, toggle-able day - is the app's own).
class AppMonthCalendar extends StatelessWidget {
  final DateTime month;
  final Set<int> eventDays;
  final int? selectedDay;
  final ValueChanged<int>? onDayTap;
  final VoidCallback? onPrevMonth;
  final VoidCallback? onNextMonth;
  const AppMonthCalendar({
    super.key,
    required this.month,
    this.eventDays = const {},
    this.selectedDay,
    this.onDayTap,
    this.onPrevMonth,
    this.onNextMonth,
  });

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingBlanks = DateTime(month.year, month.month, 1).weekday - 1;
    final today = uiNow();
    final isCurrentMonth =
        today.year == month.year && today.month == month.month;

    return GestureDetector(
      // Horizontal swipe changes month, like a native calendar.
      onHorizontalDragEnd: (d) {
        final v = d.primaryVelocity ?? 0;
        if (v < -200) onNextMonth?.call();
        if (v > 200) onPrevMonth?.call();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          if (onPrevMonth != null || onNextMonth != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppTintIconButton(
                      icon: Icons.chevron_left_rounded,
                      semanticLabel: 'Previous month',
                      onTap: onPrevMonth),
                  Flexible(
                    child: Text('${_monthNames[month.month - 1]} ${month.year}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: EmType.bodyLarge.copyWith(color: EmColors.ink)),
                  ),
                  AppTintIconButton(
                      icon: Icons.chevron_right_rounded,
                      semanticLabel: 'Next month',
                      onTap: onNextMonth),
                ],
              ),
            ),
          Row(
            children: [
              for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                    child: Center(
                        child: Text(d,
                            style: EmType.caption.copyWith(
                                color: EmColors.textSecondary,
                                fontWeight: FontWeight.w600)))),
            ],
          ),
          const SizedBox(height: EmSpacing.s4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leadingBlanks + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4),
            itemBuilder: (context, i) {
              if (i < leadingBlanks) return const SizedBox.shrink();
              final day = i - leadingBlanks + 1;
              final isToday = isCurrentMonth && today.day == day;
              final hasEvent = eventDays.contains(day);
              final isSelected = selectedDay == day;
              // today is an outlined ring, the selected day a solid circle: they differ by more than colour
              return Semantics(
                button: onDayTap != null,
                selected: isSelected,
                label:
                    '$day ${_monthNames[month.month - 1]}${isToday ? ', today' : ''}${hasEvent ? ', has events' : ''}',
                excludeSemantics: true,
                onTap: onDayTap == null ? null : () => onDayTap!(day),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDayTap == null ? null : () => onDayTap!(day),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? EmColors.primary
                          : (isToday ? EmColors.primaryTint : null),
                      border: isToday && !isSelected
                          ? Border.all(color: EmColors.primary, width: 2)
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$day',
                          style: EmType.label.copyWith(
                            fontWeight: isToday || isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? EmColors.onPrimary
                                : (isToday ? EmColors.primary : EmColors.ink),
                          ),
                        ),
                        if (hasEvent)
                          Positioned(
                            bottom: 4,
                            child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                    color: isSelected
                                        ? EmColors.onPrimary
                                        : EmColors.accent,
                                    shape: BoxShape.circle)),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
