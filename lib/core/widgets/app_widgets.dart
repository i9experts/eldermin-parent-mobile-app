import 'package:flutter/material.dart';
import '../utils/greeting.dart';
import '../design/design.dart';
import '../theme/app_theme.dart';
import 'em_section_header.dart';

/// The app's long-standing shared widgets, now thin wrappers over the Eldermin design kit (`core/design`). Their
/// public constructors are unchanged so no call site changes; new code should use the `Em*` widgets directly.
/// Mapping (legacy -> kit): AppTag -> EmChip.status, AppCard -> EmCard, StatsRow -> EmCard tiles,
/// ListCardRow -> EmListRow, SegmentedControl -> EmSegmentedTabs, DateStripWidget -> EmDateStrip,
/// DonutRing -> EmProgressRing, AppLoader -> EmLoading, AppErrorView -> EmErrorState,
/// AppEmptyView -> EmEmptyState, SectionRow -> EmSectionHeader, ScreenHeader (removed: pushed screens use ScreenIntro, tabs use TabHeading).
/// AppProgressBar and AppTimeline have no kit equivalent: they are drawn from kit tokens.

class AppTag extends StatelessWidget {
  final String label;
  final TagStyle style;
  const AppTag(this.label, {super.key, this.style = TagStyle.info});

  @override
  Widget build(BuildContext context) =>
      EmChip.status(label: label, tone: style.tone);
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(EmSpacing.block),
    this.margin = const EdgeInsets.only(bottom: EmSpacing.row),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
      padding: margin,
      child: EmCard(padding: padding, onTap: onTap, child: child));
}

Widget _fit(Widget text) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: text);

