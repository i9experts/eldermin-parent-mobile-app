import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:eldermin_parent_app/app/components/rich_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A real 1x1 PNG.
final Uint8List kPngBytes = base64.decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

/// Never finishes loading (the shimmer state).
class PendingImage extends ImageProvider<PendingImage> {
  @override
  Future<PendingImage> obtainKey(ImageConfiguration c) => SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(PendingImage key, ImageDecoderCallback decode) => MultiFrameImageStreamCompleter(codec: Completer<ui.Codec>().future, scale: 1);
}

/// Fails like a 403 / 404 / undecodable file.
class FailingImage extends ImageProvider<FailingImage> {
  @override
  Future<FailingImage> obtainKey(ImageConfiguration c) => SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(FailingImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: Future<ui.Codec>.error(Exception('HTTP 403')), scale: 1);
}

/// Routes every URL to a fake provider and restores the real one afterwards. Make NO real network calls in tests.
void useFakeImages(ImageProvider Function(String url) provider) {
  final saved = RichImageView.providerFor;
  final savedTimeout = RichImageView.loadTimeout;
  RichImageView.providerFor = provider;
  addTearDown(() {
    RichImageView.providerFor = saved;
    RichImageView.loadTimeout = savedTimeout;
  });
}

/// A loaded image, decoded ahead of time so the first frame is synchronous.
Future<ImageProvider> loadedImage(WidgetTester t) async {
  final p = MemoryImage(kPngBytes);
  await t.runAsync(() async {
    final c = Completer<void>();
    p.resolve(ImageConfiguration.empty).addListener(ImageStreamListener((_, __) => c.complete(), onError: (e, s) => c.complete()));
    await c.future;
  });
  return p;
}
