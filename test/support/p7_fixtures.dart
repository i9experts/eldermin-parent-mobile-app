import 'dart:async';
import 'p5_fixtures.dart';

/// Sentinel data for the Early Years screens: every field the views read carries a DISTINCT value (the EY views read typed models,
/// `lib/core/models/early_years_models.dart`, whose parsing is an allow-list, so the "keys" are the model fields).
Map<String, dynamic> eySummarySent({String id = 's1', bool ey = true, int portfolio = 2, int observations = 3}) => ey
    ? {
        'studentId': id,
        'firstName': 'EyFirstSent',
        'lastName': 'EyLastSent',
        'isEarlyYears': true,
        'programme': 'early-years',
        'grade': 'EyGradeSent',
        'section': 'EySecSent',
        'keyPerson': 'EyKeyPersonSent',
        'academicYear': 'EyYearSent',
        'sharedPortfolioCount': portfolio,
        'sharedObservationCount': observations,
        'lastSharedAt': '2026-10-02T08:00:00.000Z',
      }
    : {'studentId': id, 'firstName': 'Omar', 'lastName': 'Khan', 'isEarlyYears': false, 'programme': 'k12'};

Map<String, dynamic> eyEntrySent(String id, {String title = 'EyEntryTitleSent'}) => {
      'id': id,
      'title': title,
      'narrative': 'EyNarrativeSent',
      'tryThisAtHome': 'EyTryHomeSent',
      'createdAt': '2026-10-01T10:00:00.000Z',
      'media': [
        {'type': 'photo', 'url': null, 'caption': null},
        {'type': 'photo', 'url': 'https://example.invalid/photo.jpg?sig=x', 'caption': 'EyCaptionSent'},
        {'type': 'video', 'url': null, 'caption': null},
      ],
    };

Map<String, dynamic> eyObservationSent(String id) => {
      'id': id,
      'type': 'learning_story',
      'narrative': 'EyObsNarrativeSent',
      'nextStep': 'EyNextStepSent',
      'createdAt': '2026-10-03T09:00:00.000Z',
      'learningAreas': [
        {'skill': 'EySkillSent', 'level': 'EyLevelSent'},
        {'skill': 'EySkillTwoSent', 'level': ''},
      ],
      'media': [
        {'type': 'work_sample', 'url': null, 'caption': null}
      ],
    };

Map<String, dynamic> eyPageSent(List<Map<String, dynamic>> items, {int page = 1, int? total, bool hasMore = false}) =>
    {'items': items, 'page': page, 'limit': 20, 'total': total ?? items.length, 'hasMore': hasMore};

/// The fake API for the Early Years screens (falls back to the P5 answers). [eligible] = the selected child is in Early Years;
/// [summaryFails] = the summary call errors; [pages] = the portfolio is served in two pages.
FutureOr<dynamic> Function(String, String) p7Api({
  Completer<dynamic>? hold,
  bool empty = false,
  bool eligible = true,
  bool summaryFails = false,
  bool pages = false,
  bool portfolioFails = false,
  int portfolio = 2,
  int observations = 3,
}) {
  final base = p5Api(hold: hold, empty: empty);
  var portfolioCalls = 0;
  return (method, url) {
    if (hold != null || empty) return base(method, url);
    if (url.contains('/early-years/')) {
      if (url.endsWith('/early-years/summary')) {
        if (summaryFails) throw StateError('summary failed');
        final id = RegExp(r'/students/([^/]+)/').firstMatch(url)!.group(1)!;
        return eySummarySent(id: id, ey: eligible, portfolio: portfolio, observations: observations);
      }
      if (url.endsWith('/early-years/portfolio')) {
        if (portfolioFails) throw StateError('portfolio failed');
        portfolioCalls++;
        if (pages) {
          return portfolioCalls == 1
              ? eyPageSent([eyEntrySent('e1', title: 'EyEntryOneSent')], total: 2, hasMore: true)
              : eyPageSent([eyEntrySent('e2', title: 'EyEntryTwoSent')], page: 2, total: 2);
        }
        return eyPageSent([eyEntrySent('e1'), eyEntrySent('e2', title: 'EyEntryTwoSent')], total: 2);
      }
      if (url.endsWith('/early-years/observations')) return eyPageSent([eyObservationSent('o1')], total: 1);
      if (url.contains('/early-years/portfolio/')) return eyEntrySent(url.split('/').last);
    }
    return base(method, url);
  };
}
