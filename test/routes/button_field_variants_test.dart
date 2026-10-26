import 'package:eldermin_parent_app/app/components/custom_button.dart';
import 'package:eldermin_parent_app/app/components/custom_text_field.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:eldermin_parent_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/route_harness.dart';

/// CustomButton picks the kit variant from the colours a call site passes; CustomTextField renders a meaningful prefix and
/// top-aligns a multi-line label.
void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);

  Future<void> pump(WidgetTester t, Widget w) async {
    setUpRouteDeps((m, u) => <dynamic>[]);
    await pumpApp(t, home: Scaffold(body: Padding(padding: const EdgeInsets.all(20), child: w)));
  }

  group('CustomButton variants', () {
    testWidgets('navy (what every form passes) -> the primary accent button', (t) async {
      await pump(t, CustomButton(label: 'Save', color: AppColors.primaryColor, onPressed: () {}));
      expect(find.byType(EmMorphButton), findsOneWidget);
      expect(find.byType(EmPrimaryButton), findsNothing);
      await disposeApp(t);
    });

    testWidgets('red / danger colour -> EmPrimaryButton(destructive), error fill; taps work; loading ignores taps', (t) async {
      var taps = 0;
      await pump(t, CustomButton(label: 'Delete', color: AppColors.red, onPressed: () => taps++));
      final b = t.widget<EmPrimaryButton>(find.byType(EmPrimaryButton));
      expect(b.destructive, isTrue);
      final style = t.widget<ElevatedButton>(find.byType(ElevatedButton)).style!;
      expect(style.backgroundColor!.resolve({}), EmColors.error);
      await t.tap(find.text('Delete'));
      expect(taps, 1);
      await disposeApp(t);

      taps = 0;
      await pump(t, CustomButton(label: '', color: AppColors.delete, prefix: const SizedBox(), onPressed: () => taps++));
      expect(t.widget<EmPrimaryButton>(find.byType(EmPrimaryButton)).loading, isTrue);
      await t.tap(find.byType(EmPrimaryButton), warnIfMissed: false);
      expect(taps, 0);
      await disposeApp(t);
    });

    testWidgets('disabled danger button is not tappable', (t) async {
      var taps = 0;
      await pump(t, CustomButton(label: 'Delete', color: AppColors.red, enabled: false, onPressed: () => taps++));
      expect(t.widget<EmPrimaryButton>(find.byType(EmPrimaryButton)).onPressed, isNull);
      await t.tap(find.text('Delete'), warnIfMissed: false);
      expect(taps, 0);
      await disposeApp(t);
    });

    testWidgets('white / transparent / muted fill -> EmSecondaryButton (white with the accent border)', (t) async {
      for (final c in [AppColors.white, AppColors.transparent, AppColors.muted]) {
        await pump(t, CustomButton(label: 'Back', color: c, onPressed: () {}));
        final b = t.widget<EmSecondaryButton>(find.byType(EmSecondaryButton));
        expect(b.destructive, isFalse);
        expect(b.expand, isTrue);
        final style = t.widget<OutlinedButton>(find.byType(OutlinedButton)).style!;
        expect(style.backgroundColor!.resolve({}), EmColors.surface);
        await disposeApp(t);
      }
    });

    testWidgets('an outlined button (borderColor set) is secondary; with red text or border it is the destructive secondary', (t) async {
      await pump(t, CustomButton(label: 'Cancel', borderColor: AppColors.grey, onPressed: () {}));
      expect(t.widget<EmSecondaryButton>(find.byType(EmSecondaryButton)).destructive, isFalse);
      await disposeApp(t);
      await pump(t, CustomButton(label: 'Remove', color: AppColors.white, textColor: AppColors.red, onPressed: () {}));
      final b = t.widget<EmSecondaryButton>(find.byType(EmSecondaryButton));
      expect(b.destructive, isTrue);
      expect(t.widget<OutlinedButton>(find.byType(OutlinedButton)).style!.side!.resolve({})!.color, EmColors.error);
      await disposeApp(t);
    });

    testWidgets('secondary loading shows a spinner and ignores taps', (t) async {
      var taps = 0;
      await pump(t, CustomButton(label: '', color: AppColors.white, prefix: const SizedBox(), onPressed: () => taps++));
      expect(t.widget<EmSecondaryButton>(find.byType(EmSecondaryButton)).loading, isTrue);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await t.tap(find.byType(EmSecondaryButton), warnIfMissed: false);
      expect(taps, 0);
      await disposeApp(t);
    });
  });

  group('CustomTextField', () {
    testWidgets('a prefix that is not an icon (a country code) renders in front of the field', (t) async {
      final c = TextEditingController();
      await pump(t, CustomTextField(label: 'Phone', controller: c, prefixIcon: const Text('+92'), keyboardType: TextInputType.phone));
      expect(find.text('+92'), findsOneWidget);
      final prefix = t.getRect(find.text('+92'));
      final field = t.getRect(find.byType(EmTextField));
      expect(prefix.right, lessThanOrEqualTo(field.left + 0.5), reason: 'the prefix sits before the field');
      await t.enterText(find.byType(TextField), '3001234567');
      expect(c.text, '3001234567');
      await disposeApp(t);
    });

    testWidgets('an Icon prefix still goes into the kit field', (t) async {
      await pump(t, const CustomTextField(label: 'Phone', prefixIcon: Icon(Icons.phone)));
      expect(t.widget<EmTextField>(find.byType(EmTextField)).prefixIcon, Icons.phone);
      await disposeApp(t);
    });

    testWidgets('a multi-line field keeps its label at the top; a single-line one is centred', (t) async {
      await pump(t, const Column(children: [
        CustomTextField(label: 'Reason', maxLines: 4),
        SizedBox(height: 20),
        CustomTextField(label: 'Subject'),
      ]));
      final reasonField = t.getRect(find.byType(EmTextField).first);
      final reasonLabel = t.getRect(find.text('Reason'));
      expect(reasonLabel.top - reasonField.top, lessThan(24), reason: 'top-aligned label');
      final subjectField = t.getRect(find.byType(EmTextField).last);
      final subjectLabel = t.getRect(find.text('Subject'));
      expect((subjectLabel.center.dy - subjectField.center.dy).abs(), lessThan(8), reason: 'single line stays centred');
      await disposeApp(t);
    });
  });
}
