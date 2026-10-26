import 'package:eldermin_parent_app/app/modules/auth/views/phone_entry_screen.dart';
import 'package:eldermin_parent_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(Get.reset);

  testWidgets('App boots to the phone entry screen when unauthenticated', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({}); // no stored session
    await tester.pumpWidget(const EldeminParentApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);

    // the session check holds the splash for 3 s (AuthController._bootstrap): pump past it so no timer is left pending
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PhoneEntryScreen), findsOneWidget);
  });
}
