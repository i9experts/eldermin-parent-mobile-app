// Mirrored from eldermin-teacher-app lib/core/utils/safe_text.dart (design-kit-v1, 2f2f5a6) — keep in sync.
// Parent copy differs from the teacher original ON PURPOSE (see the "parent:" notes): links survive flattening, ordered lists are numbered,
// every line of HTML stays its own paragraph, an unclosed <script> drops its tail, mailto:/tel: links are allowed, and — new — bold / italic /
// underline are kept as styled runs, nested lists are indented, and <img> becomes an image block when its source is allowlisted (see
// [kConsentImageHosts]) or a small data:image. The teacher copy deliberately stays text-only.
//
// Safe rendering helpers for server-supplied rich text (consent descriptions are HTML from the web editor; other bodies may be markdown or
// plain text).
//
// RULE: nothing from the server is ever rendered as HTML / run as script. Images are fetched only from the allowlisted hosts (or decoded from a
// size-capped data:image of a raster type); every other image stays a link. HTML is reduced to plain text with paragraph breaks, bullets and
// `[text](url)` links; links are opened only after the user confirms (http, https, mailto, tel only).
import 'dart:convert';
import 'dart:typed_data';
import '../constants/media_hosts.dart';

final _scriptStyle = RegExp(r'<(script|style|iframe|object|embed|svg|template)\b[^>]*>[\s\S]*?</\1\s*>', caseSensitive: false);
// parent: an unclosed dangerous container drops everything after it too, so its body can never show as text.
// (<embed> is a void element with no body, so it is left to the generic tag strip.)
final _openNoClose = RegExp(r'<(script|style|iframe|object|svg|template)\b[\s\S]*$', caseSensitive: false);
final _comment = RegExp(r'<!--[\s\S]*?-->');
final _brTag = RegExp(r'<br\s*/?>', caseSensitive: false);
final _anchor = RegExp(r'<a\b([^>]*)>([\s\S]*?)</a\s*>', caseSensitive: false);
final _img = RegExp(r'<img\b[^>]*>', caseSensitive: false);
final _heading = RegExp(r'<(/?)h[1-6]\b[^>]*>', caseSensitive: false);
final _blockOpen = RegExp(r'<(p|div|tr|table|blockquote|section|article)\b[^>]*>', caseSensitive: false);
final _blockClose = RegExp(r'</(p|div|tr|table|blockquote|section|article)\s*>', caseSensitive: false);
final _cellClose = RegExp(r'</t[dh]\s*>', caseSensitive: false);
final _listTag = RegExp(r'<(/?)(ul|ol|li)\b[^>]*>', caseSensitive: false);
final _anyTag = RegExp(r'<[^>]*>');

/// True when [s] contains something that looks like an HTML tag.
bool looksLikeHtml(String s) => RegExp(r'<\/?[a-zA-Z][^>]*>').hasMatch(s);

String? _attr(String attrs, String name) {
  final m = RegExp('\\b$name\\s*=\\s*(?:"([^"]*)"|\'([^\']*)\')', caseSensitive: false).firstMatch(attrs);
  return m == null ? null : (m.group(1) ?? m.group(2));
}

// A URL safe to embed in a `[text](url)` token (no spaces or parentheses).
String _mdUrl(Uri u) => u.toString().replaceAll(' ', '%20').replaceAll('(', '%28').replaceAll(')', '%29');

/// HTML -> plain text. Scripts, styles, frames, comments and every other tag disappear (their text content stays except for the dangerous
/// containers above). `<br>`, block ends and `<li>` become line breaks / "• " / "1. "; headings become "# "; `<a href>` becomes `[text](url)` and
/// `<img src>` becomes `[alt](url)` (only for allowed schemes, otherwise the text or nothing). Entities are decoded. The result never contains
/// '<' from a tag.
String htmlToPlainText(String html) => _flatten(html, rich: false);

