// Qaida & Tajweed progress as the parent portal sends it (`GET /parent-portal/students/:id/qaida`, backend parent-qaida.projection.ts: an
// explicit allowlist, so any field may be absent). Parses defensively: a missing, null or wrongly typed field becomes a neutral default
// and never throws.

String _text(Object? v) {
  if (v == null) return '';
  final s = v.toString().trim();
  return s == 'null' ? '' : s;
}

int _int(Object? v) => v is num ? v.toInt() : (int.tryParse(_text(v)) ?? 0);

num? _num(Object? v) => v is num ? v : num.tryParse(_text(v));

DateTime? _date(Object? v) => DateTime.tryParse(_text(v));

Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};

List<Map<String, dynamic>> _maps(Object? v) => v is List ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)] : const [];

List<String> _strings(Object? v) => v is List ? [for (final e in v) if (_text(e).isNotEmpty) _text(e)] : const [];

/// Where a takhti (board) stands for the child.
enum QaidaStatus {
  mastered('Mastered'),
  needsRevision('Needs revision'),
  inProgress('In progress'),
  notStarted('Not started'),
  notTracked('Not tracked');

  final String label;
  const QaidaStatus(this.label);

  static QaidaStatus parse(Object? v) => switch (_text(v)) {
        'mastered' => QaidaStatus.mastered,
        'needs_revision' => QaidaStatus.needsRevision,
        'in_progress' => QaidaStatus.inProgress,
        'not_tracked' => QaidaStatus.notTracked,
        _ => QaidaStatus.notStarted,
      };

  /// A board the teacher has actually worked on with the child (listed in the detailed breakdown).
  bool get isStarted => this == mastered || this == needsRevision || this == inProgress;
}

String qaidaRatingLabel(String rating) => switch (rating) {
      'needs_practice' => 'Needs practice',
      'developing' => 'Developing',
      'proficient' => 'Proficient',
      'mastered' => 'Mastered',
      _ => rating.isEmpty ? '' : _humanize(rating),
    };

const Map<String, String> _errorLabels = {
  'makhraj_confusion': 'Makhraj confusion (similar-sounding letters)',
  'missed_ghunna': 'Ghunna (nasalization) missed',
  'madd_too_short': 'Madd (elongation) held too short',
  'madd_too_long': 'Madd (elongation) held too long',
  'tashdeed_not_doubled': 'Tashdeed (doubling) not applied',
  'waqf_ignored': 'Waqf (stop sign) ignored',
  'tanween_as_noon': 'Tanween read as noon',
  'letter_shape_misread': 'Letter shape misread when joined',
  // Nazra adds a few of its own tags
  'qalqalah_missed': 'Qalqalah missed',
  'idgham_missed': 'Idgham missed',
  'ikhfa_missed': 'Ikhfa missed',
  'izhar_missed': 'Izhar missed',
  'iqlab_missed': 'Iqlab missed',
  'fluency_too_slow': 'Reading too slowly',
  'word_misread': 'Word misread',
};

String qaidaErrorLabel(String key) => _errorLabels[key] ?? _humanize(key);

String _humanize(String key) {
  final s = key.replaceAll('_', ' ').trim();
  return s.isEmpty ? '' : '${s[0].toUpperCase()}${s.substring(1)}';
}

class QaidaSabaq {
  final DateTime? date;
  final String from;
  final String to;
  final String rating;
  QaidaSabaq.fromJson(Map<String, dynamic> j)
      : date = _date(j['date']),
        from = _text(j['sabaqFrom']),
        to = _text(j['sabaqTo']),
        rating = _text(j['rating']);

  /// "Alif to Kaf", "Alif", or '' when the teacher recorded no range.
  String get range => from.isEmpty ? '' : (to.isEmpty || to == from ? from : '$from to $to');
}

class QaidaAttempt {
  final DateTime? date;
  final String rating;
  final int? makhraj;
  final int? tajweed;
  final int? fluency;
  final List<String> errors;
  final String remarks;
  QaidaAttempt.fromJson(Map<String, dynamic> j)
      : date = _date(j['date']),
        rating = _text(j['rating']),
        makhraj = _num(j['makhrajAccuracy'])?.toInt(),
        tajweed = _num(j['tajweedAccuracy'])?.toInt(),
        fluency = _num(j['fluency'])?.toInt(),
        errors = _strings(j['errorsNoted']),
        remarks = _text(j['remarks']);
}

class QaidaTakhti {
  final int number;
  final String titleEn;
  final String titleUr;
  final String pageReference;
  final QaidaStatus status;
  final DateTime? started;
  final DateTime? mastered;
  final int revisionCount;
  final int attempts;
  final List<QaidaSabaq> sabaqLog;
  final QaidaAttempt? latest;

  QaidaTakhti.fromJson(Map<String, dynamic> j)
      : number = _int(j['number']),
        titleEn = _text(j['titleEn']),
        titleUr = _text(j['titleUr']),
        pageReference = _text(j['pageReference']),
        status = QaidaStatus.parse(j['status']),
        started = _date(j['startedDate']),
        mastered = _date(j['masteredDate']),
        revisionCount = _int(j['revisionCount']),
        attempts = _int(j['attemptCount']),
        sabaqLog = [for (final s in _maps(j['sabaqLog'])) QaidaSabaq.fromJson(s)],
        latest = j['latestAttempt'] is Map ? QaidaAttempt.fromJson(_map(j['latestAttempt'])) : null;
}

class QaidaError {
  final String key;
  final int count;
  QaidaError.fromJson(Map<String, dynamic> j)
      : key = _text(j['error']),
        count = _int(j['count']);
  String get label => qaidaErrorLabel(key);
}

class QaidaReport {
  final String studentName;
  final int currentTakhti;
  final String overallStatus;
  final int mastered;
  final int total;
  final int tracked;
  final int masteryPct;
  final String currentTeacher;
  final String overallRemarks;
  final List<QaidaTakhti> takhtis;
  final List<QaidaError> commonErrors;

  QaidaReport.fromJson(Map<String, dynamic> j)
      : studentName = _text(j['studentName']),
        currentTakhti = _int(j['currentTakhti']),
        overallStatus = _text(j['overallStatus']),
        mastered = _int(j['masteredCount']),
        total = _int(j['totalTakhtis']) == 0 ? 16 : _int(j['totalTakhtis']),
        tracked = _int(j['trackedTakhtis']),
        masteryPct = _int(j['masteryPct']),
        currentTeacher = _text(j['currentTeacher']),
        overallRemarks = _text(j['overallRemarks']),
        takhtis = [for (final t in _maps(j['takhtis'])) QaidaTakhti.fromJson(t)]..sort((a, b) => a.number.compareTo(b.number)),
        commonErrors = [for (final e in _maps(j['commonErrors'])) QaidaError.fromJson(e)];

  /// Parses the endpoint's payload: `{ recorded: false }` (no Qaida record yet) is null, a real report is a [QaidaReport].
  static QaidaReport? fromResponse(Map<String, dynamic> json) => json['recorded'] == false ? null : QaidaReport.fromJson(json);

  List<QaidaTakhti> get started => [for (final t in takhtis) if (t.status.isStarted) t];
  int get needsRevision => takhtis.where((t) => t.status == QaidaStatus.needsRevision).length;
  int get notStarted => takhtis.where((t) => t.status == QaidaStatus.notStarted).length;

  String get overallLabel => switch (overallStatus) {
        'completed' => 'Completed',
        'not_started' => 'Not started',
        _ => 'In progress',
      };
}
