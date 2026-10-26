@Tags(['golden'])
library;

import 'dart:io';
import 'package:eldermin_parent_app/app/modules/home/controllers/home_shell_controller.dart';
import 'package:eldermin_parent_app/app/modules/home/views/home_shell.dart';
import 'package:eldermin_parent_app/core/utils/greeting.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../routes/shell_home_test.dart' show homeApi, attendanceFixture, homeworkFixture;
import '../support/auth_harness.dart';
import '../support/route_harness.dart';

/// Goldens of the shell (greeting header + child switcher + bell + kit bottom nav) and the Home tab: 390x844 at text
/// scale 1.0 and 1.3, the Home tab loading, and the Progress tab (nav state). macOS baselines (other hosts skip).
///
///   Update:  flutter test test/design/home_goldens_test.dart --tags golden --update-goldens
void main() {
  setUpAll(loadAuthFonts);
  tearDown(() {
    uiNow = DateTime.now;
    Get.reset();
  });
  final skip = Platform.isMacOS ? null : 'goldens are macOS baselines';

  Future<void> shell(WidgetTester t, {double scale = 1, int tab = 0}) async {
    setUpRouteDeps(homeApi(attendance: attendanceFixture, homework: homeworkFixture, dues: [
      {'balanceDue': 500}
    ]));
    uiNow = () => DateTime(2026, 10, 26, 9, 30);
    await pumpApp(t, home: const HomeShell(), textScale: scale);
    await settle(t);
    if (tab != 0) {
      Get.find<HomeShellController>().tabIndex.value = tab;
      await settle(t);
    }
  }

  for (final scale in [1.0, 1.3]) {
    final name = scale == 1.0 ? 'normal' : 'scale13';
    testWidgets('home / $name', (t) async {
      await shell(t, scale: scale);
      await expectLater(find.byType(HomeShell), matchesGoldenFile('goldens/home/home_$name.png'));
      await disposeApp(t);
    }, skip: skip != null);

    testWidgets('home scrolled to the end / $name', (t) async {
      await shell(t, scale: scale);
      await t.drag(find.byType(ListView).first, const Offset(0, -2000));
      await t.pump(const Duration(milliseconds: 400));
      await expectLater(find.byType(HomeShell), matchesGoldenFile('goldens/home/home_end_$name.png'));
      await disposeApp(t);
    }, skip: skip != null);

    testWidgets('shell, Progress tab / $name', (t) async {
      await shell(t, scale: scale, tab: 1);
      await expectLater(find.byType(HomeShell), matchesGoldenFile('goldens/home/shell_progress_$name.png'));
      await disposeApp(t);
    }, skip: skip != null);
  }
}
