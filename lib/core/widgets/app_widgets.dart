import 'package:flutter/material.dart';
import '../design/design.dart';
import '../theme/app_theme.dart';
import 'em_section_header.dart';

/// The app's long-standing shared widgets, now thin wrappers over the Eldermin design kit (`core/design`). Their
/// public constructors are unchanged so no call site changes; new code should use the `Em*` widgets directly.
/// Mapping (legacy -> kit): AppTag -> EmChip.status, AppCard -> EmCard, StatsRow -> EmCard tiles,
/// ListCardRow -> EmListRow, SegmentedControl -> EmSegmentedTabs, DateStripWidget -> EmDateStrip,
/// DonutRing -> EmProgressRing, AppLoader -> EmLoading, AppErrorView -> EmErrorState,
/// AppEmptyView -> EmEmptyState, SectionRow -> EmSectionHeader, ScreenHeader -> EmType + EmChip.
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
                    Text(item.$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            EmType.value.copyWith(color: EmColors.primaryDark)),
                    Text(item.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: EmType.caption
                            .copyWith(color: EmColors.textSecondary)),
                    if (item.$3 != null)
                      Text(item.$3!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              EmType.caption.copyWith(color: EmColors.success)),
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
      {super.key, required this.percent, this.color = AppColors.blue});

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
      this.iconColor = AppColors.blue,
      required this.title,
      required this.subtitle,
      this.trailing,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.row),
      child: EmListRow(
        // the icon keeps the colour the call site chose (blue by default), on the kit's 44 dp tinted circle
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: iconColor.withAlpha(31), shape: BoxShape.circle),
          child:
              ExcludeSemantics(child: Icon(icon, size: 22, color: iconColor)),
        ),
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
  Widget build(BuildContext context) => EmSegmentedTabs<int>(
        segments: [for (final (i, o) in options.indexed) EmSegment(i, o)],
        selected: selectedIndex,
        onChanged: onChanged,
      );
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
      this.color = AppColors.blue,
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

/// The in-body title + caption at the top of a screen's scrolling content, with an optional context chip (a working
/// selector when [onSelectTap] is set, otherwise an informational tag).
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? caption;
  final String? selectLabel;
  final VoidCallback? onSelectTap;
  const ScreenHeader(
      {super.key,
      required this.title,
      this.caption,
      this.selectLabel,
      this.onSelectTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.block),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                    header: true,
                    child: Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: EmType.title.copyWith(color: EmColors.ink))),
                if (caption != null)
                  Text(caption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          EmType.body.copyWith(color: EmColors.textSecondary)),
              ],
            ),
          ),
          if (selectLabel != null) ...[
            const SizedBox(width: EmSpacing.s12),
            if (onSelectTap != null)
              EmChip(
                  label: selectLabel!,
                  onTap: onSelectTap,
                  icon: Icons.expand_more_rounded)
            else
              EmChip.status(label: selectLabel!, tone: EmTone.info),
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
    final now = DateTime.now();
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
