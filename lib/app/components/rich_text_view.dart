// Mirrored from eldermin-teacher-app lib/app/components/rich_text_view.dart (design-kit-v1, 2f2f5a6) — keep in sync.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../core/design/design.dart';
import '../../core/utils/safe_text.dart';
import 'external_link.dart';
import 'rich_image.dart';

/// Renders [raw] (markdown-lite / plain text / HTML, see [parseRichText]) as inert text: headings, bullets, numbers, paragraphs, bold / italic /
/// underline. Links are tappable but open only after the confirmation dialog of [ExternalLinks]. Images only from an allowed source (see
/// `allowedImageSource`), shown by [RichImageView]. No HTML, no scripts.
class RichTextView extends StatefulWidget {
  final String raw;
  const RichTextView(this.raw, {super.key});

  @override
  State<RichTextView> createState() => _RichTextViewState();
}

class _RichTextViewState extends State<RichTextView> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  TextSpan _span(List<InlineRun> runs, TextStyle base) {
    return TextSpan(style: base, children: [
      for (final r in runs)
        TextSpan(
          text: r.text,
          style: TextStyle(
            fontWeight: r.bold ? FontWeight.w700 : null,
            fontStyle: r.italic ? FontStyle.italic : null,
            color: r.link == null ? null : EmColors.primary,
            decoration: r.link != null || r.underline ? TextDecoration.underline : null,
          ),
          recognizer: r.link == null ? null : _link(r.link!),
        ),
    ]);
  }

  TapGestureRecognizer _link(String url) {
    final r = TapGestureRecognizer()..onTap = () => ExternalLinks.openWithConfirm(url);
    _recognizers.add(r);
    return r;
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final blocks = parseRichText(widget.raw);
    final base = EmType.bodyRegular.copyWith(color: EmColors.ink, height: 1.5);
    return Column(key: const Key('rich_text'), crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final b in blocks)
        Padding(
          padding: EdgeInsetsDirectional.only(
            bottom: EmSpacing.s8,
            top: b.kind == TextBlockKind.heading ? EmSpacing.s8 : 0,
            start: EmSpacing.s16 * b.indent,
          ),
          child: switch (b.kind) {
            TextBlockKind.image => RichImageView(url: b.imageUrl, bytes: b.imageBytes, alt: b.alt),
            TextBlockKind.heading => Text.rich(_span(b.runs, EmType.bodyLarge.copyWith(fontWeight: FontWeight.w800, color: EmColors.ink, height: 1.5))),
            TextBlockKind.paragraph => Text.rich(_span(b.runs, base)),
            TextBlockKind.bullet => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('•  ', style: base), Expanded(child: Text.rich(_span(b.runs, base)))]),
            TextBlockKind.numbered => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: EmSpacing.s32, child: Text('${b.number}.', style: base.copyWith(fontWeight: FontWeight.w700))), Expanded(child: Text.rich(_span(b.runs, base)))]),
          },
        ),
    ]);
  }
}
