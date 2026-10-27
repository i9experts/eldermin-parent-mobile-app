@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/p5_fixtures.dart';
import '../support/route_harness.dart';

/// Goldens of PTM, leaves, profile and dues (and the two form sheets, empty and with errors) at 390x844, text scale 1.0 and 1.3.
/// Deterministic, exact comparison, macOS baselines.
///
///   Update:  flutter test test/design/p5_goldens_test.dart --tags golden --update-goldens
void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);
  final skip = Platform.isMacOS ? null : 'goldens are macOS baselines';

  final screens = {'ptm': Routes.ptm, 'leaves': Routes.leaves, 'profile': Routes.profile, 'dues': Routes.dues};
  for (final scale in [1.0, 1.3]) {
    final tag = scale == 1.0 ? 'normal' : 'scale13';
    for (final e in screens.entries) {
      testWidgets('${e.key} / $tag', (t) async {
        setUpRouteDeps(p5Api());
        await pumpApp(t, textScale: scale);
        unawaited(Get.toNamed(e.value));
        await settle(t);
        await expectLater(find.byType(EmScaffold).last, matchesGoldenFile('goldens/p5/${e.key}_$tag.png'));
        await disposeApp(t);
      }, skip: skip != null);
    }

    for (final (name, route, open) in [('ptm_form', Routes.ptm, 'ptm_open_form'), ('leave_form', Routes.leaves, 'leave_open_form')]) {
      testWidgets('$name with validation errors / $tag', (t) async {
        setUpRouteDeps(p5Api());
        await pumpApp(t, textScale: scale);
        unawaited(Get.toNamed(route));
        await settle(t);
        await t.tap(find.byKey(Key(open)));
        await settle(t);
        await t.tap(find.byKey(Key(name == 'ptm_form' ? 'ptm_submit' : 'leave_submit')));
        await t.pump(const Duration(milliseconds: 100));
        await t.pump(const Duration(seconds: 4)); // let the warning snackbar go
        await settle(t);
        await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('goldens/p5/${name}_errors_$tag.png'));
        await disposeApp(t);
      }, skip: skip != null);
    }
  }
}
