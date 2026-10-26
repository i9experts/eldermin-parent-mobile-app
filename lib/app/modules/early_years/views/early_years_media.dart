import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/models/early_years_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../components/custom_text.dart';
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
      child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(height: height, width: width, child: child)),
    );
  }

  Widget _photo() {
    final url = media.url;
    if (url == null) return const EyUnavailable(label: 'Photo unavailable');
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (c, w, p) => p == null ? w : const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
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
        color: AppColors.background,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: AppColors.faint, size: 26),
          const SizedBox(height: 4),
          CustomText(text: label, color: AppColors.faint, fontSize: 10, textAlign: TextAlign.center),
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
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: media.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => EyMediaView(
          media: media[i],
          width: 150,
          height: 150,
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

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: PageView.builder(
          controller: _page,
          itemCount: widget.photos.length,
          itemBuilder: (c, i) => Column(children: [
            Expanded(child: InteractiveViewer(child: EyMediaView(media: widget.photos[i], fit: BoxFit.contain))),
            if (widget.photos[i].caption != null)
              Padding(padding: const EdgeInsets.all(12), child: CustomText(text: widget.photos[i].caption!, color: Colors.white, fontSize: 13)),
          ]),
        ),
      );
}
