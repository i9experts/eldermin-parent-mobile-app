import 'package:flutter/material.dart';
import '../../../../core/design/design.dart';
import '../../../../core/models/behaviour_models.dart';
import '../../../../core/utils/detail_format.dart';
import '../../../../core/widgets/detail_bottom_sheet.dart';

EmTone toneOfKind(BehaviourKind k) => switch (k) {
      BehaviourKind.merit => EmTone.success,
      BehaviourKind.concern => EmTone.warning,
      BehaviourKind.note => EmTone.neutral,
    };

String pointsText(int p) => p > 0 ? '+$p' : '$p';

/// Opens one behaviour record (everything the school shares: date, category, points, description, action taken).
Future<void> showBehaviourRecordSheet(BuildContext context, ParentBehaviourRecord r) =>
    DetailBottomSheet.show<void>(context, data: () => recordSheetData(r));

/// What the record sheet shows. A field the server did not send is simply not shown.
DetailSheetData recordSheetData(ParentBehaviourRecord r) => DetailSheetData(
      title: r.displayTitle,
      statusLabel: r.kind.label,
      statusTone: toneOfKind(r.kind),
      fields: [
        DetailField('Date', formatDayOf(r.date?.toIso8601String(), utcDay: true)),
        DetailField('Category', categoryLabel(r.category)),
        DetailField('Points', r.points == 0 ? null : pointsText(r.points)),
        DetailField('Action taken', r.actionTaken),
      ],
      longTextLabel: 'Details',
      longText: r.description,
    );

/// Opens one Tarbiyah assessment: score, every trait, strengths, observations, areas to improve, recommended actions.
Future<void> showAssessmentSheet(BuildContext context, TarbiyahReport a) =>
    DetailBottomSheet.show<void>(context, data: () => assessmentSheetData(a));

DetailSheetData assessmentSheetData(TarbiyahReport a) {
  final tone = switch (a.overallRating) {
    'excellent' || 'good' => EmTone.success,
    'satisfactory' => EmTone.warning,
    'needs_improvement' || 'critical' => EmTone.error,
    _ => EmTone.neutral,
  };
  String? score(double? s) => s == null ? null : (s == s.roundToDouble() ? s.toStringAsFixed(0) : s.toStringAsFixed(1));
  final overall = [
    if (a.overallPercentage != null) '${a.overallPercentage}%',
    if (a.overallScore != null) 'score ${score(a.overallScore)}${a.scaleMax != null ? ' of ${a.scaleMax}' : ''}',
  ].join(' · ');
  return DetailSheetData(
    title: a.displayPeriod,
    statusLabel: a.ratingLabel.isEmpty ? null : a.ratingLabel,
    statusTone: tone,
    fields: [
      DetailField('Programme', a.programName),
      DetailField('Date', formatDayOf(a.assessmentDate?.toIso8601String(), utcDay: true)),
      DetailField('Overall', overall),
    ],
    sections: [
      DetailSection('Character traits', [
        for (final t in a.traits) DetailField(t.name, '${t.percentage}%${t.observation.isEmpty ? '' : ' · ${t.observation}'}'),
      ]),
      DetailSection('Areas of strength', [for (final s in a.areasOfStrength) DetailField('•', s)]),
      DetailSection('Areas to improve', [for (final s in a.areasForImprovement) DetailField('•', s)]),
      DetailSection('Recommended actions', [DetailField('•', a.recommendedActions)]),
    ],
    longTextLabel: 'Teacher observations',
    longText: a.teacherObservations,
  );
}
