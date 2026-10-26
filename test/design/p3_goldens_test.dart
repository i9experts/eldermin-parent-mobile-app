@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';
import 'package:eldermin_parent_app/app/modules/home/controllers/home_shell_controller.dart';
import 'package:eldermin_parent_app/app/modules/home/views/home_shell.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:eldermin_parent_app/core/utils/greeting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/p3_fixtures.dart';
import '../support/route_harness.dart';
import '../support/tolerant_golden.dart';

/// Goldens of the P3 screens at 390x844, text scale 1.0 and 1.3: the four tab roots inside the shell (Progress, Calendar,
/// Messages, More) and the converted pushed screens (attendance, homework, timetable, notifications, message thread), plus
/// the homework sheet and the month picker. macOS baselines (other hosts skip). The comparator tolerates 2 % of the pixels
/// because the month / date text changes with the calendar.
///
///   Update:  flutter test test/design/p3_goldens_test.dart --tags golden --update-goldens
void main() {
  setUpAll(() async {
    await loadAuthFonts();
    useTolerantGoldens(Uri.parse('test/design/p3_goldens_test.dart'));
  });
  tearDown(() {
    uiNow = DateTime.now;
    Get.reset();
  });
  final skip = Platform.isMacOS ? null : 'goldens are macOS baselines';

  String tag(double s) => s == 1.0 ? 'normal' : 'scale13';

  for (final scale in [1.0, 1.3]) {
    for (final (i, name) in ['progress', 'calendar', 'messages', 'more'].indexed) {
      testWidgets('tab $name / ${tag(scale)}', (t) async {
        setUpRouteDeps(p3Api());
        uiNow = () => DateTime(2026, 10, 26, 9, 30);
        await pumpApp(t, home: const HomeShell(), textScale: scale);
        await settle(t);
        Get.find<HomeShellController>().tabIndex.value = i + 1;
        await settle(t);
        await expectLater(find.byType(HomeShell), matchesGoldenFile('goldens/p3/tab_${name}_${tag(scale)}.png'));
        await disposeApp(t);
      }, skip: skip != null);
    }

    final pushed = {
      'attendance': (Routes.attendance, null),
      'homework': (Routes.homework, null),
      'timetable': (Routes.timetable, null),
      'notifications': (Routes.notifications, null),
      'thread': (Routes.messageThread, {'threadId': 't1', 'subject': 'Homework help', 'staffName': 'Ms Sara Ahmed', 'studentName': 'Ayesha Khan'}),
    };
    for (final e in pushed.entries) {
      testWidgets('${e.key} / ${tag(scale)}', (t) async {
        setUpRouteDeps(p3Api());
        await pumpApp(t, textScale: scale);
        unawaited(Get.toNamed(e.value.$1, arguments: e.value.$2));
        await settle(t);
        await expectLater(find.byType(EmScaffold).last, matchesGoldenFile('goldens/p3/${e.key}_${tag(scale)}.png'));
        await disposeApp(t);
      }, skip: skip != null);
    }
  }

  testWidgets('homework detail sheet / normal', (t) async {
    setUpRouteDeps(p3Api());
    await pumpApp(t);
    unawaited(Get.toNamed(Routes.homework));
    await settle(t);
    await t.tap(find.text('Fractions worksheet - page 14 to 16'));
    await settle(t);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('goldens/p3/homework_sheet_normal.png'));
    await disposeApp(t);
  }, skip: skip != null);

  testWidgets('month picker sheet / normal', (t) async {
    setUpRouteDeps(p3Api());
    await pumpApp(t);
    unawaited(Get.toNamed(Routes.attendance));
    await settle(t);
    await t.tap(find.byType(EmChip).first);
    await settle(t);
    await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('goldens/p3/month_picker_normal.png'));
    await disposeApp(t);
  }, skip: skip != null);
}
