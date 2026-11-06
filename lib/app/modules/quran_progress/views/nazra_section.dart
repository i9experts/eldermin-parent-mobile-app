import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/design/design.dart';
import '../../../../core/models/nazra_models.dart';
import '../../../../core/models/qaida_models.dart' show qaidaErrorLabel;
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/hero_card.dart';

/// How many diary days are listed before the "latest N of M" note (the server already caps and sorts newest first).
const int kNazraDiaryShown = 15;

EmTone _paraTone(NazraStatus s) => switch (s) {
      NazraStatus.completed => EmTone.success,
      NazraStatus.needsRevision => EmTone.warning,
      NazraStatus.inProgress => EmTone.info,
      NazraStatus.notStarted || NazraStatus.notTracked => EmTone.neutral,
    };

String _day(DateTime d) => DateFormat('d MMM yyyy').format(d.toLocal());

/// The Nazra (Qur'an reading) part of the Qur'an progress screen: overview, the 30-para journey, the daily Sabaq / Sabqi / Manzil diary
/// (newest first), the paras worked on, recurring areas needing attention and the teacher's remarks. Nothing is invented.
List<Widget> nazraSection(NazraReport r) {
  final current = r.currentPara > 0 ? 'Currently on ${r.paraName(r.currentPara)}' : r.overallLabel;
  final diary = r.diary.take(kNazraDiaryShown).toList();
  return [
    HeroCard(
      kicker: 'Nazra · paras completed',
      value: '${r.completed}/${r.total}',
      trend: current,
      percent: r.completionPct,
      metrics: [
        ('${r.completionPct}%', 'Complete'),
        ('${r.needsRevision}', 'Needs revision'),
        ('${r.started.length}', 'Paras started'),
      ],
      metricIcons: const [Icons.percent_rounded, Icons.replay_rounded, Icons.flag_outlined],
    ),
    if (r.currentTeacher.isNotEmpty) ...[
      const SizedBox(height: EmSpacing.s8),
      Text('Nazra teacher: ${r.currentTeacher}', style: EmType.caption.copyWith(color: EmColors.textSecondary)),
    ],
    const SizedBox(height: EmSpacing.s16),
    const SectionRow(title: 'The 30-para journey'),
    AppCard(child: _ParaGrid(paras: r.paras)),
    if (diary.isNotEmpty) ...[
      const SectionRow(title: 'Daily diary'),
      for (final (i, e) in diary.indexed) _DiaryTile(index: i, entry: e, report: r),
      if (r.diaryTotal > diary.length)
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s12),
          child: Text('Showing the latest ${diary.length} of ${r.diaryTotal} diary days.', style: EmType.caption.copyWith(color: EmColors.textSecondary)),
        ),
    ],
    if (r.started.isNotEmpty) ...[
      const SectionRow(title: 'Paras worked on'),
      for (final p in r.started) _ParaTile(para: p),
    ],
    if (r.commonErrors.isNotEmpty) ...[
      const SectionRow(title: 'Areas needing attention'),
      AppCard(
        child: Wrap(spacing: EmSpacing.s8, runSpacing: EmSpacing.s8, children: [
          for (final e in r.commonErrors) EmChip.status(label: '${e.label} ×${e.count}', tone: EmTone.warning),
        ]),
      ),
    ],
    if (r.overallRemarks.isNotEmpty) ...[
      const SectionRow(title: 'Teacher remarks'),
      AppCard(child: Text(r.overallRemarks, style: EmType.body.copyWith(color: EmColors.ink))),
    ],
  ];
}

/// The 30 paras as numbered tiles coloured by status, with a legend.
class _ParaGrid extends StatelessWidget {
  final List<NazraPara> paras;
  const _ParaGrid({required this.paras});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 6,
        mainAxisSpacing: EmSpacing.s8,
        crossAxisSpacing: EmSpacing.s8,
        children: [
          for (final p in paras)
            Semantics(
              label: 'Para ${p.number}, ${p.titleEn}, ${p.status.label}',
              excludeSemantics: true,
              child: DecoratedBox(
                key: Key('para_${p.number}'),
                decoration: BoxDecoration(color: _paraTone(p.status).background, borderRadius: EmRadius.controlAll),
                child: Center(child: Text('${p.number}', style: EmType.label.copyWith(color: _paraTone(p.status).foreground))),
              ),
            ),
        ],
      ),
      const SizedBox(height: EmSpacing.s12),
      Wrap(spacing: EmSpacing.s8, runSpacing: EmSpacing.s8, children: [
        for (final s in [NazraStatus.completed, NazraStatus.inProgress, NazraStatus.needsRevision, NazraStatus.notStarted])
          EmChip.status(label: s.label, tone: _paraTone(s)),
      ]),
    ]);
  }
}

String _partLine(String label, NazraLessonPart? p, NazraReport r) {
  if (p == null) return '';
  final bits = [
    if (p.para != null) r.paraName(p.para),
    if (p.pages.isNotEmpty) p.pages,
    if (p.rating.isNotEmpty) nazraRatingLabel(p.rating),
  ];
  return bits.isEmpty ? label : '$label: ${bits.join(' · ')}';
}

