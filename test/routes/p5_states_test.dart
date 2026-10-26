import 'dart:async';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/p5_fixtures.dart';
import '../support/route_harness.dart';

/// PTM, leaves, profile and dues in every state at 390 dp and 320 dp @1.3x: one title, no week strip, nothing under 12 sp, no
/// overflow; loading, failed and empty answers.
void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);
  final routes = {'ptm': Routes.ptm, 'leaves': Routes.leaves, 'profile': Routes.profile, 'dues': Routes.dues};

  Future<void> open(WidgetTester t, String route, {double w = 390, double h = 844, double scale = 1}) async {
    await pumpApp(t, width: w, height: h, textScale: scale);
    unawaited(Get.toNamed(route));
    await settle(t);
  }

  for (final e in routes.entries) {
    for (final (w, h, scale) in [(390.0, 844.0, 1.0), (320.0, 640.0, 1.3)]) {
      testWidgets('${e.key}: data at ${w}dp @${scale}x', (t) async {
        setUpRouteDeps(p5Api());
        await open(t, e.value, w: w, h: h, scale: scale);
        expect(find.byType(EmAppBar), findsOneWidget);
        expect(find.byType(EmDateStrip), findsNothing);
        expect(t.takeException(), isNull);
        for (final text in t.widgetList<Text>(find.byType(Text))) {
          final size = text.style?.fontSize;
          if (size != null) expect(size, greaterThanOrEqualTo(12), reason: '"${text.data}" is $size sp');
        }
        await disposeApp(t);
      });
    }

    testWidgets('${e.key}: loading, failed and empty answers at 320 dp @1.3x', (t) async {
      final hold = Completer<dynamic>();
      setUpRouteDeps(p5Api(hold: hold));
      await open(t, e.value, w: 320, h: 640, scale: 1.3);
      expect(find.byType(EmShimmer), findsWidgets, reason: 'skeleton while loading');
      expect(t.takeException(), isNull);
      hold.complete(<dynamic>[]);
      await settle(t);
      await disposeApp(t);

      setUpRouteDeps((m, url) => throw networkError(url));
      await open(t, e.value, w: 320, h: 640, scale: 1.3);
      expect(find.byType(EmErrorState), findsOneWidget);
      expect(t.takeException(), isNull);
      await disposeApp(t);

      setUpRouteDeps(p5Api(empty: true));
      await open(t, e.value, w: 320, h: 640, scale: 1.3);
      expect(t.takeException(), isNull);
      await disposeApp(t);
    });
  }
}