// Private-use markers the rich flattening leaves in the text for the block parser. They are stripped from every input first, so server text can
// never forge one.
const _bOn = '\uE000', _bOff = '\uE001', _iOn = '\uE002', _iOff = '\uE003', _uOn = '\uE004', _uOff = '\uE005';
const _imgStart = '\uE010', _imgSep = '\uE011', _imgEnd = '\uE012', _indent = '\uE020';
final _markers = RegExp('[\uE000-\uE0FF]');
final _styleTag = RegExp(r'<(/?)(b|strong|i|em|u)\b[^>]*>', caseSensitive: false);

String _flatten(String html, {required bool rich}) {
  var s = html;
  if (rich) s = s.replaceAll(_markers, '');
  s = s.replaceAll(_comment, '');
  s = s.replaceAll(_scriptStyle, '').replaceAll(_openNoClose, '');
  if (rich) {
    s = s.replaceAllMapped(_styleTag, (m) {
      final close = m.group(1) == '/';
      return switch (m.group(2)!.toLowerCase()) {
        'b' || 'strong' => close ? _bOff : _bOn,
        'i' || 'em' => close ? _iOff : _iOn,
        _ => close ? _uOff : _uOn,
      };
    });
  }
  s = s.replaceAllMapped(_anchor, (m) {
    final text = m.group(2)!.replaceAll(_anyTag, '').replaceAll(RegExp(r'[\[\]]'), '').trim();
    final u = safeExternalUri(decodeEntities(_attr(m.group(1)!, 'href') ?? ''));
    if (u == null) return text;
    return '[${text.isEmpty ? u.toString() : text}](${_mdUrl(u)})';
  });
  s = s.replaceAllMapped(_img, (m) {
    final alt = (_attr(m.group(0)!, 'alt') ?? '').replaceAll(RegExp(r'[\[\]]'), '').trim();
    if (rich) {
      // The block parser decides what the source may become (image, link or nothing).
      // Decoded once here and re-escaped, so the final entity pass restores the value exactly and no entity can inject a line break or a tag.
      String esc(String v) => v.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
      final src = decodeEntities(_attr(m.group(0)!, 'src') ?? '').replaceAll(RegExp(r'\s'), '');
      final altText = decodeEntities(alt).replaceAll(RegExp(r'\s+'), ' ').trim();
      return src.isEmpty ? alt : '\n$_imgStart${esc(src)}$_imgSep${esc(altText)}$_imgEnd\n';
    }
    final u = safeExternalUri(decodeEntities(_attr(m.group(0)!, 'src') ?? ''));
    if (u == null || u.scheme == 'mailto' || u.scheme == 'tel') return alt;
    return '\n[${alt.isEmpty ? 'Image' : alt}](${_mdUrl(u)})\n';
  });
  s = s.replaceAllMapped(_heading, (m) => m.group(1) == '/' ? '\n' : '\n# ');
  final lists = <_ListState>[];
  s = s.replaceAllMapped(_listTag, (m) {
    final closing = m.group(1) == '/';
    final tag = m.group(2)!.toLowerCase();
    if (tag == 'li') {
      if (closing) return '\n';
      final lead = rich && lists.length > 1 ? _indent * (lists.length - 1) : '';
      return '$lead${lists.isNotEmpty && lists.last.ordered ? '${++lists.last.n}. ' : '• '}';
    }
    if (closing) {
      if (lists.isNotEmpty) lists.removeLast();
    } else {
      lists.add(_ListState(tag == 'ol'));
    }
    return '\n';
  });
  s = s.replaceAll(_brTag, '\n').replaceAll(_blockOpen, '\n').replaceAll(_blockClose, '\n').replaceAll(_cellClose, '  ');
  s = s.replaceAll(_anyTag, '');
  // A leftover '<' that started a broken tag ("<img src=x onerror=...") is dropped with the rest of its line. Done BEFORE entities are decoded, so a
  // literal "&lt;b&gt;" in the text stays text. (Nothing is ever parsed as markup at render time either way.)
  s = s.replaceAll(RegExp(r'<[a-zA-Z/!][^\n]*$', multiLine: true), '');
  s = decodeEntities(s);
  s = s.replaceAll(RegExp(r'[ \t\u00A0]+'), ' ').replaceAll(RegExp(r' *\n *'), '\n').replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return s.trim();
}

