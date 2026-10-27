import 'dart:async';
import 'package:eldermin_parent_app/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eldermin_parent_app/app/components/rich_image.dart';
import 'package:eldermin_parent_app/core/constants/media_hosts.dart';
import '../../support/fake_images.dart';
import '../../support/route_harness.dart';
import 'consent_fixtures.dart';

Future<FakeClient> _open(WidgetTester t, Future<dynamic> Function(String, String) api, {double textScale = 1}) async {
  final client = setUpRouteDeps(api);
  await pumpRoute(t, Routes.consent, textScale: textScale);
  return client;
}

Future<void> _openRow(WidgetTester t, String title) async {
  await t.ensureVisible(find.text(title));
  await t.tap(find.text(title));
  await settle(t);
}

/// Closes any open sheet / dialog / snackbar, then tears the app down.
Future<void> _done(WidgetTester t) async {
  t.state<NavigatorState>(find.byType(Navigator).first).popUntil((r) => r.isFirst);
  await t.pump(const Duration(milliseconds: 500));
  await t.pump(const Duration(seconds: 4));
  await disposeApp(t);
}

Finder _inSheet(Finder f) => find.descendant(of: find.byKey(const Key('detail_sheet')), matching: f);

Future<void> _scrollTo(WidgetTester t, Finder f) =>
    t.scrollUntilVisible(f, 200, scrollable: find.descendant(of: find.byKey(const Key('detail_sheet')), matching: find.byType(Scrollable)).first);

final _grant = find.byKey(const Key('consent_grant'));
final _decline = find.byKey(const Key('consent_decline'));

