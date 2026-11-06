import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../../core/design/design.dart';
import '../../../../core/models/qaida_models.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/hero_card.dart';
import '../controllers/quran_progress_controller.dart';

/// The Qaida & Tajweed part of the Qur'an progress screen: the child's Noorani Qaida progress through the 16 takhtis, the same facts as
/// the school's printed report (overview, the 16-takhti journey, detailed breakdown of the boards worked on, recurring areas needing
/// attention) plus the report as a PDF. Nothing is invented.
List<Widget> qaidaSection(QuranProgressController controller, QaidaReport r) {
  final current = r.currentTakhti > 0 ? 'Currently on Takhti ${r.currentTakhti}' : r.overallLabel;
  return [
    HeroCard(
      kicker: 'Qaida & Tajweed · takhtis mastered',
      value: '${r.mastered}/${r.total}',
      trend: current,
      percent: r.masteryPct,
      metrics: [
        ('${r.masteryPct}%', 'Mastery'),
        ('${r.needsRevision}', 'Needs revision'),
        ('${r.started.length}', 'Boards started'),
      ],
      metricIcons: const [Icons.percent_rounded, Icons.replay_rounded, Icons.flag_outlined],
    ),
    const SizedBox(height: EmSpacing.s12),
    Obx(() => EmSecondaryButton(
          key: const Key('qaida_pdf'),
          label: 'Download report (PDF)',
          icon: Icons.picture_as_pdf_outlined,
          expand: true,
          loading: controller.downloading.value,
          onPressed: controller.openQaidaPdf,
        )),
    if (r.currentTeacher.isNotEmpty) ...[
      const SizedBox(height: EmSpacing.s8),
      Text('Qaida teacher: ${r.currentTeacher}', style: EmType.caption.copyWith(color: EmColors.textSecondary)),
    ],
    const SizedBox(height: EmSpacing.s16),
    const SectionRow(title: 'The 16-takhti journey'),
    AppCard(child: _Journey(takhtis: r.takhtis)),
    if (r.started.isNotEmpty) ...[
      const SectionRow(title: 'Detailed breakdown'),
      for (final t in r.started) _TakhtiTile(takhti: t),
      if (r.notStarted > 0)
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: EmSpacing.s12),
          child: Text('${r.notStarted} more ${r.notStarted == 1 ? 'takhti is' : 'takhtis are'} not started yet.',
              style: EmType.caption.copyWith(color: EmColors.textSecondary)),
        ),
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

EmTone _tone(QaidaStatus s) => switch (s) {
      QaidaStatus.mastered => EmTone.success,
      QaidaStatus.needsRevision => EmTone.warning,
      QaidaStatus.inProgress => EmTone.info,
      QaidaStatus.notStarted || QaidaStatus.notTracked => EmTone.neutral,
    };

/// The 16 boards as a grid of numbered tiles coloured by status, with a legend.
class _Journey extends StatelessWidget {
  final List<QaidaTakhti> takhtis;
  const _Journey({required this.takhtis});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: EmSpacing.s8,
        crossAxisSpacing: EmSpacing.s8,
        childAspectRatio: 1.1,
        children: [
          for (final t in takhtis)
            Semantics(
              label: 'Takhti ${t.number}, ${t.titleEn}, ${t.status.label}',
              excludeSemantics: true,
              child: DecoratedBox(
                key: Key('takhti_${t.number}'),
                decoration: BoxDecoration(color: _tone(t.status).background, borderRadius: EmRadius.controlAll),
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(EmSpacing.s4),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('${t.number}', style: EmType.value.copyWith(color: _tone(t.status).foreground)),
                    // scale a long board name down to fit one line instead of breaking it mid-word
                    FittedBox(fit: BoxFit.scaleDown, child: Text(t.titleEn, maxLines: 1, style: EmType.caption.copyWith(color: _tone(t.status).foreground))),
                  ]),
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: EmSpacing.s12),
      Wrap(spacing: EmSpacing.s8, runSpacing: EmSpacing.s8, children: [
        for (final s in [QaidaStatus.mastered, QaidaStatus.inProgress, QaidaStatus.needsRevision, QaidaStatus.notStarted])
          EmChip.status(label: s.label, tone: _tone(s)),
      ]),
    ]);
  }
}

/// One board the teacher has worked on: status, dates, attempts, latest remarks; expands to the lesson (sabaq) log and the ratings.
class _TakhtiTile extends StatelessWidget {
  final QaidaTakhti takhti;
  const _TakhtiTile({required this.takhti});

  static String _day(DateTime d) => DateFormat('d MMM yyyy').format(d.toLocal());

  @override
  Widget build(BuildContext context) {
    final t = takhti;
    final latest = t.latest;
    final meta = [
      if (t.started != null) 'Started ${_day(t.started!)}',
      if (t.mastered != null) 'Mastered ${_day(t.mastered!)}',
      '${t.attempts} ${t.attempts == 1 ? 'attempt' : 'attempts'}',
    ].join(' · ');
    final ratings = [
      if (latest?.makhraj != null) 'Makhraj ${latest!.makhraj}/5',
      if (latest?.tajweed != null) 'Tajweed ${latest!.tajweed}/5',
      if (latest?.fluency != null) 'Fluency ${latest!.fluency}/5',
    ];
    final hasMore = t.sabaqLog.isNotEmpty || (latest?.remarks.isNotEmpty ?? false) || ratings.isNotEmpty || (latest?.errors.isNotEmpty ?? false);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: Key('takhti_tile_${t.number}'),
          tilePadding: const EdgeInsetsDirectional.symmetric(horizontal: EmSpacing.block),
          childrenPadding: const EdgeInsetsDirectional.fromSTEB(EmSpacing.block, 0, EmSpacing.block, EmSpacing.block),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: Row(children: [
            Expanded(child: Text('${t.number}. ${t.titleEn}', maxLines: 2, overflow: TextOverflow.ellipsis, style: EmType.body.copyWith(color: EmColors.ink))),
            if (t.titleUr.isNotEmpty) Text(t.titleUr, textDirection: TextDirection.rtl, style: EmType.caption.copyWith(color: EmColors.textSecondary)),
          ]),
          subtitle: Padding(
            padding: const EdgeInsetsDirectional.only(top: EmSpacing.s4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              EmChip.status(label: t.status.label, tone: _tone(t.status)),
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
                  if (latest != null && latest.errors.isNotEmpty) ...[
                    Wrap(spacing: EmSpacing.s8, runSpacing: EmSpacing.s4, children: [
                      for (final e in latest.errors) EmChip.status(label: qaidaErrorLabel(e), tone: EmTone.warning),
                    ]),
                    const SizedBox(height: EmSpacing.s8),
                  ],
                  if (t.sabaqLog.isNotEmpty) ...[
                    Text('Lesson log', style: EmType.caption.copyWith(color: EmColors.textSecondary)),
                    for (final s in t.sabaqLog)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: EmSpacing.s4),
                        child: Row(children: [
                          Expanded(
                            child: Text([if (s.date != null) _day(s.date!), if (s.range.isNotEmpty) s.range].join(' · '),
                                style: EmType.bodyRegular.copyWith(color: EmColors.ink)),
                          ),
                          if (s.rating.isNotEmpty) Text(qaidaRatingLabel(s.rating), style: EmType.caption.copyWith(color: EmColors.textSecondary)),
                        ]),
                      ),
                  ],
                ]
              : const [],
        ),
      ),
    );
  }
}
