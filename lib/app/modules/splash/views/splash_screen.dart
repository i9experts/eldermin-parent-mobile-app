import 'dart:async';
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design/design.dart';

/// The root screen shown while [AuthController] resolves its bootstrap
/// (token check + cached profile read). Purely presentational - the swap away
/// from this screen is driven entirely by `_AuthGate` in main.dart reacting to
/// `AuthController.status`.
///
/// Frame 0 is the native splash: the app navy and the reversed logomark at
/// [EmLogomark.splashHeight] in the exact centre, nothing moving. Then, in the
/// first beat, the first photo crossfades in behind the logo under the navy
/// overlay, a white rounded tile grows around the logo (which turns navy /
/// orange), light travels along the logo's links, and two thin accent rings
/// ripple out of the tile (they keep going while the session is checked).
///
/// Reduce motion: the photo and the tile crossfade in ([EmMotion.crossfade]);
/// no rings, no link motion.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  static const String title = 'Eldermin Parent';
  static const String tagline = 'Stay connected, stay informed.';

  /// Side of the white logo tile (the logo inside is [EmLogomark.splashHeight]).
  static const double tileSize = EmLogomark.splashHeight / EmLogoTile.logoShare;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // windows (ms) of the intro, the same as the teacher app's splash
  static const _intro = Duration(milliseconds: 1500);
  static const _charge = (begin: 40, end: 790);
  static const _pulse = (begin: 680, end: 1300);
  static const _text = (begin: 120, end: 520);
  static const _photoWait = Duration(milliseconds: 400);

  late final AnimationController _introC = AnimationController(vsync: this, duration: _intro);
  late final AnimationController _time = AnimationController(vsync: this, duration: EmMotion.ambientPeriod);
  late final AnimationController _reveal = AnimationController(vsync: this, duration: EmMotion.photoReveal);
  late final AnimationController _rings = AnimationController(vsync: this, duration: EmMotion.ringPeriod);

  late final Animation<double> _chargeA, _pulseA, _dash, _titleFade, _taglineFade;
  late final Animation<Offset> _titleSlide;
  late final CurvedAnimation _photo, _tile;

  bool _reduced = false;
  bool _configured = false;
  bool _revealStarted = false;

  double _at(int ms) => ms / _intro.inMilliseconds;

  @override
  void initState() {
    super.initState();
    Animation<double> window(({int begin, int end}) w) => CurvedAnimation(parent: _introC, curve: Interval(_at(w.begin), _at(w.end)));
    _chargeA = window(_charge);
    _pulseA = window(_pulse);
    // 60 whole dash periods per ambient loop: the dash drift never seams
    _dash = Tween<double>(begin: 0, end: EmMotion.ambientPeriod.inMilliseconds / EmMotion.dashPeriod.inMilliseconds).animate(_time);
    _photo = CurvedAnimation(parent: _reveal, curve: Curves.easeOut);
    _tile = CurvedAnimation(parent: _reveal, curve: const Interval(0.2, 1, curve: Curves.easeOutCubic));
    final t0 = _at(_text.begin), t1 = _at(_text.end);
    _titleFade = CurvedAnimation(parent: _introC, curve: Interval(t0, t0 + (t1 - t0) * 0.7, curve: Curves.easeOut));
    _titleSlide = Tween(begin: const Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _introC, curve: Interval(t0, t1, curve: EmMotion.enter)));
    _taglineFade = CurvedAnimation(parent: _introC, curve: Interval(t0 + (t1 - t0) * 0.3, t1, curve: Curves.easeOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = EmReduceMotion.of(context);
    if (!_revealStarted) {
      _revealStarted = true;
      _reveal.duration = reduced ? EmMotion.crossfade : EmMotion.photoReveal;
      _beginReveal();
    }
    if (!_configured || reduced != _reduced) {
      _configured = true;
      _reduced = reduced;
      if (reduced) {
        _introC.stop();
        _time.stop();
        _rings.stop();
      } else {
        if (!_introC.isCompleted && !_introC.isAnimating) _introC.forward();
        if (!_time.isAnimating) _time.repeat();
        if (!_rings.isAnimating) _rings.repeat();
      }
    }
  }

  /// Preloads the photos (the splash one first), then crossfades the first in. Never waits
  /// longer than [_photoWait]: the reveal starts anyway (the photo area stays navy).
  Future<void> _beginReveal() async {
    unawaited(EmAuthPhotos.precache(context));
    await EmAuthPhotos.precache(context, assets: const [EmAuthPhotos.photo1]).timeout(_photoWait, onTimeout: () {});
    if (mounted && !_reveal.isAnimating && !_reveal.isCompleted) _reveal.forward();
  }

  @override
  void dispose() {
    _photo.dispose();
    _tile.dispose();
    _introC.dispose();
    _time.dispose();
    _reveal.dispose();
    _rings.dispose();
    super.dispose();
  }

  EmNetworkDrive get _drive => _reduced
      ? EmNetworkDrive(to: EmNetworkPalette.standard, morph: _tile)
      : EmNetworkDrive(to: EmNetworkPalette.standard, morph: _tile, charge: _chargeA, dashPhase: _dash, pulse: _pulseA);

  @override
  Widget build(BuildContext context) {
    const tileSize = SplashScreen.tileSize;
    final mark = SizedBox.square(
      dimension: tileSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (!_reduced)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: EmRippleRings(phase: _rings, strength: _tile, radiusFactor: EmRadius.logoTileRatio)),
              ),
            ),
          // the white tile grows in around the logo, with a small swell on the pulse
          FadeTransition(
            opacity: _tile,
            child: AnimatedBuilder(
              animation: Listenable.merge([_tile, _pulseA]),
              builder: (context, child) {
                final swell = _reduced ? 1.0 : 1 + 0.03 * (_pulseA.value <= 0 || _pulseA.value >= 1 ? 0 : 1 - (2 * _pulseA.value - 1).abs());
                return Transform.scale(scale: lerpDouble(0.92, 1, _tile.value)! * swell, child: child);
              },
              child: const EmLogoTile(size: tileSize, child: SizedBox.shrink()),
            ),
          ),
          EmLogomark(height: EmLogomark.splashHeight, reversed: true, semanticLabel: SplashScreen.title, drive: _drive),
        ],
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Material(
        type: MaterialType.transparency,
        child: LayoutBuilder(
          builder: (context, box) {
            final screen = box.biggest;
            final textTop = screen.height / 2 + tileSize / 2 + EmSpacing.s24;
            // the text sits at or below the overlay's strong line, whatever the text size
            final safeTop = EmPhotoOverlay.safeTopFor(textTop / screen.height, margin: 0.02);
            return Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: EmColors.primaryDark),
                FadeTransition(
                  opacity: _photo,
                  child: EmPhotoBackdrop(image: EmAuthPhotos.provider(EmAuthPhotos.photo1), safeTop: safeTop),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: textTop,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: EmSpacing.s32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FadeTransition(
                          opacity: _reduced ? const AlwaysStoppedAnimation(1) : _titleFade,
                          child: SlideTransition(
                            position: _reduced ? const AlwaysStoppedAnimation(Offset.zero) : _titleSlide,
                            child: Text(SplashScreen.title,
                                key: const Key('splash_title'),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: EmType.splashTitle.copyWith(color: EmColors.onPrimaryDark)),
                          ),
                        ),
                        const SizedBox(height: EmSpacing.s8),
                        FadeTransition(
                          opacity: _reduced ? const AlwaysStoppedAnimation(1) : _taglineFade,
                          child: Text(SplashScreen.tagline,
                              key: const Key('splash_tagline'),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: EmType.splashTagline.copyWith(color: EmColors.accent)),
                        ),
                      ],
                    ),
                  ),
                ),
                // exact centre, identical to the native splash image at frame 0
                Center(child: mark),
                // the animated mark has its own label; this keeps the loading cue for screen readers
                Positioned(bottom: 0, left: 0, child: Semantics(label: 'Loading', liveRegion: true, child: const SizedBox(width: 1, height: 1))),
              ],
            );
          },
        ),
      ),
    );
  }
}
