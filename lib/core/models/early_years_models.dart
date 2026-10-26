// Read-only Early Years models for the parent app.
//
// Parsing is deliberately an allow-list: each class reads only the fields the
// backend's parent endpoints document (parent-portal/students/:id/early-years/*)
// and ignores everything else, so nothing else (care, allergy, support, staff
// or internal data) can ever be picked up even if a response carried it.

String? _str(dynamic v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

int _int(dynamic v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

DateTime? _date(dynamic v) => DateTime.tryParse(v?.toString() ?? '')?.toLocal();

List<Map<String, dynamic>> _maps(dynamic v) =>
    v is List ? [for (final e in v) if (e is Map) Map<String, dynamic>.from(e)] : const [];

/// One photo/attachment. [url] is a signed link that expires (~15 min) and can
/// be null when storage is unavailable on the server.
class EyMedia {
  final String type;
  final String? url;
  final String? caption;
  const EyMedia({required this.type, this.url, this.caption});

  bool get isPhoto => type == 'photo';

  factory EyMedia.fromJson(Map<String, dynamic> j) =>
      EyMedia(type: _str(j['type']) ?? 'photo', url: _str(j['url']), caption: _str(j['caption']));
}

class EySummary {
  final String studentId;
  final String firstName;
  final String lastName;
  final bool isEarlyYears;
  final String? programme;
  final String? grade;
  final String? section;
  final String? keyPerson;
  final String? academicYear;
  final int sharedPortfolioCount;
  final int sharedObservationCount;
  final DateTime? lastSharedAt;

  const EySummary({
    required this.studentId,
    this.firstName = '',
    this.lastName = '',
    required this.isEarlyYears,
    this.programme,
    this.grade,
    this.section,
    this.keyPerson,
    this.academicYear,
    this.sharedPortfolioCount = 0,
    this.sharedObservationCount = 0,
    this.lastSharedAt,
  });

  String get classLabel => [grade, section].whereType<String>().join(' - ');

  factory EySummary.fromJson(Map<String, dynamic> j) => EySummary(
        studentId: _str(j['studentId']) ?? '',
        firstName: _str(j['firstName']) ?? '',
        lastName: _str(j['lastName']) ?? '',
        isEarlyYears: j['isEarlyYears'] == true,
        programme: _str(j['programme']),
        grade: _str(j['grade']),
        section: _str(j['section']),
        keyPerson: _str(j['keyPerson']),
        academicYear: _str(j['academicYear']),
        sharedPortfolioCount: _int(j['sharedPortfolioCount']),
        sharedObservationCount: _int(j['sharedObservationCount']),
        lastSharedAt: _date(j['lastSharedAt']),
      );
}

class EyPortfolioEntry {
  final String id;
  final String title;
  final String narrative;
  final String? tryThisAtHome;
  final DateTime? createdAt;
  final List<EyMedia> media;
  const EyPortfolioEntry({
    required this.id,
    required this.title,
    required this.narrative,
    this.tryThisAtHome,
    this.createdAt,
    this.media = const [],
  });

  factory EyPortfolioEntry.fromJson(Map<String, dynamic> j) => EyPortfolioEntry(
        id: _str(j['id']) ?? '',
        title: _str(j['title']) ?? '',
        narrative: _str(j['narrative']) ?? '',
        tryThisAtHome: _str(j['tryThisAtHome']),
        createdAt: _date(j['createdAt']),
        media: _maps(j['media']).map(EyMedia.fromJson).toList(),
      );
}

class EyLearningArea {
  final String skill;
  final String level;
  const EyLearningArea({required this.skill, required this.level});
}

class EyObservation {
  final String id;
  final String type;
  final String narrative;
  final String? nextStep;
  final DateTime? createdAt;
  final List<EyLearningArea> learningAreas;
  final List<EyMedia> media;
  const EyObservation({
    required this.id,
    required this.type,
    required this.narrative,
    this.nextStep,
    this.createdAt,
    this.learningAreas = const [],
    this.media = const [],
  });

  factory EyObservation.fromJson(Map<String, dynamic> j) => EyObservation(
        id: _str(j['id']) ?? '',
        type: _str(j['type']) ?? '',
        narrative: _str(j['narrative']) ?? '',
        nextStep: _str(j['nextStep']),
        createdAt: _date(j['createdAt']),
        learningAreas: [
          for (final a in _maps(j['learningAreas']))
            if (_str(a['skill']) != null) EyLearningArea(skill: _str(a['skill'])!, level: _str(a['level']) ?? ''),
        ],
        media: _maps(j['media']).map(EyMedia.fromJson).toList(),
      );
}

/// One page of a paged list. Entries without an id are dropped (never shown).
class EyPage<T> {
  final List<T> items;
  final int page;
  final int total;
  final bool hasMore;
  const EyPage({required this.items, required this.page, required this.total, required this.hasMore});

  static EyPage<T> parse<T>(Map<String, dynamic> j, T Function(Map<String, dynamic>) item, String Function(T) idOf) {
    final items = _maps(j['items']).map(item).where((e) => idOf(e).isNotEmpty).toList();
    return EyPage<T>(items: items, page: _int(j['page']) == 0 ? 1 : _int(j['page']), total: _int(j['total']), hasMore: j['hasMore'] == true);
  }
}
