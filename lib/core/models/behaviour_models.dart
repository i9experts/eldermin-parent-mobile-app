// Behaviour & Tarbiyah as the parent portal sends them (`GET /parent-portal/students/:id/behaviour`, backend
// parent-portal.service.ts getBehaviourAndTarbiyah + parent-behaviour.projection.ts: an explicit allowlist, so any field may be
// absent today or later). Everything here parses defensively: a missing, null or wrongly typed field becomes a neutral default and
// never throws.

String _text(Object? v) {
  if (v == null) return '';
  final s = v.toString().trim();
  return s == 'null' ? '' : s;
}

num? _num(Object? v) => v is num ? v : num.tryParse(_text(v));

DateTime? _date(Object? v) => DateTime.tryParse(_text(v));

List<String> _strings(Object? v) => v is List ? [for (final e in v) if (_text(e).isNotEmpty) _text(e)] : const [];

Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};

List<Map<String, dynamic>> _maps(Object? v) => v is List ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)] : const [];

/// "Merit / concern / note" of a record.
enum BehaviourKind {
  merit('Merit'),
  concern('Concern'),
  note('Note');

  final String label;
  const BehaviourKind(this.label);
}

const Map<String, String> _categoryLabels = {
  'academic_excellence': 'Academic excellence',
  'helping_others': 'Helping others',
  'leadership': 'Leadership',
  'good_conduct': 'Good conduct',
  'community_service': 'Community service',
  'innovation': 'Innovation',
  'sportsmanship': 'Sportsmanship',
  'attendance_excellence': 'Perfect attendance',
  'moral_courage': 'Moral courage',
  'misconduct': 'Misconduct',
  'bullying': 'Bullying',
  'cheating': 'Cheating',
  'dishonesty': 'Dishonesty',
  'disrespect': 'Disrespect',
  'property_damage': 'Property damage',
  'late_coming': 'Late coming',
  'uniform_violation': 'Uniform violation',
  'phone_misuse': 'Phone misuse',
  'absenteeism': 'Absenteeism',
  'fighting': 'Fighting',
  'harassment': 'Harassment',
  'vandalism': 'Vandalism',
  'counselling_referral': 'Counselling referral',
  'parent_meeting': 'Parent meeting',
  'warning_issued': 'Warning issued',
  'behaviour_contract': 'Behaviour contract',
  'restorative_practice': 'Restorative practice',
};

/// "helping_others" -> "Helping others" (a readable form for a category this app version does not know).
String categoryLabel(String wire) {
  if (wire.isEmpty) return '';
  return _categoryLabels[wire] ?? wire[0].toUpperCase() + wire.substring(1).replaceAll('_', ' ');
}

class ParentBehaviourRecord {
  final String id;
  final DateTime? date;
  final String typeWire;
  final String category;
  final String title;
  final String description;
  final int points;
  final String actionTaken;

  /// 'teacher_note' for a note a teacher flagged to the parents (other store), else ''.
  final String source;

  const ParentBehaviourRecord({
    this.id = '',
    this.date,
    this.typeWire = '',
    this.category = '',
    this.title = '',
    this.description = '',
    this.points = 0,
    this.actionTaken = '',
    this.source = '',
  });

  factory ParentBehaviourRecord.fromJson(Object? raw) {
    final j = _map(raw);
    return ParentBehaviourRecord(
      id: _text(j['_id'] ?? j['id']),
      date: _date(j['date']),
      typeWire: _text(j['type']),
      category: _text(j['category']),
      title: _text(j['title']),
      description: _text(j['description']),
      points: _num(j['points'])?.round() ?? 0,
      actionTaken: _text(j['actionTaken']),
      source: _text(j['source']),
    );
  }

  /// By the `type` the school recorded; without one, by the sign of the points (positive = merit, negative = concern, zero = note).
  BehaviourKind get kind {
    switch (typeWire) {
      case 'positive':
        return BehaviourKind.merit;
      case 'negative':
        return BehaviourKind.concern;
      case 'neutral':
        return BehaviourKind.note;
    }
    return points > 0 ? BehaviourKind.merit : (points < 0 ? BehaviourKind.concern : BehaviourKind.note);
  }

  /// The title, else the category, else a generic word: never blank.
  String get displayTitle => title.isNotEmpty ? title : (categoryLabel(category).isNotEmpty ? categoryLabel(category) : 'Observation');
}

class TraitResult {
  final String key;
  final String name;
  final int percentage;
  final double? score;
  final String observation;
  const TraitResult({this.key = '', this.name = '', this.percentage = 0, this.score, this.observation = ''});

  factory TraitResult.fromJson(Object? raw) {
    final j = _map(raw);
    final key = _text(j['traitKey']);
    return TraitResult(
      key: key,
      name: _text(j['traitName']).isNotEmpty ? _text(j['traitName']) : _readableKey(key),
      percentage: (_num(j['percentage']) ?? 0).round().clamp(0, 100),
      score: _num(j['score'])?.toDouble(),
      observation: _text(j['observation']),
    );
  }

  static String _readableKey(String key) {
    if (key.isEmpty) return 'Trait';
    final spaced = key.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(1)}').replaceAll('_', ' ').trim();
    return spaced[0].toUpperCase() + spaced.substring(1);
  }
}

