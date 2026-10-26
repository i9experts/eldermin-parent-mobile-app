import 'dart:async';
import 'package:eldermin_parent_app/app/modules/events/views/events_calendar_screen.dart';
import 'package:eldermin_parent_app/app/modules/home/controllers/home_shell_controller.dart';
import 'package:eldermin_parent_app/app/modules/home/views/home_shell.dart';
import 'package:eldermin_parent_app/app/modules/messages/views/messages_screen.dart';
import 'package:eldermin_parent_app/app/modules/more/views/more_screen.dart';
import 'package:eldermin_parent_app/app/modules/results/views/results_screen.dart';
import 'package:eldermin_parent_app/app/modules/auth/controllers/auth_controller.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:eldermin_parent_app/core/widgets/app_widgets.dart';
import 'package:eldermin_parent_app/core/widgets/em_tab_heading.dart';
import 'package:eldermin_parent_app/core/widgets/em_tile_grid.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/p3_fixtures.dart';
import '../support/route_harness.dart';

/// P3: the four tab roots and the converted screens (attendance, homework, timetable, notifications, message thread):
/// every state, 320 dp at 1.3x text, one title per screen, no week strip, behaviour unchanged.
final tabs = <String, Widget>{
  'Progress': const ResultsScreen(),
  'Calendar': const EventsCalendarScreen(),
  'Messages': const MessagesScreen(),
  'More': const MoreScreen(),
};

final pushed = <String, (String, Object?)>{
  'attendance': (Routes.attendance, null),
  'homework': (Routes.homework, null),
  'timetable': (Routes.timetable, null),
  'notifications': (Routes.notifications, null),
  'message thread': (Routes.messageThread, {'threadId': 't1', 'subject': 'Homework help', 'staffName': 'Ms Sara Ahmed', 'studentName': 'Ayesha Khan'}),
};

Future<void> openTab(WidgetTester t, Widget tab, {double width = 390, double height = 844, double scale = 1}) async {
  await pumpApp(t, home: Scaffold(body: tab), width: width, height: height, textScale: scale);
  await settle(t);
}

