import 'dart:async';
import 'package:eldermin_parent_app/app/modules/circulars/controllers/circulars_controller.dart';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../../support/route_harness.dart';

// "now" is 26 Oct 2026, the circulars screen starts on that month.
List<dynamic> rows() => [
      {
        '_id': 'c1',
        'title': 'Winter uniform',
        'body': 'Please wear the winter uniform from Monday.',
        'category': 'circular',
        'priority': 'high',
        'attachmentUrls': ['https://cdn.example/circulars/uniform%20list.pdf'],
        'requiresAcknowledgment': true,
        'acknowledged': false,
        'effectiveDate': '2026-10-20T06:00:00.000Z',
        'createdAt': '2026-10-19T06:00:00.000Z',
      },
      {'_id': 'c2', 'title': 'Sports day', 'body': '', 'category': 'event', 'priority': 'normal', 'attachmentUrls': [], 'requiresAcknowledgment': false, 'acknowledged': false, 'effectiveDate': '2026-10-21T06:00:00.000Z'},
      {'_id': 'c3', 'title': 'Fee reminder', 'body': 'Fees are due.', 'category': 'notice', 'requiresAcknowledgment': true, 'acknowledged': true, 'effectiveDate': '2026-10-22T06:00:00.000Z'},
    ];

Future<FakeClient> _open(WidgetTester t, {dynamic Function(String url)? onAck}) async {
  final client = setUpRouteDeps((m, u) {
    if (m == 'POST' && u.contains('/circulars/')) return onAck != null ? onAck(u) : {'ok': true};
    if (u.endsWith('/circulars')) return rows();
    return <dynamic>[];
  });
  await pumpRoute(t, Routes.circulars);
  return client;
}

final _sheet = find.byKey(const Key('detail_sheet'));
final _ack = find.byKey(const Key('circular_acknowledge'));

/// Lets any snackbar finish (it holds a ticker) before the app is torn down.
Future<void> _done(WidgetTester t) async {
  await t.pump(const Duration(seconds: 4));
  await disposeApp(t);
}

Future<void> _closeSheet(WidgetTester t) async {
  t.state<NavigatorState>(find.byType(Navigator).first).pop();
  await settle(t);
}

Future<void> _open1(WidgetTester t, String title) async {
  await t.ensureVisible(find.text(title));
  await t.tap(find.text(title));
  await settle(t);
}

void main() {
  testWidgets('row tap opens the new detail sheet with category, priority, date, body and attachments', (t) async {
    await _open(t);
    await _open1(t, 'Winter uniform');
    expect(_sheet, findsOneWidget);
    expect(find.descendant(of: _sheet, matching: find.text('Winter uniform')), findsOneWidget);
    expect(find.descendant(of: _sheet, matching: find.text('Acknowledgement needed')), findsOneWidget);
    expect(find.descendant(of: _sheet, matching: find.text('Circular')), findsOneWidget);
    expect(find.descendant(of: _sheet, matching: find.text('High')), findsOneWidget);
    expect(find.descendant(of: _sheet, matching: find.text('20 Oct 2026')), findsOneWidget);
    expect(find.descendant(of: _sheet, matching: find.text('Please wear the winter uniform from Monday.')), findsOneWidget);
    expect(find.descendant(of: _sheet, matching: find.text('uniform list.pdf')), findsOneWidget);
    expect(_ack, findsOneWidget);
    await _closeSheet(t);
    await _done(t);
  });

  testWidgets('a normal-priority circular with no body and no attachments hides those rows and says so', (t) async {
    await _open(t);
    await _open1(t, 'Sports day');
    expect(find.descendant(of: _sheet, matching: find.text('Priority')), findsNothing);
    expect(find.descendant(of: _sheet, matching: find.text('Attachments')), findsNothing);
    expect(find.descendant(of: _sheet, matching: find.text('No further details.')), findsOneWidget);
    expect(_ack, findsNothing);
    expect(find.byKey(const Key('detail_sheet_footer')), findsNothing);
    await _closeSheet(t);
    await _done(t);
  });

  testWidgets('an already acknowledged circular is read-only', (t) async {
    await _open(t);
    await _open1(t, 'Fee reminder');
    expect(find.descendant(of: _sheet, matching: find.text('Acknowledged')), findsOneWidget);
    expect(_ack, findsNothing);
    await _closeSheet(t);
    await _done(t);
  });

  testWidgets('acknowledge: posts, closes the sheet, patches the circular in place and confirms', (t) async {
    final client = await _open(t);
    await _open1(t, 'Winter uniform');
    await t.tap(_ack);
    await settle(t);
    expect(client.calls.where((c) => c.startsWith('POST') && c.contains('/circulars/c1')), hasLength(1));
    expect(_sheet, findsNothing);
    expect(find.text('Thank you — acknowledged.'), findsOneWidget);
    expect(Get.find<CircularsController>().byId('c1')!['acknowledged'], isTrue);
    await _done(t);
  });

  testWidgets('failure keeps the sheet open with the error and the button available', (t) async {
    final client = await _open(t, onAck: (url) => throw networkError(url));
    await _open1(t, 'Winter uniform');
    await t.tap(_ack);
    await settle(t);
    expect(_sheet, findsOneWidget);
    expect(find.byKey(const Key('circular_error')), findsOneWidget);
    expect(_ack, findsOneWidget);
    expect(Get.find<CircularsController>().byId('c1')!['acknowledged'], isFalse);
    expect(client.calls.where((c) => c.startsWith('POST')), hasLength(1));
    await _closeSheet(t);
    await _done(t);
  });

  testWidgets('in flight: the button is disabled and a second acknowledge is ignored', (t) async {
    final hold = Completer<dynamic>();
    final client = await _open(t, onAck: (_) => hold.future);
    await _open1(t, 'Winter uniform');
    await t.tap(_ack);
    await t.pump(const Duration(milliseconds: 300));
    expect(t.widget<ElevatedButton>(find.descendant(of: _ack, matching: find.byType(ElevatedButton))).onPressed, isNull);
    expect(await Get.find<CircularsController>().acknowledge('c1'), isFalse);
    expect(client.calls.where((c) => c.startsWith('POST')), hasLength(1));
    hold.complete({'ok': true});
    await settle(t);
    expect(_sheet, findsNothing);
    await _done(t);
  });
}