void main() {
  testWidgets('the list rows no longer carry Grant / Decline buttons', (t) async {
    await _open(t, consentApi());
    expect(find.text('Museum trip'), findsOneWidget);
    expect(_grant, findsNothing);
    expect(_decline, findsNothing);
    expect(find.text('Grant consent'), findsNothing);
    await _done(t);
  });

  testWidgets('row preview never shows raw HTML or script text', (t) async {
    await _open(t, consentApi());
    expect(find.textContaining('<'), findsNothing);
    expect(find.textContaining('alert'), findsNothing);
    await _done(t);
  });

  testWidgets('row preview shows clean text for a body with a link and an image', (t) async {
    final rows = [
      {
        '_id': 'rich1',
        'title': 'Rich body',
        'description': '<div>Dear parents</div><div>See <a href="https://school.edu/trip">the trip page</a></div><div><img src="https://cdn.example/a.png"></div>',
        'response': null,
      },
    ];
    await _open(t, consentApi(rows: rows));
    expect(find.text('Dear parents See the trip page'), findsOneWidget);
    expect(find.textContaining('](', findRichText: true), findsNothing);
    expect(find.textContaining('[Image]', findRichText: true), findsNothing);
    await _done(t);
  });

  group('images in the body and attachments', () {
    final host = 'https://${kConsentImageHosts.first}/school/consent-attachments';
    // What the web editor (Chrome execCommand) stores: div lines, a list, a link, an uploaded image as a bare <img src>.
    final realBody = '<div>Dear parents,</div><div>We visit the <b>museum</b> on <u>12 Nov</u>.</div><div><br></div>'
        '<ul><li>Packed lunch</li><li>Water bottle</li></ul>'
        '<div>Details: <a href="https://school.edu/trip">trip page</a></div><div><img src="$host/map.png"></div>';
    List<dynamic> rows() => [
          {
            '_id': 'img1',
            'title': 'Gallery visit',
            'description': realBody,
            'dueDate': '2026-10-30T00:00:00.000Z',
            'attachments': ['$host/slip.png', '$host/rules.pdf', 'https://cdn.example/other.png', '$host/vector.svg', '$host/photo.heic'],
            'response': null,
          },
        ];

    testWidgets('the sheet renders a real-format body: text, styles, list, link and the image', (t) async {
      final p = await loadedImage(t);
      useFakeImages((_) => p);
      await _open(t, consentApi(rows: rows()));
      await _openRow(t, 'Gallery visit');
      expect(_inSheet(find.textContaining('Dear parents,', findRichText: true)), findsOneWidget);
      expect(_inSheet(find.textContaining('museum', findRichText: true)), findsOneWidget);
      expect(_inSheet(find.textContaining('Packed lunch', findRichText: true)), findsOneWidget);
      expect(_inSheet(find.textContaining('trip page', findRichText: true)), findsOneWidget);
      expect(_inSheet(find.byKey(const Key('rich_text'))), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('rich_text')), matching: find.byType(RichImageView)), findsOneWidget);
      expect(_inSheet(find.textContaining('<', findRichText: true)), findsNothing);
      await _done(t);
    });

    testWidgets('allowlisted image attachments are a thumbnail row that opens the viewer; other attachments stay links', (t) async {
      final p = await loadedImage(t);
      useFakeImages((_) => p);
      await _open(t, consentApi(rows: rows()));
      await _openRow(t, 'Gallery visit');
      final row = find.byKey(const Key('detail_image_attachments'));
      await _scrollTo(t, row);
      expect(find.descendant(of: row, matching: find.byType(RichImageView)), findsOneWidget); // only slip.png
      // pdf, svg, heic and a foreign-host png keep the open-link row
      await _scrollTo(t, find.byKey(ValueKey('detail_attachment_$host/photo.heic')));
      for (final f in ['rules.pdf', 'vector.svg', 'photo.heic']) {
        expect(find.byKey(ValueKey('detail_attachment_$host/$f')), findsOneWidget, reason: f);
      }
      expect(find.byKey(const ValueKey('detail_attachment_https://cdn.example/other.png')), findsOneWidget);
      expect(find.byKey(ValueKey('detail_attachment_$host/slip.png')), findsNothing);

      await t.tap(find.descendant(of: row, matching: find.byType(RichImageView)));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('image_viewer')), findsOneWidget);
      await t.tap(find.byKey(const Key('image_viewer_close')));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('image_viewer')), findsNothing);
      expect(find.byKey(const Key('detail_sheet')), findsOneWidget); // back on the sheet
      await _done(t);
    });

    testWidgets('a failing attachment thumbnail shows the unavailable tile', (t) async {
      useFakeImages((_) => FailingImage());
      await _open(t, consentApi(rows: rows()));
      await _openRow(t, 'Gallery visit');
      await _scrollTo(t, find.byKey(const Key('detail_image_attachments')));
      await t.pump();
      expect(find.descendant(of: find.byKey(const Key('detail_image_attachments')), matching: find.byKey(const Key('image_unavailable'))), findsOneWidget);
      await _done(t);
    });
  });

  testWidgets('tapping a pending row opens the sheet with every field and the actions', (t) async {
    await _open(t, consentApi());
    await _openRow(t, 'Museum trip');
    expect(find.byKey(const Key('detail_sheet')), findsOneWidget);
    expect(find.text('Pending'), findsWidgets);
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Ayesha Khan · Class 5 - A'), findsOneWidget); // the client-side selected student
    expect(find.text('Field trip'), findsOneWidget);
    expect(find.text('Ms Sara'), findsOneWidget);
    expect(find.text('20 Oct 2026'), findsOneWidget);
    expect(find.text('30 Oct 2026'), findsOneWidget);
    expect(_inSheet(find.textContaining('We visit the museum', findRichText: true)), findsOneWidget); // HTML description rendered, tags gone
    expect(_inSheet(find.textContaining('Packed lunch', findRichText: true)), findsOneWidget);
    expect(find.textContaining('alert'), findsNothing);
    expect(find.text('permission slip.png'), findsOneWidget); // attachment, decoded name
    expect(_grant, findsOneWidget);
    expect(_decline, findsOneWidget);
    expect(find.text('Your response'), findsNothing);
    await _done(t);
  });

  testWidgets('another child\'s id or the responder\'s user id is never shown', (t) async {
    await _open(t, consentApi());
    await _openRow(t, 'Museum trip');
    expect(find.textContaining('OTHER_CHILD_ID', findRichText: true), findsNothing);
    await t.tapAt(const Offset(10, 10)); // dismiss
    await settle(t);
    await _openRow(t, 'Photo permission');
    expect(find.textContaining('SECRET_USER_ID', findRichText: true), findsNothing);
    expect(find.textContaining('OTHER_CHILD_ID', findRichText: true), findsNothing);
    await _done(t);
  });

  testWidgets('due today and no-due-date requests still offer the actions', (t) async {
    await _open(t, consentApi());
    await _openRow(t, 'Due today');
    expect(_grant, findsOneWidget);
    await t.tapAt(const Offset(10, 10));
    await settle(t);
    await _openRow(t, 'No due date');
    expect(_grant, findsOneWidget);
    expect(find.text('Respond by'), findsNothing); // empty field hidden
    await _done(t);
  });

  testWidgets('an expired request opens read-only with a notice and no actions', (t) async {
    await _open(t, consentApi());
    await _openRow(t, 'Old trip');
    expect(find.text('Expired'), findsWidgets);
    expect(find.byKey(const Key('detail_notice')), findsOneWidget);
    expect(_grant, findsNothing);
    expect(_decline, findsNothing);
    expect(find.byKey(const Key('detail_sheet_footer')), findsNothing);
    await _done(t);
  });

  testWidgets('a responded request shows the response read-only, with "Responded on", and no actions', (t) async {
    await _open(t, consentApi());
    await _openRow(t, 'Photo permission');
    expect(find.text('Declined'), findsWidgets);
    expect(find.text('Your response'), findsOneWidget);
    expect(find.text('Consent declined'), findsOneWidget);
    expect(find.text('Ahmed Khan'), findsOneWidget);
    expect(find.text('Responded on'), findsOneWidget);
    expect(find.text('14 Oct 2026'), findsOneWidget);
    expect(find.text('We prefer not to'), findsOneWidget);
    expect(_grant, findsNothing);
    expect(_decline, findsNothing);
    await _done(t);
  });

  testWidgets('grant: confirm, submit, the sheet closes, the row updates, a snackbar confirms', (t) async {
    final client = await _open(t, consentApi());
    await _openRow(t, 'Museum trip');
    await t.tap(_grant);
    await settle(t);
    expect(find.text('Grant consent?'), findsOneWidget);
    expect(client.postedTo('/respond'), isEmpty); // nothing sent before the confirmation
    await t.tap(find.widgetWithText(TextButton, 'Grant consent'));
    await settle(t);
    expect(client.postedTo('/consent/pending1/respond'), [
      {'decision': 'granted'}
    ]);
    expect(find.byKey(const Key('detail_sheet')), findsNothing);
    expect(find.text('Response recorded — consent granted.'), findsOneWidget);
    expect(find.text('Granted'), findsWidgets); // the row's tag, patched in place
    await _done(t);
  });

  testWidgets('grant: cancelling the confirmation sends nothing and keeps the sheet', (t) async {
    final client = await _open(t, consentApi());
    await _openRow(t, 'Museum trip');
    await t.tap(_grant);
    await settle(t);
    await t.tap(find.text('Cancel'));
    await settle(t);
    expect(client.postedTo('/respond'), isEmpty);
    expect(find.byKey(const Key('detail_sheet')), findsOneWidget);
    await _done(t);
  });

  testWidgets('decline with a reason: the reason goes out as notes', (t) async {
    final client = await _open(t, consentApi(onRespond: (_) => savedResponse('declined', notes: 'Not that day')));
    await _openRow(t, 'Museum trip');
    await t.tap(_decline);
    await settle(t);
    expect(find.text('Decline consent?'), findsOneWidget);
    await t.enterText(find.byKey(const Key('consent_reason')), 'Not that day');
    await t.tap(find.widgetWithText(TextButton, 'Decline'));
    await settle(t);
    expect(client.postedTo('/respond'), [
      {'decision': 'declined', 'notes': 'Not that day'}
    ]);
    expect(find.byKey(const Key('detail_sheet')), findsNothing);
    expect(find.text('Response recorded — consent declined.'), findsOneWidget);
    await _done(t);
  });

  testWidgets('decline without a reason sends no notes', (t) async {
    final client = await _open(t, consentApi(onRespond: (_) => savedResponse('declined')));
    await _openRow(t, 'Museum trip');
    await t.tap(_decline);
    await settle(t);
    await t.tap(find.widgetWithText(TextButton, 'Decline'));
    await settle(t);
    expect(client.postedTo('/respond'), [
      {'decision': 'declined'}
    ]);
    await _done(t);
  });

  testWidgets('API failure keeps the sheet open, shows the error and allows a retry', (t) async {
    var fail = true;
    final client = await _open(t, consentApi(onRespond: (url) => fail ? throw respondFails(url) : savedResponse('granted')));
    await _openRow(t, 'Museum trip');
    await t.tap(_grant);
    await settle(t);
    await t.tap(find.widgetWithText(TextButton, 'Grant consent'));
    await settle(t);
    expect(find.byKey(const Key('detail_sheet')), findsOneWidget);
    expect(find.byKey(const Key('consent_error')), findsOneWidget);
    expect(_grant, findsOneWidget);
    expect(client.postedTo('/respond'), hasLength(1));
    // retry succeeds
    fail = false;
    await t.tap(_grant);
    await settle(t);
    await t.tap(find.widgetWithText(TextButton, 'Grant consent'));
    await settle(t);
    expect(client.postedTo('/respond'), hasLength(2));
    expect(find.byKey(const Key('detail_sheet')), findsNothing);
    await _done(t);
  });

  testWidgets('while a request is in flight both buttons are disabled: no double submit', (t) async {
    final hold = Completer<dynamic>();
    final client = await _open(t, consentApi(onRespond: (_) => hold.future));
    await _openRow(t, 'Museum trip');
    await t.tap(_grant);
    await settle(t);
    await t.tap(find.widgetWithText(TextButton, 'Grant consent'));
    await t.pump(const Duration(milliseconds: 300));
    expect(client.postedTo('/respond'), hasLength(1));
    expect(t.widget<ElevatedButton>(find.descendant(of: _grant, matching: find.byType(ElevatedButton))).onPressed, isNull);
    expect(t.widget<OutlinedButton>(find.descendant(of: _decline, matching: find.byType(OutlinedButton))).onPressed, isNull);
    await t.tap(_grant, warnIfMissed: false);
    await t.tap(_decline, warnIfMissed: false);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Decline consent?'), findsNothing);
    expect(client.postedTo('/respond'), hasLength(1));
    hold.complete(savedResponse('granted'));
    await settle(t);
    expect(find.byKey(const Key('detail_sheet')), findsNothing);
    await _done(t);
  });

  for (final scale in [1.2, 1.5, 2.0]) {
    testWidgets('text scale $scale: no overflow, the actions stack and stay reachable', (t) async {
      await _open(t, consentApi(), textScale: scale);
      await _openRow(t, 'Museum trip');
      expect(_grant, findsOneWidget);
      expect(_decline, findsOneWidget);
      expect(t.getTopLeft(_grant).dy, greaterThan(t.getTopLeft(_decline).dy));
      await _done(t); // any layout exception thrown above fails the test: nothing is consumed
    });
  }
}