void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);

  group('tab roots', () {
    for (final e in tabs.entries) {
      for (final (w, scale) in [(390.0, 1.0), (320.0, 1.3)]) {
        testWidgets('${e.key}: data at ${w}dp @${scale}x, one TabHeading, no week strip', (t) async {
          setUpRouteDeps(p3Api());
          await openTab(t, e.value, width: w, height: w == 320 ? 640 : 844, scale: scale);
          expect(find.byType(TabHeading), findsOneWidget);
          expect(find.byType(AppWeekDateStrip), findsNothing);
          expect(find.byType(EmDateStrip), findsNothing);
          expect(t.takeException(), isNull);
          await disposeApp(t);
        });
      }

      testWidgets('${e.key}: the title stays when loading, failing and empty', (t) async {
        final hold = Completer<dynamic>();
        setUpRouteDeps(p3Api(hold: hold));
        await openTab(t, e.value);
        if (e.key != 'More') expect(find.byType(TabHeading), findsOneWidget, reason: 'loading');
        hold.complete(<dynamic>[]);
        await settle(t);
        await disposeApp(t);

        setUpRouteDeps((m, url) => throw networkError(url));
        await openTab(t, e.value);
        expect(find.byType(TabHeading), findsOneWidget, reason: 'error');
        expect(t.takeException(), isNull);
        await disposeApp(t);

        setUpRouteDeps(p3Api(empty: true));
        await openTab(t, e.value);
        expect(find.byType(TabHeading), findsOneWidget, reason: 'empty');
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });
    }

    testWidgets('Progress: hero, subject scores and the assessment chip; the duplicate stat row is gone', (t) async {
      setUpRouteDeps(p3Api());
      await openTab(t, const ResultsScreen());
      expect(find.byType(EmHeroCard), findsOneWidget);
      expect(find.text('Subject scores'), findsOneWidget);
      for (final s in ['Mathematics', 'English', 'Science']) {
        expect(find.text(s), findsOneWidget);
      }
      expect(find.text('Mid-term 2026'), findsWidgets); // the chip and the trend chart's label
      expect(find.text('Performance trend'), findsOneWidget);
      await disposeApp(t);
    });

    testWidgets('Progress: error shows the kit error with retry; empty the empty state', (t) async {
      setUpRouteDeps((m, url) => throw networkError(url));
      await openTab(t, const ResultsScreen());
      expect(find.byType(EmErrorState), findsOneWidget);
      await t.tap(find.text('Try again'));
      await settle(t);
      await disposeApp(t);
      setUpRouteDeps(p3Api(empty: true));
      await openTab(t, const ResultsScreen());
      expect(find.text('No results published yet'), findsOneWidget);
      await disposeApp(t);
    });

    testWidgets('Messages: rows show name, topic, preview, time and the unread dot; tapping opens the thread with the same arguments', (t) async {
      setUpRouteDeps(p3Api());
      await openTab(t, const MessagesScreen());
      expect(find.text('Ms Sara Ahmed'), findsOneWidget);
      expect(find.text('re Ayesha Khan · Homework help'), findsOneWidget);
      expect(find.byKey(const Key('unread_t1')), findsOneWidget);
      expect(find.byKey(const Key('unread_t2')), findsNothing);
      expect(find.text('Unread'), findsOneWidget);
      expect(find.text('Communication health'), findsOneWidget);
      await t.tap(find.byKey(const Key('thread_t1')));
      await settle(t);
      expect(Get.currentRoute, Routes.messageThread);
      expect((Get.arguments as Map)['threadId'], 't1');
      expect((Get.arguments as Map)['staffName'], 'Ms Sara Ahmed');
      await disposeApp(t);
    });

    testWidgets('Calendar: the month chip opens the month picker in a kit sheet; days toggle; an event opens its sheet', (t) async {
      setUpRouteDeps(p3Api());
      await openTab(t, const EventsCalendarScreen());
      expect(find.byKey(const Key('month_chip')), findsOneWidget);
      expect(find.text('Events'), findsOneWidget);
      expect(find.text('Parent-teacher meeting'), findsOneWidget);
      // tap the 10th: the list narrows to that day
      await t.tap(find.bySemanticsLabel(RegExp(r'^10 ')).first);
      await settle(t);
      expect(find.text('Mid-term exams'), findsNothing);
      await t.tap(find.bySemanticsLabel(RegExp(r'^10 ')).first);
      await settle(t);
      expect(find.text('Mid-term exams'), findsOneWidget);
      await t.tap(find.text('Parent-teacher meeting'));
      await settle(t);
      expect(find.byType(EmBottomSheet), findsOneWidget);
      expect(find.text('School hall'), findsWidgets);
      await t.tapAt(const Offset(10, 10));
      await settle(t);
      await t.tap(find.byKey(const Key('month_chip')));
      await settle(t);
      expect(find.text('Select month'), findsOneWidget);
      await t.tap(find.text('Jump to this month'));
      await settle(t);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });

    testWidgets('More: no count row; every entry is a kit tile and keeps its destination; logout asks first', (t) async {
      setUpRouteDeps(p3Api());
      await openTab(t, const MoreScreen());
      expect(find.text('Services'), findsNothing);
      expect(find.text('Children linked'), findsNothing);
      expect(find.byType(StatsRow), findsNothing);
      expect(find.byType(GridView), findsNothing);
      expect(find.byType(EmTileGrid), findsNWidgets(2));
      expect(find.byKey(const Key('more_child_card')), findsOneWidget);
      const destinations = {
        'Class diary': Routes.diary,
        'My courses': Routes.courses,
        'Online quizzes': Routes.quizzes,
        'Learning resources': Routes.learningResources,
        'Library': Routes.library,
        'Behaviour & Tarbiyah': Routes.tarbiyah,
        'Student profile': Routes.profile,
        'Medical': Routes.medical,
        'Academic documents': Routes.documents,
        'Consent': Routes.consent,
        'My leaves': Routes.leaves,
        'Home tasks': Routes.homeTasks,
        'Datesheet': Routes.datesheet,
        'Parent-teacher meetings': Routes.ptm,
        'Circulars': Routes.circulars,
        'Inbox': Routes.notifications,
        'Feedback': Routes.feedback,
        'Privacy policy': Routes.privacyPolicy,
        'About us': Routes.aboutUs,
        'Help': Routes.help,
      };
      for (final d in destinations.entries) {
        final tile = find.byKey(Key('service_${d.key}'));
        await t.scrollUntilVisible(tile, 200, scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
        await t.ensureVisible(tile);
        await t.pump();
        await t.tap(tile);
        await settle(t);
        expect(Get.currentRoute, d.value, reason: d.key);
        Get.back();
        await settle(t);
      }
      // Switch user -> Coming soon (no fabricated data)
      final sw = find.byKey(const Key('service_Switch user'));
      await t.scrollUntilVisible(sw, 200, scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
        await t.ensureVisible(sw);
        await t.pump();
      await t.tap(sw);
      await settle(t);
      expect(find.text('This screen is still being built'), findsOneWidget);
      Get.back();
      await settle(t);
      for (final q in {'Attendance': Routes.attendance, 'Homework': Routes.homework, 'Dues': Routes.dues, 'Timetable': Routes.timetable}.entries) {
        final tile = find.byKey(Key('quick_${q.key}'));
        await t.scrollUntilVisible(tile, -200, scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
        await t.ensureVisible(tile);
        await t.pump();
        await t.tap(tile);
        await settle(t);
        expect(Get.currentRoute, q.value, reason: q.key);
        Get.back();
        await settle(t);
      }
      // logout: a kit dialog; Cancel keeps the session
      final lo = find.byKey(const Key('service_Logout'));
      await t.scrollUntilVisible(lo, 200, scrollable: find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first);
        await t.ensureVisible(lo);
        await t.pump();
      await t.tap(lo);
      await settle(t);
      expect(find.byType(EmDialog), findsOneWidget);
      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await settle(t);
      expect(Get.find<AuthController>().status.value, AuthStatus.authenticated);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });
  });

  group('pushed screens', () {
    for (final e in pushed.entries) {
      for (final (w, scale) in [(390.0, 1.0), (320.0, 1.3)]) {
        testWidgets('${e.key}: data at ${w}dp @${scale}x, one title (the app bar), no week strip', (t) async {
          setUpRouteDeps(p3Api());
          await pumpApp(t, width: w, height: w == 320 ? 640 : 844, textScale: scale);
          unawaited(Get.toNamed(e.value.$1, arguments: e.value.$2));
          await settle(t);
          expect(find.byType(EmAppBar), findsOneWidget);
          expect(find.byType(ScreenIntro).evaluate().length, lessThanOrEqualTo(1));
          expect(find.byType(AppWeekDateStrip), findsNothing);
          expect(t.takeException(), isNull);
          await disposeApp(t);
        });
      }
    }

    testWidgets('attendance: month chip picks a month; hero, trend and rows show', (t) async {
      setUpRouteDeps(p3Api());
      await pumpApp(t);
      unawaited(Get.toNamed(Routes.attendance));
      await settle(t);
      expect(find.text('Monthly attendance'.toUpperCase()), findsNothing);
      expect(find.byType(EmHeroCard), findsOneWidget);
      expect(find.text('Present'), findsWidgets);
      expect(find.text('Absent'), findsWidgets);
      expect(find.text('Late'), findsWidgets);
      expect(find.text('6-month trend'), findsOneWidget);
      await t.tap(find.byType(EmChip).first);
      await settle(t);
      expect(find.text('Select month'), findsOneWidget);
      await disposeApp(t);
    });

    testWidgets('homework: filter, detail sheet, submit calls the API once, graded rows show score and feedback', (t) async {
      final client = setUpRouteDeps(p3Api());
      await pumpApp(t);
      unawaited(Get.toNamed(Routes.homework));
      await settle(t);
      expect(find.text('Score: 8/10'), findsOneWidget);
      expect(find.textContaining('Feedback: Well structured'), findsOneWidget);
      expect(find.text('Overdue'), findsWidgets);
      expect(find.text('Submitted'), findsWidgets);
      await t.tap(find.descendant(of: find.byType(EmSegmentedTabs<int>), matching: find.text('Pending')));
      await settle(t);
      expect(find.text('Book report'), findsNothing);
      await t.tap(find.text('All tasks'));
      await settle(t);
      // open the sheet of a pending homework
      await t.tap(find.text('Fractions worksheet - page 14 to 16'));
      await settle(t);
      expect(find.byType(EmBottomSheet), findsOneWidget);
      expect(find.text('Solve all questions.'), findsOneWidget);
      expect(find.byType(EmTextField), findsOneWidget);
      // empty answer -> no API call
      final before = client.calls.where((c) => c.startsWith('POST')).length;
      await t.tap(find.text('Submit'));
      await settle(t);
      expect(client.calls.where((c) => c.startsWith('POST')).length, before);
      await t.enterText(find.byType(EmTextField), 'My answer');
      await t.tap(find.text('Submit'));
      await settle(t);
      expect(client.calls.where((c) => c.startsWith('POST') && c.contains('/homework/h1/submit')).length, 1);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 4));
      await disposeApp(t);
    });

    testWidgets('homework: a graded task shows the read-only sheet, one without a submission explains why', (t) async {
      setUpRouteDeps(p3Api());
      await pumpApp(t);
      unawaited(Get.toNamed(Routes.homework));
      await settle(t);
      await t.tap(find.text('Book report'));
      await settle(t);
      expect(find.text('Graded - this can no longer be resubmitted.'), findsOneWidget);
      expect(find.byType(EmTextField), findsNothing);
      await t.tapAt(const Offset(10, 10));
      await settle(t);
      expect(find.byType(EmBottomSheet), findsNothing);
      await t.drag(find.byType(ListView).first, const Offset(0, -500));
      await settle(t);
      await t.ensureVisible(find.text('Not on the roster yet'));
      await t.pump();
      await t.tap(find.text('Not on the roster yet'));
      await settle(t);
      expect(find.textContaining("isn't on your child's class roster"), findsOneWidget);
      await disposeApp(t);
    });

    testWidgets('timetable: periods as a timeline, the weekday chip opens the kit picker and changes the day', (t) async {
      setUpRouteDeps(p3Api());
      await pumpApp(t);
      unawaited(Get.toNamed(Routes.timetable));
      await settle(t);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Day progress'), findsOneWidget);
      expect(find.text('Periods'), findsOneWidget);
      await t.tap(find.byType(EmChip).first);
      await settle(t);
      expect(find.text('Select day'), findsOneWidget);
      await t.tap(find.byKey(const Key('weekday_0')));
      await settle(t);
      expect(find.text('Select day'), findsNothing);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });

    testWidgets('notifications: unread dots, tap marks read and opens the same route, "Mark all read" is in the app bar', (t) async {
      final client = setUpRouteDeps(p3Api());
      await pumpApp(t);
      unawaited(Get.toNamed(Routes.notifications));
      await settle(t);
      expect(find.byKey(const Key('unread_n1')), findsOneWidget);
      expect(find.byKey(const Key('unread_n3')), findsNothing);
      expect(find.text('Mark all read'), findsOneWidget);
      await t.tap(find.text('New homework: Fractions worksheet'));
      await settle(t);
      expect(client.calls.any((c) => c.contains('/notifications/n1/read')), isTrue);
      expect(Get.currentRoute, Routes.homework);
      await disposeApp(t);
    });

    testWidgets('message thread: bubbles on both sides, send posts the text', (t) async {
      final client = setUpRouteDeps(p3Api());
      await pumpApp(t);
      unawaited(Get.toNamed(Routes.messageThread, arguments: {'threadId': 't1', 'subject': 'Homework help', 'staffName': 'Ms Sara Ahmed', 'studentName': 'Ayesha Khan'}));
      await settle(t);
      expect(find.text('Ms Sara Ahmed'), findsOneWidget);
      expect(find.text('Re: Ayesha Khan'), findsOneWidget);
      expect(find.text('Hello! Ayesha did very well in the quiz today.'), findsOneWidget);
      expect(find.text('Thank you so much, that is lovely to hear.'), findsOneWidget);
      await t.enterText(find.byType(TextField), 'See you tomorrow');
      await t.tap(find.byKey(const Key('send_message')));
      await settle(t);
      expect(client.calls.any((c) => c.startsWith('POST') && c.contains('/threads/t1/messages')), isTrue);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });
  });

  group('shell: five tabs', () {
    testWidgets('every tab root opens from the nav at 320 dp @1.3x without overflow', (t) async {
      setUpRouteDeps(p3Api());
      await pumpApp(t, home: const HomeShell(), width: 320, height: 640, textScale: 1.3);
      await settle(t);
      final shell = Get.find<HomeShellController>();
      for (final (i, label) in ['Progress', 'Calendar', 'Messages', 'More'].indexed) {
        await t.tap(find.descendant(of: find.byKey(HomeShell.navKey), matching: find.text(label)));
        await settle(t);
        expect(shell.tabIndex.value, i + 1);
        expect(find.byType(TabHeading), findsOneWidget, reason: label);
        expect(t.takeException(), isNull, reason: label);
      }
      await disposeApp(t);
    });
  });
}
