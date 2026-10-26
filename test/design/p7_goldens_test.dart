@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';
import 'package:eldermin_parent_app/app/modules/home/controllers/home_shell_controller.dart';
import 'package:eldermin_parent_app/app/modules/home/views/home_shell.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:eldermin_parent_app/core/models/early_years_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/p7_fixtures.dart';
import '../support/route_harness.dart';

/// Goldens of the Early Years screens at 390x844, text scale 1.0 and 1.3: home (portfolio and observations tabs), entry detail,
/// observation detail, the loading skeleton, the "not available" state, and the More tab with the Early Years tile.
/// Deterministic, exact comparison, macOS baselines.
///
///   Update:  flutter test test/design/p7_goldens_test.dart --tags golden --update-goldens
void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);
  final skip = Platform.isMacOS ? null : 'goldens are macOS baselines';

  for (final scale in [1.0, 1.3]) {
    final tag = scale == 1.0 ? 'normal' : 'scale13';

    Future<void> screen(WidgetTester t, String name, String route, {Object? args, bool tapObservations = false, Completer<dynamic>? hold, bool eligible = true}) async {
      setUpRouteDeps(p7Api(hold: hold, eligible: eligible));
      await pumpApp(t, textScale: scale);
      unawaited(Get.toNamed(route, arguments: args));
      await settle(t);
      if (tapObservations) {
        await t.tap(find.text('Shared observations'));
        await settle(t);
      }
      await expectLater(find.byType(EmScaffold).last, matchesGoldenFile('goldens/p7/${name}_$tag.png'));
      await disposeApp(t);
    }

    testWidgets('home portfolio / $tag', (t) => screen(t, 'ey_home', Routes.earlyYears), skip: skip != null);
    testWidgets('home observations / $tag', (t) => screen(t, 'ey_observations', Routes.earlyYears, tapObservations: true), skip: skip != null);
    testWidgets('entry detail / $tag', (t) => screen(t, 'ey_entry', Routes.earlyYearsEntry, args: EyPortfolioEntry.fromJson(eyEntrySent('e1'))), skip: skip != null);
    testWidgets('observation detail / $tag', (t) => screen(t, 'ey_observation', Routes.earlyYearsObservation, args: EyObservation.fromJson(eyObservationSent('o1'))), skip: skip != null);
    testWidgets('loading skeleton / $tag', (t) async {
      final hold = Completer<dynamic>();
      await screen(t, 'ey_loading', Routes.earlyYears, hold: hold);
    }, skip: skip != null);
    testWidgets('not available / $tag', (t) => screen(t, 'ey_unavailable', Routes.earlyYears, eligible: false), skip: skip != null);

    testWidgets('More tab with the Early Years tile / $tag', (t) async {
      setUpRouteDeps(p7Api());
      await pumpApp(t, home: const HomeShell(), textScale: scale);
      await settle(t);
      Get.find<HomeShellController>().tabIndex.value = 4;
      await settle(t);
      final list = find.descendant(of: find.byType(ListView).first, matching: find.byType(Scrollable)).first;
      await t.scrollUntilVisible(find.byKey(const Key('service_Early Years')), 300, scrollable: list);
      await t.pump();
      await expectLater(find.byType(HomeShell), matchesGoldenFile('goldens/p7/more_ey_tile_$tag.png'));
      await disposeApp(t);
    }, skip: skip != null);
  }
}
