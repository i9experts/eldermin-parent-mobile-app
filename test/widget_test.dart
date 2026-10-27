import 'package:eldermin_parent_app/app/modules/auth/views/phone_entry_screen.dart';
import 'package:eldermin_parent_app/app/modules/splash/views/splash_screen.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
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
    EmAuthPhotos.precacheImpl = (_, __) async {}; // the photos cannot be decoded in a widget test
    await tester.pumpWidget(const EldeminParentApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(SplashScreen), findsOneWidget);

    // the session check holds the splash for 3 s (AuthController._bootstrap); let it finish, then the crossfade
    await tester.pump(const Duration(seconds: 4));
    // the splash overlay stays until its hand-off into the login screen has played
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(PhoneEntryScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });
}
