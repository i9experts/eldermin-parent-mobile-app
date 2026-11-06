import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/models/nazra_models.dart';
import 'package:eldermin_parent_app/core/models/qaida_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/route_harness.dart';

Map<String, dynamic> _takhti(int n, String en, String status, {Map<String, dynamic>? latest, List<Map<String, dynamic>> log = const [], int attempts = 0}) => {
      'number': n,
      'titleEn': en,
      'titleUr': 'ur$n',
      'pageReference': 'p. $n',
      'status': status,
      'startedDate': status == 'not_started' ? null : '2026-10-26T09:00:00.000Z',
      'masteredDate': status == 'mastered' ? '2026-10-29T09:00:00.000Z' : null,
      'revisionCount': 0,
      'attemptCount': attempts,
      'sabaqLog': log,
      'latestAttempt': latest,
    };

Map<String, dynamic> _report() => {
      'recorded': true,
      'studentName': 'Lubaba',
      'currentTakhti': 2,
      'overallStatus': 'in_progress',
      'masteredCount': 1,
      'totalTakhtis': 16,
      'trackedTakhtis': 16,
      'masteryPct': 6,
      'currentTeacher': 'QaidaTeacherSent',
      'overallRemarks': 'OverallRemarksSent',
      'takhtis': [
        _takhti(1, 'Mufradat', 'mastered', attempts: 1, latest: {'rating': 'proficient', 'remarks': 'LatestRemarksSent', 'makhrajAccuracy': 4, 'errorsNoted': <String>[]}, log: [
          {'date': '2026-10-26T09:00:00.000Z', 'sabaqFrom': 'Alif', 'sabaqTo': 'Kaf', 'rating': 'proficient'}
        ]),
        _takhti(2, 'Murakkabat', 'needs_revision', attempts: 1, latest: {'rating': 'developing', 'remarks': 'NeedsMoreSent', 'errorsNoted': ['missed_ghunna']}),
        for (var n = 3; n <= 16; n++) _takhti(n, 'Board$n', 'not_started'),
      ],
      'commonErrors': [
        {'error': 'makhraj_confusion', 'count': 3}
      ],
    };

Map<String, dynamic> _nazra({int diary = 2}) => {
      'recorded': true,
      'studentName': 'Lubaba',
      'currentPara': 2,
      'overallStatus': 'in_progress',
      'completedCount': 1,
      'totalParas': 30,
      'trackedParas': 30,
      'completionPct': 3,
      'currentTeacher': 'NazraTeacherSent',
      'overallRemarks': 'NazraRemarksSent',
      'paras': [
        {'number': 1, 'titleEn': 'Alif Lam Meem', 'titleAr': 'الم', 'approxPageRange': 'pp. 1-21', 'status': 'completed', 'startedDate': '2026-11-01T09:00:00.000Z', 'completedDate': '2026-11-04T09:00:00.000Z', 'revisionCount': 0, 'attemptCount': 2,
          'latestAttempt': {'rating': 'proficient', 'remarks': 'ParaRemarksSent', 'tajweedAccuracy': 4, 'errorsNoted': ['qalqalah_missed']}},
        {'number': 2, 'titleEn': 'Sayaqul', 'titleAr': 'سيقول', 'approxPageRange': 'pp. 22-41', 'status': 'in_progress', 'startedDate': '2026-11-05T09:00:00.000Z', 'revisionCount': 0, 'attemptCount': 0, 'latestAttempt': null},
        for (var n = 3; n <= 30; n++) {'number': n, 'titleEn': 'Para$n', 'status': 'not_started', 'attemptCount': 0, 'revisionCount': 0, 'latestAttempt': null},
      ],
      'diaryTotal': diary,
      'diary': [
        for (var i = 0; i < diary; i++)
          {
            'date': '2026-11-0${5 - (i % 5)}T09:00:00.000Z',
            'sabaq': {'paraNumber': 2, 'pageFrom': '22', 'pageTo': '23', 'rating': 'proficient', 'makhrajAccuracy': 4, 'errorsNoted': ['idgham_missed'], 'remarks': 'SabaqRemarksSent'},
            'sabqi': {'paraNumber': 1, 'pageFrom': '1', 'rating': 'developing', 'errorsNoted': []},
            'manzil': null,
          }
      ],
      'commonErrors': [
        {'error': 'qalqalah_missed', 'count': 2}
      ],
    };

