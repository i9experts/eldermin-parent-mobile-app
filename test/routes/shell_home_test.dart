import 'dart:async';
import 'package:eldermin_parent_app/app/modules/auth/controllers/auth_controller.dart';
import 'package:eldermin_parent_app/app/modules/home/controllers/home_shell_controller.dart';
import 'package:eldermin_parent_app/app/modules/home/views/home_shell.dart';
import 'package:eldermin_parent_app/app/modules/students/controllers/student_controller.dart';
import 'package:eldermin_parent_app/core/constants/api_constants.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:eldermin_parent_app/core/models/student.dart';
import 'package:eldermin_parent_app/core/utils/greeting.dart';
import 'package:eldermin_parent_app/core/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/route_harness.dart';

/// The shell (greeting header + child switcher, bell, five tabs, kit bottom nav) and the Home tab, in every state.
final ayesha = testStudent;
final bilal = Student(id: 's2', firstName: 'Bilal', lastName: 'Khan', currentGrade: '3', currentSection: 'B', admissionNo: '1002');

typedef Respond = FutureOr<dynamic> Function(String method, String url);

/// Answers by endpoint; unknown endpoints answer an empty list.
Respond homeApi({Object? attendance, Object? homework, Object? dues, Object? events, bool failAttendance = false, Completer<dynamic>? hold}) {
  return (m, url) {
    if (hold != null && url.contains('/students/')) {
      return hold.future;
    }
    if (url == ApiConstants.myStudents) {
      return [
        {'_id': 's1', 'firstName': 'Ayesha', 'lastName': 'Khan', 'currentGrade': '5', 'currentSection': 'A'},
        {'_id': 's2', 'firstName': 'Bilal', 'lastName': 'Khan', 'currentGrade': '3', 'currentSection': 'B'},
      ];
    }
    if (url.endsWith('/attendance')) {
      if (failAttendance) throw networkError(url);
      return attendance ?? <dynamic>[];
    }
    if (url.endsWith('/homework')) return homework ?? <dynamic>[];
    if (url.endsWith('/dues')) return dues ?? <dynamic>[];
    if (url == ApiConstants.events) return events ?? <dynamic>[];
    return <dynamic>[];
  };
}

final attendanceFixture = [
  {'status': 'present'},
  {'status': 'present'},
  {'status': 'late'},
  {'status': 'absent'},
];

final homeworkFixture = [
  {'_id': 'h1', 'subject': 'Maths', 'title': 'Fractions worksheet', 'dueDate': '2026-10-28T00:00:00.000Z', 'mySubmission': null},
  {'_id': 'h2', 'subject': 'Science', 'title': 'Plant diary', 'dueDate': '2026-10-30T00:00:00.000Z', 'mySubmission': {'status': 'submitted'}},
];

Future<FakeClient> pumpShell(WidgetTester t, Respond respond, {double scale = 1, bool twoStudents = false, double width = 390, double height = 844}) async {
  final client = setUpRouteDeps(respond);
  if (twoStudents) Get.find<StudentController>().students.value = [ayesha, bilal];
  uiNow = () => DateTime(2026, 10, 26, 9, 30);
  await pumpApp(t, home: const HomeShell(), textScale: scale, width: width, height: height);
  await settle(t);
  return client;
}

