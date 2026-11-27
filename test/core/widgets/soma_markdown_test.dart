import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/core/utils/note_markdown.dart';
import 'package:somasmart_flutter/core/widgets/soma_markdown.dart';

// The same cases the website checks (src/lib/noteMarkdownCases.json).
final _cases = (jsonDecode(File('test/fixtures/note_markdown_cases.json').readAsStringSync()) as List)
    .cast<Map<String, dynamic>>();

/// Text shown outside equations, and the equations drawn.
({String text, List<Math> math}) _inspect(WidgetTester tester) {
  final math = tester.widgetList<Math>(find.byType(Math)).toList();
  final text = StringBuffer();
  for (final element in find.byType(RichText).evaluate()) {
    if (element.findAncestorWidgetOfExactType<Math>() != null) continue;
    text.write((element.widget as RichText).text.toPlainText());
    text.write('\n');
  }
  return (text: text.toString(), math: math);
}

void main() {
  group('note rendering cases (shared with the website)', () {
    for (final c in _cases) {
      testWidgets(c['name'] as String, (tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SomaMarkdown(data: c['md'] as String, styleSheet: MarkdownStyleSheet()),
            ),
          ),
        ));
        expect(tester.takeException(), isNull);
        final (:text, :math) = _inspect(tester);
        expect(math.where((m) => m.parseError != null).map((m) => m.parseError.toString()), isEmpty);
        expect(math.length, c['math']);
        for (final t in (c['text'] as List? ?? const [])) {
          expect(text, contains(t));
        }
        for (final t in (c['notText'] as List? ?? const [])) {
          expect(text, isNot(contains(t)));
        }
      });
    }
  });

  group('normalizeNoteMarkdown', () {
    test('puts a one-line display equation on its own lines', () {
      expect(normalizeNoteMarkdown(r'$$x^2$$'), '\$\$\nx^2\n\$\$');
      expect(normalizeNoteMarkdown(r'  \[x^2\]'), '  \$\$\n  x^2\n  \$\$');
    });

    test('escapes money but keeps maths that starts with a number', () {
      expect(normalizeNoteMarkdown(r'costs $2 and $5'), r'costs \$2 and $5');
      expect(normalizeNoteMarkdown(r'solve $2x + 3 = 5$'), r'solve $2x + 3 = 5$');
      expect(normalizeNoteMarkdown(r'$ x = 1 $'), r'$ x = 1 $');
    });

    test('leaves code alone', () {
      expect(normalizeNoteMarkdown('```\n\\(a\\)\n```'), '```\n\\(a\\)\n```');
    });
  });

  testWidgets('a Markdown image is centred on the page, without a frame', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SomaMarkdown(
          data: 'Text\n\n![Ball on a slope](https://example.com/slope.png)\n\nMore',
          styleSheet: MarkdownStyleSheet(),
        ),
      ),
    ));
    await tester.pump();
    final image = find.byType(Image);
    expect((tester.widget<Image>(image).image as NetworkImage).url, 'https://example.com/slope.png');
    expect(find.ancestor(of: image, matching: find.byType(Center)), findsWidgets);
    expect(find.ancestor(of: image, matching: find.byType(DecoratedBox)), findsNothing);
  });

  group('convertMhchem', () {
    test('writes formulas, ions, states and arrows as plain TeX', () {
      expect(convertMhchem(r'\ce{2H2 + O2 -> 2H2O}'),
          r'2\mathrm{H_{2}} + \mathrm{O_{2}} \longrightarrow 2\mathrm{H_{2}O}');
      expect(convertMhchem(r'\ce{SO4^2-}'), r'\mathrm{SO_{4}}^{2-}');
      expect(convertMhchem(r'\ce{NaCl(aq)}'), r'\mathrm{NaCl}\,(\mathrm{aq})');
      expect(convertMhchem(r'\ce{CaCO3 ->[heat] CaO + CO2}'),
          r'\mathrm{CaCO_{3}} \xrightarrow{\text{heat}} \mathrm{CaO} + \mathrm{CO_{2}}');
    });
  });
}
