import 'dart:async';
import 'package:eldermin_parent_app/app/modules/consent/controllers/consent_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../../support/route_harness.dart';
import 'consent_fixtures.dart';

Future<ConsentController> _controller(Future<dynamic> Function(String, String) api, [void Function(FakeClient)? got]) async {
  final client = setUpRouteDeps(api);
  final c = Get.put(ConsentController());
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  got?.call(client);
  return c;
}

void main() {
  tearDown(Get.reset);

  group('statusOf (pinned now: 26 Oct 2026 09:30)', () {
    test('no response and a future due date is pending', () {
      expect(ConsentController.statusOf({'dueDate': '2026-10-30T00:00:00.000Z'}, now: pinnedNow), ConsentStatus.pending);
    });
    test('due today is still pending until the end of the day', () {
      expect(ConsentController.statusOf({'dueDate': '2026-10-26T00:00:00.000Z'}, now: pinnedNow), ConsentStatus.pending);
      expect(ConsentController.statusOf({'dueDate': '2026-10-26T00:00:00.000Z'}, now: DateTime(2026, 10, 26, 23, 59, 58)), ConsentStatus.pending);
      expect(ConsentController.statusOf({'dueDate': '2026-10-26T00:00:00.000Z'}, now: DateTime(2026, 10, 27, 0, 0, 1)), ConsentStatus.expired);
    });
    test('no response and a past due date is expired', () {
      expect(ConsentController.statusOf({'dueDate': '2026-10-25T00:00:00.000Z'}, now: pinnedNow), ConsentStatus.expired);
    });
    test('no due date never expires', () {
      expect(ConsentController.statusOf({}, now: DateTime(2030)), ConsentStatus.pending);
      expect(ConsentController.statusOf({'dueDate': null}, now: DateTime(2030)), ConsentStatus.pending);
    });
    test('a response wins over an expired due date', () {
      expect(ConsentController.statusOf({'dueDate': '2020-01-01T00:00:00.000Z', 'response': {'decision': 'granted'}}, now: pinnedNow), ConsentStatus.responded);
    });
    test('an unparsable due date is treated as none', () {
      expect(ConsentController.statusOf({'dueDate': 'garbage'}, now: pinnedNow), ConsentStatus.pending);
    });
  });

  group('respond', () {
    test('grant success: posts the decision only, patches the item in place, no refetch', () async {
      late FakeClient client;
      final c = await _controller(consentApi(), (x) => client = x);
      expect(c.requests, hasLength(5));
      final before = client.calls.where((x) => x.startsWith('GET')).length;

      expect(await c.respond('pending1', 'granted'), isTrue);

      expect(client.postedTo('/consent/pending1/respond'), [
        {'decision': 'granted'}
      ]);
      expect(client.calls.where((x) => x.startsWith('GET')).length, before);
      expect(c.requests, hasLength(5));
      expect(ConsentController.statusOf(c.byId('pending1')!), ConsentStatus.responded);
      expect(c.byId('pending1')!['response']['respondedByName'], 'Ahmed Khan');
      expect(c.byId('pending1')!['title'], 'Museum trip'); // the rest of the item is kept
      expect(c.respondingId.value, isNull);
      expect(c.respondError.value, isNull);
    });

    test('decline with a reason sends it as notes (trimmed)', () async {
      late FakeClient client;
      final c = await _controller(consentApi(onRespond: (_) => savedResponse('declined', notes: 'Not that day')), (x) => client = x);
      expect(await c.respond('pending1', 'declined', notes: '  Not that day  '), isTrue);
      expect(client.postedTo('/respond'), [
        {'decision': 'declined', 'notes': 'Not that day'}
      ]);
      expect(c.byId('pending1')!['response']['notes'], 'Not that day');
    });

    test('decline without a reason (null or blank) sends no notes key', () async {
      late FakeClient client;
      final c = await _controller(consentApi(onRespond: (_) => savedResponse('declined')), (x) => client = x);
      expect(await c.respond('pending1', 'declined'), isTrue);
      expect(await c.respond('nodue1', 'declined', notes: '   '), isTrue);
      expect(client.postedTo('/respond'), [
        {'decision': 'declined'},
        {'decision': 'declined'},
      ]);
    });

    test('API failure: false, error kept apart from the list error, item unchanged', () async {
      final c = await _controller(consentApi(onRespond: (url) => throw respondFails(url)));
      expect(await c.respond('pending1', 'granted'), isFalse);
      expect(c.respondError.value, isNotNull);
      expect(c.error.value, isNull); // the list must not turn into an error view
      expect(ConsentController.statusOf(c.byId('pending1')!), ConsentStatus.pending);
      expect(c.respondingId.value, isNull);
      // and it can be retried
      expect(c.requests, hasLength(5));
    });

    test('a body that is not a response document falls back to refetching', () async {
      late FakeClient client;
      final c = await _controller(consentApi(onRespond: (_) => 'ok'), (x) => client = x);
      final before = client.calls.where((x) => x.startsWith('GET')).length;
      expect(await c.respond('pending1', 'granted'), isTrue);
      expect(client.calls.where((x) => x.startsWith('GET')).length, before + 1);
    });

    test('no double submit: a second call while one is in flight is ignored', () async {
      final hold = Completer<dynamic>();
      late FakeClient client;
      final c = await _controller((m, u) => m == 'POST' ? hold.future : consentApi()(m, u), (x) => client = x);
      final first = c.respond('pending1', 'granted');
      await Future<void>.delayed(Duration.zero);
      expect(c.respondingId.value, 'pending1');
      expect(await c.respond('pending1', 'granted'), isFalse);
      expect(await c.respond('nodue1', 'declined'), isFalse); // not even another request
      hold.complete(savedResponse('granted'));
      expect(await first, isTrue);
      expect(client.postedTo('/respond'), hasLength(1));
      expect(c.respondingId.value, isNull);
    });

    test('expired and responded items are refused without calling the API', () async {
      late FakeClient client;
      final c = await _controller(consentApi(), (x) => client = x);
      expect(await c.respond('expired1', 'granted'), isFalse);
      expect(await c.respond('done1', 'granted'), isFalse); // the backend would allow changing it; the app does not
      expect(await c.respond('missing', 'granted'), isFalse);
      expect(client.postedTo('/respond'), isEmpty);
      expect(c.byId('done1')!['response']['decision'], 'declined');
    });
  });
}
