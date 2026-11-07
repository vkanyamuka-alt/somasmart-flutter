import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/services/push/push_controller.dart';
import 'package:somasmart_flutter/core/services/push/push_messaging.dart';
import 'package:somasmart_flutter/core/services/push/push_providers.dart';
import 'package:somasmart_flutter/core/services/push/push_routing.dart';
import 'package:somasmart_flutter/core/services/support_contact_service.dart';
import 'package:somasmart_flutter/core/theme/app_theme.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/settings/data/study_reminder.dart';
import 'package:somasmart_flutter/features/settings/presentation/controllers/settings_controller.dart';
import 'package:somasmart_flutter/features/settings/presentation/screens/settings_screen.dart';
import 'package:somasmart_flutter/features/settings/presentation/widgets/study_reminder_flow.dart';

class FakeMessaging implements PushMessaging {
  bool configured = true;
  PushPermission current = PushPermission.notDetermined;
  PushPermission answer = PushPermission.granted; // what the student taps in Android's dialog
  int permissionDialogs = 0;
  String? token = 'fcm-token-1';
  int deleted = 0;
  PushMessage? initial;
  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();

  @override
  Future<bool> initialize() async => configured;
  @override
  Future<PushPermission> permission() async => current;
  @override
  Future<PushPermission> requestPermission() async {
    permissionDialogs++;
    if (current == PushPermission.notDetermined) current = answer;
    return current;
  }

  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> deleteToken() async {
    deleted++;
    token = null;
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Stream<PushMessage> get onForegroundMessage => foreground.stream;
  @override
  Stream<PushMessage> get onMessageOpenedApp => opened.stream;
  @override
  Future<PushMessage?> getInitialMessage() async => initial;
}

class FakeBackend implements PushBackend {
  final registered = <String>[];
  final removed = <String>[];
  bool fail = false;

  @override
  Future<void> register(String token) async {
    if (fail) throw Exception('offline');
    registered.add(token);
  }

  @override
  Future<void> remove(String token) async => removed.add(token);

