import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';

/// The website runs the same cases (src/lib/accessStatusCases.json) against
/// src/lib/accessStatus.js, so both apps show the same status and days.
void main() {
  final shared = jsonDecode(File('test/fixtures/access_status_cases.json').readAsStringSync())
      as Map<String, dynamic>;
  final now = DateTime.parse(shared['now'] as String);

  DateTime? date(Object? v) => v == null ? null : DateTime.parse(v as String);

  group('UserProfile.accessAt: shared cases', () {
    for (final c in (shared['cases'] as List).cast<Map<String, dynamic>>()) {
      test(c['name'], () {
        final p = (c['profile'] as Map).cast<String, dynamic>();
        final profile = UserProfile.fromSupabase({
          'id': 'case',
          'subscription_status': p['subscription_status'] ?? 'free',
          'role': p['role'] ?? 'student',
          'free_access': p['free_access'] ?? false,
          'subscription_expires_at': p['subscription_expires_at'],
          'created_at': p['created_at'],
        }, null);
        final e = (c['expect'] as Map).cast<String, dynamic>();
        final s = profile.accessAt(now);

        expect(s.kind.name, e['kind']);
        expect(s.days, e['days']);
        expect(s.endsAt?.toUtc(), date(e['endsAt'])?.toUtc());
      });
    }
  });

  test('the fixture is the same file as the website copy', () {
    // Only checkable when the website checkout sits next to this one.
    for (final path in ['../SomaSmart App/src/lib/accessStatusCases.json', '../web/src/lib/accessStatusCases.json']) {
      final web = File(path);
      if (web.existsSync()) {
        expect(File('test/fixtures/access_status_cases.json').readAsStringSync(), web.readAsStringSync());
      }
    }
  });
}
