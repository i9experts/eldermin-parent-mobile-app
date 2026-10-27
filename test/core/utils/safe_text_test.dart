import 'dart:convert';
import 'dart:typed_data';
import 'package:eldermin_parent_app/core/constants/media_hosts.dart';
import 'package:eldermin_parent_app/core/utils/safe_text.dart';
import 'package:flutter_test/flutter_test.dart';

// Fixtures use the HTML the web consent editor produces (Eldermin-Frontend src/pages/school-calendar/RichTextEditor.tsx: a contentEditable
// div driven by document.execCommand — Chrome emits <b>/<i>/<u>, one <div> per Enter, <div><br></div> for an empty line, <ul>/<ol><li>,
// <a href> from createLink, <img src> from insertImage, &nbsp; for runs of spaces), plus hostile / unsupported markup.
const editorOutput = 'Dear parents,<div>We are taking <b>Class 5</b> to the <i>museum</i> on <u>12&nbsp;Nov</u> &amp; back.</div>'
    '<div><br></div><div>Please send:</div>'
    '<ul><li>Packed lunch</li><li>Water bottle<ul><li>1 litre</li></ul></li></ul>'
    '<ol><li>Sign the slip</li><li>Return by Friday</li></ol>'
    '<div>Details: <a href="https://school.edu/trip?id=1&amp;x=2">trip page</a>&nbsp;or <a href="mailto:office@school.edu">email us</a> or <a href="tel:+9200000">call</a></div>'
    '<div>Permission slip:</div><div><img src="https://cdn.school.edu/consent-attachments/slip.png"></div>';

String text(List<TextBlock> b) => b.map((x) => x.plain).join('\n');