/// One-line plain text for list previews: like [htmlToPlainText] but with no link/image markers. Images are dropped, links keep only their text,
/// and all whitespace (including line breaks) collapses to single spaces.
String htmlToPreviewText(String html) {
  var s = html.replaceAll(_comment, '').replaceAll(_scriptStyle, '').replaceAll(_openNoClose, '');
  s = s.replaceAll(_img, ' ');
  s = s.replaceAllMapped(_anchor, (m) => ' ${m.group(2)!.replaceAll(_anyTag, '')} ');
  return htmlToPlainText(s).replaceAll(RegExp(r'\s+'), ' ').trim();
}

class _ListState {
  _ListState(this.ordered);
  final bool ordered;
  int n = 0;
}

final _entity = RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z]+);');
const _named = {'amp': '&', 'lt': '<', 'gt': '>', 'quot': '"', 'apos': "'", 'nbsp': ' ', 'ndash': '-', 'mdash': '-', 'hellip': '...', 'rsquo': "'", 'lsquo': "'", 'rdquo': '"', 'ldquo': '"', 'bull': '•'};

String decodeEntities(String s) => s.replaceAllMapped(_entity, (m) {
      final e = m.group(1)!;
      if (e.startsWith('#x')) {
        final c = int.tryParse(e.substring(2), radix: 16);
        return c == null || c > 0x10FFFF ? m.group(0)! : String.fromCharCode(c);
      }
      if (e.startsWith('#')) {
        final c = int.tryParse(e.substring(1));
        return c == null || c > 0x10FFFF ? m.group(0)! : String.fromCharCode(c);
      }
      return _named[e] ?? m.group(0)!;
    });

/// Only absolute http(s) URLs with a host, `mailto:` and `tel:` with an address / number may ever be opened. parent: mailto / tel added.
Uri? safeExternalUri(String? raw) {
  if (raw == null) return null;
  final u = Uri.tryParse(raw.trim());
  if (u == null) return null;
  final scheme = u.scheme.toLowerCase();
  if (scheme == 'https' || scheme == 'http') return u.hasAuthority && u.host.isNotEmpty ? u : null;
  if (scheme == 'mailto' || scheme == 'tel') return u.path.isNotEmpty ? u : null;
  return null;
}

enum TextBlockKind { heading, paragraph, bullet, numbered, image }

class InlineRun {
  final String text;
  final String? link; // validated allowed-scheme URL or null
  final bool bold, italic, underline;
  const InlineRun(this.text, [this.link, this.bold = false, this.italic = false, this.underline = false]);
}

class TextBlock {
  final TextBlockKind kind;
  final List<InlineRun> runs;
  final int? number;

  /// Nesting level of a list item (0 = top level).
  final int indent;

  /// For [TextBlockKind.image]: exactly one of [imageUrl] (https on an allowlisted host) and [imageBytes] (a verified small raster data: image).
  final String? imageUrl;
  final Uint8List? imageBytes;
  final String alt;
  const TextBlock(this.kind, this.runs, {this.number, this.indent = 0, this.imageUrl, this.imageBytes, this.alt = ''});
  String get plain => kind == TextBlockKind.image ? alt : runs.map((r) => r.text).join();
}

/// Largest decoded `data:image` the renderer will show.
const kMaxDataImageBytes = 256 * 1024;

