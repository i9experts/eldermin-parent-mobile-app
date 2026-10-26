import 'dart:async';
import 'package:eldermin_parent_app/app/modules/early_years/controllers/early_years_controller.dart';
import 'package:eldermin_parent_app/app/modules/early_years/views/early_years_detail_screens.dart';
import 'package:eldermin_parent_app/app/modules/early_years/views/early_years_screen.dart';
import 'package:eldermin_parent_app/app/modules/more/views/more_screen.dart';
import 'package:eldermin_parent_app/core/models/early_years_models.dart';
import 'package:eldermin_parent_app/core/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/early_years_fakes.dart';

late FakeEyApi api;

Future<EarlyYearsController> boot(WidgetTester t, Widget screen, {String child = 's1'}) async {
  Get.reset();
  api = FakeEyApi();
  return _bootWith(t, screen, child);
}

Future<EarlyYearsController> _bootWith(WidgetTester t, Widget screen, String child) async {
  final students = studentsOf(api, [kid('s1'), kid('s2', name: 'Omar')], selected: child);
  Get.put(students);
  final c = Get.put(EarlyYearsController(api: api, students: students));
  await t.pumpWidget(GetMaterialApp(home: screen));
  return c;
}

/// Pump a few frames without waiting for endless spinners (pumpAndSettle would hang on them).
Future<void> frames(WidgetTester t, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(const Duration(milliseconds: 30));
  }
}

