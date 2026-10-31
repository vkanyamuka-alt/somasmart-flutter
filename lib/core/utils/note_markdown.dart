// How a note's Markdown is read, the same way as the website and the admin
// preview (SomaSmart App: src/lib/noteMarkdown.js). Both are checked against
// the same cases: test/fixtures/note_markdown_cases.json is a copy of the
// website's src/lib/noteMarkdownCases.json, so keep the two in step.
//
// Notes are Markdown (CommonMark + GitHub tables, lists, footnotes) with TeX
// maths: $inline$, $$display$$, \(inline\), \[display\] and \ce{...}
// chemistry. Only <sub>, <sup> and <br> HTML tags are honoured.
import 'package:markdown/markdown.dart' as md;

final _fence = RegExp(r'^ {0,3}(`{3,}|~{3,})');

/// Rewrites a note so the Markdown parser reads its maths the way the
/// website does. Code blocks and `code spans` are left alone.
String normalizeNoteMarkdown(String text) {
  final lines = text.replaceAll(RegExp(r'\r\n?'), '\n').split('\n');
  final out = <String>[];
  String? fence;
  for (final line in lines) {
    final f = _fence.firstMatch(line);
    if (fence != null) {
      out.add(line);
      final mark = f?.group(1);
      if (mark != null &&
          mark[0] == fence[0] &&
          mark.length >= fence.length &&
          line.trim().substring(mark.length).isEmpty) {
        fence = null;
      }
      continue;
    }
    if (f != null) {
      fence = f.group(1);
      out.add(line);
      continue;
    }
    final indent = RegExp(r'^\s*').stringMatch(line)!;
    final t = line.trim();
    // \[ and \] on their own lines, or opening/closing a display block.
    if (t == r'\[' || t == r'\]') {
      out.add('$indent\$\$');
      continue;
    }
    if (t.startsWith(r'\[') && !t.contains(r'\]')) {
      out
        ..add('$indent\$\$')
        ..add('$indent${t.substring(2).trim()}');
      continue;
    }
    if (t.endsWith(r'\]') && !t.contains(r'\[')) {
      out
        ..add('$indent${t.substring(0, t.length - 2).trim()}')
        ..add('$indent\$\$');
      continue;
    }
    // A line that is only $$...$$ (or \[...\]) is a display equation.
    final display = RegExp(r'^(?:\$\$(.+)\$\$|\\\[(.+)\\\])$').firstMatch(t);
    if (display != null && !(display.group(1) ?? '').contains(r'$$')) {
      out
        ..add('$indent\$\$')
        ..add('$indent${(display.group(1) ?? display.group(2))!.trim()}')
        ..add('$indent\$\$');
      continue;
    }
    out.add(_normalizeLine(line));
  }
  return out.join('\n');
}

String _normalizeLine(String line) {
  final buf = StringBuffer();
  var last = 0;
  for (final m in RegExp(r'`+[^`]*`+').allMatches(line)) {
    buf
      ..write(_normalizeSegment(line.substring(last, m.start)))
      ..write(m.group(0));
    last = m.end;
  }
  buf.write(_normalizeSegment(line.substring(last)));
  return buf.toString();
}

String _normalizeSegment(String s) => _escapeCurrency(s
    .replaceAllMapped(RegExp(r'\\\[(.+?)\\\]'), (m) => '\$\$${m[1]}\$\$')
    .replaceAllMapped(RegExp(r'\\\((.+?)\\\)'), (m) => '\$${m[1]}\$'));

// "$2 and $5" is money, not maths: a $ followed by a digit whose partner $
// comes after a space (or before a digit) is escaped.
String _escapeCurrency(String s) {
  final out = StringBuffer();
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == r'\') {
      out.write(s.substring(i, i + 2 > s.length ? s.length : i + 2));
      i += 2;
      continue;
    }
    if (c != r'$') {
      out.write(c);
      i += 1;
      continue;
    }
    if (i + 1 < s.length && s[i + 1] == r'$') {
      final end = s.indexOf(r'$$', i + 2);
      if (end < 0) {
        out.write(s.substring(i));
        break;
      }
      out.write(s.substring(i, end + 2));
      i = end + 2;
      continue;
    }
    var j = i + 1;
    while (j < s.length && s[j] != r'$') {
      j += s[j] == r'\' ? 2 : 1;
    }
    if (j >= s.length) {
      out.write(c);
      i += 1;
      continue;
    }
    final content = s.substring(i + 1, j);
    final after = j + 1 < s.length ? s[j + 1] : '';
    if (RegExp(r'^\d').hasMatch(content) &&
        (RegExp(r'\s$').hasMatch(content) || RegExp(r'^\d').hasMatch(after))) {
      out.write(r'\$');
      i += 1;
      continue;
    }
    out.write(s.substring(i, j + 1));
    i = j + 1;
  }
  return out.toString();
}

/// flutter_math has no mhchem, so \ce{...} is rewritten into plain TeX:
/// \ce{2H2 + O2 -> 2H2O}, ions (Na+, SO4^2-), states ((aq)) and arrows with
/// conditions (->[heat]).
String convertMhchem(String tex) => tex.replaceAllMapped(
      RegExp(r'\\ce\{((?:[^{}]|\{[^{}]*\})*)\}'),
      (m) => _ce(m[1]!),
    );

