import 'package:dio/dio.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/route_harness.dart';

Future<FakeClient> _open(WidgetTester t, {required bool Function() failing}) async {
  final client = setUpRouteDeps((m, u) {
    if (m == 'POST' && u.endsWith('/complaints')) {
      if (failing()) {
        throw DioException(
          requestOptions: RequestOptions(path: u),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(path: u), statusCode: 500, data: {'message': 'Server said no'}),
        );
      }
      return <String, dynamic>{};
    }
    return <dynamic>[];
  });
  await pumpRoute(t, Routes.feedback);
  return client;
}

Future<void> _fillAndSubmit(WidgetTester t) async {
  await t.enterText(find.byType(TextField).at(0), 'Bus timing');
  await t.enterText(find.byType(TextField).at(1), 'The bus arrives late every Monday.');
  await t.ensureVisible(find.text('Submit feedback'));
  await t.tap(find.text('Submit feedback'));
  await settle(t);
}

void main() {
  testWidgets('a successful submit closes the screen and still shows the success message', (t) async {
    final client = await _open(t, failing: () => false);
    expect(find.text('Send feedback'), findsOneWidget);
    await _fillAndSubmit(t);
    expect(client.postedTo('/complaints'), hasLength(1));
    expect(find.text('Send feedback'), findsNothing); // popped
    expect(find.text('Thanks — your feedback has been submitted.'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await disposeApp(t);
  });

  testWidgets('it still closes when an error snackbar from the first attempt is on screen', (t) async {
    var fail = true;
    final client = await _open(t, failing: () => fail);
    await _fillAndSubmit(t);
    expect(find.text('Send feedback'), findsOneWidget); // failed: the form stays
    expect(find.text('Server said no'), findsWidgets); // the error snackbar is up
    fail = false;
    await t.ensureVisible(find.text('Submit feedback'));
    await t.tap(find.text('Submit feedback'));
    await settle(t);
    expect(client.postedTo('/complaints'), hasLength(2));
    expect(find.text('Send feedback'), findsNothing); // popped although a GetX snackbar was open
    await t.pump(const Duration(seconds: 4)); // GetX queues snackbars: the success one appears once the error one has gone
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Thanks — your feedback has been submitted.'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    await disposeApp(t);
  });
}