class TarbiyahReport {
  final String id;
  final String period;
  final String periodType;
  final DateTime? assessmentDate;
  final List<TraitResult> traits;
  final int? overallPercentage;
  final double? overallScore;
  final String overallRating;
  final String teacherObservations;
  final List<String> areasOfStrength;
  final List<String> areasForImprovement;
  final String recommendedActions;
  final String programName;
  final int? scaleMax;

  const TarbiyahReport({
    this.id = '',
    this.period = '',
    this.periodType = '',
    this.assessmentDate,
    this.traits = const [],
    this.overallPercentage,
    this.overallScore,
    this.overallRating = '',
    this.teacherObservations = '',
    this.areasOfStrength = const [],
    this.areasForImprovement = const [],
    this.recommendedActions = '',
    this.programName = '',
    this.scaleMax,
  });

  factory TarbiyahReport.fromJson(Object? raw) {
    final j = _map(raw);
    return TarbiyahReport(
      id: _text(j['_id'] ?? j['id']),
      period: _text(j['period']),
      periodType: _text(j['periodType']),
      assessmentDate: _date(j['assessmentDate']),
      traits: [for (final t in _maps(j['traits'])) TraitResult.fromJson(t)],
      overallPercentage: _num(j['overallPercentage'])?.round().clamp(0, 100),
      overallScore: _num(j['overallScore'])?.toDouble(),
      overallRating: _text(j['overallRating']),
      teacherObservations: _text(j['teacherObservations']),
      areasOfStrength: _strings(j['areasOfStrength']),
      areasForImprovement: _strings(j['areasForImprovement']),
      recommendedActions: _text(j['recommendedActions']),
      programName: _text(j['programName']),
      scaleMax: _num(_map(j['ratingScale'])['max'])?.round(),
    );
  }

  /// "Term 1", else the period type, else "Assessment".
  String get displayPeriod => period.isNotEmpty ? period : (periodType.isNotEmpty ? '${periodType[0].toUpperCase()}${periodType.substring(1)} assessment' : 'Assessment');

  String get ratingLabel {
    switch (overallRating) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'satisfactory':
        return 'Satisfactory';
      case 'needs_improvement':
        return 'Needs improvement';
      case 'critical':
        return 'Needs support';
    }
    return overallRating.isEmpty ? '' : overallRating[0].toUpperCase() + overallRating.substring(1).replaceAll('_', ' ');
  }

  bool get hasAnyContent => traits.isNotEmpty || overallPercentage != null || teacherObservations.isNotEmpty || areasOfStrength.isNotEmpty || areasForImprovement.isNotEmpty || recommendedActions.isNotEmpty;
}

/// A whole answer of the endpoint, parsed: records newest first, assessments newest first.
class BehaviourAndTarbiyah {
  final List<ParentBehaviourRecord> records;
  final List<TarbiyahReport> assessments;
  const BehaviourAndTarbiyah({this.records = const [], this.assessments = const []});

  factory BehaviourAndTarbiyah.fromJson(Object? raw) {
    final j = _map(raw);
    final rs = [for (final r in (j['behaviourRecords'] is List ? j['behaviourRecords'] as List : const [])) ParentBehaviourRecord.fromJson(r)];
    final ts = [for (final a in (j['tarbiyahAssessments'] is List ? j['tarbiyahAssessments'] as List : const [])) TarbiyahReport.fromJson(a)];
    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    rs.sort((a, b) => (b.date ?? epoch).compareTo(a.date ?? epoch));
    ts.sort((a, b) => (b.assessmentDate ?? epoch).compareTo(a.assessmentDate ?? epoch));
    return BehaviourAndTarbiyah(records: rs, assessments: ts);
  }
}

/// The server sends at most this many records (parent-portal.service.ts `.limit(50)`) and 20 assessments. When the list is exactly that long
/// there may be older ones the endpoint cannot return: the screen says so instead of silently dropping them.
const int kParentRecordsServerLimit = 50;
const int kParentAssessmentsServerLimit = 20;

/// Filters of the record list: kind (merit / concern / note) and an inclusive date range (calendar days).
class RecordFilter {
  final BehaviourKind? kind;
  final DateTime? from;
  final DateTime? to;
  const RecordFilter({this.kind, this.from, this.to});

  static const none = RecordFilter();

  bool get isActive => kind != null || from != null || to != null;
  int get count => [kind, from, to].where((e) => e != null).length;

  RecordFilter copyWith({Object? kind = _keep, Object? from = _keep, Object? to = _keep}) => RecordFilter(
        kind: identical(kind, _keep) ? this.kind : kind as BehaviourKind?,
        from: identical(from, _keep) ? this.from : from as DateTime?,
        to: identical(to, _keep) ? this.to : to as DateTime?,
      );

  /// A record without a date never passes a date filter (it cannot be placed in the range).
  bool accepts(ParentBehaviourRecord r) {
    if (kind != null && r.kind != kind) return false;
    if (from != null || to != null) {
      final d = r.date;
      if (d == null) return false;
      final day = DateTime.utc(d.toUtc().year, d.toUtc().month, d.toUtc().day);
      if (from != null && day.isBefore(DateTime.utc(from!.year, from!.month, from!.day))) return false;
      if (to != null && day.isAfter(DateTime.utc(to!.year, to!.month, to!.day))) return false;
    }
    return true;
  }
}

const Object _keep = Object();
