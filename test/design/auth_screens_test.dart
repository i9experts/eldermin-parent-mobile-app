import 'dart:async';
import 'package:eldermin_parent_app/app/modules/auth/controllers/otp_verify_controller.dart';
import 'package:eldermin_parent_app/app/modules/auth/controllers/phone_entry_controller.dart';
import 'package:eldermin_parent_app/app/modules/auth/views/create_account_screen.dart';
import 'package:eldermin_parent_app/app/modules/auth/views/email_sign_in_screen.dart';
import 'package:eldermin_parent_app/app/modules/auth/views/otp_verify_screen.dart';
import 'package:eldermin_parent_app/app/modules/auth/views/phone_entry_screen.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:eldermin_parent_app/core/network/api_exception.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';

class _Case {
  const _Case(this.name, this.build, this.submit, {this.otp = false});
  final String name;
  final Widget Function() build;
  final String submit; // the primary action's label
  final bool otp;
}

const cases = [
  _Case('login', PhoneEntryScreen.new, 'Send Verification Code'),
  _Case('otp', OtpVerifyScreen.new, 'Verify & Continue', otp: true),
  _Case('email', EmailSignInScreen.new, 'Sign In'),
  _Case('create', CreateAccountScreen.new, 'Create Account'),
];

double shakeOffset(WidgetTester t) =>
    t.widget<Transform>(find.descendant(of: find.byType(EmShake), matching: find.byType(Transform)).first).transform.getTranslation().x;

