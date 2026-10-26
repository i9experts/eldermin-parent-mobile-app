import 'package:eldermin_parent_app/app/components/custom_button.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every field and button is 10 dp rounded; every button is the accent with a dark label (the kit's EmMorphButton).
void main() {
  test('the radius token is 10 for fields and buttons', () {
    expect(const CustomButton(label: 'x', onPressed: null).borderRadius, 10, reason: 'the button default');
    expect(EmRadius.control, 10);
  });

  testWidgets('CustomButton is the kit button: accent fill, ink label, 10 dp, whatever colour a call site asks for', (t) async {
    await t.pumpWidget(MaterialApp(
        theme: buildEmTheme(),
        home: Scaffold(body: CustomButton(label: 'Save', color: EmColors.primaryDark, textColor: EmColors.surface, onPressed: () {}))));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.byType(EmMorphButton), findsOneWidget);
    final fill = t.widget<AnimatedContainer>(find.descendant(of: find.byType(EmMorphButton), matching: find.byType(AnimatedContainer))).decoration! as BoxDecoration;
    expect(fill.color, EmColors.accent);
    expect(fill.borderRadius, BorderRadius.circular(10));
    expect(t.widget<Text>(find.text('Save')).style!.color, EmColors.ink);
  });
}
