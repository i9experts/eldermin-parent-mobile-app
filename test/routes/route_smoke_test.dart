import 'dart:async';
import 'package:eldermin_parent_app/app/routes/app_pages.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';
import '../support/route_harness.dart';

/// Every named route renders without an exception in each of its load states (empty answer, failed request,
/// request still pending) at normal and 1.3x text. The fake API means no network and no storage.
final routes = <String, Object?>{
  Routes.otpVerify: {'phone': '+923001234567', 'devCode': '123456'},
  Routes.createAccount: null,
  Routes.emailSignIn: null,
  Routes.studentSelector: null,
  Routes.notifications: null,
  Routes.dues: null,
  Routes.attendance: null,
  Routes.homework: null,
  Routes.timetable: null,
  Routes.tarbiyah: null,
  Routes.library: null,
  Routes.leaves: null,
  Routes.homeTasks: null,
  Routes.circulars: null,
  Routes.consent: null,
  Routes.profile: null,
  Routes.medical: null,
  Routes.documents: null,
  Routes.courses: null,
  Routes.quizzes: null,
  Routes.quizAttempt: {'assessmentId': 'a1', 'subject': 'Maths', 'title': 'Fractions'},
  Routes.diary: null,
  Routes.learningResources: null,
  Routes.datesheet: null,
  Routes.ptm: null,
  Routes.feedback: null,
  Routes.messageThread: {'threadId': 't1', 'subject': 'Homework', 'staffName': 'Ms Sara', 'studentName': 'Ayesha Khan'},
  Routes.aboutUs: null,
  Routes.help: null,
  Routes.privacyPolicy: null,
};

void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);

  test('the smoke test covers every named route (30)', () {
    final registered = AppPages.pages.map((p) => p.name).toSet();
    expect(routes.keys.toSet(), registered);
    expect(routes.length, 30);
  });

  for (final entry in routes.entries) {
    group(entry.key, () {
      for (final scale in [1.0, 1.3]) {
        testWidgets('empty answer @${scale}x', (t) async {
          setUpRouteDeps((m, url) => <dynamic>[]);
          await pumpRoute(t, entry.key, arguments: entry.value, textScale: scale);
          expect(t.takeException(), isNull);
          expect(find.byType(Scaffold), findsWidgets);
          await disposeApp(t);
          expect(t.takeException(), isNull);
        });
      }

      testWidgets('failed request', (t) async {
        setUpRouteDeps((m, url) => throw networkError(url));
        await pumpRoute(t, entry.key, arguments: entry.value);
        expect(t.takeException(), isNull);
        expect(find.byType(Scaffold), findsWidgets);
        await disposeApp(t);
      });

      testWidgets('request still pending (loading state)', (t) async {
        setUpRouteDeps((m, url) => Completer<dynamic>().future);
        await pumpRoute(t, entry.key, arguments: entry.value);
        expect(t.takeException(), isNull);
        expect(find.byType(Scaffold), findsWidgets);
        await disposeApp(t);
      });
    });
  }
}
