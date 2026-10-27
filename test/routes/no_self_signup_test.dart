import 'dart:io';

import 'package:eldermin_parent_app/app/routes/app_pages.dart';
import 'package:eldermin_parent_app/app/modules/auth/views/phone_entry_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../support/auth_harness.dart';

/// Parents log in only with the WhatsApp number the school added against their child: no route, button or link
/// leads to account creation or email sign-in.
void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);

  test('no registered route is an account-creation or email sign-in route', () {
    for (final p in AppPages.pages) {
      expect(p.name, isNot(matches(RegExp('create|sign-?up|register|email', caseSensitive: false))), reason: p.name);
    }
  });

  testWidgets('the login screen offers the number field and the code button, with no create-account or email link', (t) async {
    setUpAuthDeps();
    await pumpScreen(t, const PhoneEntryScreen());
    expect(find.text('Send Verification Code'), findsOneWidget);
    expect(find.textContaining(RegExp('create an account|sign up|email', caseSensitive: false), findRichText: true), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  test('lib/ has no self-signup code left', () {
    final hits = <String>[];
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final text = f.readAsStringSync();
      if (RegExp(r'CreateAccount|EmailSignIn|registerLead|loginLead|isParentLead|schoolOnboarded|Routes\.createAccount').hasMatch(text)) hits.add(f.path);
    }
    expect(hits, isEmpty);
  });
}
