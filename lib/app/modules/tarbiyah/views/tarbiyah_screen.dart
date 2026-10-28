import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/design/design.dart';
import '../../../../core/models/behaviour_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/detail_format.dart';
import '../../../../core/widgets/app_date_picker.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/hero_card.dart';
import '../../../../core/widgets/locked_feature_view.dart';
import '../../../../core/widgets/shimmer_widgets.dart';
import '../controllers/tarbiyah_controller.dart';
import 'tarbiyah_detail_sheets.dart';

/// A trait at or above this percentage is drawn in the "strong" colour (the school's own scale is converted to 0-100 by the server).
const int kTraitStrongPercent = 88;

/// "Growth & tarbiyah": the latest assessment, the full assessment history, and the behaviour records the school shares (newest first,
/// filterable, each one opens its detail). Everything the server sends may be absent: the models default, so no row ever shows "null".
class TarbiyahScreen extends GetView<TarbiyahController> {
  const TarbiyahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EmScaffold(
      appBar: EmAppBar(title: 'Growth & tarbiyah'),
      body: Obx(() {
        if (controller.loading.value && controller.isEmpty) return const _Loading();
        if (controller.error.value != null) {
          return AppErrorView(message: controller.error.value!, onRetry: controller.fetch);
        }
        if (controller.locked.value) return const LockedFeatureView();

        final latest = controller.latestAssessment;
        final assessments = controller.assessments.toList();
        final records = controller.records.toList();
        final visible = controller.visibleRecords;
        final filter = controller.filter.value;

        return RefreshIndicator(
          onRefresh: controller.fetch,
          child: ListView(
            padding: EmSpacing.listPadding,
            children: [
              const ScreenIntro(caption: 'Character, wellbeing and positive habits'),
              if (controller.isEmpty)
                const AppEmptyView(
                  key: Key('tb_empty'),
                  icon: Icons.spa_outlined,
                  title: 'Nothing recorded yet',
                  subtitle: 'Teacher notes and character assessments will appear here once the school shares them.',
                )
              else ...[
                if (latest != null) ..._latest(context, latest),
                if (assessments.isNotEmpty) ..._history(context, assessments),
                ..._records(context, records, visible, filter),
              ],
            ],
          ),
        );
      }),
    );
  }

  List<Widget> _latest(BuildContext context, TarbiyahReport a) {
    final pct = a.overallPercentage;
    final when = a.assessmentDate == null ? null : formatDay(a.assessmentDate!.toUtc());
    final headline = [a.displayPeriod, if (when != null) when].join(' · ');
    return [
      HeroCard(
        kicker: a.programName.isEmpty ? 'Holistic growth score' : '${a.programName} score',
        value: pct != null ? '$pct%' : (a.overallScore != null ? a.overallScore!.toStringAsFixed(a.overallScore! == a.overallScore!.roundToDouble() ? 0 : 1) : '—'),
        trend: headline,
        percent: pct ?? 0,
        metrics: [
          ('${controller.meritCount}', 'Merits'),
          ('${a.traits.length}', 'Traits tracked'),
          ('${controller.concernCount}', 'Concerns'),
        ],
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: EmTextAction(key: const Key('tb_view_assessment'), onPressed: () => showAssessmentSheet(context, a), icon: Icons.article_outlined, label: 'View full assessment'),
      ),
      const SizedBox(height: EmSpacing.s16),
      if (a.traits.isNotEmpty) ...[
        StatsRow(items: [for (final t in a.traits.take(3)) ('${t.percentage}%', t.name, null)]),
        const SizedBox(height: EmSpacing.s12),
        const SectionRow(title: 'Character development'),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, t) in a.traits.indexed)
                Padding(
                  padding: EdgeInsetsDirectional.only(top: i == 0 ? 0 : EmSpacing.s12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(t.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: EmType.caption.copyWith(color: EmColors.textSecondary))),
                      const SizedBox(width: EmSpacing.s8),
                      Text('${t.percentage}%', style: EmType.caption.copyWith(color: EmColors.primaryDark, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: EmSpacing.s8),
                    AppProgressBar(percent: t.percentage, color: t.percentage < kTraitStrongPercent ? EmColors.accent : EmColors.success),
                  ]),
                ),
            ],
          ),
        ),
        const SizedBox(height: EmSpacing.s16),
      ],
    ];
  }

  List<Widget> _history(BuildContext context, List<TarbiyahReport> list) {
    return [
      const SectionRow(title: 'Assessment history'),
      for (final (i, a) in list.indexed)
        ListCardRow(
          key: Key('tb_asm_$i'),
          icon: Icons.spa_rounded,
          iconColor: EmColors.success,
          title: a.displayPeriod,
          subtitle: [
            if (a.assessmentDate != null) formatDay(a.assessmentDate!.toUtc()),
            if (a.overallPercentage != null) '${a.overallPercentage}% overall',
          ].join(' · '),
          trailing: a.ratingLabel.isEmpty ? null : AppTag(a.ratingLabel, style: _ratingStyle(a.overallRating)),
          onTap: () => showAssessmentSheet(context, a),
        ),
      if (controller.assessmentsMayBeTruncated)
        const _Note(key: Key('tb_asm_truncated'), text: 'Showing the latest 20 assessments. Older ones are kept by the school.'),
      const SizedBox(height: EmSpacing.s16),
    ];
  }

  List<Widget> _records(BuildContext context, List<ParentBehaviourRecord> all, List<ParentBehaviourRecord> visible, RecordFilter filter) {
    return [
      const SectionRow(title: 'Teacher notes & observations'),
      if (all.isEmpty)
        const AppEmptyView(key: Key('tb_no_records'), icon: Icons.favorite_outline_rounded, title: 'No observations recorded yet')
      else ...[
        _FilterBar(controller: controller, onOpen: () => _openFilter(context)),
        if (visible.isEmpty)
          AppEmptyView(key: const Key('tb_filter_empty'), icon: Icons.filter_alt_off_outlined, title: filter.isActive ? 'Nothing matches these filters' : 'No observations recorded yet')
        else
          for (final (i, r) in visible.indexed)
            ListCardRow(
              key: Key('tb_rec_$i'),
              icon: _iconOf(r.kind),
              iconColor: _colorOf(r.kind),
              title: r.displayTitle,
              subtitle: [
                if (r.date != null) formatDay(r.date!.toUtc()),
                if (r.description.isNotEmpty) r.description,
              ].join(' · '),
              trailing: AppTag(r.kind.label, style: switch (r.kind) {
                BehaviourKind.merit => TagStyle.green,
                BehaviourKind.concern => TagStyle.amber,
                BehaviourKind.note => TagStyle.neutral,
              }),
              onTap: () => showBehaviourRecordSheet(context, r),
            ),
        if (controller.recordsMayBeTruncated)
          const _Note(key: Key('tb_rec_truncated'), text: 'Showing the latest 50 entries. Older ones are kept by the school.'),
      ],
    ];
  }

  Future<void> _openFilter(BuildContext context) => EmBottomSheet.show<void>(
        context,
        title: 'Filter observations',
        child: _FilterSheet(
          initial: controller.filter.value,
          onApply: (f) {
            Navigator.of(context).pop();
            controller.setFilter(f);
          },
        ),
      );

  static IconData _iconOf(BehaviourKind k) => switch (k) {
        BehaviourKind.merit => Icons.favorite_rounded,
        BehaviourKind.concern => Icons.flag_rounded,
        BehaviourKind.note => Icons.chat_bubble_outline_rounded,
      };

  static Color _colorOf(BehaviourKind k) => switch (k) {
        BehaviourKind.merit => EmColors.success,
        BehaviourKind.concern => EmColors.error,
        BehaviourKind.note => EmColors.textSecondary,
      };

  static TagStyle _ratingStyle(String rating) => switch (rating) {
        'excellent' || 'good' => TagStyle.green,
        'satisfactory' => TagStyle.amber,
        'needs_improvement' || 'critical' => TagStyle.red,
        _ => TagStyle.neutral,
      };
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => AppShimmer(
        child: ListView(
          padding: EmSpacing.listPadding,
          children: [
            const ShimmerScreenIntroSkeleton(),
            const SizedBox(height: EmSpacing.s16),
            const ShimmerHeroCardSkeleton(),
            const SizedBox(height: EmSpacing.s16),
            const ShimmerStatsRowSkeleton(count: 3),
            const SizedBox(height: EmSpacing.s12),
            const ShimmerChartSkeleton(),
            const SizedBox(height: EmSpacing.s16),
            ...shimmerListRows(4),
          ],
        ),
      );
}