/// Where a rich-text image may come from: `https` on a host of [kConsentImageHosts] (never `.svg`), or `data:image/(png|jpeg|webp|gif);base64`
/// that decodes to at most [kMaxDataImageBytes] and starts with that format's magic bytes. Everything else (http, file, relative, other
/// schemes, svg, other hosts, malformed data) returns null and is never fetched or decoded. Exactly one of the two fields is set.
({String? url, Uint8List? bytes})? allowedImageSource(String? raw) {
  final src = raw?.trim() ?? '';
  if (src.isEmpty) return null;
  if (src.length > 5 && src.substring(0, 5).toLowerCase() == 'data:') {
    final m = RegExp(r'^data:image/(png|jpeg|webp|gif);base64,([A-Za-z0-9+/]+={0,2})$', caseSensitive: false).firstMatch(src);
    if (m == null || m.group(2)!.length > kMaxDataImageBytes * 4 ~/ 3 + 4) return null;
    final Uint8List bytes;
    try {
      bytes = base64.decode(m.group(2)!);
    } on FormatException {
      return null;
    }
    if (bytes.isEmpty || bytes.length > kMaxDataImageBytes || !_hasMagic(m.group(1)!.toLowerCase(), bytes)) return null;
    return (url: null, bytes: bytes);
  }
  return isAllowedImageUrl(src) ? (url: src, bytes: null) : null;
}

/// True for an absolute `https` URL on an allowlisted image host (default port, no credentials) that is not an `.svg`.
bool isAllowedImageUrl(String? raw) {
  final u = Uri.tryParse(raw?.trim() ?? '');
  if (u == null || u.scheme.toLowerCase() != 'https' || u.userInfo.isNotEmpty || (u.hasPort && u.port != 443)) return false;
  if (!kConsentImageHosts.contains(u.host.toLowerCase())) return false;
  return !u.path.toLowerCase().endsWith('.svg');
}

bool _hasMagic(String type, Uint8List b) {
  bool at(int i, List<int> sig) => b.length >= i + sig.length && [for (var k = 0; k < sig.length; k++) b[i + k] == sig[k]].every((x) => x);
  return switch (type) {
    'png' => at(0, [0x89, 0x50, 0x4E, 0x47]),
    'jpeg' => at(0, [0xFF, 0xD8, 0xFF]),
    'gif' => at(0, [0x47, 0x49, 0x46, 0x38]),
    _ => at(0, [0x52, 0x49, 0x46, 0x46]) && at(8, [0x57, 0x45, 0x42, 0x50]),
  };
}

final _mdLink = RegExp(r'\[([^\]]+)\]\(((?:[^()\s]|\([^()\s]*\))+)\)');

class _Fmt {
  bool bold = false, italic = false, underline = false;
}

List<InlineRun> _inline(String line, _Fmt f) {
  final runs = <InlineRun>[];
  String clean(String t) => t.replaceAll(RegExp(r'(\*\*|__)'), '').replaceAll(RegExp(r'(?<![\w*])[*_`]|[*_`](?![\w*])'), '');
  // Splits [text] at style markers, carrying the bold / italic / underline state across segments, links and lines.
  void seg(String text, String? link) {
    final buf = StringBuffer();
    void emit() {
      final t = clean(buf.toString());
      buf.clear();
      if (t.isNotEmpty) runs.add(InlineRun(t, link, f.bold, f.italic, f.underline));
    }

    for (final c in text.codeUnits) {
      switch (String.fromCharCode(c)) {
        case _bOn || _bOff || _iOn || _iOff || _uOn || _uOff:
          emit();
          final on = c == _bOn.codeUnitAt(0) || c == _iOn.codeUnitAt(0) || c == _uOn.codeUnitAt(0);
          if (c == _bOn.codeUnitAt(0) || c == _bOff.codeUnitAt(0)) f.bold = on;
          if (c == _iOn.codeUnitAt(0) || c == _iOff.codeUnitAt(0)) f.italic = on;
          if (c == _uOn.codeUnitAt(0) || c == _uOff.codeUnitAt(0)) f.underline = on;
        default:
          buf.writeCharCode(c);
      }
    }
    emit();
  }

  var last = 0;
  for (final m in _mdLink.allMatches(line)) {
    if (m.start > last) seg(line.substring(last, m.start), null);
    final u = safeExternalUri(m.group(2));
    seg(m.group(1)!, u?.toString()); // an unsafe scheme (javascript:, file: ...) keeps the text, drops the link
    last = m.end;
  }
  if (last < line.length) seg(line.substring(last), null);
  return runs;
}

