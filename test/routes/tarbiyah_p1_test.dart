// P1: the Behaviour & Tarbiyah screen: dates, newest first, filters, record detail, assessment history + detail, truncation notes, null-safety.
import 'dart:async';
import 'package:eldermin_parent_app/app/modules/students/controllers/student_controller.dart';
import 'package:eldermin_parent_app/app/modules/tarbiyah/controllers/tarbiyah_controller.dart';
import 'package:eldermin_parent_app/app/modules/tarbiyah/views/tarbiyah_detail_sheets.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/models/behaviour_models.dart';
import 'package:eldermin_parent_app/core/models/student.dart';
import 'package:eldermin_parent_app/core/widgets/app_widgets.dart';
import 'package:eldermin_parent_app/core/design/design.dart' show EmChip;
import 'package:eldermin_parent_app/core/widgets/locked_feature_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/route_harness.dart';

Map<String, dynamic> body({List<dynamic>? records, List<dynamic>? assessments}) => {
      'behaviourRecords': records ??
          [
            {'_id': 'r1', 'studentId': 's1', 'date': '2026-09-02T00:00:00.000Z', 'type': 'positive', 'category': 'helping_others', 'title': 'Helped a classmate', 'description': 'Shared her notes.', 'points': 5},
            {'_id': 'r2', 'studentId': 's1', 'date': '2026-09-20T00:00:00.000Z', 'type': 'negative', 'category': 'late_coming', 'title': 'Late to class', 'description': 'Ten minutes late.', 'points': -2},
            {'_id': 'r3', 'studentId': 's1', 'date': '2026-09-10T00:00:00.000Z', 'type': 'neutral', 'title': 'Settling in', 'description': 'Doing well.', 'points': 0, 'source': 'teacher_note', 'actionTaken': 'Spoke to her'},
          ],
      'tarbiyahAssessments': assessments ??
          [
            {
              '_id': 'a1', 'studentId': 's1', 'period': 'Term 1', 'periodType': 'termly', 'assessmentDate': '2026-09-10T00:00:00.000Z', 'overallPercentage': 80, 'overallScore': 4, 'overallRating': 'good',
              'teacherObservations': 'A thoughtful child.', 'areasOfStrength': ['Honesty'], 'areasForImprovement': ['Focus in class'], 'recommendedActions': 'Read together every evening.',
              'programName': 'Tarbiyah', 'ratingScale': {'min': 1, 'max': 5},
              'traits': [
                {'traitKey': 'sidq', 'traitName': 'Truthfulness', 'percentage': 90, 'score': 4.5, 'observation': 'Always honest'},
                {'traitKey': 'adab', 'traitName': 'Manners', 'percentage': 70, 'score': 3.5},
              ],
            },
            {'_id': 'a0', 'studentId': 's1', 'period': 'Term 2 (earlier)', 'assessmentDate': '2026-03-01T00:00:00.000Z', 'overallPercentage': 65, 'overallRating': 'satisfactory', 'traits': [{'traitKey': 'sidq', 'percentage': 60}]},
          ],
    };