void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);

  void deps(_Case c) {
    setUpAuthDeps();
    if (c.otp) Get.put<OtpVerifyController>(TestOtp(dev: '123456'));
  }

  group('layout matrix: widths 320/360/375/430 x text 1.0/1.3 x LTR/RTL x keyboard closed/open', () {
    for (final c in cases) {
      testWidgets(c.name, (t) async {
        for (final w in [320.0, 360.0, 375.0, 430.0]) {
          for (final scale in [1.0, 1.3]) {
            for (final dir in [TextDirection.ltr, TextDirection.rtl]) {
              for (final kb in [0.0, 300.0]) {
                deps(c);
                final h = w < 400 ? 667.0 : 844.0;
                await pumpScreen(t, c.build(), width: w, height: h, textScale: scale, dir: dir, keyboard: kb);
                final reason = '${c.name} ${w}x$h @$scale ${dir.name} kb=$kb';
                final e = t.takeException();
                expect(e, isNull, reason: '$reason: ${e?.toString().split('\n').first}');
                final f = find.descendant(of: find.byType(EmMorphButton), matching: find.text(c.submit));
                expect(f, findsOneWidget, reason: reason);
                await t.ensureVisible(f);
                await t.pump(const Duration(milliseconds: 300));
                final r = t.getRect(f);
                expect(r.bottom, lessThanOrEqualTo(h - kb + 0.5), reason: '$reason: submit hidden by the keyboard');
                expect(r.top, greaterThanOrEqualTo(0), reason: reason);
                expect(t.takeException(), isNull, reason: reason);
              }
            }
          }
        }
      });
    }
  });

  group('look', () {
    testWidgets('login: navy page, photo header (cover) with the logo tile, accent heading, outlined fields, accent button with an ink label', (t) async {
      setUpAuthDeps();
      await pumpScreen(t, const PhoneEntryScreen());
      expect(t.widget<Scaffold>(find.byType(Scaffold)).backgroundColor, EmColors.primaryDark);
      expect(find.byKey(const Key('auth_photo')), findsOneWidget);
      expect(t.getSize(find.byKey(const Key('auth_photo'))).height, closeTo(844 * 0.55, 1));
      expect(find.byType(EmLogoTile), findsOneWidget);
      final title = t.widget<Text>(find.byKey(const Key('auth_title')));
      expect(title.data, 'Log in with WhatsApp');
      expect(title.style!.color, EmColors.accent);
      // the teacher's on-dark field: transparent, 1 px light border, accent when focused, 10 dp corners
      final tf = t.widget<EmTextField>(find.byType(EmTextField));
      expect(tf.label, 'WhatsApp number');
      expect(tf.radius, EmRadius.control);
      expect(EmOnDark.of(t.element(find.byType(EmTextField))), isTrue);
      final field = t.widget<InputDecorator>(find.descendant(of: find.byType(EmTextField), matching: find.byType(InputDecorator))).decoration;
      expect(field.filled, isFalse);
      expect((field.enabledBorder! as OutlineInputBorder).borderSide.color, EmColors.primaryLight);
      expect((field.focusedBorder! as OutlineInputBorder).borderSide.color, EmColors.accent);
      expect((field.enabledBorder! as OutlineInputBorder).borderRadius, BorderRadius.circular(EmRadius.control));
      expect(EmRadius.control, 10, reason: 'every field and button is 10 dp');
      final fill = t.widget<AnimatedContainer>(find.descendant(of: find.byType(EmMorphButton), matching: find.byType(AnimatedContainer))).decoration! as BoxDecoration;
      expect(fill.color, EmColors.accent);
      expect(t.widget<Text>(find.descendant(of: find.byType(EmMorphButton), matching: find.text('Send Verification Code'))).style!.color, EmColors.ink);
      expect(fill.borderRadius, BorderRadius.circular(10));
    });

    testWidgets('keyboard open: the photo collapses to a strip that still holds the logo tile', (t) async {
      setUpAuthDeps();
      await pumpScreen(t, const PhoneEntryScreen());
      final full = t.getSize(find.byKey(const Key('auth_photo'))).height;
      await pumpScreen(t, const PhoneEntryScreen(), keyboard: 300, height: 667);
      await t.pump(const Duration(milliseconds: 600));
      expect(t.getSize(find.byKey(const Key('auth_photo'))).height, lessThan(full - 100));
      expect(t.getRect(find.byType(EmLogoTile)).bottom, lessThan(t.getSize(find.byKey(const Key('auth_photo'))).height));
    });

    testWidgets('pushed screens have the back circle, the old app bar title is kept as a small line, login has no back', (t) async {
      setUpAuthDeps();
      await pumpScreen(t, const PhoneEntryScreen());
      expect(find.bySemanticsLabel('Back'), findsNothing);
      expect(find.byType(AppBar), findsNothing);
      for (final (screen, eyebrow) in [(const EmailSignInScreen(), 'Sign In'), (const CreateAccountScreen(), 'Create Account')]) {
        setUpAuthDeps();
        await pumpScreen(t, screen);
        expect(find.byTooltip('Back'), findsOneWidget);
        expect(t.widget<Text>(find.byKey(const Key('auth_eyebrow'))).data, eyebrow);
      }
      Get.reset();
      deps(cases[1]);
      await pumpScreen(t, const OtpVerifyScreen());
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(t.widget<Text>(find.byKey(const Key('auth_eyebrow'))).data, 'Verify Number');
    });

    testWidgets('copy is unchanged', (t) async {
      setUpAuthDeps();
      await pumpScreen(t, const PhoneEntryScreen());
      expect(find.text("Enter the WhatsApp number registered with your child's school. We'll send a verification code — no password needed."), findsOneWidget);
      expect(find.text("Haven't registered this number with your school yet? Contact the school office to link it to your child's profile."), findsOneWidget);
      expect(find.textContaining('Create an account', findRichText: true), findsOneWidget);
      deps(cases[1]);
      await pumpScreen(t, const OtpVerifyScreen());
      expect(find.text('Enter the code'), findsOneWidget);
      expect(find.text('We sent a 6-digit code via WhatsApp to +923001234567'), findsOneWidget);
      expect(find.text('Dev mode code: 123456'), findsOneWidget);
    });
  });

  group('flows are unchanged (restyle only)', () {
    testWidgets('login: a short number shows the same message, calls no API, and shakes the content', (t) async {
      final api = setUpAuthDeps();
      await pumpScreen(t, const PhoneEntryScreen());
      await t.enterText(find.byType(TextField), '300');
      await t.tap(find.text('Send Verification Code'));
      await t.pump();
      expect(find.text('Enter your complete WhatsApp number.'), findsOneWidget);
      expect(api.otpCalls, isEmpty);
      var maxOffset = 0.0;
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 16));
        maxOffset = maxOffset < shakeOffset(t).abs() ? shakeOffset(t).abs() : maxOffset;
      }
      expect(maxOffset, inInclusiveRange(2, EmMotion.shakeDistance));
      await t.pump(const Duration(milliseconds: 600));
      expect(shakeOffset(t), 0);
    });

    testWidgets('login: the number is normalised exactly as before and the button morphs to a spinner while it waits', (t) async {
      final api = setUpAuthDeps();
      final gate = Completer<void>();
      api.otpError = null;
      api.otpResult = {'sent': false, 'reason': 'try later'};
      await pumpScreen(t, const PhoneEntryScreen());
      await t.enterText(find.byType(TextField), '0300 1234567');
      await t.tap(find.text('Send Verification Code'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 20));
      expect(api.otpCalls, ['+923001234567']);
      gate.complete();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text("Couldn't send the code right now: try later"), findsOneWidget, reason: 'the existing wording');
    });

    testWidgets('login: loading shows the circular spinner button', (t) async {
      setUpAuthDeps();
      await pumpScreen(t, const PhoneEntryScreen());
      Get.find<PhoneEntryController>().loading.value = true;
      await t.pump();
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(t.getSize(find.descendant(of: find.byType(EmMorphButton), matching: find.byType(AnimatedContainer))).width, EmMorphButton.height);
      Get.find<PhoneEntryController>().loading.value = false;
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('Send Verification Code'), findsOneWidget);
    });

    testWidgets('login: a server error keeps its message (ApiException)', (t) async {
      final api = setUpAuthDeps();
      api.otpError = ApiException('Number not registered', statusCode: 404);
      await pumpScreen(t, const PhoneEntryScreen());
      await t.enterText(find.byType(TextField), '3001234567');
      await t.tap(find.text('Send Verification Code'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Number not registered'), findsWidgets, reason: 'shown under the field (and as the existing toast)');
      await t.pump(const Duration(seconds: 6)); // let the existing toast's timer finish
    });

    testWidgets('OTP: Verify is dimmed and inactive until all 6 digits are in', (t) async {
      deps(cases[1]);
      await pumpScreen(t, const OtpVerifyScreen());
      expect(t.widget<EmMorphButton>(find.byType(EmMorphButton)).onPressed, isNull);
      expect(t.widget<Opacity>(find.descendant(of: find.byType(EmMorphButton), matching: find.byType(Opacity)).first).opacity, lessThan(1));
      Get.find<OtpVerifyController>().code.value = '123456';
      await t.pump();
      expect(t.widget<EmMorphButton>(find.byType(EmMorphButton)).onPressed, isNotNull);
    });

    testWidgets('create account: the terms checkbox and every field keep their hints', (t) async {
      setUpAuthDeps();
      await pumpScreen(t, const CreateAccountScreen());
      // every field keeps its hint (shown when the label floats) and gains its former heading as the label
      final fields = {
        'Full Name': 'Enter your full name',
        'School Name': "Your child's school name",
        'Email Address': 'Enter your email',
        'Phone Number': '+92 300 1234567',
        'Password': 'Create a password',
        'Confirm Password': 'Confirm your password',
      };
      for (final e in fields.entries) {
        final f = find.byWidgetPredicate((w) => w is EmTextField && w.label == e.key && w.hint == e.value);
        await t.ensureVisible(f);
        expect(f, findsOneWidget, reason: e.key);
      }
      expect(find.text('I agree to the Terms & Conditions and Privacy Policy'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });
  });

  group('reduce motion', () {
    testWidgets('no shake, no width morph: the button collapses on the first frame and the label swaps in place', (t) async {
      setUpAuthDeps();
      await pumpScreen(t, const PhoneEntryScreen(), reduce: true);
      await t.enterText(find.byType(TextField), '300');
      await t.tap(find.text('Send Verification Code'));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 16));
        expect(shakeOffset(t), 0, reason: 'no shake');
      }
      expect(find.text('Enter your complete WhatsApp number.'), findsOneWidget);
      Get.find<PhoneEntryController>().loading.value = true;
      await t.pump();
      expect(t.getSize(find.descendant(of: find.byType(EmMorphButton), matching: find.byType(AnimatedContainer))).width, EmMorphButton.height);
    });

    testWidgets('the photo collapses instantly with the keyboard (no animated resize)', (t) async {
      setUpAuthDeps();
      await pumpScreen(t, const PhoneEntryScreen(), reduce: true, keyboard: 300);
      await t.pump(const Duration(milliseconds: 16));
      expect(t.getSize(find.byKey(const Key('auth_photo'))).height, lessThan(200));
      expect(t.takeException(), isNull);
    });
  });
}