void main() {
  setUpAll(loadAuthFonts);
  tearDown(() {
    uiNow = DateTime.now;
    Get.reset();
  });

  group('shell', () {
    testWidgets('greeting header with the child switcher, the bell without a dot, and the five kit nav tabs', (t) async {
      await pumpShell(t, homeApi());
      expect(find.byType(EmGreetingHeader), findsOneWidget);
      expect(find.text('Ayesha Khan'), findsOneWidget);
      expect(find.text('Grade 5 - A'), findsOneWidget);
      expect(find.byKey(const Key('child_switch_badge')), findsOneWidget);
      // no controller exposes unread notifications at the shell, so the bell has no dot
      expect(t.widget<EmIconCircleButton>(find.byKey(const Key('bell_button'))).showDot, isFalse);
      expect(find.byKey(const Key('em_dot')), findsNothing);
      final nav = t.widget<EmBottomNav>(find.byKey(HomeShell.navKey));
      expect([for (final i in nav.items) i.label], ['Home', 'Progress', 'Calendar', 'Messages', 'More']);
      expect(nav.items.every((i) => i.svgIcon != null), isTrue);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('the five labels fit on a 320 dp phone @${scale}x', (t) async {
        await pumpShell(t, homeApi(), scale: scale, width: 320, height: 640);
        for (final l in ['Home', 'Progress', 'Calendar', 'Messages', 'More']) {
          expect(find.descendant(of: find.byKey(HomeShell.navKey), matching: find.text(l)), findsOneWidget, reason: l);
        }
        expect(t.takeException(), isNull);
        await disposeApp(t);
      });
    }

    testWidgets('each tab opens (same destinations as before) and the Home tab refreshes when re-opened', (t) async {
      final client = await pumpShell(t, homeApi());
      final shell = Get.find<HomeShellController>();
      for (final (i, label) in ['Progress', 'Calendar', 'Messages', 'More'].indexed) {
        await t.tap(find.descendant(of: find.byKey(HomeShell.navKey), matching: find.text(label)));
        await settle(t);
        expect(shell.tabIndex.value, i + 1, reason: label);
        expect(t.takeException(), isNull, reason: label);
      }
      final before = client.calls.where((c) => c.endsWith('/attendance')).length;
      await t.tap(find.descendant(of: find.byKey(HomeShell.navKey), matching: find.text('Home')));
      await settle(t);
      expect(shell.tabIndex.value, 0);
      expect(client.calls.where((c) => c.endsWith('/attendance')).length, greaterThan(before));
      await disposeApp(t);
    });

    testWidgets('child switch: the header opens the selector, picking a child updates the header and reloads Home', (t) async {
      final client = await pumpShell(t, homeApi(attendance: attendanceFixture), twoStudents: true);
      expect(find.text('Ayesha Khan'), findsOneWidget);
      expect(client.calls.any((c) => c.contains('/students/s1/attendance')), isTrue);
      await t.tap(find.byKey(const Key('shell_header')));
      await settle(t);
      expect(find.text('Select your child'), findsOneWidget);
      expect(find.byKey(const Key('student_s1')), findsOneWidget);
      await t.tap(find.byKey(const Key('student_s2')));
      await settle(t);
      expect(Get.find<StudentController>().selectedStudent!.id, 's2');
      expect(find.text('Bilal Khan'), findsOneWidget);
      expect(find.text('Ayesha Khan'), findsNothing);
      expect(client.calls.any((c) => c.contains('/students/s2/attendance')), isTrue);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });

    testWidgets('the bell opens notifications', (t) async {
      await pumpShell(t, homeApi());
      await t.tap(find.byKey(const Key('bell_button')));
      await settle(t);
      expect(find.text('Notifications'), findsOneWidget);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });

    testWidgets('no child selected: the empty state, and the header asks to select a child', (t) async {
      setUpRouteDeps(homeApi(), withStudent: false);
      await pumpApp(t, home: const HomeShell());
      await settle(t);
      expect(find.text('Select child'), findsOneWidget);
      expect(find.text('No child selected'), findsOneWidget);
      expect(find.byType(EmEmptyState), findsOneWidget);
      await disposeApp(t);
    });
  });

  group('home', () {
    testWidgets('data: hero card with the attendance %, the three metrics, quick access, pending homework', (t) async {
      await pumpShell(t, homeApi(attendance: attendanceFixture, homework: homeworkFixture, dues: [
        {'balanceDue': 500}
      ]));
      expect(find.byType(EmHeroCard), findsOneWidget);
      expect(find.text("Ayesha's day at a glance"), findsOneWidget);
      expect(find.text('75%'), findsWidgets); // hero value + ring + attendance tile
      expect(find.text('Due'), findsOneWidget);
      for (final l in ['Attendance', 'Homework', 'Fees']) {
        expect(find.text(l), findsWidgets, reason: l);
      }
      expect(find.text('Quick access'), findsOneWidget);
      for (final l in ['Attendance', 'Homework', 'Fees & dues', 'Timetable']) {
        expect(find.byKey(Key('quick_$l')), findsOneWidget, reason: l);
      }
      // only the homework not yet submitted is a priority
      expect(find.text('Fractions worksheet'), findsOneWidget);
      expect(find.text('Plant diary'), findsNothing);
      expect(find.text('Due 28/10'), findsOneWidget);
      // the date line, no decorative week strip, no duplicate title
      expect(find.byKey(const Key('greeting_date')), findsOneWidget);
      expect(find.text('Good morning'), findsOneWidget);
      expect(find.text('Monday, 26 October 2026'), findsOneWidget);
      expect(find.byType(AppWeekDateStrip), findsNothing);
      expect(find.byType(EmDateStrip), findsNothing);
      expect(find.byType(ScreenHeader), findsNothing);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });

    testWidgets('quick access opens the same routes', (t) async {
      await pumpShell(t, homeApi());
      await t.ensureVisible(find.byKey(const Key('quick_Timetable')));
      await t.tap(find.byKey(const Key('quick_Timetable')));
      await settle(t);
      expect(Get.currentRoute, '/timetable');
      await disposeApp(t);
    });

    testWidgets('loading: skeletons only', (t) async {
      final hold = Completer<dynamic>();
      setUpRouteDeps(homeApi(hold: hold));
      uiNow = () => DateTime(2026, 10, 26, 9, 30);
      await pumpApp(t, home: const HomeShell());
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(EmShimmer), findsWidgets);
      expect(find.byType(EmHeroCard), findsNothing);
      expect(find.byType(EmErrorState), findsNothing);
      hold.complete(<dynamic>[]);
      await settle(t);
      await disposeApp(t);
    });

    testWidgets('error: the kit error state with Try again; retrying reloads', (t) async {
      final client = await pumpShell(t, homeApi(failAttendance: true));
      expect(find.byType(EmErrorState), findsOneWidget);
      expect(find.text('Could not load attendance'), findsOneWidget);
      expect(find.byType(EmHeroCard), findsNothing);
      final before = client.calls.where((c) => c.endsWith('/attendance')).length;
      await t.ensureVisible(find.text('Try again'));
      await t.tap(find.text('Try again'));
      await settle(t);
      expect(client.calls.where((c) => c.endsWith('/attendance')).length, greaterThan(before));
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });

    testWidgets('empty: no attendance shows the dash and "No attendance recorded yet"; no homework shows All caught up', (t) async {
      await pumpShell(t, homeApi());
      expect(find.text('—'), findsWidgets);
      expect(find.text('No attendance recorded yet'), findsOneWidget);
      expect(find.text('All caught up'), findsOneWidget);
      expect(find.text('No pending homework right now.'), findsOneWidget);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });

    testWidgets('a self-serve parent account sees the Eldermin explanation, not a child list', (t) async {
      setUpRouteDeps(homeApi());
      final auth = Get.find<AuthController>();
      auth.isParentLead.value = true;
      await pumpApp(t, home: const HomeShell());
      await settle(t);
      expect(find.text("Your school isn't on Eldermin yet"), findsOneWidget);
      expect(find.textContaining('joins Eldermin'), findsOneWidget);
      expect(find.byType(EmEmptyState), findsOneWidget);
      auth.schoolOnboarded.value = true;
      await settle(t);
      expect(find.text("You're almost there!"), findsOneWidget);
      await disposeApp(t);
    });

    for (final scale in [1.0, 1.3]) {
      testWidgets('lays out without overflow @${scale}x on 360 and 320 dp', (t) async {
        for (final w in [360.0, 320.0]) {
          await pumpShell(t, homeApi(attendance: attendanceFixture, homework: homeworkFixture), scale: scale, width: w, height: 700);
          expect(t.takeException(), isNull, reason: '$w @$scale');
          await disposeApp(t);
        }
      });
    }
  });
}
