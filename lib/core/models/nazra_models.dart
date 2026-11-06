import 'qaida_models.dart' show qaidaErrorLabel, qaidaRatingLabel;

// Nazra (Qur'an reading) progress as the parent portal sends it (`GET /parent-portal/students/:id/nazra`, backend
// parent-nazra.projection.ts: an explicit allowlist, so any field may be absent). Parses defensively: a missing, null or wrongly typed
// field becomes a neutral default and never throws.

String _text(Object? v) {
  if (v == null) return '';
  final s = v.toString().trim();
  return s == 'null' ? '' : s;
}

int _int(Object? v) => v is num ? v.toInt() : (int.tryParse(_text(v)) ?? 0);

int? _intOrNull(Object? v) => v is num ? v.toInt() : int.tryParse(_text(v));

DateTime? _date(Object? v) => DateTime.tryParse(_text(v));

Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};

List<Map<String, dynamic>> _maps(Object? v) => v is List ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)] : const [];

List<String> _strings(Object? v) => v is List ? [for (final e in v) if (_text(e).isNotEmpty) _text(e)] : const [];

/// Where a para (juz) stands for the child.
enum NazraStatus {
  completed('Completed'),
  needsRevision('Needs revision'),
  inProgress('In progress'),
  notStarted('Not started'),
  notTracked('Not tracked');

  final String label;
  const NazraStatus(this.label);

  static NazraStatus parse(Object? v) => switch (_text(v)) {
        'completed' => NazraStatus.completed,
        'needs_revision' => NazraStatus.needsRevision,
        'in_progress' => NazraStatus.inProgress,
        'not_tracked' => NazraStatus.notTracked,
        _ => NazraStatus.notStarted,
      };

  /// A para the teacher has actually worked on with the child (listed in the detailed breakdown).
  bool get isStarted => this == completed || this == needsRevision || this == inProgress;
}

class NazraAttempt {
  final DateTime? date;
  final String rating;
  final String pages;
  final int? makhraj;
  final int? tajweed;
  final int? fluency;
  final List<String> errors;
  final String remarks;
  NazraAttempt.fromJson(Map<String, dynamic> j)
      : date = _date(j['date']),
        rating = _text(j['rating']),
        pages = _pages(j),
        makhraj = _intOrNull(j['makhrajAccuracy']),
        tajweed = _intOrNull(j['tajweedAccuracy']),
        fluency = _intOrNull(j['fluency']),
        errors = _strings(j['errorsNoted']),
        remarks = _text(j['remarks']);
}

/// "pp. 3-5", "p. 3" or '' when the teacher recorded no page range.
String _pages(Map<String, dynamic> j) {
  final from = _text(j['pageFrom']);
  final to = _text(j['pageTo']);
  if (from.isEmpty) return '';
  return to.isEmpty || to == from ? 'p. $from' : 'pp. $from-$to';
}

class NazraPara {
  final int number;
  final String titleEn;
  final String titleAr;
  final String pageRange;
  final NazraStatus status;
  final DateTime? started;
  final DateTime? completed;
  final int revisionCount;
  final int attempts;
  final NazraAttempt? latest;

  NazraPara.fromJson(Map<String, dynamic> j)
      : number = _int(j['number']),
        titleEn = _text(j['titleEn']),
        titleAr = _text(j['titleAr']),
        pageRange = _text(j['approxPageRange']),
        status = NazraStatus.parse(j['status']),
        started = _date(j['startedDate']),
        completed = _date(j['completedDate']),
        revisionCount = _int(j['revisionCount']),
        attempts = _int(j['attemptCount']),
        latest = j['latestAttempt'] is Map ? NazraAttempt.fromJson(_map(j['latestAttempt'])) : null;
}

/// One lesson part of a diary day: the new lesson (sabaq) or a revision (sabqi / manzil) of an earlier para.
class NazraLessonPart {
  final int? para;
  final String pages;
  final String rating;
  final int? makhraj;
  final int? tajweed;
  final int? fluency;
  final List<String> errors;
  final String remarks;
  NazraLessonPart.fromJson(Map<String, dynamic> j)
      : para = _intOrNull(j['paraNumber']),
        pages = _pages(j),
        rating = _text(j['rating']),
        makhraj = _intOrNull(j['makhrajAccuracy']),
        tajweed = _intOrNull(j['tajweedAccuracy']),
        fluency = _intOrNull(j['fluency']),
        errors = _strings(j['errorsNoted']),
        remarks = _text(j['remarks']);
}

class NazraDiaryEntry {
  final DateTime? date;
  final NazraLessonPart? sabaq;
  final NazraLessonPart? sabqi;
  final NazraLessonPart? manzil;
  NazraDiaryEntry.fromJson(Map<String, dynamic> j)
      : date = _date(j['date']),
        sabaq = j['sabaq'] is Map ? NazraLessonPart.fromJson(_map(j['sabaq'])) : null,
        sabqi = j['sabqi'] is Map ? NazraLessonPart.fromJson(_map(j['sabqi'])) : null,
        manzil = j['manzil'] is Map ? NazraLessonPart.fromJson(_map(j['manzil'])) : null;
}

class NazraError {
  final String key;
  final int count;
  NazraError.fromJson(Map<String, dynamic> j)
      : key = _text(j['error']),
        count = _int(j['count']);
  String get label => qaidaErrorLabel(key);
}

class NazraReport {
  final String studentName;
  final int currentPara;
  final String overallStatus;
  final int completed;
  final int total;
  final int completionPct;
  final String currentTeacher;
  final String overallRemarks;
  final List<NazraPara> paras;
  final List<NazraDiaryEntry> diary;
  final int diaryTotal;
  final List<NazraError> commonErrors;

  NazraReport.fromJson(Map<String, dynamic> j)
      : studentName = _text(j['studentName']),
        currentPara = _int(j['currentPara']),
        overallStatus = _text(j['overallStatus']),
        completed = _int(j['completedCount']),
        total = _int(j['totalParas']) == 0 ? 30 : _int(j['totalParas']),
        completionPct = _int(j['completionPct']),
        currentTeacher = _text(j['currentTeacher']),
        overallRemarks = _text(j['overallRemarks']),
        paras = [for (final p in _maps(j['paras'])) NazraPara.fromJson(p)]..sort((a, b) => a.number.compareTo(b.number)),
        diary = [for (final e in _maps(j['diary'])) NazraDiaryEntry.fromJson(e)],
        diaryTotal = _int(j['diaryTotal']),
        commonErrors = [for (final e in _maps(j['commonErrors'])) NazraError.fromJson(e)];

  /// `{ recorded: false }` (the child has not reached Nazra yet) is null.
  static NazraReport? fromResponse(Map<String, dynamic> json) => json['recorded'] == false ? null : NazraReport.fromJson(json);

  List<NazraPara> get started => [for (final p in paras) if (p.status.isStarted) p];
  int get needsRevision => paras.where((p) => p.status == NazraStatus.needsRevision).length;

  String get overallLabel => switch (overallStatus) {
        'completed' => 'Completed',
        'not_started' => 'Not started',
        _ => 'In progress',
      };

  /// "Para 3 · Tilka'r-Rusul", or "Para 3" when the title is unknown.
  String paraName(int? n) {
    if (n == null) return '';
    final t = paras.where((p) => p.number == n).map((p) => p.titleEn).firstWhere((s) => s.isNotEmpty, orElse: () => '');
    return t.isEmpty ? 'Para $n' : 'Para $n · $t';
  }
}

String nazraRatingLabel(String rating) => qaidaRatingLabel(rating);
