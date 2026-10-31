import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

import '../utils/note_markdown.dart';

/// Markdown with TeX maths, read the same way as on the website (see
/// note_markdown.dart). Notes and Ask Me answers use it with their own
/// [styleSheet]; maths takes its size and colour from the paragraph style.
class SomaMarkdown extends StatelessWidget {
  final String data;
  final MarkdownStyleSheet styleSheet;
  final bool selectable;

  /// Background behind display equations; none when null.
  final BoxDecoration? displayMathDecoration;

  /// Colour of TeX that cannot be drawn (shown as its source text).
  final Color errorColor;

  const SomaMarkdown({
    super.key,
    required this.data,
    required this.styleSheet,
    this.selectable = false,
    this.displayMathDecoration,
    this.errorColor = Colors.deepOrange,
  });

  @override
  Widget build(BuildContext context) {
    final base = styleSheet.p ?? const TextStyle(fontSize: 15);
    return MarkdownBody(
      data: normalizeNoteMarkdown(data),
      selectable: selectable,
      extensionSet: noteExtensionSet(),
      styleSheet: styleSheet,
      builders: {
        'math': _MathBuilder(base: base, errorColor: errorColor),
        'mathBlock': _MathBuilder(
          base: base,
          errorColor: errorColor,
          display: true,
          decoration: displayMathDecoration,
        ),
      },
    );
  }
}

class _MathBuilder extends MarkdownElementBuilder {
  final TextStyle base;
  final Color errorColor;
  final bool display;
  final BoxDecoration? decoration;

  _MathBuilder({
    required this.base,
    required this.errorColor,
    this.display = false,
    this.decoration,
  });

  // Display equations are blocks of their own, not part of a paragraph.
  @override
  bool isBlockElement() => display;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final source = element.textContent.trim();
    final around = display ? base : (parentStyle ?? base);
    final size = around.fontSize ?? 15;
    final math = Math.tex(
      convertMhchem(source),
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: TextStyle(fontSize: display ? size + 0.5 : size, color: around.color),
      onErrorFallback: (_) => Text(
        source,
        style: TextStyle(fontFamily: 'monospace', fontSize: size - 2, color: errorColor),
      ),
    );
    if (display) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: decoration == null
            ? const EdgeInsets.symmetric(vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: decoration,
        alignment: Alignment.center,
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: math),
      );
    }
    // A span on the text baseline, so inline maths lines up with the words.
    return Text.rich(TextSpan(children: [
      WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: math,
      ),
    ]));
  }
}