/// An `<img>` the renderer doesn't show as an image: a tappable "Image" link for an http(s) source (opened only after the confirmation
/// dialog), otherwise just its alt text, otherwise nothing.
TextBlock? _imageFallback(String src, String alt) {
  final u = safeExternalUri(src);
  if (u != null && (u.scheme == 'https' || u.scheme == 'http')) return TextBlock(TextBlockKind.paragraph, [InlineRun(alt.isEmpty ? 'Image' : alt, u.toString())]);
  return alt.isEmpty ? null : TextBlock(TextBlockKind.paragraph, [InlineRun(alt)]);
}

/// Markdown-lite, plain text or HTML -> blocks. HTML is flattened first (see [htmlToPlainText]); every non-empty line of an HTML source is its own
/// paragraph (parent: the editor's Enter key is a line break, the teacher copy merged them), plain text / markdown still joins consecutive lines.
/// Images (`![alt](url)`) in markdown / plain text are never fetched: only the alt text remains. `<img>` in HTML becomes an image block only for an
/// allowed source ([allowedImageSource]). Supported: `#` headings, `-`/`*`/`•` bullets (nested ones indented), `1.` numbers, paragraphs,
/// `[text](url)` links, bold / italic / underline from HTML (`<b>/<strong>`, `<i>/<em>`, `<u>`), `**bold**` (marker dropped).
List<TextBlock> parseRichText(String raw) {
  var s = raw.replaceAll(_markers, '');
  final html = looksLikeHtml(s);
  if (html) s = _flatten(s, rich: true);
  s = s.replaceAllMapped(RegExp(r'!\[([^\]]*)\]\([^)]*\)'), (m) => m.group(1) ?? '');
  final blocks = <TextBlock>[];
  final para = <String>[];
  final fmt = _Fmt();
  void flush() {
    if (para.isEmpty) return;
    final runs = _inline(para.join(' '), fmt);
    para.clear();
    if (runs.isNotEmpty) blocks.add(TextBlock(TextBlockKind.paragraph, runs)); // a line of only style markers is nothing
  }

  for (final rawLine in s.split('\n')) {
    final line = rawLine.trimRight();
    var t = line.trim();
    if (t.isEmpty) {
      flush();
      continue;
    }
    if (t.startsWith(_imgStart) && t.endsWith(_imgEnd) && t.contains(_imgSep)) {
      flush();
      final body = t.substring(1, t.length - 1); // entities were already decoded once by the flattening
      final cut = body.indexOf(_imgSep);
      final src = body.substring(0, cut), alt = body.substring(cut + 1);
      final ok = allowedImageSource(src);
      if (ok != null) {
        blocks.add(TextBlock(TextBlockKind.image, const [], imageUrl: ok.url, imageBytes: ok.bytes, alt: alt));
      } else {
        final fb = _imageFallback(src, alt);
        if (fb != null) blocks.add(fb);
      }
      continue;
    }
    var depth = 0;
    while (t.startsWith(_indent)) {
      depth++;
      t = t.substring(1).trimLeft();
    }
    final h = RegExp(r'^#{1,6}\s+(.*)$').firstMatch(t);
    final b = RegExp(r'^[-*•]\s+(.*)$').firstMatch(t);
    final n = RegExp(r'^(\d{1,3})[.)]\s+(.*)$').firstMatch(t);
    if (h != null) {
      flush();
      blocks.add(TextBlock(TextBlockKind.heading, _inline(h.group(1)!, fmt)));
    } else if (b != null) {
      flush();
      blocks.add(TextBlock(TextBlockKind.bullet, _inline(b.group(1)!, fmt), indent: depth));
    } else if (n != null) {
      flush();
      blocks.add(TextBlock(TextBlockKind.numbered, _inline(n.group(2)!, fmt), number: int.parse(n.group(1)!), indent: depth));
    } else {
      para.add(t);
      if (html) flush();
    }
  }
  flush();
  return blocks;
}
