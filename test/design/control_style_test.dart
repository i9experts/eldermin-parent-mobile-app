import 'package:eldermin_parent_app/app/components/custom_button.dart';
import 'package:eldermin_parent_app/app/config/app_dimens.dart';
import 'package:eldermin_parent_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every field and button is 10 dp rounded; every button is the theme yellow with a dark label.
void main() {
  test('the radius token is 10 for fields and buttons', () {
    expect(AppDimen.borderRadius, 10);
    expect(AppRadius.control, 10);
  });

  testWidgets('CustomButton is yellow with a dark label whatever colour a call site asks for', (t) async {
    await t.pumpWidget(MaterialApp(
        home: Scaffold(
            body: CustomButton(label: 'Save', color: AppColors.primaryColor, textColor: AppColors.white, onPressed: () {}))));
    final style = t.widget<ElevatedButton>(find.byType(ElevatedButton)).style!;
    expect(style.backgroundColor!.resolve({}), AppColors.accentColor);
    expect((style.shape!.resolve({})! as RoundedRectangleBorder).borderRadius, BorderRadius.circular(10));
    expect(t.widget<Text>(find.text('Save')).style!.color, AppColors.black);
  });
}
