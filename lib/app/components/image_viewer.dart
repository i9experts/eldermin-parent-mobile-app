import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/design/design.dart';
import 'rich_image.dart';

/// Full-screen image with pinch zoom and pan, on the kit's dark scrim. Takes a URL or bytes (the caller has already checked the
/// source against the allowlist). Independent of any feature module; the same chrome as the Early Years photo viewer.
class ImageViewer extends StatelessWidget {
  const ImageViewer({super.key, this.url, this.bytes, this.alt = ''}) : assert((url == null) != (bytes == null), 'give either a url or bytes');
  final String? url;
  final Uint8List? bytes;
  final String alt;

  static Future<void> open(BuildContext context, {String? url, Uint8List? bytes, String alt = ''}) =>
      Navigator.of(context).push(MaterialPageRoute<void>(fullscreenDialog: true, builder: (_) => ImageViewer(url: url, bytes: bytes, alt: alt)));

  @override
  Widget build(BuildContext context) {
    final Widget image = bytes != null
        ? Image.memory(bytes!, fit: BoxFit.contain, errorBuilder: (c, e, s) => const ImageUnavailable())
        : Image(image: RichImageView.providerFor(url!), fit: BoxFit.contain, errorBuilder: (c, e, s) => const ImageUnavailable());
    return Scaffold(
      key: const Key('image_viewer'),
      backgroundColor: EmColors.scrim,
      appBar: AppBar(
        backgroundColor: EmColors.scrim,
        foregroundColor: EmColors.onPrimary,
        iconTheme: const IconThemeData(color: EmColors.onPrimary),
        automaticallyImplyLeading: false,
        leading: IconButton(key: const Key('image_viewer_close'), tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
      ),
      body: SafeArea(
        child: Semantics(
          label: alt.isEmpty ? 'Image' : alt,
          image: true,
          child: Center(child: InteractiveViewer(minScale: 1, maxScale: 5, child: image)),
        ),
      ),
    );
  }
}