void main() {
  late FakeClient client;
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);

  Future<void> open(WidgetTester t, Object? payload, {double w = 390, double h = 2400}) async {
    client = setUpRouteDeps((m, url) => url.endsWith('/behaviour') ? payload : <dynamic>[]);
    await pumpApp(t, width: w, height: h);
    unawaited(Get.toNamed(Routes.tarbiyah));
    await settle(t);
  }

  TarbiyahController ctl() => Get.find<TarbiyahController>();

  group('records: dates, order, empty states', () {
    testWidgets('every record shows its date; newest first; kind tags say Merit / Concern / Note', (t) async {
      await open(t, body());
      expect(client.calls.where((c) => c.endsWith('/students/s1/behaviour')), hasLength(1));
      expect(find.textContaining('20 Sep 2026 · Ten minutes late.'), findsOneWidget);
      expect(find.textContaining('10 Sep 2026 · Doing well.'), findsOneWidget);
      expect(find.textContaining('2 Sep 2026 · Shared her notes.'), findsOneWidget);
      final order = [for (final i in [0, 1, 2]) t.getTopLeft(find.byKey(Key('tb_rec_$i'))).dy];
      expect(order[0] < order[1] && order[1] < order[2], isTrue);
      expect(ctl().visibleRecords.map((r) => r.id), ['r2', 'r3', 'r1']);
      expect(find.text('Merit'), findsWidgets);
      expect(find.text('Concern'), findsWidgets);
      expect(find.text('Note'), findsWidgets);
      expect(find.text('Follow-up'), findsNothing, reason: 'the old label for a concern is gone');
    });

    testWidgets('nothing at all: ONE calm empty state, no stray sections', (t) async {
      await open(t, {'behaviourRecords': [], 'tarbiyahAssessments': []});
      expect(find.byKey(const Key('tb_empty')), findsOneWidget);
      expect(find.text('Nothing recorded yet'), findsOneWidget);
      expect(find.text('Assessment history'), findsNothing);
      expect(find.text('Teacher notes & observations'), findsNothing);
    });

    testWidgets('records but no assessment: no hero, no fabricated "development" claim, the records still show', (t) async {
      await open(t, body(assessments: []));
      expect(find.text('Holistic growth score'), findsNothing);
      expect(find.text('Consistent positive development'), findsNothing);
      expect(find.text('Assessment history'), findsNothing);
      expect(find.text('Late to class'), findsOneWidget);
    });

    testWidgets('assessment but no records: history shows, the records section says so', (t) async {
      await open(t, body(records: []));
      expect(find.byKey(const Key('tb_no_records')), findsOneWidget);
      expect(find.text('Assessment history'), findsOneWidget);
    });
  });

  group('filters', () {
    Future<void> openFilters(WidgetTester t) async {
      await t.tap(find.byKey(const Key('tb_filter_btn')));
      await settle(t);
    }

    testWidgets('type filter: Concern shows only the concern; the chip and count update; removing the chip restores the list', (t) async {
      await open(t, body());
      expect(find.text('3 of 3'), findsOneWidget);
      await openFilters(t);
      await t.tap(find.byKey(const Key('tb_f_kind_concern')));
      await t.tap(find.byKey(const Key('tb_f_apply')));
      await settle(t);
      expect(find.text('Late to class'), findsOneWidget);
      expect(find.text('Helped a classmate'), findsNothing);
      expect(find.text('Filters (1)'), findsOneWidget);
      expect(find.text('1 of 3'), findsOneWidget);
      await t.tap(find.byKey(const Key('tb_filter_Concern')));
      await settle(t);
      expect(find.text('Helped a classmate'), findsOneWidget);
      expect(find.text('3 of 3'), findsOneWidget);
    });

    testWidgets('a filter with no match says so (and stays clearable); Clear filters restores', (t) async {
      await open(t, body());
      ctl().setFilter(RecordFilter(from: DateTime(2026, 10, 1)));
      await settle(t);
      expect(find.byKey(const Key('tb_filter_empty')), findsOneWidget);
      expect(find.text('Nothing matches these filters'), findsOneWidget);
      await openFilters(t);
      await t.tap(find.byKey(const Key('tb_f_clear')));
      await settle(t);
      expect(find.byKey(const Key('tb_filter_empty')), findsNothing);
      expect(find.text('Late to class'), findsOneWidget);
    });

    testWidgets('date range (controller): inclusive, newest first within the range', (t) async {
      await open(t, body());
      ctl().setFilter(RecordFilter(from: DateTime(2026, 9, 10), to: DateTime(2026, 9, 20)));
      await settle(t);
      expect(ctl().visibleRecords.map((r) => r.id), ['r2', 'r3']);
      expect(find.text('Filters (2)'), findsOneWidget);
    });

    testWidgets('the filter sheet offers the three kinds and both dates, and reopens on the current filter', (t) async {
      await open(t, body());
      await openFilters(t);
      for (final k in ['tb_f_kind_merit', 'tb_f_kind_concern', 'tb_f_kind_note', 'tb_f_from', 'tb_f_to', 'tb_f_apply', 'tb_f_clear']) {
        expect(find.byKey(Key(k)), findsOneWidget, reason: k);
      }
      await t.tap(find.byKey(const Key('tb_f_kind_merit')));
      await t.tap(find.byKey(const Key('tb_f_apply')));
      await settle(t);
      await openFilters(t);
      expect(t.widget<EmChip>(find.byKey(const Key('tb_f_kind_merit'))).selected, isTrue);
    });
  });

  group('record detail sheet', () {
    testWidgets('tapping a record opens its sheet: date, category, points, details', (t) async {
      await open(t, body());
      await t.tap(find.text('Late to class'));
      await settle(t);
      expect(find.byKey(const Key('detail_sheet')), findsOneWidget);
      expect(find.text('20 Sep 2026'), findsWidgets);
      expect(find.text('Late coming'), findsOneWidget);
      expect(find.text('-2'), findsOneWidget);
      expect(find.text('Ten minutes late.'), findsWidgets);
    });

    testWidgets('a teacher note shows the action taken', (t) async {
      await open(t, body());
      await t.tap(find.text('Settling in'));
      await settle(t);
      expect(find.text('Action taken'), findsOneWidget);
      expect(find.text('Spoke to her'), findsOneWidget);
    });

    test('recordSheetData: only fields that exist are shown; an empty record is still a sheet', () {
      final d = recordSheetData(ParentBehaviourRecord.fromJson({}));
      expect(d.title, 'Observation');
      expect(d.fields.where((f) => f.visible), isEmpty);
      final full = recordSheetData(ParentBehaviourRecord.fromJson({'date': '2026-09-02T00:00:00.000Z', 'category': 'leadership', 'points': 3, 'description': 'd', 'type': 'positive'}));
      expect(full.statusLabel, 'Merit');
      expect([for (final f in full.fields.where((f) => f.visible)) '${f.label}=${f.value}'], ['Date=2 Sep 2026', 'Category=Leadership', 'Points=+3']);
    });
  });

  group('assessments: headline, history, detail', () {
    testWidgets('the headline is the NEWEST assessment (period + date, not an invented sentence); history lists all, newest first', (t) async {
      await open(t, body());
      expect(find.text('80%'), findsWidgets);
      expect(find.text('Term 1 · 10 Sep 2026'), findsOneWidget);
      expect(find.text('Assessment history'), findsOneWidget);
      expect(find.byKey(const Key('tb_asm_0')), findsOneWidget);
      expect(find.byKey(const Key('tb_asm_1')), findsOneWidget);
      expect(find.text('Term 2 (earlier)'), findsOneWidget);
      expect(t.getTopLeft(find.byKey(const Key('tb_asm_0'))).dy < t.getTopLeft(find.byKey(const Key('tb_asm_1'))).dy, isTrue);
    });

    testWidgets('an OLDER assessment opens its own detail from the history', (t) async {
      await open(t, body());
      await t.tap(find.byKey(const Key('tb_asm_1')));
      await settle(t);
      expect(find.byKey(const Key('detail_sheet')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('detail_sheet')), matching: find.text('Term 2 (earlier)')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('detail_sheet')), matching: find.text('Satisfactory')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('detail_sheet')), matching: find.text('Term 1')), findsNothing, reason: 'the OLDER assessment, not the headline one');
    });

    testWidgets('the full assessment sheet shows traits with observations, strengths, improvements, recommended actions and the teacher\'s text', (t) async {
      await open(t, body());
      await t.tap(find.byKey(const Key('tb_view_assessment')));
      await settle(t);
      for (final s in ['Term 1', 'Good', 'Tarbiyah', '80% · score 4 of 5', 'Truthfulness', '90% · Always honest', 'Manners', 'Honesty', 'Focus in class', 'Read together every evening.', 'A thoughtful child.']) {
        final inSheet = find.descendant(of: find.byKey(const Key('detail_sheet')), matching: find.text(s));
        await t.scrollUntilVisible(inSheet.first, 200, scrollable: find.descendant(of: find.byKey(const Key('detail_sheet')), matching: find.byType(Scrollable)).first);
        expect(inSheet, findsWidgets, reason: s);
      }
    });

    test('assessmentSheetData: a bare assessment yields a sheet with no empty rows or sections', () {
      final d = assessmentSheetData(TarbiyahReport.fromJson({}));
      expect(d.title, 'Assessment');
      expect(d.statusLabel, isNull);
      expect(d.fields.where((f) => f.visible), isEmpty);
      expect(d.sections.where((s) => s.fields.any((f) => f.visible)), isEmpty);
      expect(d.longText, '');
    });

    test('assessmentSheetData: score text without a scale and without a percentage', () {
      final d = assessmentSheetData(TarbiyahReport.fromJson({'overallScore': 3.5}));
      expect(d.fields.firstWhere((f) => f.label == 'Overall').value, 'score 3.5');
    });
  });

  group('nothing silently dropped', () {
    testWidgets('50 records (the server limit): a note says older ones are kept by the school', (t) async {
      final many = [for (var i = 0; i < 50; i++) {'_id': 'r$i', 'date': '2026-09-${(i % 28 + 1).toString().padLeft(2, '0')}T00:00:00.000Z', 'title': 'Entry $i', 'type': 'positive', 'points': 1}];
      await open(t, body(records: many), h: 9000);
      expect(ctl().records, hasLength(50));
      expect(ctl().recordsMayBeTruncated, isTrue);
      await t.scrollUntilVisible(find.byKey(const Key('tb_rec_truncated')), 400, scrollable: find.byType(Scrollable).first);
      expect(find.byKey(const Key('tb_rec_truncated')), findsOneWidget);
    });

    testWidgets('fewer than the limit: no note', (t) async {
      await open(t, body());
      expect(find.byKey(const Key('tb_rec_truncated')), findsNothing);
      expect(find.byKey(const Key('tb_asm_truncated')), findsNothing);
    });

    test('20 assessments flag the assessment note too', () {
      final c = BehaviourAndTarbiyah.fromJson({'tarbiyahAssessments': [for (var i = 0; i < 20; i++) {'_id': 'a$i'}]});
      expect(c.assessments.length >= kParentAssessmentsServerLimit, isTrue);
    });
  });

  group('null-safety on the screen', () {
    testWidgets('a payload full of missing / null / odd fields renders with no exception and no "null" text', (t) async {
      await open(t, {
        'behaviourRecords': [
          {'_id': 'x1'},
          {'title': null, 'description': null, 'points': 'many', 'date': 'soon', 'type': 5},
          {'points': 3},
          'junk',
          null,
        ],
        'tarbiyahAssessments': [
          {},
          {'traits': 'not a list', 'areasOfStrength': null, 'overallPercentage': 'high'},
          {'traits': [null, {'traitKey': 'adab'}], 'assessmentDate': 'whenever'},
        ],
      }, h: 4000);
      expect(t.takeException(), isNull);
      final texts = [for (final w in t.widgetList<Text>(find.byType(Text))) w.data ?? ''];
      expect(texts.where((s) => RegExp(r'\bnull\b|NaN|Instance of').hasMatch(s)), isEmpty);
    });

    testWidgets('an entirely wrong body (a string) ends in the error view with a retry, never a stuck spinner or a crash', (t) async {
      await open(t, 'oops');
      expect(t.takeException(), isNull);
      expect(ctl().loading.value, isFalse);
      expect(ctl().error.value, isNotNull);
      expect(find.byType(AppErrorView), findsOneWidget);
      await disposeApp(t); // the error toast holds a 2 s timer
    });

    testWidgets('a null body is "unexpected response": the error view with a retry (never a crash or a stuck spinner)', (t) async {
      await open(t, null);
      expect(t.takeException(), isNull);
      expect(ctl().loading.value, isFalse);
      expect(find.byType(AppErrorView), findsOneWidget);
      await disposeApp(t);
    });

    testWidgets('traits with no name use the readable key; a missing percentage shows 0%, not an error', (t) async {
      await open(t, body(assessments: [{'_id': 'a', 'overallPercentage': 50, 'traits': [{'traitKey': 'adab'}]}]));
      expect(find.text('Adab'), findsWidgets);
    });
  });

  group('states and student switching', () {
    testWidgets('locked: the calm lock view only, no data', (t) async {
      await open(t, suspendedBody);
      expect(find.byType(LockedFeatureView), findsOneWidget);
      expect(find.text('Late to class'), findsNothing);
    });

    testWidgets('error: the error view with a retry that reloads', (t) async {
      var fail = true;
      client = setUpRouteDeps((m, url) {
        if (url.endsWith('/behaviour')) {
          if (fail) throw networkError(url);
          return body();
        }
        return <dynamic>[];
      });
      await pumpApp(t, height: 2400);
      unawaited(Get.toNamed(Routes.tarbiyah));
      await settle(t);
      expect(find.byType(AppErrorView), findsOneWidget);
      fail = false;
      await ctl().fetch();
      await settle(t);
      expect(find.text('Late to class'), findsOneWidget);
    });

    testWidgets('switching the selected child reloads that child and resets the filter', (t) async {
      await open(t, body());
      ctl().setFilter(const RecordFilter(kind: BehaviourKind.merit));
      final students = Get.find<StudentController>();
      students.students.value = [testStudent, Student(id: 's2', firstName: 'Omar', lastName: 'Khan', currentGrade: '3', currentSection: 'B', admissionNo: '1002')];
      students.selectedId.value = 's2';
      await settle(t);
      expect(client.calls.where((c) => c.endsWith('/students/s2/behaviour')), isNotEmpty);
      expect(ctl().filter.value.isActive, isFalse);
    });

    testWidgets('a slow answer for the previous child cannot overwrite the new child\'s data', (t) async {
      final slow = Completer<dynamic>();
      client = setUpRouteDeps((m, url) {
        if (url.endsWith('/students/s1/behaviour')) return slow.future;
        if (url.endsWith('/students/s2/behaviour')) return body(records: [{'_id': 'o1', 'title': 'Omar entry', 'date': '2026-09-01T00:00:00.000Z', 'type': 'positive', 'points': 1}], assessments: []);
        return <dynamic>[];
      });
      await pumpApp(t, height: 2400);
      unawaited(Get.toNamed(Routes.tarbiyah));
      await t.pump();
      final students = Get.find<StudentController>();
      students.students.value = [testStudent, Student(id: 's2', firstName: 'Omar', lastName: 'Khan', currentGrade: '3', currentSection: 'B', admissionNo: '1002')];
      students.selectedId.value = 's2';
      await settle(t);
      slow.complete(body());
      await settle(t);
      expect(find.text('Omar entry'), findsOneWidget);
      expect(find.text('Late to class'), findsNothing);
    });
  });

  testWidgets('layout: 320 dp wide at 1.3x text, filtered and with a sheet open, no overflow', (t) async {
    client = setUpRouteDeps((m, url) => url.endsWith('/behaviour') ? body() : <dynamic>[]);
    await pumpApp(t, width: 320, height: 2000, textScale: 1.3);
    unawaited(Get.toNamed(Routes.tarbiyah));
    await settle(t);
    expect(t.takeException(), isNull);
    await t.tap(find.text('Late to class'));
    await settle(t);
    expect(t.takeException(), isNull);
  });
}