  @override
  Future<int> sendTest(String language) async => 1;
}

void main() {
  group('Where a tapped notification opens', () {
    test('announcements open home with the announcements sheet', () {
      expect(pushTargetFor({'type': 'announcement', 'route': '/forum'}), const PushTarget('/home', openAnnouncements: true));
    });

    test('a study reminder opens its route', () {
      expect(pushTargetFor({'type': 'study_reminder', 'route': '/home'}), const PushTarget('/home'));
      expect(pushTargetFor({'route': '/quiz-exams?tab=past_paper'}), const PushTarget('/quiz-exams?tab=past_paper'));
      expect(pushTargetFor({'route': '/forum/123'}), const PushTarget('/forum/123'));
    });

    test('unknown, empty or outside links go home instead', () {
      for (final route in ['', 'home', '/nowhere', '//evil.example', 'https://evil.example/home', '/', 'javascript:alert(1)']) {
        expect(pushTargetFor({'route': route}), const PushTarget('/home'), reason: route);
      }
      expect(pushTargetFor({}), const PushTarget('/home'));
    });

    test('the app waits on splash and sign-in screens before opening', () {
      for (final p in ['/splash', '/welcome', '/login', '/signup', '/']) {
        expect(isPushHoldingRoute(p), isTrue, reason: p);
      }
      expect(isPushHoldingRoute('/home'), isFalse);
      expect(isPushHoldingRoute('/settings'), isFalse);
    });
  });

  group('Time zone sent with the reminder', () {
    test('Tanzania (UTC+3) is Africa/Dar_es_Salaam', () {
      expect(timeZoneForOffset(const Duration(hours: 3)), 'Africa/Dar_es_Salaam');
    });
    test('other whole-hour offsets use Etc/GMT with the inverted sign', () {
      expect(timeZoneForOffset(const Duration(hours: 2)), 'Etc/GMT-2');
      expect(timeZoneForOffset(const Duration(hours: -5)), 'Etc/GMT+5');
      expect(timeZoneForOffset(Duration.zero), 'Etc/GMT');
    });
    test('half-hour offsets fall back to Tanzania', () {
      expect(timeZoneForOffset(const Duration(hours: 5, minutes: 30)), 'Africa/Dar_es_Salaam');
    });
  });

  group('StudyReminder', () {
    test('reads Postgres times and rejects nonsense', () {
      expect(StudyReminder.parseTime('18:30:00'), const TimeOfDay(hour: 18, minute: 30));
      expect(StudyReminder.parseTime('7:05'), const TimeOfDay(hour: 7, minute: 5));
      expect(StudyReminder.parseTime('25:00'), StudyReminder.defaultTime);
      expect(StudyReminder.parseTime(null), StudyReminder.defaultTime);
    });

    test('row for Supabase: zero-padded time, zone and language', () {
      final row = const StudyReminder(enabled: true, time: TimeOfDay(hour: 6, minute: 5))
          .toRow(userId: 'u1', language: 'fr', utcOffset: const Duration(hours: 3));
      expect(row, {
        'user_id': 'u1',
        'enabled': true,
        'remind_at': '06:05',
        'time_zone': 'Africa/Dar_es_Salaam',
        'language': 'sw',
      });
    });
  });

  group('PushController', () {
    late FakeMessaging messaging;
    late FakeBackend backend;
    late SharedPreferences prefs;
    late bool signedIn;
    late StreamController<bool> auth;
    late List<PushTarget> opened;
    late List<PushMessage> shown;
    var today = DateTime(2026, 11, 7, 9);

    PushController make() => PushController(
          messaging: messaging,
          backend: backend,
          prefs: prefs,
          isSignedIn: () => signedIn,
          signedInChanges: auth.stream,
          onOpen: opened.add,
          onForeground: shown.add,
          now: () => today,
        );

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      messaging = FakeMessaging();
      backend = FakeBackend();
      signedIn = true;
      auth = StreamController<bool>.broadcast();
      opened = [];
      shown = [];
      today = DateTime(2026, 11, 7, 9);
    });

    test('first launch on Android 13+: no permission dialog, nothing registered', () async {
      final c = make();
      await c.start();
      expect(c.available, isTrue);
      expect(messaging.permissionDialogs, 0);
      expect(backend.registered, isEmpty);
      expect(c.enabled, isFalse);
    });

    test('Android 12 and older (already allowed): registers on start without asking', () async {
      messaging.current = PushPermission.granted;
      final c = make();
      await c.start();
      expect(messaging.permissionDialogs, 0);
      expect(backend.registered, ['fcm-token-1']);
      expect(c.enabled, isTrue);
    });

    test('turning notifications on asks once, then registers', () async {
      final c = make();
      await c.start();
      expect(await c.enable(), PushPermission.granted);
      expect(messaging.permissionDialogs, 1);
      expect(backend.registered, ['fcm-token-1']);
      expect(c.enabled, isTrue);
    });

    test('a student who says "Don\'t allow" is not registered', () async {
      messaging.answer = PushPermission.denied;
      final c = make();
      await c.start();
      expect(await c.enable(), PushPermission.denied);
      expect(backend.registered, isEmpty);
      expect(c.enabled, isFalse);
    });

    test('signed-out phones are never registered; signing in registers', () async {
      messaging.current = PushPermission.granted;
      signedIn = false;
      final c = make();
      await c.start();
      expect(backend.registered, isEmpty);
      signedIn = true;
      auth.add(true);
      await pumpEventQueue();
      expect(backend.registered, ['fcm-token-1']);
    });

    test('the same token is not sent twice, a refreshed one is', () async {
      messaging.current = PushPermission.granted;
      final c = make();
      await c.start();
      auth.add(true); // initialSession after start
      await pumpEventQueue();
      expect(backend.registered, ['fcm-token-1']);
      messaging.refresh.add('fcm-token-2');
      await pumpEventQueue();
      expect(backend.registered, ['fcm-token-1', 'fcm-token-2']);
    });

    test('sign-out removes the server row and the phone token', () async {
      messaging.current = PushPermission.granted;
      final c = make();
      await c.start();
      await c.unregisterForSignOut();
      expect(backend.removed, ['fcm-token-1']);
      expect(messaging.deleted, 1);
    });

    test('a session ending elsewhere deletes the phone token', () async {
      messaging.current = PushPermission.granted;
      final c = make();
      await c.start();
      auth.add(false);
      await pumpEventQueue();
      expect(messaging.deleted, 1);
    });

    test('switching notifications off removes this phone and stays off', () async {
      messaging.current = PushPermission.granted;
      final c = make();
      await c.start();
      await c.disable();
      expect(backend.removed, ['fcm-token-1']);
      expect(c.enabled, isFalse);
      messaging.refresh.add('fcm-token-2');
      await pumpEventQueue();
      expect(backend.registered, ['fcm-token-1']);
    });

    test('a failed registration is retried next time', () async {
      messaging.current = PushPermission.granted;
      backend.fail = true;
      final c = make();
      await c.start();
      expect(backend.registered, isEmpty);
      backend.fail = false;
      await c.registerIfAllowed();
      expect(backend.registered, ['fcm-token-1']);
    });

    test('builds without Firebase config do nothing', () async {
      messaging.configured = false;
      final c = make();
      await c.start();
      expect(c.available, isFalse);
      expect(await c.enable(), PushPermission.denied);
      expect(messaging.permissionDialogs, 0);
      await c.unregisterForSignOut();
      expect(messaging.deleted, 0);
    });

    test('a tap that launched the app, a tap in the background, and a foreground message', () async {
      messaging.initial = const PushMessage(data: {'type': 'announcement'});
      final c = make();
      await c.start();
      expect(opened, [const PushTarget('/home', openAnnouncements: true)]);

      messaging.opened.add(const PushMessage(data: {'type': 'study_reminder', 'route': '/home'}));
      messaging.foreground.add(const PushMessage(title: 'Muda wa kusoma umefika', data: {'type': 'study_reminder'}));
      await pumpEventQueue();
      expect(opened.last, const PushTarget('/home'));
      expect(shown.single.title, 'Muda wa kusoma umefika');
      c.dispose();
    });

    test('the reminder offer waits until the day after the first launch', () async {
      final c = make();
      await c.start();
      expect(c.usedBeforeToday, isFalse);
      today = DateTime(2026, 11, 7, 23, 59);
      expect(c.usedBeforeToday, isFalse);
      today = DateTime(2026, 11, 8, 7);
      expect(c.usedBeforeToday, isTrue);
    });
  });

  group('Screens', () {
    late SharedPreferences prefs;
    late FakeMessaging messaging;

    setUp(() async {
      SharedPreferences.setMockInitialValues({PushController.prefFirstOpen: '2026-01-01'});
      prefs = await SharedPreferences.getInstance();
      messaging = FakeMessaging();
    });

    Future<PushController> started({bool signedIn = true}) async {
      final c = PushController(
        messaging: messaging,
        backend: FakeBackend(),
        prefs: prefs,
        isSignedIn: () => signedIn,
        signedInChanges: const Stream.empty(),
        onOpen: (_) {},
        onForeground: (_) {},
      );
      await c.start();
      return c;
    }

    Widget wrap(Widget child, PushController c, {StudyReminder? reminder, String lang = 'en'}) => ProviderScope(
          key: UniqueKey(),
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            supportContactProvider.overrideWith((ref) async => const SupportContact()),
            languageProvider.overrideWith((ref) => _Lang(lang)),
            pushControllerProvider.overrideWith((ref) => c),
            studyReminderProvider.overrideWith(() => _Reminder(reminder)),
          ],
          child: MaterialApp(theme: AppTheme.lightTheme, home: Scaffold(body: child)),
        );

    testWidgets('home offers the reminder from day two, and "Not now" hides it for good', (tester) async {
      final c = await started();
      await tester.pumpWidget(wrap(const StudyReminderPrompt(), c));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-reminder-prompt')), findsOneWidget);
      expect(find.text('Want a daily study reminder?'), findsOneWidget);
      expect(messaging.permissionDialogs, 0, reason: 'showing the card must not ask Android yet');

      await tester.tap(find.byKey(const Key('home-reminder-not-now')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-reminder-prompt')), findsNothing);
      expect(prefs.getBool(StudyReminderPrompt.prefDismissed), isTrue);
    });

    testWidgets('no offer on the first day, when a reminder exists, or when signed out', (tester) async {
      await prefs.setString(PushController.prefFirstOpen, '2999-01-01');
      var c = await started();
      await tester.pumpWidget(wrap(const StudyReminderPrompt(), c));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-reminder-prompt')), findsNothing);

      await prefs.setString(PushController.prefFirstOpen, '2026-01-01');
      c = await started();
      await tester.pumpWidget(wrap(const StudyReminderPrompt(), c,
          reminder: const StudyReminder(enabled: false, time: StudyReminder.defaultTime)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-reminder-prompt')), findsNothing);

      c = await started(signedIn: false);
      await tester.pumpWidget(wrap(const StudyReminderPrompt(), c));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('home-reminder-prompt')), findsNothing);
    });

    testWidgets('home offer in Swahili', (tester) async {
      final c = await started();
      await tester.pumpWidget(wrap(const StudyReminderPrompt(), c, lang: 'sw'));
      await tester.pumpAndSettle();
      expect(find.text('Nikukumbushe kusoma kila siku?'), findsOneWidget);
      expect(find.text('Chagua saa'), findsOneWidget);
    });

    testWidgets('settings: switching notifications on asks Android, then shows the test row', (tester) async {
      final c = await started();
      await tester.pumpWidget(wrap(const SettingsScreen(), c));
      await tester.pumpAndSettle();
      expect(find.text('Daily study reminder'), findsOneWidget);
      expect(find.byKey(const Key('settings-test-push')), findsNothing);
      expect(tester.widget<Switch>(find.byKey(const Key('settings-notifications'))).value, isFalse);

      await tester.tap(find.byKey(const Key('settings-notifications')));
      await tester.pumpAndSettle();
      expect(messaging.permissionDialogs, 1);
      expect(tester.widget<Switch>(find.byKey(const Key('settings-notifications'))).value, isTrue);
      expect(find.byKey(const Key('settings-test-push')), findsOneWidget);
    });

    testWidgets('settings: a saved reminder shows its time', (tester) async {
      messaging.current = PushPermission.granted;
      final c = await started();
      await tester.pumpWidget(wrap(const SettingsScreen(), c,
          reminder: const StudyReminder(enabled: true, time: TimeOfDay(hour: 19, minute: 30))));
      await tester.pumpAndSettle();
      expect(find.text('Every day at 19:30. Tap to change.'), findsOneWidget);
      expect(tester.widget<Switch>(find.byKey(const Key('settings-reminder-switch'))).value, isTrue);
    });

    testWidgets('settings: builds without Firebase say so and disable the switches', (tester) async {
      messaging.configured = false;
      final c = await started();
      await tester.pumpWidget(wrap(const SettingsScreen(), c));
      await tester.pumpAndSettle();
      expect(find.text('Not available in this version of the app'), findsOneWidget);
      expect(tester.widget<Switch>(find.byKey(const Key('settings-notifications'))).onChanged, isNull);
      expect(tester.widget<Switch>(find.byKey(const Key('settings-reminder-switch'))).onChanged, isNull);
    });
  });
}

class _Lang extends StateNotifier<String> implements LanguageNotifier {
  _Lang(super.state);
  @override
  Future<void> setLanguage(String lang) async => state = lang;
}

class _Reminder extends StudyReminderNotifier {
  final StudyReminder? initial;
  _Reminder(this.initial);
  @override
  Future<StudyReminder?> build() async => initial;
  @override
  Future<void> save(StudyReminder r, {required String language}) async => state = AsyncData(r);
}