/// One diary day: the new lesson (sabaq) and the revisions (sabqi, manzil); expands to ratings, errors and remarks.
class _DiaryTile extends StatelessWidget {
  final int index;
  final NazraDiaryEntry entry;
  final NazraReport report;
  const _DiaryTile({required this.index, required this.entry, required this.report});

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final lines = [_partLine('Sabaq', e.sabaq, report), _partLine('Sabqi', e.sabqi, report), _partLine('Manzil', e.manzil, report)].where((l) => l.isNotEmpty).toList();
    final ratings = [
      if (e.sabaq?.makhraj != null) 'Makhraj ${e.sabaq!.makhraj}/5',
      if (e.sabaq?.tajweed != null) 'Tajweed ${e.sabaq!.tajweed}/5',
      if (e.sabaq?.fluency != null) 'Fluency ${e.sabaq!.fluency}/5',
    ];
    final errors = {...?e.sabaq?.errors, ...?e.sabqi?.errors, ...?e.manzil?.errors};
    final remarks = [
      if ((e.sabaq?.remarks ?? '').isNotEmpty) e.sabaq!.remarks,
      if ((e.sabqi?.remarks ?? '').isNotEmpty) 'Sabqi: ${e.sabqi!.remarks}',
      if ((e.manzil?.remarks ?? '').isNotEmpty) 'Manzil: ${e.manzil!.remarks}',
    ];
    final hasMore = ratings.isNotEmpty || errors.isNotEmpty || remarks.isNotEmpty;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('diary_$index'),
          tilePadding: const EdgeInsetsDirectional.symmetric(horizontal: EmSpacing.block),
          childrenPadding: const EdgeInsetsDirectional.fromSTEB(EmSpacing.block, 0, EmSpacing.block, EmSpacing.block),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Text(e.date == null ? 'Diary entry' : _day(e.date!), style: EmType.body.copyWith(color: EmColors.ink)),
          subtitle: Padding(
            padding: const EdgeInsetsDirectional.only(top: EmSpacing.s4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              for (final l in lines) Text(l, style: EmType.caption.copyWith(color: EmColors.textSecondary)),
            ]),
          ),
          children: hasMore
              ? [
                  if (ratings.isNotEmpty) Text(ratings.join(' · '), style: EmType.caption.copyWith(color: EmColors.textSecondary)),
                  if (errors.isNotEmpty) ...[
                    const SizedBox(height: EmSpacing.s8),
                    Wrap(spacing: EmSpacing.s8, runSpacing: EmSpacing.s4, children: [
                      for (final x in errors) EmChip.status(label: qaidaErrorLabel(x), tone: EmTone.warning),
                    ]),
                  ],
                  for (final rm in remarks) ...[
                    const SizedBox(height: EmSpacing.s8),
                    Text(rm, style: EmType.body.copyWith(color: EmColors.ink)),
                  ],
                ]
              : const [],
        ),
      ),
    );
  }
}

/// One para the teacher has worked on: status, dates, attempts, latest remarks.
class _ParaTile extends StatelessWidget {
  final NazraPara para;
  const _ParaTile({required this.para});

  @override
  Widget build(BuildContext context) {
    final p = para;
    final latest = p.latest;
    final meta = [
      if (p.started != null) 'Started ${_day(p.started!)}',
      if (p.completed != null) 'Completed ${_day(p.completed!)}',
      '${p.attempts} ${p.attempts == 1 ? 'attempt' : 'attempts'}',
    ].join(' · ');
    final ratings = [
      if (latest?.makhraj != null) 'Makhraj ${latest!.makhraj}/5',
      if (latest?.tajweed != null) 'Tajweed ${latest!.tajweed}/5',
      if (latest?.fluency != null) 'Fluency ${latest!.fluency}/5',
    ];
    final hasMore = (latest?.remarks.isNotEmpty ?? false) || ratings.isNotEmpty || (latest?.errors.isNotEmpty ?? false);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('para_tile_${p.number}'),
          tilePadding: const EdgeInsetsDirectional.symmetric(horizontal: EmSpacing.block),
          childrenPadding: const EdgeInsetsDirectional.fromSTEB(EmSpacing.block, 0, EmSpacing.block, EmSpacing.block),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Row(children: [
            Expanded(child: Text('Para ${p.number}${p.titleEn.isEmpty ? '' : ' · ${p.titleEn}'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: EmType.body.copyWith(color: EmColors.ink))),
            if (p.titleAr.isNotEmpty) Text(p.titleAr, textDirection: TextDirection.rtl, style: EmType.caption.copyWith(color: EmColors.textSecondary)),
          ]),
          subtitle: Padding(
            padding: const EdgeInsetsDirectional.only(top: EmSpacing.s4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EmChip.status(label: p.status.label, tone: _paraTone(p.status)),
              const SizedBox(height: EmSpacing.s4),
              Text(meta, style: EmType.caption.copyWith(color: EmColors.textSecondary)),
            ]),
          ),
          children: hasMore
              ? [
                  if (latest != null && latest.remarks.isNotEmpty) ...[
                    Text('Latest remarks', style: EmType.caption.copyWith(color: EmColors.textSecondary)),
                    Text(latest.remarks, style: EmType.body.copyWith(color: EmColors.ink)),
                    const SizedBox(height: EmSpacing.s8),
                  ],
                  if (ratings.isNotEmpty) ...[
                    Text(ratings.join(' · '), style: EmType.caption.copyWith(color: EmColors.textSecondary)),
                    const SizedBox(height: EmSpacing.s8),
                  ],
                  if (latest != null && latest.errors.isNotEmpty)
                    Wrap(spacing: EmSpacing.s8, runSpacing: EmSpacing.s4, children: [
                      for (final x in latest.errors) EmChip.status(label: qaidaErrorLabel(x), tone: EmTone.warning),
                    ]),
                ]
              : const [],
        ),
      ),
    );
  }
}
