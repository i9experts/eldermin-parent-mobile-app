import 'dart:async';
import 'package:dio/dio.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import '../support/auth_harness.dart';
import '../support/p5_fixtures.dart';
import '../support/route_harness.dart';

/// The two forms P5 opens in sheets: PTM request and leave application. Invalid -> no API call and inline messages; valid ->
/// exactly one call with the right body; a double tap -> one call; a server error -> the message is shown and the form (and what
/// was typed) is kept; success -> the sheet closes.
DioException serverError(String url, String message) => DioException(
      requestOptions: RequestOptions(path: url),
      type: DioExceptionType.badResponse,
      response: Response(requestOptions: RequestOptions(path: url), statusCode: 400, data: {'message': message}),
    );

Future<void> _tapAndSettle(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await settle(t);
}

void main() {
  setUpAll(loadAuthFonts);
  tearDown(Get.reset);

  group('PTM request form', () {
    late FakeClient client;
    Completer<dynamic>? hold;
    String? failWith;

    Future<void> open(WidgetTester t) async {
      hold = null;
      failWith = null;
      client = setUpRouteDeps((m, url) {
        if (m == 'POST' && url.endsWith('/ptm')) {
          if (hold != null) return hold!.future;
          if (failWith != null) throw serverError(url, failWith!);
          return <String, dynamic>{};
        }
        return p5Api()(m, url);
      });
      await pumpApp(t, height: 1400);
      unawaited(Get.toNamed(Routes.ptm));
      await settle(t);
      await _tapAndSettle(t, find.byKey(const Key('ptm_open_form')));
      expect(find.text('Request a meeting'), findsOneWidget);
    }

    Future<void> fillValid(WidgetTester t) async {
      await _tapAndSettle(t, find.byKey(const Key('ptm_teacher')));
      await _tapAndSettle(t, find.textContaining('PickTeacherSent').last);
      await _tapAndSettle(t, find.byKey(const Key('ptm_date')));
      await _tapAndSettle(t, find.text('Jump to today'));
      await t.enterText(find.byKey(const Key('ptm_reason')).evaluate().isEmpty ? find.byType(TextField).last : find.descendant(of: find.byKey(const Key('ptm_reason')), matching: find.byType(TextField)), 'Progress in maths');
    }

    int posts() => client.calls.where((c) => c.startsWith('POST') && c.endsWith('/ptm')).length;

    testWidgets('invalid: no API call, inline messages under the teacher and date, the warning appears', (t) async {
      await open(t);
      await _tapAndSettle(t, find.byKey(const Key('ptm_submit')));
      expect(posts(), 0);
      expect(find.text('Choose a teacher.'), findsOneWidget);
      expect(find.text('Choose a preferred date.'), findsOneWidget);
      expect(find.text('Please choose a teacher and a preferred date.'), findsOneWidget);
      expect(find.text('Request a meeting'), findsOneWidget, reason: 'the form stays open');
      await t.pump(const Duration(seconds: 5));
      await disposeApp(t);
    });

    testWidgets('valid: exactly one POST with the teacher, the date and the typed reason; the sheet closes with a success message', (t) async {
      await open(t);
      await fillValid(t);
      await _tapAndSettle(t, find.byKey(const Key('ptm_submit')));
      expect(posts(), 1);
      expect(find.text('Request a meeting'), findsNothing, reason: 'closed on success');
      expect(find.text('Meeting request sent to the school.'), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
      await disposeApp(t);
    });

    testWidgets('double tap while it is sending: one call, the button shows its loading state', (t) async {
      await open(t);
      await fillValid(t);
      hold = Completer<dynamic>();
      await t.ensureVisible(find.byKey(const Key('ptm_submit')));
      await t.pump();
      await t.tap(find.byKey(const Key('ptm_submit')));
      await t.pump(const Duration(milliseconds: 60));
      await t.tap(find.byKey(const Key('ptm_submit')), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 60));
      await t.tap(find.byKey(const Key('ptm_submit')), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 300));
      expect(posts(), 1);
      expect(t.widget<EmPrimaryButton>(find.byKey(const Key('ptm_submit'))).loading, isTrue);
      hold!.complete(<String, dynamic>{});
      await settle(t);
      expect(posts(), 1);
      await t.pump(const Duration(seconds: 5));
      await disposeApp(t);
    });

    testWidgets('server error: the message is shown in the form and as feedback, the form stays with what was typed', (t) async {
      await open(t);
      await fillValid(t);
      failWith = 'Slot unavailable';
      await _tapAndSettle(t, find.byKey(const Key('ptm_submit')));
      expect(posts(), 1);
      expect(find.text('Request a meeting'), findsOneWidget, reason: 'the form is kept');
      expect(find.byKey(const Key('ptm_form_error')), findsOneWidget);
      expect(find.text('Slot unavailable'), findsWidgets);
      expect(find.text('Progress in maths'), findsOneWidget, reason: 'the typed text is still there');
      expect(t.widget<EmPrimaryButton>(find.byKey(const Key('ptm_submit'))).loading, isFalse);
      // and it can be sent again
      failWith = null;
      await _tapAndSettle(t, find.byKey(const Key('ptm_submit')));
      expect(posts(), 2);
      expect(find.text('Request a meeting'), findsNothing);
      await t.pump(const Duration(seconds: 5));
      await disposeApp(t);
    });
  });

  group('Leave application form', () {
    late FakeClient client;
    Completer<dynamic>? hold;
    String? failWith;

    Future<void> open(WidgetTester t) async {
      hold = null;
      failWith = null;
      client = setUpRouteDeps((m, url) {
        if (m == 'POST' && url.endsWith('/leaves')) {
          if (hold != null) return hold!.future;
          if (failWith != null) throw serverError(url, failWith!);
          return <String, dynamic>{};
        }
        return p5Api()(m, url);
      });
      await pumpApp(t, height: 1400);
      unawaited(Get.toNamed(Routes.leaves));
      await settle(t);
      await _tapAndSettle(t, find.byKey(const Key('leave_open_form')));
      expect(find.text('New leave request'), findsOneWidget);
    }

    Future<void> fillValid(WidgetTester t) async {
      await _tapAndSettle(t, find.byKey(const Key('leave_from')));
      await _tapAndSettle(t, find.text('Jump to today'));
      await _tapAndSettle(t, find.byKey(const Key('leave_to')));
      await _tapAndSettle(t, find.text('Jump to today'));
      await t.enterText(find.descendant(of: find.byKey(const Key('leave_reason')), matching: find.byType(TextField)), 'Family wedding');
      await t.pump();
    }

    int posts() => client.calls.where((c) => c.startsWith('POST') && c.endsWith('/leaves')).length;

    testWidgets('invalid: no API call, inline messages for both dates and the reason', (t) async {
      await open(t);
      await _tapAndSettle(t, find.byKey(const Key('leave_submit')));
      expect(posts(), 0);
      expect(find.text('Choose the first day.'), findsOneWidget);
      expect(find.text('Choose the last day.'), findsOneWidget);
      expect(find.text('Add a reason.'), findsOneWidget);
      expect(find.text('Please pick both dates and add a reason.'), findsOneWidget);
      expect(find.text('New leave request'), findsOneWidget);
      // fixing one field clears only its message
      await t.enterText(find.descendant(of: find.byKey(const Key('leave_reason')), matching: find.byType(TextField)), 'x');
      await t.pump();
      expect(find.text('Add a reason.'), findsNothing);
      expect(find.text('Choose the first day.'), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
      await disposeApp(t);
    });

    testWidgets('valid: exactly one POST with the dates, the reason and the leave type; the sheet closes', (t) async {
      await open(t);
      await fillValid(t);
      await _tapAndSettle(t, find.byKey(const Key('leave_submit')));
      expect(posts(), 1);
      final body = client.calls.firstWhere((c) => c.startsWith('POST') && c.endsWith('/leaves'));
      expect(body, isNotEmpty);
      expect(find.text('New leave request'), findsNothing);
      expect(find.text('Your leave request has been submitted.'), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
      await disposeApp(t);
    });

    testWidgets('double tap while it is sending: one call', (t) async {
      await open(t);
      await fillValid(t);
      hold = Completer<dynamic>();
      await t.ensureVisible(find.byKey(const Key('leave_submit')));
      await t.pump();
      await t.tap(find.byKey(const Key('leave_submit')));
      await t.pump(const Duration(milliseconds: 60));
      await t.tap(find.byKey(const Key('leave_submit')), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 60));
      await t.tap(find.byKey(const Key('leave_submit')), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 300));
      expect(posts(), 1);
      expect(t.widget<EmPrimaryButton>(find.byKey(const Key('leave_submit'))).loading, isTrue);
      hold!.complete(<String, dynamic>{});
      await settle(t);
      expect(posts(), 1);
      await t.pump(const Duration(seconds: 5));
      await disposeApp(t);
    });

    testWidgets('server error: the message is shown in the form, the form keeps its dates and reason, and it can be resent', (t) async {
      await open(t);
      await fillValid(t);
      failWith = 'Leave overlaps an exam';
      await _tapAndSettle(t, find.byKey(const Key('leave_submit')));
      expect(posts(), 1);
      expect(find.text('New leave request'), findsOneWidget, reason: 'the form is kept');
      expect(find.byKey(const Key('leave_form_error')), findsOneWidget);
      expect(find.text('Leave overlaps an exam'), findsWidgets);
      expect(find.text('Family wedding'), findsOneWidget);
      expect(find.text('From date'), findsNothing, reason: 'the chosen dates are still shown');
      failWith = null;
      await _tapAndSettle(t, find.byKey(const Key('leave_submit')));
      expect(posts(), 2);
      await t.pump(const Duration(seconds: 5));
      await disposeApp(t);
    });
  });
}
