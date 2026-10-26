import 'package:eldermin_parent_app/app/modules/auth/controllers/otp_verify_controller.dart';
import 'package:eldermin_parent_app/app/modules/auth/views/create_account_screen.dart';
import 'package:eldermin_parent_app/app/modules/auth/views/email_sign_in_screen.dart';
import 'package:eldermin_parent_app/app/modules/auth/views/otp_verify_screen.dart';
import 'package:eldermin_parent_app/app/modules/auth/views/phone_entry_screen.dart';
import 'package:eldermin_parent_app/app/modules/auth/widgets/auth_page_shell.dart';
import 'package:eldermin_parent_app/app/modules/splash/views/splash_screen.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';

/// Text on the photo overlay: every text colour is AA against the overlay's guaranteed colour (its alpha at the
/// strong line over pure white = the worst photo), and on every screen the text really starts at or below that line.
void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);

  group('tokens', () {
    test('the overlay is clear at the top and near-opaque at the bottom, monotonic', () {
      for (final safeTop in [0.3, 0.5, EmPhotoOverlay.defaultSafeTop, AuthPageShell.photoSafeTop]) {
        expect(EmPhotoOverlay.alphaAt(0, safeTop: safeTop), 0);
        expect(EmPhotoOverlay.alphaAt(1, safeTop: safeTop), EmPhotoOverlay.bottomAlpha);
        var prev = -1.0;
        for (var y = 0.0; y <= 1.0; y += 0.01) {
          final a = EmPhotoOverlay.alphaAt(y, safeTop: safeTop);
          expect(a, greaterThanOrEqualTo(prev), reason: 'at $y');
          prev = a;
        }
        expect(EmPhotoOverlay.alphaAt(EmPhotoOverlay.strongLine(safeTop), safeTop: safeTop), closeTo(EmPhotoOverlay.strongAlpha, 1e-9));
      }
    });

    test('the overlay base is the Eldermin design navy (teacher palette)', () => expect(EmPhotoOverlay.base.toARGB32(), 0xFF18457A));

    for (final pair in EmPhotoOverlay.pairs) {
      test('${pair.name}: >= ${pair.min}:1 on the overlay at the strong line (worst-case photo)', () {
        expect(contrastRatio(pair.foreground, EmPhotoOverlay.worstCaseAtStrongLine), greaterThanOrEqualTo(pair.min));
      });
    }

    test('the button label (ink) on the accent fill is AA', () => expect(contrastRatio(EmColors.ink, EmColors.accent), greaterThanOrEqualTo(4.5)));
    test('error text and field errors hold up on the overlay', () {
      expect(contrastRatio(EmColors.errorContainer, EmPhotoOverlay.worstCaseAtStrongLine), greaterThanOrEqualTo(4.5));
    });
    test('accent is only ever used on the navy: never as text on a light surface', () {
      expect(contrastRatio(EmColors.accent, EmColors.surface), lessThan(3), reason: 'accent on white would fail: it is only used on navy');
    });
  });

  group('placement: no text above the strong line', () {
    final sizes = [(320.0, 568.0), (375.0, 667.0), (390.0, 844.0), (430.0, 932.0)];

    void expectBelow(WidgetTester t, double line, String reason) {
      for (final e in find.byType(Text).evaluate()) {
        final w = e.widget as Text;
        expect(t.getRect(find.byWidget(w)).top, greaterThanOrEqualTo(line - 0.5), reason: '$reason: "${w.data ?? w.textSpan?.toPlainText()}"');
      }
    }

    testWidgets('login (tall photo), OTP, email sign in, create account (short photo)', (t) async {
      for (final (w, h) in sizes) {
        for (final scale in [1.0, 1.3]) {
          for (final (name, build, fraction) in <(String, Widget Function(), double)>[
            ('login', () => const PhoneEntryScreen(), AuthPhotoSize.tall.fraction),
            ('otp', () => const OtpVerifyScreen(), AuthPhotoSize.short.fraction),
            ('email', () => const EmailSignInScreen(), AuthPhotoSize.short.fraction),
            ('create', () => const CreateAccountScreen(), AuthPhotoSize.short.fraction),
          ]) {
            setUpAuthDeps();
            if (name == 'otp') Get.put<OtpVerifyController>(TestOtp(dev: '123456'));
            await pumpScreen(t, build(), width: w, height: h, textScale: scale);
            final photo = t.getSize(find.byKey(const Key('auth_photo'))).height;
            expect(photo, closeTo(h * (name == 'login' ? AuthPhotoSize.tall.fractionFor(h) : fraction), 1), reason: name);
            // everything but the back button and the logo tile lives below the line
            expectBelow(t, photo * AuthPageShell.contentStart, '$name ${w}x$h @$scale');
          }
        }
      }
    });

    testWidgets('login fits the iPhone SE (375 x 667) without scrolling: the photo gives way to 46%', (t) async {
      setUpAuthDeps();
      await pumpScreen(t, const PhoneEntryScreen(), width: 375, height: 667);
      expect(t.getSize(find.byKey(const Key('auth_photo'))).height, closeTo(667 * AuthPhotoSize.compactTall, 1));
      expect(t.getRect(find.textContaining('Create an account', findRichText: true)).bottom, lessThanOrEqualTo(667));
      expect(t.getRect(find.byType(EmMorphButton)).bottom, lessThanOrEqualTo(667));
    });

    testWidgets('splash: title and tagline start below the strong line', (t) async {
      for (final (w, h) in sizes) {
        for (final scale in [1.0, 1.3]) {
          setUpAuthDeps();
          await pumpScreen(t, const SplashScreen(), width: w, height: h, textScale: scale, topInset: 0, bottomInset: 0);
          final backdrop = t.widget<EmPhotoBackdrop>(find.byType(EmPhotoBackdrop));
          final line = EmPhotoOverlay.strongLine(backdrop.safeTop) * h;
          for (final key in const [Key('splash_title'), Key('splash_tagline')]) {
            expect(t.getRect(find.byKey(key)).top, greaterThanOrEqualTo(line - 0.5), reason: '$key ${w}x$h @$scale (line $line)');
          }
        }
      }
    });
  });

  group('text styles on the overlay', () {
    testWidgets('only white, muted-light, light-caption and accent text on a photo screen; accent only as heading, link or label', (t) async {
      final allowed = {EmColors.onPrimaryDark, EmColors.primaryContainer, EmColors.primaryLight, EmColors.accent, EmColors.ink, EmColors.errorContainer};
      for (final build in <Widget Function()>[() => const PhoneEntryScreen(), () => const EmailSignInScreen(), () => const CreateAccountScreen(), () => const SplashScreen()]) {
        setUpAuthDeps();
        await pumpScreen(t, build());
        for (final text in t.widgetList<Text>(find.byType(Text))) {
          final c = text.style?.color;
          if (c != null) expect(allowed, contains(c), reason: '"${text.data}"');
          // spans (the "Create an account" links)
          text.textSpan?.visitChildren((span) {
            final sc = span.style?.color;
            if (sc != null) expect(allowed, contains(sc), reason: 'span');
            return true;
          });
        }
      }
    });
  });
}