class StatsRow extends StatelessWidget {
  final List<(String value, String label, String? trend)> items;
  const StatsRow({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const SizedBox(width: EmSpacing.s8),
            Expanded(
              child: EmCard(
                radius: EmRadius.tile,
                padding: EmSpacing.cardPadCompact,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // scaled down (never cut off) when the tile is narrow at a large text size
                    _fit(Text(item.$1,
                        maxLines: 1,
                        style: EmType.value
                            .copyWith(color: EmColors.primaryDark))),
                    _fit(Text(item.$2,
                        maxLines: 1,
                        style: EmType.caption
                            .copyWith(color: EmColors.textSecondary))),
                    if (item.$3 != null)
                      _fit(Text(item.$3!,
                          maxLines: 1,
                          style: EmType.caption
                              .copyWith(color: EmColors.success))),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Linear progress bar (no kit equivalent; the kit's [EmProgressRing] is a ring).
class AppProgressBar extends StatelessWidget {
  final int percent;
  final Color color;
  const AppProgressBar(
      {super.key, required this.percent, this.color = EmColors.primary});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Progress $percent percent',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: EmRadius.pillAll,
        child: SizedBox(
          height: 8,
          child: LinearProgressIndicator(
            value: percent.clamp(0, 100) / 100,
            backgroundColor: EmColors.primaryContainer,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ),
    );
  }
}

class ListCardRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const ListCardRow(
      {super.key,
      required this.icon,
      this.iconColor = EmColors.primary,
      required this.title,
      required this.subtitle,
      this.trailing,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    // the leading icon keeps the colour the call site chose (blue by default), on the kit's 44 dp tinted circle
    final leading = Container(
      width: 44,
      height: 44,
      decoration:
          BoxDecoration(color: iconColor.withAlpha(31), shape: BoxShape.circle),
      child: ExcludeSemantics(child: Icon(icon, size: 22, color: iconColor)),
    );
    // At large text sizes a trailing tag would squeeze the title and subtitle into a few letters per line: the same
    // content is stacked instead (title, subtitle, then the tag), nothing is cut off.
    if (trailing != null && MediaQuery.textScalerOf(context).scale(1) > 1.15) {
      return Padding(
        padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.row),
        child: EmCard(
          onTap: onTap,
          padding: const EdgeInsetsDirectional.fromSTEB(
              EmSpacing.s16, EmSpacing.s12, EmSpacing.s16, EmSpacing.s12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            leading,
            const SizedBox(width: EmSpacing.s12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: EmType.bodyLarge.copyWith(color: EmColors.ink)),
                    if (subtitle.isNotEmpty)
                      Text(subtitle,
                          style: EmType.body.copyWith(
                              color: EmColors.textSecondary,
                              fontWeight: FontWeight.w400)),
                    const SizedBox(height: EmSpacing.s8),
                    trailing!,
                  ]),
            ),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.row),
      child: EmListRow(
        leading: leading,
        title: title,
        subtitle: subtitle.isEmpty ? null : subtitle,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

/// Vertical timeline (no kit equivalent): dot + rail, drawn from kit tokens.
class AppTimeline extends StatelessWidget {
  final List<(String time, String title, String meta, Color dotColor)> items;
  const AppTimeline({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final (i, e) in items.indexed)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Column(
                    children: [
                      Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: e.$4,
                              border: Border.all(
                                  color: EmColors.primaryContainer, width: 3))),
                      if (i != items.length - 1)
                        Expanded(
                            child: Container(width: 2, color: EmColors.border)),
                    ],
                  ),
                ),
                const SizedBox(width: EmSpacing.s8),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsetsDirectional.only(bottom: EmSpacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.$1,
                            style: EmType.caption
                                .copyWith(color: EmColors.textSecondary)),
                        Text(e.$2,
                            style:
                                EmType.bodyLarge.copyWith(color: EmColors.ink)),
                        Text(e.$3,
                            style: EmType.caption.copyWith(
                                color: EmColors.textSecondary,
                                fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class SegmentedControl extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  const SegmentedControl(
      {super.key,
      required this.options,
      required this.selectedIndex,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // the kit's segmented tabs keep one line per label; at large text sizes the same choices are kit choice chips that wrap
    if (MediaQuery.textScalerOf(context).scale(1) > 1.15) {
      return Wrap(
        spacing: EmSpacing.s8,
        children: [
          for (final (i, o) in options.indexed)
            EmChip(
                label: o,
                selected: i == selectedIndex,
                onTap: () => onChanged(i))
        ],
      );
    }
    return EmSegmentedTabs<int>(
      segments: [for (final (i, o) in options.indexed) EmSegment(i, o)],
      selected: selectedIndex,
      onChanged: onChanged,
    );
  }
}

class DateStripWidget extends StatelessWidget {
  final List<DateTime> days;
  final DateTime selected;
  final Set<DateTime> highlighted;
  final ValueChanged<DateTime> onSelect;
  const DateStripWidget(
      {super.key,
      required this.days,
      required this.selected,
      this.highlighted = const {},
      required this.onSelect});

  @override
  Widget build(BuildContext context) => EmDateStrip(
      days: days,
      selected: selected,
      onSelected: onSelect,
      markedDays: highlighted);
}

class DonutRing extends StatelessWidget {
  final int percent;
  final Color color;
  final double size;
  const DonutRing(
      {super.key,
      required this.percent,
      this.color = EmColors.primary,
      this.size = 84});

  @override
  Widget build(BuildContext context) => EmProgressRing(
        value: percent.clamp(0, 100) / 100,
        size: size,
        strokeWidth: size >= 120 ? 12 : 8,
        centerText: '$percent%',
        color: color,
        knob: false,
      );
}

/// A 48 dp round action tinted on the kit's light fill (month arrows, a sheet's close button) for use on white surfaces,
/// where the kit's white [EmIconCircleButton] would disappear. Disabled when [onTap] is null.
class AppTintIconButton extends StatelessWidget {
  const AppTintIconButton(
      {super.key,
      required this.icon,
      required this.semanticLabel,
      required this.onTap});
  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: semanticLabel,
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      style: IconButton.styleFrom(
        backgroundColor: EmColors.background,
        foregroundColor: EmColors.ink,
        disabledBackgroundColor: EmColors.background,
        disabledForegroundColor: EmColors.onDisabled,
        minimumSize: const Size(EmSpacing.minTouch, EmSpacing.minTouch),
      ),
    );
  }
}

/// A state body inside a scrolling list has unbounded height (no nested scroll view there); as a screen body it is bounded
/// (the kit state centres and scrolls). Picks the kit option that fits where it is placed.
Widget _stateBody(Widget Function(bool scroll) build) =>
    LayoutBuilder(builder: (context, c) => build(c.hasBoundedHeight));

class AppLoader extends StatelessWidget {
  const AppLoader({super.key});
  @override
  Widget build(BuildContext context) => const EmLoading();
}

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AppErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) => _stateBody((scroll) => EmErrorState(
      message: message,
      onRetry: onRetry,
      retryLabel: 'Try again',
      scroll: scroll,
      compact: !scroll));
}

class AppEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  const AppEmptyView(
      {super.key, required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => _stateBody((scroll) => EmEmptyState(
      icon: icon,
      title: title,
      message: subtitle,
      scroll: scroll,
      compact: !scroll));
}

class SectionRow extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionRow({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) =>
      EmSectionHeader(title: title, onAction: onSeeAll);
}

/// The context line at the top of a pushed screen's scrolling content: the caption and an optional chip (a working
/// selector when [onSelectTap] is set, otherwise an informational tag). The screen's title is the [EmAppBar]'s, so it is
/// shown once.
class ScreenIntro extends StatelessWidget {
  final String? caption;
  final String? selectLabel;
  final VoidCallback? onSelectTap;
  const ScreenIntro(
      {super.key, this.caption, this.selectLabel, this.onSelectTap});

  @override
  Widget build(BuildContext context) {
    if (caption == null && selectLabel == null) return const SizedBox.shrink();
    final chip = selectLabel == null
        ? null
        : (onSelectTap != null
            ? EmChip(
                label: selectLabel!,
                onTap: onSelectTap,
                icon: Icons.expand_more_rounded)
            : EmChip.status(label: selectLabel!, tone: EmTone.info));
    final text = caption == null
        ? null
        : Text(caption!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: EmType.body.copyWith(color: EmColors.textSecondary));
    // at large text sizes the chip goes under the caption, on its own line, so neither is cut off
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.15;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.block),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (text != null) text,
                if (chip != null) ...[
                  const SizedBox(height: EmSpacing.s8),
                  chip
                ]
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: text ?? const SizedBox.shrink()),
                if (chip != null) ...[
                  const SizedBox(width: EmSpacing.s12),
                  Flexible(child: chip)
                ],
              ],
            ),
    );
  }
}

/// A current-week strip that manages its own selected day (no controller wiring). Decorative on the screens that still
/// show it; the Home tab no longer does.
class AppWeekDateStrip extends StatefulWidget {
  final Set<DateTime> highlighted;
  final ValueChanged<DateTime>? onSelect;
  const AppWeekDateStrip(
      {super.key, this.highlighted = const {}, this.onSelect});

  @override
  State<AppWeekDateStrip> createState() => _AppWeekDateStripState();
}

class _AppWeekDateStripState extends State<AppWeekDateStrip> {
  late DateTime _selected;
  late List<DateTime> _days;

  @override
  void initState() {
    super.initState();
    final now = uiNow();
    _days = EmDateStrip.weekOf(now);
    _selected = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    return DateStripWidget(
      days: _days,
      selected: _selected,
      highlighted: widget.highlighted,
      onSelect: (d) {
        setState(() => _selected = d);
        widget.onSelect?.call(d);
      },
    );
  }
}
