import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/core/utils/subject_content.dart';

/// The website runs the same cases (src/lib/subjectContentCases.json) against
/// src/lib/subjectContent.js, so both apps put each item in the same tab.
void main() {
  final cases = (jsonDecode(
    File('test/fixtures/subject_content_cases.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();

  group('tabOf: shared cases', () {
    for (final c in cases) {
      test(c['name'], () {
        final kind = ContentKind.values.byName(c['kind'] as String);
        expect(tabOf(kind, c['section'] as String?).name, c['tab']);
      });
    }
  });

  test('the fixture is the same file as the website copy', () {
    for (final path in [
      '../SomaMkononi App/src/lib/subjectContentCases.json',
      '../content/src/lib/subjectContentCases.json',
    ]) {
      final f = File(path);
      if (!f.existsSync()) continue;
      expect(
        jsonDecode(f.readAsStringSync()),
        jsonDecode(
          File('test/fixtures/subject_content_cases.json').readAsStringSync(),
        ),
      );
    }
  });
}