class _Note extends StatelessWidget {
  final String text;
  const _Note({super.key, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: EmSpacing.s8),
        child: Text(text, textAlign: TextAlign.center, style: EmType.caption.copyWith(color: EmColors.textSecondary, fontWeight: FontWeight.w400)),
      );
}

/// "Filters" button and one removable chip per active filter.
class _FilterBar extends StatelessWidget {
  final TarbiyahController controller;
  final VoidCallback onOpen;
  const _FilterBar({required this.controller, required this.onOpen});

  @override
  Widget build(BuildContext context) => Obx(() {
        final f = controller.filter.value;
        final chips = <(String, RecordFilter)>[
          if (f.kind != null) (f.kind!.label, f.copyWith(kind: null)),
          if (f.from != null) ('From ${formatDay(f.from!)}', f.copyWith(from: null)),
          if (f.to != null) ('To ${formatDay(f.to!)}', f.copyWith(to: null)),
        ];
        return Padding(
          padding: const EdgeInsets.only(bottom: EmSpacing.s12),
          child: Wrap(spacing: EmSpacing.s8, runSpacing: EmSpacing.s8, crossAxisAlignment: WrapCrossAlignment.center, children: [
            EmChip(key: const Key('tb_filter_btn'), label: f.count == 0 ? 'Filters' : 'Filters (${f.count})', icon: Icons.tune_rounded, selected: f.count > 0, onTap: onOpen),
            for (final (label, without) in chips) EmChip(key: Key('tb_filter_$label'), label: label, icon: Icons.close_rounded, selected: true, onTap: () => controller.setFilter(without)),
            Text('${controller.visibleRecords.length} of ${controller.records.length}', key: const Key('tb_count'), style: EmType.caption.copyWith(color: EmColors.textSecondary)),
          ]),
        );
      });
}

