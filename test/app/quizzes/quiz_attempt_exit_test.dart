import 'dart:async';
import 'package:dio/dio.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import '../../support/p4_fixtures.dart';
import '../../support/route_harness.dart';

const _args = {'assessmentId': 'a1', 'subject': 'Mathematics', 'title': 'Fractions quiz'};

Future<void> _open(WidgetTester t, {bool failSubmit = false, bool Function()? failing}) async {
  setUpRouteDeps((m, url) {
    if (url.endsWith('/submit') && (failing?.call() ?? failSubmit)) {
      throw DioException(
        requestOptions: RequestOptions(path: url),
        type: DioExceptionType.badResponse,
        response: Response(requestOptions: RequestOptions(path: url), statusCode: 500, data: {'message': 'Could not submit the quiz'}),
      );
    }
    if (url.endsWith('/submit')) return {'status': 'graded', 'totalMarks': 3, 'passingMarks': 1, 'obtainedMarks': 2};
    return p4Api()(m, url);
  });
  await pumpApp(t);
  unawaited(Get.toNamed(Routes.quizAttempt, arguments: _args));
  await settle(t);
}

/// Answers question 1, goes to the last question and submits (confirming the dialog).
Future<void> _answerAndSubmit(WidgetTester t) async {
  await t.tap(find.text('1'));
  await t.tap(find.text('Next'));
  await settle(t);
  await t.tap(find.text('Next'));
  await settle(t);
  await t.tap(find.text('Submit (1/3)'));
  await settle(t);
  await t.tap(find.descendant(of: find.byType(EmDialog), matching: find.text('Submit')));
  await settle(t);
}

void main() {
  tearDown(Get.reset);

  testWidgets('failed submit, error snackbar visible: leaving the quiz still pops the screen', (t) async {
    await _open(t, failSubmit: true);
    await _answerAndSubmit(t);
    expect(find.text('Could not submit the quiz'), findsOneWidget); // the snackbar is up
    expect(find.text('Question 3 of 3'), findsOneWidget);

    // system back / swipe -> "Leave quiz?" -> Leave
    unawaited(t.state<NavigatorState>(find.byType(Navigator).first).maybePop());
    await settle(t);
    expect(find.text('Leave quiz?'), findsOneWidget);
    await t.tap(find.text('Leave'));
    await settle(t);

    expect(find.text('Question 3 of 3'), findsNothing); // popped, not just the snackbar dismissed
    expect(Get.currentRoute, '/');
    await t.pump(const Duration(seconds: 5));
    await disposeApp(t);
  });

  testWidgets('without a snackbar, leaving still pops; Stay keeps the quiz', (t) async {
    await _open(t);
    await t.tap(find.text('1'));
    await settle(t);
    unawaited(t.state<NavigatorState>(find.byType(Navigator).first).maybePop());
    await settle(t);
    await t.tap(find.text('Stay'));
    await settle(t);
    expect(find.text('Question 1 of 3'), findsOneWidget);
    unawaited(t.state<NavigatorState>(find.byType(Navigator).first).maybePop());
    await settle(t);
    await t.tap(find.text('Leave'));
    await settle(t);
    expect(find.text('Question 1 of 3'), findsNothing);
    await disposeApp(t);
  });

  testWidgets('result view with a failed attempt\'s error snackbar still up: "Back to quizzes" pops the screen', (t) async {
    var fail = true;
    await _open(t, failing: () => fail);
    await t.tap(find.text('1'));
    await t.tap(find.text('Next'));
    await settle(t);
    await t.tap(find.text('Next'));
    await settle(t);
    // failed attempt -> error snackbar; then a quick retry that succeeds (short pumps: the snackbar lasts 3 s)
    await t.tap(find.text('Submit (1/3)'));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.descendant(of: find.byType(EmDialog), matching: find.text('Submit')));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Could not submit the quiz'), findsOneWidget);
    fail = false;
    await t.tap(find.text('Submit (1/3)'));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.descendant(of: find.byType(EmDialog), matching: find.text('Submit')));
    await t.pump(const Duration(milliseconds: 400));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Back to quizzes'), findsOneWidget); // the result view
    expect(Get.isSnackbarOpen, isTrue); // ... with the failed attempt's snackbar still showing

    await t.tap(find.text('Back to quizzes'));
    await settle(t);
    expect(find.text('Back to quizzes'), findsNothing); // popped, not just the snackbar dismissed
    expect(Get.currentRoute, '/');
    await t.pump(const Duration(seconds: 5));
    await disposeApp(t);
  });

  testWidgets('result view without a snackbar: "Back to quizzes" pops', (t) async {
    await _open(t);
    await _answerAndSubmit(t);
    expect(find.text('Back to quizzes'), findsOneWidget);
    await t.tap(find.text('Back to quizzes'));
    await settle(t);
    expect(find.text('Back to quizzes'), findsNothing);
    await disposeApp(t);
  });
}
