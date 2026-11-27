import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/services/announcements_service.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/core/widgets/notification_drawer.dart';

void main() {
  final now = DateTime.utc(2026, 10, 29, 12);
  final sample = [
    Announcement(id: 'old', title: 'Old', content: 'a', createdAt: DateTime.utc(2026, 10, 1)),
    Announcement(id: 'new', title: 'Exam timetable', content: 'Form 4 mocks start Monday', createdAt: DateTime.utc(2026, 10, 20), expiresAt: DateTime.utc(2026, 11, 1)),
    Announcement(id: 'off', title: 'Off', content: 'c', createdAt: DateTime.utc(2026, 10, 25), isActive: false),
    Announcement(id: 'gone', title: 'Gone', content: 'd', createdAt: DateTime.utc(2026, 10, 26), expiresAt: DateTime.utc(2026, 10, 28)),
  ];

  test('keeps active, unexpired announcements, newest first (same rule as the web)', () {
    expect(visibleAnnouncements(sample, now).map((a) => a.id), ['new', 'old']);
  });

  Future<ProviderContainer> pumpDrawer(WidgetTester tester, List<Announcement> items) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      announcementsProvider.overrideWith((ref) async => items),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: NotificationDrawer())),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('the drawer lists what admins posted and marks it read', (tester) async {
    final container = await pumpDrawer(tester, visibleAnnouncements(sample, now));

    expect(find.text('Exam timetable'), findsOneWidget);
    expect(find.text('Form 4 mocks start Monday'), findsOneWidget);
    expect(find.text('2 mpya'), findsOneWidget); // the app defaults to Swahili
    // Made-up release notes are gone.
    expect(find.textContaining('Offline Mode'), findsNothing);
    expect(container.read(unreadAnnouncementsCountProvider), 0);
  });

  testWidgets('with nothing posted, it says so', (tester) async {
    await pumpDrawer(tester, const []);
    expect(find.text('Hakuna matangazo kwa sasa'), findsOneWidget);
  });
}
