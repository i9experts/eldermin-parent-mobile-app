@Tags(['golden'])
library;

import 'dart:io';
import 'package:eldermin_parent_app/app/modules/auth/controllers/otp_verify_controller.dart';
import 'package:eldermin_parent_app/app/modules/auth/views/otp_verify_screen.dart';
import 'package:eldermin_parent_app/app/modules/auth/views/phone_entry_screen.dart';
import 'package:eldermin_parent_app/app/modules/splash/views/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';

/// Goldens of the photo auth screens: normal, text scale 1.3 and (form screens) keyboard open.
/// 390x844, macOS baselines (other hosts skip).
///
///   Update:  flutter test test/design/auth_goldens_test.dart --tags golden --update-goldens
void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);
  final skip = Platform.isMacOS ? null : 'goldens are macOS baselines';

  final screens = <String, (Widget Function(), bool, bool)>{
    'splash': (() => const SplashScreen(), false, false),
    'login': (() => const PhoneEntryScreen(), true, false),
    'otp': (() => const OtpVerifyScreen(), true, true),
  };

  for (final e in screens.entries) {
    final (build, hasKeyboard, otp) = e.value;
    final variants = <String, (double, double)>{'normal': (1.0, 0), 'scale13': (1.3, 0), if (hasKeyboard) 'keyboard': (1.0, 300)};
    for (final v in variants.entries) {
      testWidgets('${e.key} / ${v.key}', (t) async {
        setUpAuthDeps();
        if (otp) Get.put<OtpVerifyController>(TestOtp(dev: '123456'));
        await pumpScreen(t, build(), textScale: v.value.$1, keyboard: v.value.$2, topInset: e.key == 'splash' ? 0 : 47);
        await loadAuthPhotos(t);
        await t.pump(const Duration(milliseconds: 1200));
        expect(t.takeException(), isNull);
        await expectLater(find.byType(GetMaterialApp), matchesGoldenFile('goldens/auth/${e.key}_${v.key}.png'));
      }, skip: skip != null);
    }
  }
}
