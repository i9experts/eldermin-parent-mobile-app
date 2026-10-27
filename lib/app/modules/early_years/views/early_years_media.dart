import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/models/early_years_models.dart';
import '../../../../core/design/design.dart';
import '../controllers/early_years_controller.dart';

/// One piece of media. Photos load with [Image.network] on purpose: Flutter's
/// in-memory image cache only, so a signed link (valid ~15 min) is never
/// written to disk. A failed load most likely means the link expired, so it
/// asks the controller for fresh links and shows "Photo unavailable" until
/// they arrive. A null url (server storage unavailable) shows the same.
class EyMediaView extends StatelessWidget {
  final EyMedia media;
  final double? height;
  final double? width;
  final BoxFit fit;
  final VoidCallback? onTap;
  const EyMediaView({super.key, required this.media, this.height, this.width, this.fit = BoxFit.cover, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = media.isPhoto ? _photo() : _attachment();
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(borderRadius: EmRadius.mdAll, child: SizedBox(height: height, width: width, child: child)),
    );
  }

  Widget _photo() {
    final url = media.url;
    if (url == null) return const EyUnavailable(label: 'Photo unavailable');
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (c, w, p) => p == null ? w : const EmShimmer(child: EmSkeletonBox(width: double.infinity, height: double.infinity, radius: 0)),
      errorBuilder: (c, e, s) {
        // Expired or unreachable link: ask for fresh ones (rate limited in the controller).
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.isRegistered<EarlyYearsController>()) Get.find<EarlyYearsController>().onMediaFailed();
        });
        return const EyUnavailable(label: 'Photo unavailable');
      },
    );
  }

  Widget _attachment() {
    final label = switch (media.type) {
      'video' => 'Video',
      'voice_note' => 'Voice note',
      'work_sample' => 'Work sample',
      'document' => 'Document',
      _ => 'Attachment',
    };
    return EyUnavailable(label: '$label (not viewable in the app yet)', icon: Icons.attach_file_rounded);
  }
}

class EyUnavailable extends StatelessWidget {
  final String label;
  final IconData icon;
  const EyUnavailable({super.key, required this.label, this.icon = Icons.image_not_supported_outlined});

  @override
  Widget build(BuildContext context) => Container(
        color: EmColors.primaryTint,
        alignment: Alignment.center,
        padding: const EdgeInsetsDirectional.all(EmSpacing.s8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ExcludeSemantics(child: Icon(icon, color: EmColors.textSecondary, size: 28)),
          const SizedBox(height: EmSpacing.s4),
          Text(label, textAlign: TextAlign.center, style: EmType.caption.copyWith(color: EmColors.textSecondary)),
        ]),
      );
}

/// Photos of an entry: a horizontal strip, tap to open full screen.
class EyMediaStrip extends StatelessWidget {
  final List<EyMedia> media;
  const EyMediaStrip({super.key, required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: media.length,
        separatorBuilder: (_, __) => const SizedBox(width: EmSpacing.s8),
        itemBuilder: (context, i) => EyMediaView(
          media: media[i],
          width: 160,
          height: 160,
          onTap: media[i].isPhoto && media[i].url != null
              ? () => Get.to(() => EyPhotoViewer(photos: media.where((m) => m.isPhoto && m.url != null).toList(), initial: media[i]))
              : null,
        ),
      ),
    );
  }
}

class EyPhotoViewer extends StatefulWidget {
  final List<EyMedia> photos;
  final EyMedia initial;
  const EyPhotoViewer({super.key, required this.photos, required this.initial});

  @override
  State<EyPhotoViewer> createState() => _EyPhotoViewerState();
}

class _EyPhotoViewerState extends State<EyPhotoViewer> {
  late final PageController _page = PageController(initialPage: widget.photos.indexOf(widget.initial).clamp(0, widget.photos.length - 1));

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  // a photo is viewed on a dark ground (the kit's scrim colour), with light controls
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: EmColors.scrim,
        appBar: AppBar(backgroundColor: EmColors.scrim, foregroundColor: EmColors.onPrimary, iconTheme: const IconThemeData(color: EmColors.onPrimary)),
        body: PageView.builder(
          controller: _page,
          itemCount: widget.photos.length,
          itemBuilder: (c, i) => Column(children: [
            Expanded(child: InteractiveViewer(child: EyMediaView(media: widget.photos[i], fit: BoxFit.contain))),
            if (widget.photos[i].caption != null)
              Padding(padding: const EdgeInsetsDirectional.all(EmSpacing.s16), child: Text(widget.photos[i].caption!, style: EmType.body.copyWith(color: EmColors.onPrimary, fontWeight: FontWeight.w400))),
          ]),
        ),
      );
}
