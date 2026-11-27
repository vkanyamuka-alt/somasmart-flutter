import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/utils/forum_role.dart';
import 'package:somasmart_flutter/features/forum/presentation/widgets/forum_role_badge.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';

/// The website runs the same cases (src/lib/forumRoleCases.json) against
/// src/lib/forumRole.js, so both apps label forum authors the same way.
void main() {
  final cases = (jsonDecode(File('test/fixtures/forum_role_cases.json').readAsStringSync()) as List)
      .cast<Map<String, dynamic>>();

  group('forumRoleBadge: shared cases', () {
    for (final c in cases) {
      test('${c['role']} (${c['lang']})', () {
        final b = forumRoleBadge(c['role'] as String?, c['lang'] as String);
        expect(b?.label, c['label']);
        expect(b?.kind.name, c['kind']);
      });
    }
  });

  testWidgets('ForumRoleBadge shows Mwalimu for a teacher and nothing for a student', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: Row(children: [
        ForumRoleBadge(role: 'teacher'),
        ForumRoleBadge(role: 'student'),
      ])),
    ));
    await tester.pump();
    expect(find.text('Mwalimu'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
  });
}
