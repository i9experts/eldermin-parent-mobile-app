import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/design/design.dart';
import 'image_viewer.dart';

/// An image from admin-authored rich text. Loads with [Image.network] (Flutter's in-memory image cache only, nothing is written to disk) or
/// [Image.memory] for a verified `data:` image; the caller has already checked the source against the allowlist (see `allowedImageSource`).
/// Shows [EmShimmer] while loading and [ImageUnavailable] on ANY failure: 403 / 404, a format the device can't decode (HEIC on Android) or a
/// load that takes longer than the API receive timeout. Tapping opens [ImageViewer].
class RichImageView extends StatefulWidget {
  const RichImageView({super.key, this.url, this.bytes, this.alt = '', this.thumbnailSize, this.openable = true});
  final String? url;
  final Uint8List? bytes;
  final String alt;

  /// A square, cropped thumbnail of this size instead of a full-width image.
  final double? thumbnailSize;
  final bool openable;

  /// Test seam: how a URL becomes an [ImageProvider]. Defaults to [NetworkImage], which is what [Image.network] uses.
  static ImageProvider Function(String url) providerFor = NetworkImage.new;

  /// Test seam for the load timeout.
  static Duration loadTimeout = const Duration(milliseconds: ApiConstants.receiveTimeout);

  @override
  State<RichImageView> createState() => _RichImageViewState();
}

class _RichImageViewState extends State<RichImageView> {
  Timer? _timer;
  bool _timedOut = false;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    if (widget.url != null) {
      _timer = Timer(RichImageView.loadTimeout, () {
        if (mounted && !_shown) setState(() => _timedOut = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _loading() => widget.thumbnailSize == null
      ? const EmShimmer(child: EmSkeletonBox(width: double.infinity, height: 160, radius: 0))
      : const EmShimmer(child: EmSkeletonBox(width: double.infinity, height: double.infinity, radius: 0));

  Widget _unavailable() => ImageUnavailable(compact: widget.thumbnailSize != null);

  Widget _image() {
    if (_timedOut) return _unavailable();
    final thumb = widget.thumbnailSize != null;
    final fit = thumb ? BoxFit.cover : BoxFit.fitWidth;
    final width = thumb ? widget.thumbnailSize : double.infinity;
    if (widget.bytes != null) {
      return Image.memory(widget.bytes!, fit: fit, width: width, height: thumb ? widget.thumbnailSize : null, errorBuilder: (c, e, s) => _unavailable());
    }
    return Image(
      image: RichImageView.providerFor(widget.url!),
      fit: fit,
      width: width,
      height: thumb ? widget.thumbnailSize : null,
      frameBuilder: (c, child, f, sync) {
        if (f == null && !sync) return _loading();
        _shown = true;
        return child;
      },
      errorBuilder: (c, e, s) => _unavailable(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.thumbnailSize;
    Widget child = ClipRRect(
      borderRadius: EmRadius.mdAll,
      child: size == null ? SizedBox(width: double.infinity, child: _image()) : SizedBox(width: size, height: size, child: _image()),
    );
    if (widget.openable && !_timedOut) {
      child = Semantics(
        button: true,
        image: true,
        label: widget.alt.isEmpty ? 'Image' : widget.alt,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ImageViewer.open(context, url: widget.url, bytes: widget.bytes, alt: widget.alt),
          child: child,
        ),
      );
    }
    return child;
  }
}

/// What an image slot shows when it can't be loaded.
class ImageUnavailable extends StatelessWidget {
  const ImageUnavailable({super.key, this.compact = false});

  /// A thumbnail-sized tile: icon only.
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('image_unavailable'),
        color: EmColors.primaryTint,
        alignment: Alignment.center,
        constraints: compact ? null : const BoxConstraints(minHeight: 96),
        padding: const EdgeInsetsDirectional.all(EmSpacing.s8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ExcludeSemantics(child: Icon(Icons.image_not_supported_outlined, color: EmColors.textSecondary, size: compact ? EmSpacing.s20 : 28)),
          if (!compact) ...[
            const SizedBox(height: EmSpacing.s4),
            Text('Image unavailable', textAlign: TextAlign.center, style: EmType.caption.copyWith(color: EmColors.textSecondary)),
          ],
        ]),
      );
}
