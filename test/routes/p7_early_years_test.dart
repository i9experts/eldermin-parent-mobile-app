import 'dart:async';
import 'package:eldermin_parent_app/app/modules/early_years/controllers/early_years_controller.dart';
import 'package:eldermin_parent_app/app/modules/early_years/views/early_years_media.dart';
import 'package:eldermin_parent_app/app/modules/more/views/more_screen.dart';
import 'package:eldermin_parent_app/app/modules/students/controllers/student_controller.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:eldermin_parent_app/core/models/early_years_models.dart';
import 'package:eldermin_parent_app/core/models/student.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/p7_fixtures.dart';
import '../support/route_harness.dart';

/// Early Years: every model field the views read is rendered (sentinel values), the More tile appears under exactly the same
/// condition as on main (`EarlyYearsController.eligible`, more_screen.dart), and the screens hold up at 390 dp and 320 dp @1.3x.
Future<void> open(WidgetTester t, String route, {Object? args, double w = 390, double h = 3000, double scale = 1}) async {
  await pumpApp(t, width: w, height: h, textScale: scale);
  unawaited(Get.toNamed(route, arguments: args));
  await settle(t);
}

Finder txt(String s) => find.textContaining(s);

void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);

  for (final (w, scale) in [(390.0, 1.0), (320.0, 1.3)]) {
    group('sentinels @${w}dp @${scale}x', () {
      testWidgets('home: summary fields, entries, tags, and the observations tab', (t) async {
        setUpRouteDeps(p7Api());
        await open(t, Routes.earlyYears, w: w, scale: scale);
        for (final s in [
          'EyFirstSent EyLastSent', // firstName + lastName
          'EyGradeSent - EySecSent', // grade + section
          'Key person: EyKeyPersonSent', // keyPerson
          'EyYearSent', // academicYear
          '2 shared entries', // sharedPortfolioCount
          '3 observations', // sharedObservationCount
          'Last shared 2 Oct 2026', // lastSharedAt
          'EyEntryTitleSent', 'EyEntryTwoSent', // entry titles
          'EyNarrativeSent', // entry narrative (3 lines max)
          '1 Oct 2026', // entry createdAt
        ]) {
          expect(txt(s), findsWidgets, reason: s);
        }
        expect(find.text('Early Years'), findsWidgets, reason: 'the app bar title and the programme tag');
        expect(find.text('Photo unavailable'), findsWidgets, reason: 'a null photo url is the honest placeholder');
        // observations
        await t.tap(find.text('Shared observations'));
        await settle(t);
        for (final s in ['EyObsNarrativeSent', '3 Oct 2026', 'EySkillSent', 'EySkillTwoSent']) {
          expect(txt(s), findsWidgets, reason: s);
        }
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });

      testWidgets('entry detail: title, date, narrative, try-at-home, photos, the video placeholder and the viewer caption', (t) async {
        setUpRouteDeps(p7Api());
        final entry = EyPortfolioEntry.fromJson(eyEntrySent('e1'));
        await open(t, Routes.earlyYearsEntry, args: entry, w: w, scale: scale);
        for (final s in ['EyEntryTitleSent', '1 Oct 2026', 'EyNarrativeSent', 'Try this at home', 'EyTryHomeSent', 'Photo unavailable']) {
          expect(txt(s), findsWidgets, reason: s);
        }
        // the strip scrolls sideways: the third item (a video) is built once it is brought into view
        await t.drag(find.byType(EyMediaStrip), const Offset(-600, 0));
        await settle(t);
        expect(txt('Video (not viewable in the app yet)'), findsWidgets);
        await t.drag(find.byType(EyMediaStrip), const Offset(600, 0));
        await settle(t);
        // a photo with a link opens full screen with its caption (the image itself cannot load in a test)
        final withUrl = find.byWidgetPredicate((x) => x is EyMediaView && x.media.url != null);
        expect(withUrl, findsOneWidget);
        await t.tap(withUrl);
        await settle(t);
        expect(find.byType(EyPhotoViewer), findsOneWidget);
        expect(find.text('EyCaptionSent'), findsOneWidget, reason: 'media[].caption');
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });

      testWidgets('observation detail: date, narrative, learning areas with levels, next step, attachment placeholder', (t) async {
        setUpRouteDeps(p7Api());
        final obs = EyObservation.fromJson(eyObservationSent('o1'));
        await open(t, Routes.earlyYearsObservation, args: obs, w: w, scale: scale);
        for (final s in ['3 Oct 2026', 'EyObsNarrativeSent', 'Learning areas', 'EySkillSent', 'EyLevelSent', 'EySkillTwoSent', 'Next step', 'EyNextStepSent', 'Work sample (not viewable in the app yet)']) {
          expect(txt(s), findsWidgets, reason: s);
        }
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });
    });
  }

  group('home states', () {
    testWidgets('load more appends the next page and then goes away', (t) async {
      final client = setUpRouteDeps(p7Api(pages: true));
      await open(t, Routes.earlyYears);
      expect(txt('EyEntryOneSent'), findsOneWidget);
      expect(txt('EyEntryTwoSent'), findsNothing);
      await t.ensureVisible(find.byKey(const Key('ey_load_more')));
      await t.pump();
      await t.tap(find.byKey(const Key('ey_load_more')));
      await settle(t);
      expect(txt('EyEntryTwoSent'), findsOneWidget);
      expect(find.byKey(const Key('ey_load_more')), findsNothing);
      expect(client.calls.where((c) => c.endsWith('/early-years/portfolio')).length, 2);
      await disposeApp(t);
    });

    for (final (w, h, scale) in [(390.0, 844.0, 1.0), (320.0, 640.0, 1.3)]) {
      testWidgets('loading skeleton, error + retry, empty and not-eligible @${w}dp @${scale}x', (t) async {
        final hold = Completer<dynamic>();
        setUpRouteDeps(p7Api(hold: hold));
        await open(t, Routes.earlyYears, w: w, h: h, scale: scale);
        expect(find.byKey(const Key('ey_loading')), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(t.takeException(), isNull);
        hold.complete(<dynamic>[]);
        await settle(t);
        await disposeApp(t);

        setUpRouteDeps(p7Api(portfolioFails: true));
        await open(t, Routes.earlyYears, w: w, h: h, scale: scale);
        expect(find.byType(EmErrorState), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(t.takeException(), isNull);
        await disposeApp(t);

        setUpRouteDeps(p7Api(portfolio: 0, observations: 0));
        await open(t, Routes.earlyYears, w: w, h: h, scale: scale);
        expect(t.takeException(), isNull);
        await disposeApp(t);

        setUpRouteDeps(p7Api(eligible: false));
        await open(t, Routes.earlyYears, w: w, h: h, scale: scale);
        expect(find.text("Early Years isn't available for this child"), findsOneWidget);
        expect(find.byType(EmAppBar), findsOneWidget);
        for (final text in t.widgetList<Text>(find.byType(Text))) {
          final size = text.style?.fontSize;
          if (size != null) expect(size, greaterThanOrEqualTo(12), reason: '"${text.data}" is $size sp');
        }
        await disposeApp(t);
      });
    }
  });

  group('More tile: the same visibility condition as on main', () {
    // main: more_screen.dart `Get.isRegistered<EarlyYearsController>() && Get.find<EarlyYearsController>().eligible`, and
    // early_years_controller.dart:72 `summary != null && summary.isEarlyYears && summary.studentId == selected child`.
    Future<void> more(WidgetTester t) async {
      await pumpApp(t, home: const Scaffold(body: MoreScreen()), height: 3000);
      await settle(t);
    }

    Finder tile() => find.byKey(const Key('service_Early Years'));

    testWidgets('shown for an Early Years child, in "My child" after Home tasks and before "School & family", and opens the same route', (t) async {
      setUpRouteDeps(p7Api());
      await more(t);
      expect(tile(), findsOneWidget);
      double y(Finder f) => t.getTopLeft(f).dy;
      expect(y(find.text('My child')), lessThan(y(tile())));
      expect(y(find.byKey(const Key('service_Home tasks'))), lessThanOrEqualTo(y(tile())));
      expect(y(tile()), lessThan(y(find.text('School & family'))));
      await t.ensureVisible(tile());
      await t.pump();
      await t.tap(tile());
      await settle(t);
      expect(Get.currentRoute, Routes.earlyYears);
      await disposeApp(t);
    });

    testWidgets('hidden for a child outside Early Years (the rest of the menu is unchanged)', (t) async {
      setUpRouteDeps(p7Api(eligible: false));
      await more(t);
      expect(tile(), findsNothing);
      expect(find.byKey(const Key('service_Class diary')), findsOneWidget);
      await disposeApp(t);
    });

    testWidgets('hidden when the summary call fails, and nothing crashes', (t) async {
      setUpRouteDeps(p7Api(summaryFails: true));
      await more(t);
      expect(tile(), findsNothing);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });

    testWidgets('hidden while the summary is still loading', (t) async {
      final hold = Completer<dynamic>();
      setUpRouteDeps(p7Api(hold: hold));
      await more(t);
      expect(tile(), findsNothing);
      hold.complete(<dynamic>[]);
      await settle(t);
      await disposeApp(t);
    });

    testWidgets('follows the selected child: shown for s1, hidden after switching to a child outside EY, shown again for s1', (t) async {
      setUpRouteDeps((m, url) {
        if (url.endsWith('/students/s2/early-years/summary')) return eySummarySent(id: 's2', ey: false);
        return p7Api()(m, url);
      });
      final students = Get.find<StudentController>();
      students.students.value = [testStudent, Student(id: 's2', firstName: 'Omar', lastName: 'Khan', currentGrade: '3')];
      await more(t);
      expect(tile(), findsOneWidget);
      students.selectStudent('s2');
      await settle(t);
      expect(tile(), findsNothing, reason: 'the summary now belongs to a child outside Early Years');
      students.selectStudent('s1');
      await settle(t);
      expect(tile(), findsOneWidget);
      await disposeApp(t);
    });

    testWidgets('hidden when the held summary belongs to another child than the selected one', (t) async {
      setUpRouteDeps(p7Api());
      await more(t);
      final c = Get.find<EarlyYearsController>();
      expect(c.eligible, isTrue);
      c.summary.value = EySummary.fromJson(eySummarySent(id: 'someone-else'));
      await t.pump();
      expect(c.eligible, isFalse);
      expect(tile(), findsNothing);
      await disposeApp(t);
    });

    testWidgets('logout resets it: after AuthController.logout the controller no longer reports eligible', (t) async {
      setUpRouteDeps(p7Api());
      await more(t);
      final c = Get.find<EarlyYearsController>();
      expect(c.eligible, isTrue);
      c.reset(); // what auth_controller.dart:91 calls on logout
      await t.pump();
      expect(c.eligible, isFalse);
      expect(tile(), findsNothing);
      await disposeApp(t);
    });
  });
}