void main() {
  _consentBodyTests();
  group('editor output', () {
    final blocks = parseRichText(editorOutput);

    test('each Enter (div) is its own paragraph, empty paragraph is only a gap', () {
      expect(blocks.first.plain, 'Dear parents,');
      expect(blocks[1].plain, 'We are taking Class 5 to the museum on 12 Nov & back.');
      expect(blocks[2].plain, 'Please send:');
      expect(blocks[1].kind, TextBlockKind.paragraph);
    });

    test('bold / italic / underline degrade to readable plain text', () {
      expect(blocks[1].plain, contains('Class 5'));
      expect(blocks[1].plain, isNot(contains('<')));
    });

    test('bulleted, nested and numbered lists', () {
      final lists = blocks.where((b) => b.kind != TextBlockKind.paragraph).toList();
      expect(lists.map((b) => '${b.kind.name}:${b.plain}').toList(), [
        'bullet:Packed lunch',
        'bullet:Water bottle',
        'bullet:1 litre',
        'numbered:Sign the slip',
        'numbered:Return by Friday',
      ]);
      expect(lists.where((b) => b.kind == TextBlockKind.numbered).map((b) => b.number).toList(), [1, 2]);
    });

    test('links keep their URL (http, https, mailto, tel); &amp; in the href is decoded', () {
      final links = [for (final b in blocks) for (final r in b.runs) if (r.link != null) r];
      expect(links.map((r) => r.text).toList(), ['trip page', 'email us', 'call', 'Image']);
      expect(links[0].link, 'https://school.edu/trip?id=1&x=2');
      expect(links[1].link, 'mailto:office@school.edu');
      expect(links[2].link, 'tel:+9200000');
    });

    test('an inline image becomes a tappable "Image" link, never fetched', () {
      expect(blocks.last.runs.single.text, 'Image');
      expect(blocks.last.runs.single.link, 'https://cdn.school.edu/consent-attachments/slip.png');
    });

    test('no raw tag text on screen', () {
      expect(text(blocks), isNot(matches(RegExp(r'</?[a-zA-Z][^>]*>'))));
    });
  });

  group('entities and breaks', () {
    test('&amp; &nbsp; &lt;', () {
      expect(text(parseRichText('<div>Tom &amp; Jerry&nbsp;&nbsp;now</div>')), 'Tom & Jerry now');
      expect(text(parseRichText('<div>1 &lt; 2</div>')), '1 < 2');
    });
    test('<br> breaks a line inside one block', () {
      final b = parseRichText('<div>line one<br>line two</div>');
      expect(b.map((x) => x.plain).toList(), ['line one', 'line two']);
    });
    test('several empty paragraphs never produce empty blocks', () {
      final b = parseRichText('<div>a</div><div><br></div><div><br></div><div><br></div><div>b</div>');
      expect(b.map((x) => x.plain).toList(), ['a', 'b']);
    });
    test('plain text and markdown-lite still join consecutive lines', () {
      expect(parseRichText('one\ntwo').single.plain, 'one two');
      expect(parseRichText('# Title\n- a\n1. b').map((b) => b.kind).toList(), [TextBlockKind.heading, TextBlockKind.bullet, TextBlockKind.numbered]);
    });
  });

  group('headings and tables', () {
    test('h1-h6 become headings', () {
      final b = parseRichText('<h2>Trip</h2><p>Body</p>');
      expect(b.first.kind, TextBlockKind.heading);
      expect(b.first.plain, 'Trip');
      expect(b[1].kind, TextBlockKind.paragraph);
    });
    test('a table degrades to readable rows (cells separated, rows on their own line)', () {
      final b = parseRichText('<table><tr><th>Item</th><th>Cost</th></tr><tr><td>Bus</td><td>Rs 500</td></tr></table>');
      expect(b.map((x) => x.plain).toList(), ['Item Cost', 'Bus Rs 500']);
    });
  });

  group('hostile markup', () {
    test('script and iframe content never renders', () {
      final t = text(parseRichText('Hi<script>alert("x")</script><iframe src="https://evil.example">frame text</iframe> there'));
      expect(t, 'Hi there');
      expect(t, isNot(contains('alert')));
      expect(t, isNot(contains('frame text')));
    });
    test('an unclosed script / iframe drops its tail', () {
      expect(text(parseRichText('<div>keep</div><script>alert(1)')), 'keep');
      expect(text(parseRichText('<div>keep</div><iframe src=x>secret')), 'keep');
    });
    test('style, comment, svg, object, embed content is dropped', () {
      final t = text(parseRichText('a<style>.x{color:red}</style><!-- c --><svg><text>svg</text></svg><object>o</object><embed src=x>b'));
      expect(t, 'ab');
    });
    test('img with an event handler and a broken tag leave no markup', () {
      final t = text(parseRichText('<div>ok<img src=x onerror=alert(1)></div><div><b onclick="x">bold</b> <img src="javascript:alert(1)" alt="pic"></div>'));
      expect(t, isNot(contains('onerror')));
      expect(t, isNot(contains('<')));
      expect(t, contains('bold'));
      expect(t, contains('pic'));
    });
    test('javascript: / file: / data: links keep the text, drop the link', () {
      final b = parseRichText('<a href="javascript:alert(1)">click</a> <a href="file:///etc/passwd">f</a> <a href="data:text/html,x">d</a>');
      expect([for (final x in b) for (final r in x.runs) r.link], everyElement(isNull));
      expect(text(b), 'click f d');
    });
    test('markdown-style javascript link in plain text is not a link either', () {
      expect(parseRichText('[x](javascript:alert(1))').single.runs.single.link, isNull);
    });
    test('an escaped tag typed by the admin stays inert text', () {
      expect(text(parseRichText('<div>&lt;b&gt;not bold&lt;/b&gt;</div>')), '<b>not bold</b>');
    });
  });

  group('htmlToPreviewText', () {
    test('drops images and link markers, keeps link text, one line', () {
      const html = '<div>Dear parents</div><div>See <a href="https://school.edu/trip">the trip page</a></div><div><img src="https://cdn.example/a.png" alt="Map"></div>';
      expect(htmlToPreviewText(html), 'Dear parents See the trip page');
    });
    test('editor output has no markers, tags or line breaks', () {
      final p = htmlToPreviewText(editorOutput);
      expect(p, isNot(contains('](')));
      expect(p, isNot(contains('[')));
      expect(p, isNot(contains('<')));
      expect(p, isNot(contains('\n')));
      expect(p, contains('trip page'));
      expect(p, contains('email us'));
    });
    test('script text and unclosed script tails never appear', () {
      expect(htmlToPreviewText('Hi<script>alert(1)</script> there'), 'Hi there');
      expect(htmlToPreviewText('Hi<script>alert(1)'), 'Hi');
    });
  });

  group('safeExternalUri', () {
    test('allows http, https, mailto, tel only', () {
      expect(safeExternalUri('https://a.example/x'), isNotNull);
      expect(safeExternalUri('http://a.example'), isNotNull);
      expect(safeExternalUri('mailto:a@b.co'), isNotNull);
      expect(safeExternalUri('tel:+123'), isNotNull);
      for (final bad in ['javascript:alert(1)', 'file:///x', 'data:text/html,x', 'ftp://a.example', 'intent://x', 'https://', 'mailto:', '//a.example', '/relative', '', null]) {
        expect(safeExternalUri(bad), isNull, reason: '$bad');
      }
    });
  });
}