class _FilterSheet extends StatefulWidget {
  final RecordFilter initial;
  final void Function(RecordFilter) onApply;
  const _FilterSheet({required this.initial, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late RecordFilter f = widget.initial;

  Future<void> _pick(bool from) async {
    final today = DateTime.now();
    final day = DateTime(today.year, today.month, today.day);
    final picked = await showAppDatePicker(context, initialDate: (from ? f.from : f.to) ?? day, firstDate: DateTime(day.year - 3), lastDate: day);
    if (picked != null) setState(() => f = from ? f.copyWith(from: picked) : f.copyWith(to: picked));
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(EmSpacing.screenH, 0, EmSpacing.screenH, EmSpacing.s16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Type', style: EmType.label.copyWith(color: EmColors.textSecondary)),
          const SizedBox(height: EmSpacing.s8),
          Wrap(spacing: EmSpacing.s8, runSpacing: EmSpacing.s8, children: [
            for (final k in BehaviourKind.values)
              EmChip(key: Key('tb_f_kind_${k.name}'), label: k.label, selected: f.kind == k, onTap: () => setState(() => f = f.copyWith(kind: f.kind == k ? null : k))),
          ]),
          const SizedBox(height: EmSpacing.s16),
          Text('Date range', style: EmType.label.copyWith(color: EmColors.textSecondary)),
          const SizedBox(height: EmSpacing.s8),
          Row(children: [
            Expanded(child: KeyedSubtree(key: const Key('tb_f_from'), child: EmSelectField(icon: Icons.event_rounded, trailingIcon: null, title: f.from == null ? null : formatDay(f.from!), placeholder: 'From', onTap: () => _pick(true)))),
            const SizedBox(width: EmSpacing.s8),
            Expanded(child: KeyedSubtree(key: const Key('tb_f_to'), child: EmSelectField(icon: Icons.event_rounded, trailingIcon: null, title: f.to == null ? null : formatDay(f.to!), placeholder: 'To', onTap: () => _pick(false)))),
          ]),
          const SizedBox(height: EmSpacing.s24),
          EmPrimaryButton(key: const Key('tb_f_apply'), label: 'Apply filters', onPressed: () => widget.onApply(f)),
          const SizedBox(height: EmSpacing.s8),
          EmTextAction(key: const Key('tb_f_clear'), onPressed: () => widget.onApply(RecordFilter.none), icon: Icons.filter_alt_off_outlined, label: 'Clear filters'),
        ]),
      );
}