dynamic _answer(String url, {Object? qaida, Object? nazra}) {
  if (url.endsWith('/qaida')) return qaida ?? {'recorded': false};
  if (url.endsWith('/nazra')) return nazra ?? {'recorded': false};
  return <dynamic>[];
}

void main() {
  group('QaidaReport.fromResponse', () {
    test('recorded: false is no report', () => expect(QaidaReport.fromResponse({'recorded': false}), isNull));

    test('parses the figures, takhtis (sorted) and error tags', () {
      final r = QaidaReport.fromResponse(_report())!;
      expect(r.mastered, 1);
      expect(r.total, 16);
      expect(r.masteryPct, 6);
      expect(r.currentTakhti, 2);
      expect(r.takhtis.first.number, 1);
      expect(r.takhtis.first.status, QaidaStatus.mastered);
      expect(r.started.map((t) => t.number), [1, 2]);
      expect(r.needsRevision, 1);
      expect(r.notStarted, 14);
      expect(r.takhtis.first.sabaqLog.single.range, 'Alif to Kaf');
      expect(r.commonErrors.single.label, 'Makhraj confusion (similar-sounding letters)');
      expect(r.overallLabel, 'In progress');
    });

    test('wrong types and missing fields become neutral defaults, never a throw', () {
      final r = QaidaReport.fromResponse({'takhtis': 'oops', 'commonErrors': 5, 'masteredCount': 'x', 'currentTeacher': null})!;
      expect(r.takhtis, isEmpty);
      expect(r.total, 16);
      expect(r.mastered, 0);
      expect(r.currentTeacher, '');
    });

    test('unknown error tag is humanised, unknown rating too', () {
      expect(qaidaErrorLabel('some_new_tag'), 'Some new tag');
      expect(qaidaRatingLabel('needs_practice'), 'Needs practice');
    });
  });

  group('NazraReport.fromResponse', () {
    test('recorded: false is no report', () => expect(NazraReport.fromResponse({'recorded': false}), isNull));

    test('parses the figures, paras, diary and names a para', () {
      final r = NazraReport.fromResponse(_nazra())!;
      expect(r.completed, 1);
      expect(r.total, 30);
      expect(r.completionPct, 3);
      expect(r.started.map((p) => p.number), [1, 2]);
      expect(r.paraName(2), 'Para 2 · Sayaqul');
      expect(r.paraName(null), '');
      expect(r.diary.first.sabaq!.pages, 'pp. 22-23');
      expect(r.diary.first.sabqi!.pages, 'p. 1');
      expect(r.diary.first.manzil, isNull);
      expect(r.commonErrors.single.label, 'Qalqalah missed');
    });

    test('wrong types and missing fields become neutral defaults, never a throw', () {
      final r = NazraReport.fromResponse({'paras': 'oops', 'diary': 5, 'commonErrors': 'x', 'completedCount': 'y'})!;
      expect(r.paras, isEmpty);
      expect(r.diary, isEmpty);
      expect(r.total, 30);
      expect(r.completed, 0);
    });
  });

  group("Qur'an progress screen", () {
    testWidgets('only Qaida recorded: shows the overview, journey, breakdown, areas, remarks and the PDF button', (t) async {
      setUpRouteDeps((m, url) => _answer(url, qaida: _report()));
      await pumpRoute(t, Routes.quranProgress);
      expect(find.text('1/16'), findsWidgets);
      expect(find.textContaining('Currently on Takhti 2'), findsOneWidget);
      expect(find.byKey(const Key('qaida_pdf')), findsOneWidget);
      expect(find.byKey(const Key('takhti_1')), findsOneWidget);
      await t.scrollUntilVisible(find.byKey(const Key('takhti_tile_2')), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('2. Murakkabat'), findsOneWidget);
      await t.scrollUntilVisible(find.text('Areas needing attention'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Makhraj confusion'), findsOneWidget);
      await t.scrollUntilVisible(find.text('OverallRemarksSent'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('OverallRemarksSent'), findsOneWidget);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });

    testWidgets('a tile expands to the latest remarks and the lesson log', (t) async {
      setUpRouteDeps((m, url) => _answer(url, qaida: _report()));
      await pumpRoute(t, Routes.quranProgress);
      await t.scrollUntilVisible(find.byKey(const Key('takhti_tile_1')), 300, scrollable: find.byType(Scrollable).first);
      await t.tap(find.byKey(const Key('takhti_tile_1')));
      await t.pumpAndSettle();
      expect(find.text('LatestRemarksSent'), findsOneWidget);
      expect(find.textContaining('Alif to Kaf'), findsOneWidget);
      await disposeApp(t);
    });

    testWidgets('only Qaida recorded: no tabs, no Nazra', (t) async {
      setUpRouteDeps((m, url) => _answer(url, qaida: _report()));
      await pumpRoute(t, Routes.quranProgress);
      expect(find.text('Nazra'), findsNothing);
      expect(find.byKey(const Key('takhti_1')), findsOneWidget);
      await disposeApp(t);
    });

    testWidgets('only Nazra recorded: shows the overview, 30-para journey, diary, paras and remarks; no Qaida PDF button', (t) async {
      setUpRouteDeps((m, url) => _answer(url, nazra: _nazra()));
      await pumpRoute(t, Routes.quranProgress);
      expect(find.text('1/30'), findsWidgets);
      expect(find.textContaining('Currently on Para 2 · Sayaqul'), findsOneWidget);
      expect(find.byKey(const Key('para_30')), findsOneWidget);
      expect(find.byKey(const Key('qaida_pdf')), findsNothing);
      expect(find.text('Qaida & Tajweed'), findsNothing);
      await t.scrollUntilVisible(find.byKey(const Key('diary_0')), 300, scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Sabaq: Para 2 · Sayaqul · pp. 22-23 · Proficient'), findsOneWidget);
      expect(find.textContaining('Sabqi: Para 1 · Alif Lam Meem · p. 1 · Developing'), findsOneWidget);
      await t.ensureVisible(find.byKey(const Key('diary_0'))); // fully on screen, clear of the bars
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('diary_0')));
      await t.pumpAndSettle();
      expect(find.text('SabaqRemarksSent'), findsOneWidget);
      expect(find.text('Idgham missed'), findsOneWidget);
      await t.scrollUntilVisible(find.byKey(const Key('para_tile_1')), 300, scrollable: find.byType(Scrollable).first);
      await t.scrollUntilVisible(find.text('NazraRemarksSent'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('NazraRemarksSent'), findsOneWidget);
      await disposeApp(t);
    });

    testWidgets('both recorded: Nazra (the later stage) first, a tab switches to Qaida and back', (t) async {
      setUpRouteDeps((m, url) => _answer(url, qaida: _report(), nazra: _nazra()));
      await pumpRoute(t, Routes.quranProgress);
      expect(find.text('1/30'), findsWidgets);
      expect(find.byKey(const Key('qaida_pdf')), findsNothing);
      await t.tap(find.text('Qaida & Tajweed'));
      await t.pumpAndSettle();
      expect(find.text('1/16'), findsWidgets);
      expect(find.byKey(const Key('qaida_pdf')), findsOneWidget);
      await t.tap(find.text('Nazra'));
      await t.pumpAndSettle();
      expect(find.text('1/30'), findsWidgets);
      await disposeApp(t);
    });

    testWidgets('a long diary shows the latest days with a "latest N of M" note', (t) async {
      setUpRouteDeps((m, url) => _answer(url, nazra: _nazra(diary: 40)));
      await pumpRoute(t, Routes.quranProgress);
      await t.scrollUntilVisible(find.textContaining('Showing the latest 15 of 40'), 400, scrollable: find.byType(Scrollable).first);
      expect(find.textContaining('Showing the latest 15 of 40'), findsOneWidget);
      await disposeApp(t);
    });

    testWidgets('no Qaida record yet shows an honest empty state, no PDF button', (t) async {
      setUpRouteDeps((m, url) => _answer(url));
      await pumpRoute(t, Routes.quranProgress);
      expect(find.byKey(const Key('quran_empty')), findsOneWidget);
      expect(find.byKey(const Key('qaida_pdf')), findsNothing);
      await disposeApp(t);
    });

    testWidgets('a suspended feature shows the locked view', (t) async {
      setUpRouteDeps((m, url) => url.endsWith('/qaida') ? suspendedBody : _answer(url));
      await pumpRoute(t, Routes.quranProgress);
      expect(find.byKey(const Key('quran_empty')), findsNothing);
      expect(find.byKey(const Key('qaida_pdf')), findsNothing);
      await disposeApp(t);
    });

    testWidgets('a failing request ends in the error view', (t) async {
      setUpRouteDeps((m, url) => throw networkError(url));
      await pumpRoute(t, Routes.quranProgress);
      expect(find.byKey(const Key('qaida_pdf')), findsNothing);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });
  });
}
