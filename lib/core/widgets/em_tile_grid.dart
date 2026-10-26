import 'package:flutter/material.dart';
import '../design/design.dart';

/// One shortcut in an [EmTileGrid].
class EmTile {
  const EmTile({required this.label, required this.onTap, this.icon, this.leading, this.color = EmColors.primary, this.destructive = false, this.tileKey});
  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  /// Replaces [icon] (e.g. an SVG icon).
  final Widget? leading;
  final Color color;
  final bool destructive;
  final Key? tileKey;
}

/// Shortcut tiles on the kit: a [EmCard] per tile with a tinted icon circle and the label beside it, so the label keeps
/// room at large text sizes. Two per row; four on wide screens; one per row at text scale > 1.15 (no label breaks inside a word).
class EmTileGrid extends StatelessWidget {
  const EmTileGrid({super.key, required this.tiles});
  final List<EmTile> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.15;
      final columns = constraints.maxWidth >= 640 ? 4 : (largeText ? 1 : 2);
      final rows = <List<EmTile>>[];
      for (var i = 0; i < tiles.length; i += columns) {
        rows.add(tiles.sublist(i, i + columns > tiles.length ? tiles.length : i + columns));
      }
      Widget tile(EmTile t) {
        final color = t.destructive ? EmColors.onErrorContainer : t.color;
        return EmCard(
          key: t.tileKey ?? Key('tile_${t.label}'),
          onTap: t.onTap,
          radius: EmRadius.tile,
          padding: EmSpacing.cardPadCompact,
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: t.destructive ? EmColors.errorContainer : t.color.withAlpha(31), shape: BoxShape.circle),
              child: ExcludeSemantics(child: Center(child: t.leading ?? Icon(t.icon, color: color, size: 20))),
            ),
            const SizedBox(width: EmSpacing.s8),
            Expanded(child: Text(t.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: EmType.label.copyWith(color: t.destructive ? EmColors.onErrorContainer : EmColors.ink))),
          ]),
        );
      }

      return Column(children: [
        for (final (r, row) in rows.indexed) ...[
          if (r > 0) const SizedBox(height: EmSpacing.s8),
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (var c = 0; c < columns; c++) ...[
                if (c > 0) const SizedBox(width: EmSpacing.s8),
                Expanded(child: c < row.length ? tile(row[c]) : const SizedBox.shrink()),
              ],
            ]),
          ),
        ],
      ]);
    });
  }
}