const _arrows = {
  '<=>': r'\rightleftharpoons',
  '<->': r'\leftrightarrow',
  '->': r'\longrightarrow',
  '<-': r'\longleftarrow',
};

String _ce(String body) {
  final arrows = <String>[];
  final spaced = body.replaceAllMapped(
    RegExp(r'(<=>|<->|->|<-)(?:\[([^\]]*)\])?'),
    (m) {
      final cond = m[2];
      arrows.add(cond == null
          ? _arrows[m[1]]!
          : '\\xrightarrow{\\text{$cond}}');
      return ' \u0000${arrows.length - 1}\u0000 ';
    },
  );
  final parts = <String>[];
  for (final token in spaced.trim().split(RegExp(r'\s+'))) {
    final arrow = RegExp('^\u0000(\\d+)\u0000\$').firstMatch(token);
    if (arrow != null) {
      parts.add(arrows[int.parse(arrow[1]!)]);
    } else if (token == '+' || token == '=') {
      parts.add(token);
    } else if (token == '^') {
      parts.add(r'\uparrow');
    } else if (token.isNotEmpty) {
      parts.add(_species(token));
    }
  }
  return parts.join(' ');
}

String _species(String token) {
  final m = RegExp(r'^(\d+(?:/\d+)?)?(.*)$').firstMatch(token)!;
  final coefficient = m[1] ?? '';
  var rest = m[2]!;
  var state = '';
  final s = RegExp(r'\((s|l|g|aq)\)$').firstMatch(rest);
  if (s != null) {
    state = '\\,(\\mathrm{${s[1]}})';
    rest = rest.substring(0, s.start);
  }
  var charge = '';
  final caret = rest.indexOf('^');
  if (caret >= 0) {
    charge = rest.substring(caret + 1).replaceAll(RegExp('[{}]'), '');
    rest = rest.substring(0, caret);
  } else if (rest.length > 1 && (rest.endsWith('+') || rest.endsWith('-'))) {
    charge = rest[rest.length - 1];
    rest = rest.substring(0, rest.length - 1);
  }
  final formula = rest
      .replaceAllMapped(RegExp(r'([A-Za-z)\]])(\d+)'), (m) => '${m[1]}_{${m[2]}}')
      .replaceAll(RegExp(r'[.*]'), r'\cdot ');
  final sup = charge.isEmpty ? '' : '^{$charge}';
  return '$coefficient\\mathrm{$formula}$sup$state';
}

/// $...$ and $$...$$ inside a paragraph (an escaped \$ is plain text).
class MathInlineSyntax extends md.InlineSyntax {
  MathInlineSyntax() : super(r'\$\$([^$]+?)\$\$|\$([^$\n]+?)\$');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math', match[1] ?? match[2]!));
    return true;
  }
}

/// A display equation: $$ on its own line, the TeX, then $$.
class MathBlockSyntax extends md.BlockSyntax {
  static final _delimiter = RegExp(r'^\s*\$\$\s*$');

  @override
  RegExp get pattern => _delimiter;

  @override
  md.Node? parse(md.BlockParser parser) {
    parser.advance();
    final lines = <String>[];
    while (!parser.isDone && !_delimiter.hasMatch(parser.current.content)) {
      lines.add(parser.current.content);
      parser.advance();
    }
    if (!parser.isDone) parser.advance();
    return md.Element('mathBlock', [md.Text(lines.join('\n'))]);
  }
}

const _subscripts = {
  '0': '₀', '1': '₁', '2': '₂', '3': '₃', '4': '₄', '5': '₅', '6': '₆',
  '7': '₇', '8': '₈', '9': '₉', '+': '₊', '-': '₋', '=': '₌', '(': '₍',
  ')': '₎', 'a': 'ₐ', 'e': 'ₑ', 'o': 'ₒ', 'x': 'ₓ', 'n': 'ₙ',
};
const _superscripts = {
  '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴', '5': '⁵', '6': '⁶',
  '7': '⁷', '8': '⁸', '9': '⁹', '+': '⁺', '-': '⁻', '=': '⁼', '(': '⁽',
  ')': '⁾', 'n': 'ⁿ', 'i': 'ⁱ',
};

/// <sub>, <sup> and <br> as the website shows them; any other tag is dropped
/// and its text kept.
class NoteHtmlTagSyntax extends md.InlineSyntax {
  NoteHtmlTagSyntax()
      : super(r'<(sub|sup)>([^<]*)</\1>|<br\s*/?>|</?[a-zA-Z][a-zA-Z0-9]*(\s[^<>]*)?/?>',
            caseSensitive: false);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final kind = match[1]?.toLowerCase();
    if (kind == null) {
      if (RegExp(r'^<br', caseSensitive: false).hasMatch(match[0]!)) {
        parser.addNode(md.Element.empty('br'));
      }
      return true;
    }
    final map = kind == 'sub' ? _subscripts : _superscripts;
    final text = match[2]!;
    final mapped = text.split('').map((c) => map[c]).toList();
    parser.addNode(md.Text(mapped.contains(null) ? text : mapped.join()));
    return true;
  }
}

/// The parser set every note-style Markdown widget uses.
md.ExtensionSet noteExtensionSet() => md.ExtensionSet(
      [MathBlockSyntax(), ...md.ExtensionSet.gitHubFlavored.blockSyntaxes],
      [MathInlineSyntax(), NoteHtmlTagSyntax(), ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes],
    );
