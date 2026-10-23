import 'dart:async';
import 'dart:io';
import 'package:eldermin_parent_app/app/modules/splash/views/splash_screen.dart';
import 'package:eldermin_parent_app/core/design/design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import '../support/auth_harness.dart';

double photoOpacity(WidgetTester t) =>
    t.widget<FadeTransition>(find.ancestor(of: find.byType(EmPhotoBackdrop), matching: find.byType(FadeTransition)).first).opacity.value;
double tileOpacity(WidgetTester t) =>
    t.widget<FadeTransition>(find.ancestor(of: find.byType(EmLogoTile), matching: find.byType(FadeTransition)).first).opacity.value;

Future<void> pumpSplash(WidgetTester t, {bool reduce = false}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(
    builder: (context, c) => MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: reduce), child: c!),
    home: const SplashScreen(),
  ));
}

void main() {
  setUpAll(loadAuthFonts);
  final originalPrecache = EmAuthPhotos.precacheImpl;
  tearDown(() {
    EmAuthPhotos.precacheImpl = originalPrecache;
    Get.reset();
  });

  group('assets', () {
    test('the three photos exist, are registered in pubspec.yaml, and are WebP under 600 KB', () {
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/images/auth/'));
      for (final a in EmAuthPhotos.slides) {
        final f = File(a);
        expect(f.existsSync(), isTrue, reason: a);
        expect(f.lengthSync(), lessThan(600 * 1024), reason: a);
        final head = f.readAsBytesSync().sublist(0, 12);
        expect(String.fromCharCodes(head.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(head.sublist(8, 12)), 'WEBP');
      }
      expect(EmAuthPhotos.slides, ['assets/images/auth/parent_1.webp', 'assets/images/auth/parent_2.webp', 'assets/images/auth/parent_3.webp']);
    });

    testWidgets('they are in the asset bundle', (t) async {
      for (final a in EmAuthPhotos.slides) {
        final data = await t.runAsync(() => rootBundle.load(a));
        expect(data!.lengthInBytes, greaterThan(50 * 1024), reason: a);
      }
    });

    test('native splash config: the app navy + the reversed logo, iOS', () {
      final y = File('pubspec.yaml').readAsStringSync();
      expect(y, contains('color: "#0A3158"'));
      expect(y, contains('image: "assets/splash/splash_logo.png"'));
      expect(File('assets/splash/splash_logo.png').existsSync(), isTrue);
      expect(EmColors.primaryDark.toARGB32() & 0xFFFFFF, 0x0A3158, reason: 'the native navy is the token');
    });
  });

  group('font scope', () {
    test('Plus Jakarta Sans is bundled with its OFL licence, and used only by the photo auth screens', () {
      final y = File('pubspec.yaml').readAsStringSync();
      expect(y, contains('family: PlusJakartaSans'));
      expect(y, contains('assets/fonts/OFL.txt'));
      expect(File('assets/fonts/OFL.txt').readAsStringSync(), contains('SIL OPEN FONT LICENSE'));
      final offenders = <String>[];
      for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final p = f.path;
        final allowed = p.startsWith('lib/core/design/') || p.startsWith('lib/app/modules/auth/') || p.startsWith('lib/app/modules/splash/') || p == 'lib/main.dart';
        if (!allowed && (f.readAsStringSync().contains('PlusJakartaSans') || f.readAsStringSync().contains('EmType'))) offenders.add(p);
      }
      expect(offenders, isEmpty, reason: 'the font is for the auth screens only: $offenders');
    });

    test('the global theme is unchanged: still Inter via google_fonts, no Plus Jakarta', () {
      final theme = File('lib/core/theme/app_theme.dart').readAsStringSync();
      expect(theme, isNot(contains('PlusJakarta')));
      expect(theme, contains('GoogleFonts.inter'));
    });
  });

  group('precache during init', () {
    testWidgets('the splash precaches all three photos, the splash one first', (t) async {
      final seen = <String>[];
      EmAuthPhotos.precacheImpl = (context, p) async => seen.add((p as AssetImage).assetName);
      await pumpSplash(t);
      await t.pump(const Duration(milliseconds: 50));
      expect(seen.toSet(), EmAuthPhotos.slides.toSet());
      expect(seen.first, EmAuthPhotos.photo1);
    });

    testWidgets('frame 0 stays the native splash until the photo is decoded, then it fades in behind the logo', (t) async {
      final gate = Completer<void>();
      EmAuthPhotos.precacheImpl = (context, p) => (p as AssetImage).assetName == EmAuthPhotos.photo1 ? gate.future : Future<void>.value();
      await pumpSplash(t);
      await t.pump(const Duration(milliseconds: 200));
      expect(photoOpacity(t), 0);
      expect(tileOpacity(t), 0);
      gate.complete();
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(photoOpacity(t), inExclusiveRange(0.2, 1));
      await t.pump(EmMotion.photoReveal);
      expect(photoOpacity(t), 1);
      expect(tileOpacity(t), 1);
    });

    testWidgets('a photo that never decodes does not hold the splash (reveals after 400 ms)', (t) async {
      EmAuthPhotos.precacheImpl = (context, p) => Completer<void>().future;
      await pumpSplash(t);
      await t.pump(const Duration(milliseconds: 300));
      expect(photoOpacity(t), 0);
      await t.pump(const Duration(milliseconds: 200));
      await t.pump(EmMotion.photoReveal);
      expect(tileOpacity(t), 1);
    });

    testWidgets('a missing photo degrades to navy, no exception', (t) async {
      await t.pumpWidget(const MaterialApp(home: SizedBox(width: 200, height: 400, child: EmPhotoBackdrop(image: AssetImage('assets/images/auth/missing.webp')))));
      await t.pump(const Duration(milliseconds: 100));
      expect(t.takeException(), isNull);
    });
  });

  group('EmPhotoBackdrop', () {
    testWidgets('cover fit, configurable alignment, navy overlay from the tokens, light status-bar icons', (t) async {
      await t.pumpWidget(const MaterialApp(
        home: SizedBox(width: 200, height: 400, child: EmPhotoBackdrop(image: AssetImage(EmAuthPhotos.photo1), alignment: Alignment.bottomCenter, safeTop: 0.5)),
      ));
      final image = t.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.cover);
      expect(image.alignment, Alignment.bottomCenter);
      final g = (t.widget<DecoratedBox>(find.byKey(const Key('photo_overlay'))).decoration as BoxDecoration).gradient! as LinearGradient;
      expect(g.stops, [for (final s in EmPhotoOverlay.stops(0.5)) s.at]);
      expect(g.colors.first.a, 0);
      expect(g.colors.first.toARGB32() & 0xFFFFFF, EmColors.primaryDark.toARGB32() & 0xFFFFFF, reason: 'transparent navy, not black');
      expect(g.colors.last.a, closeTo(EmPhotoOverlay.bottomAlpha, 0.01));
      expect(t.widget<AnnotatedRegion<SystemUiOverlayStyle>>(find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first).value, SystemUiOverlayStyle.light);
    });
  });

  group('reduce motion', () {
    testWidgets('splash: photo and tile crossfade (200 ms), no rings, no logo travel; then nothing moves', (t) async {
      await pumpSplash(t, reduce: true);
      await t.pump(const Duration(milliseconds: 20));
      await t.pump(const Duration(milliseconds: 100));
      expect(photoOpacity(t), inExclusiveRange(0, 1));
      await t.pump(const Duration(milliseconds: 200));
      expect(photoOpacity(t), 1);
      expect(tileOpacity(t), 1);
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is EmRippleRings), findsNothing);
      final rect = t.getRect(find.byType(EmLogomark));
      await t.pump(const Duration(seconds: 2));
      expect(t.getRect(find.byType(EmLogomark)), rect);
      expect(t.hasRunningAnimations, isFalse);
    });

    testWidgets('normal motion: the rings loop while the session is checked', (t) async {
      await pumpSplash(t);
      await t.pump(const Duration(seconds: 3));
      expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is EmRippleRings), findsOneWidget);
      expect(t.hasRunningAnimations, isTrue);
    });
  });

  group('splash content', () {
    testWidgets('"Eldermin Parent" and the existing tagline, accent only on navy; frame 0 is the native splash picture', (t) async {
      await pumpSplash(t);
      expect(photoOpacity(t), 0, reason: 'frame 0: navy + the reversed logo only');
      final logo = find.byType(EmLogomark);
      expect(t.widget<EmLogomark>(logo).reversed, isTrue);
      expect(t.getSize(logo).height, EmLogomark.splashHeight);
      expect(t.getCenter(logo), const Offset(195, 422));
      await t.pump(const Duration(milliseconds: 1500));
      expect(t.widget<Text>(find.byKey(const Key('splash_title'))).data, 'Eldermin Parent');
      expect(t.widget<Text>(find.byKey(const Key('splash_tagline'))).data, 'Stay connected, stay informed.');
      expect(t.widget<Text>(find.byKey(const Key('splash_tagline'))).style!.color, EmColors.accent);
    });
  });

  group('ripple rings', () {
    test('two thin accent rings, half a cycle apart, each growing and fading out', () {
      expect(EmRippleRings.count, 2);
      expect(EmRippleRings.strokeWidth, lessThanOrEqualTo(2));
      expect(EmRippleRings.ring(1, 0.25).growth, isNot(EmRippleRings.ring(0, 0.25).growth));
      expect(EmRippleRings.ring(0, 0).opacity, 1);
      expect(EmRippleRings.ring(0, 0.99).opacity, lessThan(0.05));
    });
  });
}
