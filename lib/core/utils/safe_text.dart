// Mirrored from eldermin-teacher-app lib/core/utils/safe_text.dart (design-kit-v1, 2f2f5a6) — keep in sync.
// Parent copy differs from the teacher original in the HTML path only (see the "parent:" notes): links and images survive flattening, ordered
// lists are numbered, every line of HTML stays its own paragraph, an unclosed <script> drops its tail, and mailto:/tel: links are allowed.
//
// Safe rendering helpers for server-supplied rich text (consent descriptions are HTML from the web editor; other bodies may be markdown or
// plain text).
//
// RULE: nothing from the server is ever rendered as HTML / run as script / fetched as an image. HTML is reduced to plain text with
// paragraph breaks, bullets and `[text](url)` links; links are opened only after the user confirms (http, https, mailto, tel only).

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
String htmlToPlainText(String html) {
  var s = html.replaceAll(_comment, '');
  s = s.replaceAll(_scriptStyle, '').replaceAll(_openNoClose, '');
  s = s.replaceAllMapped(_anchor, (m) {
    final text = m.group(2)!.replaceAll(_anyTag, '').replaceAll(RegExp(r'[\[\]]'), '').trim();
    final u = safeExternalUri(decodeEntities(_attr(m.group(1)!, 'href') ?? ''));
    if (u == null) return text;
    return '[${text.isEmpty ? u.toString() : text}](${_mdUrl(u)})';
  });
  s = s.replaceAllMapped(_img, (m) {
    final alt = (_attr(m.group(0)!, 'alt') ?? '').replaceAll(RegExp(r'[\[\]]'), '').trim();
    final u = safeExternalUri(decodeEntities(_attr(m.group(0)!, 'src') ?? ''));
    if (u == null || u.scheme == 'mailto' || u.scheme == 'tel') return alt;
    return '\n[${alt.isEmpty ? 'Image' : alt}](${_mdUrl(u)})\n';
  });
  s = s.replaceAllMapped(_heading, (m) => m.group(1) == '/' ? '\n' : '\n# ');
  final lists = <_ListState>[];
  s = s.replaceAllMapped(_listTag, (m) {
    final closing = m.group(1) == '/';
    final tag = m.group(2)!.toLowerCase();
    if (tag == 'li') return closing ? '\n' : (lists.isNotEmpty && lists.last.ordered ? '${++lists.last.n}. ' : '• ');
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

enum TextBlockKind { heading, paragraph, bullet, numbered }

class InlineRun {
  final String text;
  final String? link; // validated allowed-scheme URL or null
  const InlineRun(this.text, [this.link]);
}

class TextBlock {
  final TextBlockKind kind;
  final List<InlineRun> runs;
  final int? number;
  const TextBlock(this.kind, this.runs, {this.number});
  String get plain => runs.map((r) => r.text).join();
}

final _mdLink = RegExp(r'\[([^\]]+)\]\(((?:[^()\s]|\([^()\s]*\))+)\)');

List<InlineRun> _inline(String line) {
  final runs = <InlineRun>[];
  var last = 0;
  String clean(String t) => t.replaceAll(RegExp(r'(\*\*|__)'), '').replaceAll(RegExp(r'(?<![\w*])[*_`]|[*_`](?![\w*])'), '');
  for (final m in _mdLink.allMatches(line)) {
    if (m.start > last) runs.add(InlineRun(clean(line.substring(last, m.start))));
    final u = safeExternalUri(m.group(2));
    runs.add(InlineRun(clean(m.group(1)!), u?.toString())); // an unsafe scheme (javascript:, file: ...) keeps the text, drops the link
    last = m.end;
  }
  if (last < line.length) runs.add(InlineRun(clean(line.substring(last))));
  return runs.where((r) => r.text.isNotEmpty).toList();
}

/// Markdown-lite, plain text or HTML -> blocks. HTML is flattened first (see [htmlToPlainText]); every non-empty line of an HTML source is its own
/// paragraph (parent: the editor's Enter key is a line break, the teacher copy merged them), plain text / markdown still joins consecutive lines.
/// Images (`![alt](url)`) are never fetched: only the alt text remains. Supported: `#` headings, `-`/`*`/`•` bullets, `1.` numbers, paragraphs,
/// `[text](url)` links, `**bold**` (marker dropped).
List<TextBlock> parseRichText(String raw) {
  var s = raw;
  final html = looksLikeHtml(s);
  if (html) s = htmlToPlainText(s);
  s = s.replaceAllMapped(RegExp(r'!\[([^\]]*)\]\([^)]*\)'), (m) => m.group(1) ?? '');
  final blocks = <TextBlock>[];
  final para = <String>[];
  void flush() {
    if (para.isEmpty) return;
    blocks.add(TextBlock(TextBlockKind.paragraph, _inline(para.join(' '))));
    para.clear();
  }

  for (final rawLine in s.split('\n')) {
    final line = rawLine.trimRight();
    final t = line.trim();
    if (t.isEmpty) {
      flush();
      continue;
    }
    final h = RegExp(r'^#{1,6}\s+(.*)$').firstMatch(t);
    final b = RegExp(r'^[-*•]\s+(.*)$').firstMatch(t);
    final n = RegExp(r'^(\d{1,3})[.)]\s+(.*)$').firstMatch(t);
    if (h != null) {
      flush();
      blocks.add(TextBlock(TextBlockKind.heading, _inline(h.group(1)!)));
    } else if (b != null) {
      flush();
      blocks.add(TextBlock(TextBlockKind.bullet, _inline(b.group(1)!)));
    } else if (n != null) {
      flush();
      blocks.add(TextBlock(TextBlockKind.numbered, _inline(n.group(2)!), number: int.parse(n.group(1)!)));
    } else {
      para.add(t);
      if (html) flush();
    }
  }
  flush();
  return blocks;
}
