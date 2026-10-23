import 'package:eldermin_parent_app/app/modules/early_years/controllers/early_years_controller.dart';
import 'package:eldermin_parent_app/app/modules/students/controllers/student_controller.dart';
import 'package:eldermin_parent_app/core/models/early_years_models.dart';
import 'package:eldermin_parent_app/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/early_years_fakes.dart';

Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late FakeEyApi api;
  late StudentController students;
  late DateTime clock;

  EarlyYearsController build(List<String> kids, {String? selected}) {
    students = studentsOf(api, [for (final k in kids) kid(k)], selected: selected);
    return Get.put(EarlyYearsController(api: api, students: students, now: () => clock));
  }

  setUp(() {
    Get.reset();
    api = FakeEyApi();
    clock = DateTime(2026, 10, 23, 10);
  });
  tearDown(Get.reset);

  group('eligibility (drives the More tile)', () {
    test('Early Years child: eligible once the summary arrives, not before', () async {
      api.summary = (id) async => eySummaryJson(id);
      final c = build(['s1']);
      expect(c.eligible, isFalse); // summary still loading
      await settle();
      expect(c.eligible, isTrue);
      expect(c.summary.value!.sharedPortfolioCount, 2);
    });

    test('a child outside Early Years is never eligible', () async {
      api.summary = (id) async => eySummaryJson(id, ey: false);
      final c = build(['s1']);
      await settle();
      expect(c.eligible, isFalse);
    });

    test('any failure (404, 403, offline, bad body) hides Early Years silently and does not throw', () async {
      for (final err in [ApiException('x', statusCode: 404), ApiException('x', statusCode: 403), ApiException('offline'), StateError('bad')]) {
        Get.reset();
        api = FakeEyApi()..summary = (id) async => throw err;
        final c = build(['s1']);
        await settle();
        expect(c.eligible, isFalse, reason: '$err');
        expect(c.summaryLoading.value, isFalse);
      }
    });

    test('a summary for another child is never accepted', () async {
      api.summary = (id) async => eySummaryJson('someone-else');
      final c = build(['s1']);
      await settle();
      expect(c.eligible, isFalse);
    });

    test('switching child refetches the summary and clears the previous child\'s lists', () async {
      api.summary = (id) async => eySummaryJson(id, ey: id == 's1', observations: 1);
      api.portfolio = (id, p) async => eyPage([eyItem('e-$id')]);
      final c = build(['s1', 's2'], selected: 's1');
      await settle();
      await c.open();
      expect(c.eligible, isTrue);
      expect(c.portfolio.map((e) => e.id), ['e-s1']);
      students.selectStudent('s2'); // not an Early Years child
      await settle();
      expect(c.eligible, isFalse);
      expect(c.portfolio, isEmpty);
      expect(c.portfolioLoaded.value, isFalse);
      expect(api.log, contains('summary:s2'));
      students.selectStudent('s1'); // back: summary refetched, lists start empty again
      await settle();
      expect(c.eligible, isTrue);
      expect(c.portfolio, isEmpty);
    });

    test('a slow summary for the previous child cannot overwrite the new one', () async {
      final students = studentsOf(api, [kid('s1'), kid('s2')], selected: 's1');
      api.summary = (id) async {
        if (id == 's1') await Future<void>.delayed(const Duration(milliseconds: 60));
        return eySummaryJson(id, ey: id == 's1');
      };
      final c = Get.put(EarlyYearsController(api: api, students: students, now: () => clock));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      students.selectStudent('s2');
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(c.summary.value?.studentId, 's2'); // s1's late answer was dropped
      expect(c.summary.value?.isEarlyYears, isFalse);
      expect(c.eligible, isFalse);
    });
  });

  group('portfolio list', () {
    test('open loads the first page; load more appends and de-duplicates; hasMore follows the server', () async {
      api.summary = (id) async => eySummaryJson(id);
      api.portfolio = (id, p) async => p == 1
          ? eyPage([eyItem('e1'), eyItem('e2')], total: 3, hasMore: true)
          : eyPage([eyItem('e2'), eyItem('e3')], page: 2, total: 3);
      final c = build(['s1']);
      await settle();
      await c.open();
      expect(c.portfolio.map((e) => e.id), ['e1', 'e2']);
      expect(c.portfolioHasMore.value, isTrue);
      await c.loadMorePortfolio();
      expect(c.portfolio.map((e) => e.id), ['e1', 'e2', 'e3']);
      expect(c.portfolioHasMore.value, isFalse);
      await c.loadMorePortfolio(); // nothing more: no extra call
      expect(api.log.where((l) => l.startsWith('portfolio:')).length, 2);
    });

    test('empty list is an honest empty state, not an error', () async {
      api.summary = (id) async => eySummaryJson(id, portfolio: 0);
      final c = build(['s1']);
      await settle();
      await c.open();
      expect(c.portfolio, isEmpty);
      expect(c.portfolioLoaded.value, isTrue);
      expect(c.portfolioError.value, isNull);
    });

    test('errors map to plain messages: 403 not your child, 404 not available, other keeps the server text', () async {
      api.summary = (id) async => eySummaryJson(id);
      final c = build(['s1']);
      await settle();
      for (final (code, text) in [(403, "You don't have access to this child's Early Years record."), (404, "Early Years isn't available for this child."), (500, 'boom')]) {
        api.portfolio = (id, p) async => throw ApiException('boom', statusCode: code);
        await c.loadPortfolio();
        expect(c.portfolioError.value, text, reason: '$code');
        expect(c.portfolio, isEmpty);
      }
      api.portfolio = (id, p) async => eyPage([eyItem('e1')]);
      await c.loadPortfolio();
      expect(c.portfolioError.value, isNull);
      expect(c.portfolio.length, 1);
    });

    test('a failed refresh keeps the entries already on screen', () async {
      api.summary = (id) async => eySummaryJson(id);
      api.portfolio = (id, p) async => eyPage([eyItem('e1')]);
      final c = build(['s1']);
      await settle();
      await c.open();
      api.portfolio = (id, p) async => throw ApiException('offline');
      await c.loadPortfolio();
      expect(c.portfolio.length, 1);
      expect(c.portfolioError.value, 'offline');
    });
  });

  group('shared observations', () {
    test('section shows only when the summary counts some, or items arrived', () async {
      api.summary = (id) async => eySummaryJson(id, observations: 0);
      final c = build(['s1']);
      await settle();
      expect(c.showObservations, isFalse);
      c.observations.add(const EyObservation(id: 'o1', type: 'spontaneous', narrative: 'n'));
      expect(c.showObservations, isTrue);
    });

    test('loads, pages and maps errors like the portfolio', () async {
      api.summary = (id) async => eySummaryJson(id, observations: 3);
      api.observations = (id, p) async => p == 1
          ? eyPage([{'id': 'o1', 'type': 'spontaneous', 'narrative': 'n', 'createdAt': '2026-10-01T10:00:00Z'}], total: 2, hasMore: true)
          : eyPage([{'id': 'o2', 'type': 'spontaneous', 'narrative': 'n2', 'createdAt': '2026-10-02T10:00:00Z'}], page: 2, total: 2);
      final c = build(['s1']);
      await settle();
      await c.open();
      expect(c.observations.map((o) => o.id), ['o1']);
      await c.loadMoreObservations();
      expect(c.observations.map((o) => o.id), ['o1', 'o2']);
      api.observations = (id, p) async => throw ApiException('x', statusCode: 404);
      await c.loadObservations();
      expect(c.observationsError.value, "Early Years isn't available for this child.");
    });
  });

  group('signed link expiry', () {
    EyMediaPhoto photo(String url) => EyMediaPhoto(url);

    test('a list older than 12 minutes is refetched on open / resume; a fresh one is not', () async {
      var n = 0;
      api.summary = (id) async => eySummaryJson(id);
      api.portfolio = (id, p) async => eyPage([eyItem('e1', media: [photo('https://signed/${++n}').json])]);
      final c = build(['s1']);
      await settle();
      await c.open();
      expect(c.portfolio.first.media.first.url, 'https://signed/1');
      clock = clock.add(const Duration(minutes: 5));
      await c.refreshIfStale();
      expect(c.portfolio.first.media.first.url, 'https://signed/1'); // still fresh
      clock = clock.add(const Duration(minutes: 8)); // 13 minutes since the fetch
      await c.refreshIfStale();
      expect(c.portfolio.first.media.first.url, 'https://signed/2');
    });

    test('an image failure refetches the links once, then is rate limited for 20 s', () async {
      var n = 0;
      api.summary = (id) async => eySummaryJson(id);
      api.portfolio = (id, p) async => eyPage([eyItem('e1', media: [photo('https://signed/${++n}').json])]);
      final c = build(['s1']);
      await settle();
      await c.open();
      await c.onMediaFailed();
      expect(c.portfolio.first.media.first.url, 'https://signed/2');
      await c.onMediaFailed(); // immediately again: ignored
      expect(c.portfolio.first.media.first.url, 'https://signed/2');
      clock = clock.add(const Duration(seconds: 25));
      await c.onMediaFailed();
      expect(c.portfolio.first.media.first.url, 'https://signed/3');
    });

    test('a failed silent refresh never replaces the list with an error', () async {
      api.summary = (id) async => eySummaryJson(id);
      api.portfolio = (id, p) async => eyPage([eyItem('e1')]);
      final c = build(['s1']);
      await settle();
      await c.open();
      api.portfolio = (id, p) async => throw ApiException('offline');
      await c.onMediaFailed();
      expect(c.portfolio.length, 1);
      expect(c.portfolioError.value, isNull);
    });

    test('loadEntry fetches fresh links for one entry; 404 says it is no longer shared', () async {
      api.summary = (id) async => eySummaryJson(id);
      api.entry = (id, e) async => eyItem(e, title: 'Fresh');
      final c = build(['s1']);
      await settle();
      await c.loadEntry('e1');
      expect(c.entry.value!.title, 'Fresh');
      api.entry = (id, e) async => throw ApiException('x', statusCode: 404);
      await c.loadEntry('e1');
      expect(c.entryError.value, 'This entry is no longer shared with you.');
    });
  });

  test('reset (logout) forgets everything', () async {
    api.summary = (id) async => eySummaryJson(id);
    api.portfolio = (id, p) async => eyPage([eyItem('e1')]);
    final c = build(['s1']);
    await settle();
    await c.open();
    c.reset();
    expect(c.summary.value, isNull);
    expect(c.portfolio, isEmpty);
    expect(c.eligible, isFalse);
  });
}

/// Small helpers local to this test file.
class EyMediaPhoto {
  final String url;
  EyMediaPhoto(this.url);
  Map<String, dynamic> get json => {'type': 'photo', 'url': url, 'caption': null};
}