// ---- consent body: inline styles, Chrome paragraphs, nested lists and images (parent renderer) ----
const _pngB64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';
final _prod = kConsentImageHosts.first;

List<InlineRun> _runs(String html) => parseRichText(html).first.runs;

void _consentBodyTests() {
  group('inline styles', () {
    test('bold, italic and underline, each tag spelling', () {
      final r = _runs('<div>a <b>b</b> <strong>c</strong> <i>d</i> <em>e</em> <u>f</u></div>');
      InlineRun run(String t) => r.firstWhere((x) => x.text == t);
      expect(run('b').bold, isTrue);
      expect(run('c').bold, isTrue);
      expect(run('d').italic, isTrue);
      expect(run('e').italic, isTrue);
      expect(run('f').underline, isTrue);
      expect(run('a ').bold, isFalse);
    });
    test('nested combinations', () {
      final r = _runs('<div><b>x<i>y<u>z</u></i></b>w</div>');
      InlineRun run(String t) => r.firstWhere((x) => x.text == t);
      expect([run('x').bold, run('x').italic, run('x').underline], [true, false, false]);
      expect([run('y').bold, run('y').italic, run('y').underline], [true, true, false]);
      expect([run('z').bold, run('z').italic, run('z').underline], [true, true, true]);
      expect([run('w').bold, run('w').italic, run('w').underline], [false, false, false]);
    });
    test('a styled link stays a link', () {
      final r = _runs('<div><b><a href="https://school.edu/x">trip</a></b></div>');
      expect(r.single.link, 'https://school.edu/x');
      expect(r.single.bold, isTrue);
    });
    test('private-use markers typed by the server cannot forge styles or images', () {
      final b = parseRichText('plain texthttps://$_prod/a.pngx');
      expect(b.every((x) => x.kind != TextBlockKind.image), isTrue);
      expect(b.first.runs.every((r) => !r.bold), isTrue);
    });
  });

  group('Chrome paragraphs', () {
    test('div lines, br and empty div never create empty or stacked blocks', () {
      final b = parseRichText('<div>One</div><div><br></div><div><br></div><div><br></div><div>Two<br>Three</div><p>Four</p>');
      expect(b.map((x) => x.plain), ['One', 'Two', 'Three', 'Four']);
    });
  });

  group('nested lists', () {
    test('nested items are indented one level', () {
      final b = parseRichText('<ul><li>A<ul><li>B</li></ul></li><li>C</li></ul>');
      expect(b.map((x) => (x.plain, x.indent)), [('A', 0), ('B', 1), ('C', 0)]);
    });
  });

  group('images', () {
    test('allowlisted https img becomes an image block', () {
      final b = parseRichText('<div>See:</div><div><img src="https://$_prod/school/consent-attachments/a.png" alt="Map"></div>');
      expect(b.last.kind, TextBlockKind.image);
      expect(b.last.imageUrl, 'https://$_prod/school/consent-attachments/a.png');
      expect(b.last.alt, 'Map');
    });
    test('a bare img src with no alt works (what insertImage emits)', () {
      final b = parseRichText('<img src="https://$_prod/s/consent-attachments/u.jpg">');
      expect(b.single.kind, TextBlockKind.image);
      expect(b.single.alt, '');
    });
    test('an entity-escaped query keeps its & and cannot break the line', () {
      final b = parseRichText('<img src="https://$_prod/a.png?x=1&amp;y=2&#10;z">');
      expect(b.single.imageUrl, 'https://$_prod/a.png?x=1&y=2z');
    });
    test('another host stays a link, never an image', () {
      final b = parseRichText('<img src="https://evil.example/a.png">');
      expect(b.single.kind, TextBlockKind.paragraph);
      expect(b.single.runs.single.text, 'Image');
      expect(b.single.runs.single.link, 'https://evil.example/a.png');
    });
    test('lookalike hosts, credentials and ports are not allowlisted', () {
      for (final u in ['https://$_prod.evil.com/a.png', 'https://evil.com/$_prod/a.png', 'https://user@$_prod/a.png', 'https://$_prod:8443/a.png']) {
        expect(allowedImageSource(u), isNull, reason: u);
      }
    });
    test('http, file, relative, other schemes and svg are rejected', () {
      for (final u in ['http://$_prod/a.png', 'file:///a.png', '/uploads/a.png', 'a.png', '//$_prod/a.png', 'ftp://$_prod/a.png', 'javascript:alert(1)', 'https://$_prod/a.svg', 'https://$_prod/A.SVG']) {
        expect(allowedImageSource(u), isNull, reason: u);
      }
      expect(parseRichText('<img src="javascript:alert(1)">'), isEmpty);
      expect(parseRichText('<img src="/uploads/a.png" alt="Pic">').single.plain, 'Pic');
    });
    test('data: png / jpeg / gif / webp with matching bytes are accepted', () {
      final ok = allowedImageSource('data:image/png;base64,$_pngB64');
      expect(ok?.bytes, isNotNull);
      expect(ok!.url, isNull);
      expect(allowedImageSource('data:image/jpeg;base64,${base64Encode([0xFF, 0xD8, 0xFF, 0xE0])}')?.bytes, isNotNull);
      expect(allowedImageSource('data:image/gif;base64,${base64Encode('GIF89a'.codeUnits)}')?.bytes, isNotNull);
      expect(allowedImageSource('data:image/webp;base64,${base64Encode([...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits])}')?.bytes, isNotNull);
    });
    test('data: svg, other types, malformed, mismatched and oversize are rejected', () {
      expect(allowedImageSource('data:image/svg+xml;base64,${base64Encode('<svg/>'.codeUnits)}'), isNull);
      expect(allowedImageSource('data:image/svg+xml,<svg/>'), isNull);
      expect(allowedImageSource('data:text/html;base64,PGI+'), isNull);
      expect(allowedImageSource('data:image/png;base64,@@@@'), isNull);
      expect(allowedImageSource('data:image/png;base64,abc'), isNull); // bad padding
      expect(allowedImageSource('data:image/png,rawbytes'), isNull);
      expect(allowedImageSource('data:image/jpeg;base64,$_pngB64'), isNull); // PNG bytes labelled jpeg
      final big = Uint8List(kMaxDataImageBytes + 1)..setAll(0, [0x89, 0x50, 0x4E, 0x47]);
      expect(allowedImageSource('data:image/png;base64,${base64Encode(big)}'), isNull);
      final edge = Uint8List(kMaxDataImageBytes)..setAll(0, [0x89, 0x50, 0x4E, 0x47]);
      expect(allowedImageSource('data:image/png;base64,${base64Encode(edge)}')?.bytes?.length, kMaxDataImageBytes);
    });
    test('a rejected data: image leaves only its alt text', () {
      expect(parseRichText('<img src="data:image/svg+xml;base64,PHN2Zy8+" alt="Logo">').single.plain, 'Logo');
      expect(parseRichText('<div>Hi</div><img src="data:image/svg+xml;base64,PHN2Zy8+">').map((b) => b.plain), ['Hi']);
    });
    test('markdown images in plain text are never fetched', () {
      expect(parseRichText('![pic](https://$_prod/a.png)').every((b) => b.kind != TextBlockKind.image), isTrue);
    });
  });
}
