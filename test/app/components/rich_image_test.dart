import 'dart:convert';
import 'package:eldermin_parent_app/app/components/rich_image.dart';
import 'package:eldermin_parent_app/app/components/rich_text_view.dart';
import 'package:eldermin_parent_app/core/constants/media_hosts.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../../support/fake_images.dart';

final _url = 'https://${kConsentImageHosts.first}/school/consent-attachments/a.png';

Widget _host(Widget child) => GetMaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

final _unavailable = find.byKey(const Key('image_unavailable'));
final _viewer = find.byKey(const Key('image_viewer'));

void main() {
  group('styled text', () {
    testWidgets('bold, italic and underline reach the rendered spans', (t) async {
      await t.pumpWidget(_host(const RichTextView('<div>a <b>bold</b> <i>ital</i> <u>under</u> <b><i>both</i></b></div>')));
      TextSpan? spanOf(String text) {
        TextSpan? hit;
        for (final w in t.widgetList<RichText>(find.byType(RichText))) {
          w.text.visitChildren((s) {
            if (s is TextSpan && s.text == text) hit = s;
            return true;
          });
        }
        return hit;
      }

      expect(spanOf('bold')!.style!.fontWeight, FontWeight.w700);
      expect(spanOf('ital')!.style!.fontStyle, FontStyle.italic);
      expect(spanOf('under')!.style!.decoration, TextDecoration.underline);
      expect(spanOf('both')!.style!.fontWeight, FontWeight.w700);
      expect(spanOf('both')!.style!.fontStyle, FontStyle.italic);
      expect(spanOf('a ')!.style!.fontWeight, isNull);
    });

    testWidgets('nested list items are indented', (t) async {
      await t.pumpWidget(_host(const RichTextView('<ul><li>Top<ul><li>Inner</li></ul></li></ul>')));
      final top = t.getTopLeft(find.textContaining('Top', findRichText: true)).dx;
      final inner = t.getTopLeft(find.textContaining('Inner', findRichText: true)).dx;
      expect(inner - top, EmSpacing.s16);
    });
  });

  group('images', () {
    testWidgets('loading shows the shimmer', (t) async {
      useFakeImages((_) => PendingImage());
      await t.pumpWidget(_host(RichTextView('<div><img src="$_url"></div>')));
      expect(find.byType(RichImageView), findsOneWidget);
      expect(find.byType(EmShimmer), findsOneWidget);
      expect(_unavailable, findsNothing);
      await t.pumpWidget(const SizedBox()); // dispose the pending timer
    });

    testWidgets('a loaded image shows no shimmer and no placeholder', (t) async {
      final p = await loadedImage(t);
      useFakeImages((_) => p);
      await t.pumpWidget(_host(RichTextView('<div><img src="$_url" alt="Map"></div>')));
      await t.pump();
      expect(find.byType(Image), findsOneWidget);
      expect(find.byType(EmShimmer), findsNothing);
      expect(_unavailable, findsNothing);
    });

    testWidgets('an error (403 / 404 / undecodable) shows "Image unavailable"', (t) async {
      useFakeImages((_) => FailingImage());
      await t.pumpWidget(_host(RichTextView('<div><img src="$_url"></div>')));
      await t.pump();
      await t.pump();
      expect(_unavailable, findsOneWidget);
      expect(find.text('Image unavailable'), findsOneWidget);
      expect(find.byType(EmShimmer), findsNothing);
    });

    testWidgets('a load that never finishes times out into the placeholder', (t) async {
      useFakeImages((_) => PendingImage());
      RichImageView.loadTimeout = const Duration(seconds: 2);
      await t.pumpWidget(_host(RichTextView('<div><img src="$_url"></div>')));
      expect(find.byType(EmShimmer), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
      expect(_unavailable, findsOneWidget);
    });

    testWidgets('with no fake, the default provider hits the test binding (no real network) and ends in the placeholder', (t) async {
      await t.pumpWidget(_host(RichTextView('<div><img src="$_url"></div>')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump();
      expect(_unavailable, findsOneWidget);
    });

    testWidgets('another host is link text and is never loaded', (t) async {
      var asked = 0;
      useFakeImages((_) {
        asked++;
        return PendingImage();
      });
      await t.pumpWidget(_host(const RichTextView('<div><img src="https://evil.example/a.png"></div>')));
      expect(asked, 0);
      expect(find.byType(RichImageView), findsNothing);
      expect(find.textContaining('Image', findRichText: true), findsOneWidget);
    });

    testWidgets('a data: image renders from bytes', (t) async {
      useFakeImages((_) => FailingImage());
      await t.pumpWidget(_host(RichTextView('<div><img src="data:image/png;base64,${base64Encode(kPngBytes)}"></div>')));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await t.pump();
      expect(find.byType(RichImageView), findsOneWidget);
      expect(_unavailable, findsNothing);
    });

    testWidgets('tap opens the full-screen viewer and the close button closes it', (t) async {
      final p = await loadedImage(t);
      useFakeImages((_) => p);
      await t.pumpWidget(_host(RichTextView('<div><img src="$_url" alt="Map"></div>')));
      await t.pump();
      expect(_viewer, findsNothing);
      await t.tap(find.byType(RichImageView));
      await t.pumpAndSettle();
      expect(_viewer, findsOneWidget);
      expect(find.byType(InteractiveViewer), findsOneWidget);
      await t.tap(find.byKey(const Key('image_viewer_close')));
      await t.pumpAndSettle();
      expect(_viewer, findsNothing);
    });

    testWidgets('the viewer shows the placeholder when the image fails', (t) async {
      useFakeImages((_) => FailingImage());
      await t.pumpWidget(_host(RichImageView(url: _url)));
      await t.tap(find.byType(RichImageView));
      await t.pumpAndSettle();
      expect(_viewer, findsOneWidget);
      expect(find.descendant(of: _viewer, matching: _unavailable), findsOneWidget);
    });
  });
}
