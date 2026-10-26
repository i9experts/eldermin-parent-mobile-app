import 'package:flutter/material.dart';
import '../design/design.dart';

/// The summary card at the top of a dashboard: kicker, a big value with a trend line, a progress ring and up to three
/// metric tiles. Built on the kit's [EmHeroCard] + [EmProgressRing] + [EmStatTile]s (the teacher Home pattern).
/// [metricIcons] (optional, one per metric) are the tiles' icons; [ringColor] defaults to the kit primary.
class HeroCard extends StatelessWidget {
  final String kicker;
  final String value;
  final String trend;
  final bool trendWarn;
  final int percent;
  final Color ringColor;
  final List<(String, String)> metrics;
  final List<IconData>? metricIcons;

  const HeroCard({
    super.key,
    required this.kicker,
    required this.value,
    required this.trend,
    this.trendWarn = false,
    required this.percent,
    this.ringColor = EmColors.primary,
    this.metrics = const [],
    this.metricIcons,
  });

  @override
  Widget build(BuildContext context) {
    return EmHeroCard(
      padding: const EdgeInsetsDirectional.all(EmSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(kicker, maxLines: 2, overflow: TextOverflow.ellipsis, style: EmType.label.copyWith(color: EmColors.textSecondary)),
          const SizedBox(height: EmSpacing.s8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(value, style: EmType.display.copyWith(color: EmColors.ink)),
                    ),
                    const SizedBox(height: EmSpacing.s8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(top: EmSpacing.s4),
                          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: trendWarn ? EmColors.accent : EmColors.success, shape: BoxShape.circle)),
                        ),
                        const SizedBox(width: EmSpacing.s8),
                        Expanded(child: Text(trend, maxLines: 2, overflow: TextOverflow.ellipsis, style: EmType.label.copyWith(color: EmColors.ink))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: EmSpacing.s12),
              EmProgressRing(
                value: percent.clamp(0, 100) / 100,
                size: 96,
                strokeWidth: 10,
                centerText: '$percent%',
                color: ringColor,
                semanticLabel: '$kicker $percent percent',
              ),
            ],
          ),
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: EmSpacing.s16),
            EmStatTileRow(tiles: [
              for (final (i, m) in metrics.indexed)
                EmStatTile(
                  icon: metricIcons != null && i < metricIcons!.length ? metricIcons![i] : Icons.insights_outlined,
                  value: m.$1,
                  label: m.$2,
                ),
            ]),
          ],
        ],
      ),
    );
  }
}
