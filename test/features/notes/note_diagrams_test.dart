import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/notes/presentation/widgets/note_diagrams.dart';

// Same shape as the circuit and geometry notes on staging.
const _note = '''
## Saketi ya mfululizo

Mkondo ule ule hupita kwenye kila kifaa.

```somasmart-circuit
{
  "title": "Series Circuit with Switch & Lamp",
  "components": [
    { "type": "battery", "x": 80, "y": 175, "rotation": 0, "label": "V1", "value": "9V" },
    { "type": "switch", "x": 230, "y": 80, "label": "S1", "value": "OFF", "closed": false },
    { "type": "lamp", "x": 380, "y": 175, "label": "L1", "value": "12W" }
  ],
  "wires": [{ "points": [[110, 175], [110, 80], [200, 80]] }]
}
```

Swichi ikifunguliwa, taa huzimika.

```somasmart-geometry
{
  "title": "Triangle ABC Construction",
  "shapes": [
    { "type": "triangle", "label": "ABC", "color": "#8b5cf6", "points": [[150, 220], [250, 80], [350, 220]], "showAngles": true },
    { "type": "circle", "label": "Circumcircle", "color": "#f59e0b", "cx": 250, "cy": 170, "r": 90 }
  ]
}
```

```somasmart-chemistry
{ "title": "Water molecule" }
```
''';

void main() {
  group('splitNoteContent', () {
    test('keeps text and diagrams in order', () {
      final segs = splitNoteContent(_note);
      expect(segs.map((s) => s.runtimeType.toString()).toList(), [
        'NoteMarkdown', 'NoteDiagramBlock', 'NoteMarkdown', 'NoteDiagramBlock', 'NoteDiagramBlock',
      ]);
      final circuit = segs[1] as NoteDiagramBlock;
      expect(circuit.type, 'circuit');
      expect(circuit.title, 'Series Circuit with Switch & Lamp');
      expect((segs[3] as NoteDiagramBlock).type, 'geometry');
      // No diagram data is left in the text parts.
      for (final s in segs.whereType<NoteMarkdown>()) {
        expect(s.text.contains('"components"'), isFalse);
        expect(s.text.contains('"shapes"'), isFalse);
      }
    });

    test('a note without diagrams is one text part', () {
      final segs = splitNoteContent('Hello\n\n```dart\nprint(1);\n```\n');
      expect(segs, hasLength(1));
      expect(segs.single, isA<NoteMarkdown>());
    });

    test('broken diagram data is a block with no config, not text', () {
      final segs = splitNoteContent('```somasmart-circuit\n{ not json\n```');
      expect(segs.single, isA<NoteDiagramBlock>());
      expect((segs.single as NoteDiagramBlock).config, isNull);
    });
  });

  testWidgets('draws circuits and geometry, and a card for other diagrams', (tester) async {
    final blocks = splitNoteContent(_note).whereType<NoteDiagramBlock>().toList();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(children: [for (final b in blocks) NoteDiagram(block: b, lang: 'sw')]),
        ),
      ),
    ));

    expect(find.text('Series Circuit with Switch & Lamp'), findsOneWidget);
    expect(find.text('Triangle ABC Construction'), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is CircuitPainter), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is CustomPaint && w.painter is GeometryPainter), findsOneWidget);
    // The chemistry block has no still drawing yet: titled card, no raw data.
    expect(find.text('Water molecule'), findsOneWidget);
    expect(find.textContaining('tovuti ya SomaSmart'), findsOneWidget);
    expect(find.textContaining('"type"'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an inserted image shows the picture at its width, with its caption', (tester) async {
    // As written by the admin's Insert > Image.
    const note = 'Before\n\n```somasmart-image\n'
        '{"src":"https://example.com/notes/images/slope.png","alt":"Ball on a slope",'
        '"caption":"Figure 1: Forces on a slope","width":"60%"}\n```\n\nAfter';
    final block = splitNoteContent(note).whereType<NoteDiagramBlock>().single;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: NoteDiagram(block: block, lang: 'en'))),
    ));
    await tester.pump();

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url, 'https://example.com/notes/images/slope.png');
    expect(image.semanticLabel, 'Ball on a slope');
    expect(find.text('Figure 1: Forces on a slope'), findsOneWidget);
    expect(tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox)).widthFactor, 0.6);
    // Not the "shown on the website" card, and no raw data.
    expect(find.textContaining('SomaSmart website'), findsNothing);
    expect(find.textContaining('"src"'), findsNothing);
  });

  testWidgets('an image block without a picture address falls back to the card', (tester) async {
    final block = splitNoteContent('```somasmart-image\n{"title":"Photo","src":""}\n```').single as NoteDiagramBlock;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: NoteDiagram(block: block, lang: 'en'))));
    expect(find.byType(Image), findsNothing);
    expect(find.text('Photo'), findsOneWidget);
  });
}