void main() {
  tearDown(Get.reset);

  testWidgets('shows the summary card and the shared portfolio entries', (t) async {
    final c = await boot(t, const EarlyYearsScreen());
    api.summary = (id) async => eySummaryJson(id, portfolio: 2);
    api.portfolio = (id, p) async => eyPage([eyItem('e1', title: 'Painting'), eyItem('e2', title: 'Sand play')], total: 2);
    await c.loadSummary();
    await frames(t);
    expect(find.text('Early Years'), findsWidgets);
    expect(find.text('Ayesha Khan'), findsOneWidget);
    expect(find.text('Nursery - A'), findsOneWidget);
    expect(find.text('Key person: Ms Sara'), findsOneWidget);
    expect(find.text('2 shared entries'), findsOneWidget);
    expect(find.text('Painting'), findsOneWidget);
    expect(find.text('Sand play'), findsOneWidget);
  });

  testWidgets('nothing shared yet is an honest empty state', (t) async {
    final c = await boot(t, const EarlyYearsScreen());
    api.summary = (id) async => eySummaryJson(id, portfolio: 0);
    await c.loadSummary();
    await frames(t);
    expect(find.text('Nothing shared yet'), findsOneWidget);
    expect(find.text('Shared observations'), findsNothing); // no observations: no tab
  });

  testWidgets('a load error shows the message and a working retry', (t) async {
    final c = await boot(t, const EarlyYearsScreen());
    api.summary = (id) async => eySummaryJson(id);
    api.portfolio = (id, p) async => throw ApiException('x', statusCode: 403);
    await c.loadSummary();
    await frames(t);
    expect(find.text("You don't have access to this child's Early Years record."), findsOneWidget);
    api.portfolio = (id, p) async => eyPage([eyItem('e1', title: 'Recovered')]);
    await t.tap(find.text('Try again'));
    await frames(t);
    expect(find.text('Recovered'), findsOneWidget);
  });

  testWidgets('a child outside Early Years sees the plain not-available state, no data calls', (t) async {
    final c = await boot(t, const EarlyYearsScreen());
    api.summary = (id) async => eySummaryJson(id, ey: false);
    await c.loadSummary();
    await frames(t);
    expect(find.text("Early Years isn't available for this child"), findsOneWidget);
    expect(api.log.any((l) => l.startsWith('portfolio')), isFalse);
  });

  testWidgets('the observations tab appears only when there are shared observations, and lists them with learning areas', (t) async {
    final c = await boot(t, const EarlyYearsScreen());
    api.summary = (id) async => eySummaryJson(id, observations: 1);
    api.observations = (id, p) async => eyPage([
          {'id': 'o1', 'type': 'learning_story', 'narrative': 'Built a tower', 'nextStep': 'Count blocks', 'createdAt': '2026-10-01T10:00:00Z',
            'learningAreas': [{'skill': 'Pencil Control', 'level': 'Developing'}], 'media': []},
        ]);
    await c.loadSummary();
    await frames(t);
    expect(find.text('Shared observations'), findsOneWidget);
    await t.tap(find.text('Shared observations'));
    await frames(t);
    expect(find.text('Built a tower'), findsOneWidget);
    expect(find.text('Pencil Control'), findsOneWidget);
  });

  testWidgets('a photo whose link is missing shows "Photo unavailable", never a broken image', (t) async {
    final c = await boot(t, const EarlyYearsScreen());
    api.summary = (id) async => eySummaryJson(id);
    api.portfolio = (id, p) async => eyPage([eyItem('e1', media: [{'type': 'photo', 'url': null, 'caption': null}])]);
    await c.loadSummary();
    await frames(t);
    expect(find.text('Photo unavailable'), findsOneWidget);
  });

  testWidgets('an image that fails to load asks for fresh links (expired signed URL)', (t) async {
    final c = await boot(t, const EarlyYearsScreen());
    api.summary = (id) async => eySummaryJson(id);
    api.portfolio = (id, p) async => eyPage([eyItem('e1', media: [{'type': 'photo', 'url': 'https://example.invalid/a.jpg?sig=old', 'caption': null}])]);
    await c.loadSummary();
    await frames(t, 12);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await frames(t, 12);
    expect(find.text('Photo unavailable'), findsWidgets);
    expect(api.log.where((l) => l.startsWith('portfolio:')).length, greaterThanOrEqualTo(2)); // initial + refresh after the failure
  });

  testWidgets('entry detail: narrative, try-this-at-home callout, photo unavailable placeholder', (t) async {
    final entry = EyPortfolioEntry.fromJson({
      'id': 'e1', 'title': 'Painting', 'narrative': 'Mixed colours', 'tryThisAtHome': 'Paint with water', 'createdAt': '2026-10-01T10:00:00Z',
      'media': [{'type': 'photo', 'url': null, 'caption': null}],
    });
    final c = await boot(t, EarlyYearsEntryScreen(initial: entry));
    api.summary = (id) async => eySummaryJson(id);
    api.entry = (id, e) async => throw ApiException('offline');
    await c.loadSummary();
    await frames(t);
    expect(find.text('Painting'), findsOneWidget);
    expect(find.text('Mixed colours'), findsOneWidget);
    expect(find.text('Try this at home'), findsOneWidget);
    expect(find.text('Paint with water'), findsOneWidget);
    expect(find.text('Photo unavailable'), findsOneWidget);
    expect(api.log, contains('entry:s1:e1')); // refreshed on open for fresh links
  });

  testWidgets('entry detail without try-this-at-home shows no callout', (t) async {
    final entry = EyPortfolioEntry.fromJson({'id': 'e1', 'title': 'Painting', 'narrative': 'n', 'createdAt': '2026-10-01T10:00:00Z', 'media': []});
    await boot(t, EarlyYearsEntryScreen(initial: entry));
    api.entry = (id, e) async => throw ApiException('offline');
    await frames(t);
    expect(find.text('Try this at home'), findsNothing);
  });

  group('More tile visibility', () {
    Future<void> openMore(WidgetTester t, String child, bool ey) async {
      Get.reset();
      api = FakeEyApi()..summary = (id) async => eySummaryJson(id, ey: ey);
      await _bootWith(t, const Scaffold(body: MoreScreen()), child);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await frames(t);
    }

    testWidgets('shown for an Early Years child', (t) async {
      await openMore(t, 's1', true);
      expect(find.text('Early Years'), findsOneWidget);
    });

    testWidgets('not shown for a child outside Early Years', (t) async {
      await openMore(t, 's2', false);
      expect(find.text('Early Years'), findsNothing);
      expect(find.text('Class diary'), findsOneWidget); // the rest of the menu is unchanged
    });

    testWidgets('not shown when the summary call fails, and nothing crashes', (t) async {
      Get.reset();
      api = FakeEyApi()..summary = (id) async => throw ApiException('offline');
      await _bootWith(t, const Scaffold(body: MoreScreen()), 's1');
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await frames(t);
      expect(find.text('Early Years'), findsNothing);
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('while the list loads the screen shows shimmer skeletons (the app\'s loading style), not a bare spinner', (t) async {
    final c = await boot(t, const EarlyYearsScreen());
    final gate = Completer<Map<String, dynamic>>();
    api.summary = (id) async => eySummaryJson(id, portfolio: 1);
    api.portfolio = (id, p) => gate.future;
    await c.loadSummary();
    await frames(t);
    expect(find.byKey(const Key('ey_loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    gate.complete(eyPage([eyItem('e1', title: 'Painting')], total: 1));
    await frames(t);
    expect(find.byKey(const Key('ey_loading')), findsNothing);
    expect(find.text('Painting'), findsOneWidget);
  });

  testWidgets('while the summary is still loading the first paint is a shimmer skeleton', (t) async {
    final gate = Completer<Map<String, dynamic>>();
    Get.reset();
    api = FakeEyApi()..summary = (id) => gate.future;
    final students = studentsOf(api, [kid('s1')], selected: 's1');
    Get.put(students);
    final c = Get.put(EarlyYearsController(api: api, students: students));
    await t.pumpWidget(GetMaterialApp(home: const EarlyYearsScreen()));
    await frames(t);
    expect(c.summaryLoading.value, isTrue);
    expect(find.byKey(const Key('ey_loading')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    gate.complete(eySummaryJson('s1', portfolio: 0));
    await frames(t);
  });
}
