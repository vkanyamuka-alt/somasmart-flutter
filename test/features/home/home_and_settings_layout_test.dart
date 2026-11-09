import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/services/support_contact_service.dart';
import 'package:somasmart_flutter/core/theme/app_theme.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/home/presentation/screens/home_screen.dart';
import 'package:somasmart_flutter/features/settings/presentation/controllers/settings_controller.dart';
import 'package:somasmart_flutter/features/settings/presentation/screens/settings_screen.dart';

/// Loads a real system font as "Roboto" so text measures like on a device
/// (the default test font draws every letter as a full square).
Future<bool> _loadDeviceLikeFont() async {
  const candidates = [
    'C:/Windows/Fonts/segoeui.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/System/Library/Fonts/Supplemental/Arial.ttf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final loader = FontLoader('Roboto')..addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    await loader.load();
    return true;
  }
  return false;
}

/// The app's Inter comes from google_fonts, which cannot load in tests; use
/// the device-like font loaded above so widths are realistic.
ThemeData _deviceFont(ThemeData t) => t.copyWith(textTheme: t.textTheme.apply(fontFamily: 'Roboto'));

final _trialStudent = UserProfile(
  id: 'trial',
  email: '255711000000@phone.somasmart.com',
  fullName: 'Rehema Hassan',
  phone: '+255711000000',
  role: 'student',
  subscriptionStatus: 'free',
  createdAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
);

void main() {
  late SharedPreferences prefs;

  setUpAll(() async => _loadDeviceLikeFont());
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget app(Widget home, {String lang = 'en', ThemeData? theme, UserProfile? profile, SupportContact contact = const SupportContact(), UserProfileNotifier? profileNotifier}) => ProviderScope(
        overrides: [
          supportContactProvider.overrideWith((ref) async => contact),
          sharedPreferencesProvider.overrideWithValue(prefs),
          languageProvider.overrideWith((ref) => _TestLanguageNotifier(lang)),
          userProfileProvider.overrideWith(() => profileNotifier ?? _MockProfileNotifier(profile ?? _trialStudent)),
        ],
        child: MaterialApp(theme: _deviceFont(theme ?? AppTheme.lightTheme), home: home),
      );

  group('Trial day count (same rule as the web)', () {
    UserProfile createdDaysAgo(double days) => UserProfile(
          id: 't',
          email: 't@x.tz',
          fullName: 'T',
          phone: '',
          role: 'student',
          subscriptionStatus: 'free',
          createdAt: DateTime.now().toUtc().subtract(Duration(minutes: (days * 24 * 60).round())),
        );

    test('a brand-new account shows 6 days, not 7', () {
      expect(createdDaysAgo(0).access.days, 6);
    });

    test('part of a day counts as a day', () {
      expect(createdDaysAgo(2.5).access.days, 4);
      expect(createdDaysAgo(5.9).access.days, 1);
    });
  });

  group('Home access card', () {
    testWidgets('a profile that fails to load shows no card, never "Subscription Expired"', (tester) async {
      await tester.pumpWidget(app(const HomeScreen(), profileNotifier: _FailingProfileNotifier()));
      await tester.pumpAndSettle();
      expect(find.text('Subscription Expired'), findsNothing);
      expect(find.text('Days Remaining'), findsNothing);
    });

    testWidgets('a trial student sees the trial days from the one rule', (tester) async {
      await tester.pumpWidget(app(const HomeScreen()));
      await tester.pumpAndSettle();
      expect(find.text('${_trialStudent.access.days} '), findsOneWidget);
      expect(find.text('Days Remaining'), findsOneWidget);
      expect(find.text('Free Trial'), findsOneWidget);
    });

    testWidgets('free access shows "Full Access", not a day count', (tester) async {
      final free = UserProfile(id: 'f', email: 'f@x.tz', fullName: 'Asha Free', phone: '', role: 'student', subscriptionStatus: 'free', freeAccess: true);
      await tester.pumpWidget(app(const HomeScreen(), profile: free));
      await tester.pumpAndSettle();
      expect(find.text('Full Access'), findsOneWidget);
      expect(find.text('Days Remaining'), findsNothing);
    });
  });

  group('Home dashboard', () {
    testWidgets('shows all seven tiles, with the forum tile across the full width', (tester) async {
      await tester.pumpWidget(app(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Hi, Rehema'), findsOneWidget);
      for (final key in ['o-level', 'a-level', 'syllabus', 'practicals', 'past-papers', 'quiz-exams', 'forum']) {
        expect(find.byKey(Key('home-card-$key')), findsOneWidget, reason: key);
      }
      expect(find.text('Free Trial'), findsOneWidget);

      final forum = tester.getRect(find.byKey(const Key('home-card-forum')));
      final oLevel = tester.getRect(find.byKey(const Key('home-card-o-level')));
      final aLevel = tester.getRect(find.byKey(const Key('home-card-a-level')));
      expect(forum.left, moreOrLessEquals(oLevel.left));
      expect(forum.right, moreOrLessEquals(aLevel.right));
      expect(forum.height, moreOrLessEquals(oLevel.height, epsilon: 0.5));
    });

    testWidgets('speaks Swahili, including the headline', (tester) async {
      await tester.pumpWidget(app(const HomeScreen(), lang: 'sw'));
      await tester.pumpAndSettle();

      expect(find.text('Habari, Rehema'), findsOneWidget);
      expect(find.text('Jifunze.'), findsOneWidget);
      expect(find.text('Jukwaa la majadiliano'), findsOneWidget);
      expect(find.text('Jaribio la Bure'), findsOneWidget);

      // Long tile names wrap to a second line instead of being cut off.
      for (final name in ['Mitihani ya zamani', 'Majaribio na mitihani']) {
        final text = tester.renderObject<RenderParagraph>(find.text(name));
        expect(text.didExceedMaxLines, isFalse, reason: name);
      }
    });

    testWidgets('never falls back to a made-up name', (tester) async {
      final unnamed = UserProfile(
        id: 'u',
        email: 'u@x.tz',
        fullName: 'User',
        phone: '',
        role: 'student',
        subscriptionStatus: 'free',
        createdAt: DateTime.now().toUtc(),
      );
      await tester.pumpWidget(app(const HomeScreen(), profile: unnamed));
      await tester.pumpAndSettle();
      expect(find.text('Hi, Student'), findsOneWidget);
      expect(find.textContaining('Anna'), findsNothing);
    });

    const sizes = <String, Size>{
      'small phone 320x568': Size(320, 568),
      'phone 360x640': Size(360, 640),
      'phone 390x844': Size(390, 844),
      'tablet 768x1024': Size(768, 1024),
      'tablet landscape 1280x800': Size(1280, 800),
    };
    for (final entry in sizes.entries) {
      for (final dark in [false, true]) {
        testWidgets('lays out without overflow on ${entry.key}${dark ? ' (dark)' : ''}', (tester) async {
          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          await tester.pumpWidget(app(const HomeScreen(), lang: 'sw', theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme));
          await tester.pumpAndSettle();

          final forum = find.byKey(const Key('home-card-forum'));
          await tester.ensureVisible(forum);
          await tester.pumpAndSettle();
          expect(tester.getRect(forum).right, lessThanOrEqualTo(entry.value.width));
        });
      }
    }
  });

  group('Settings', () {
    testWidgets('shows the same groups as the web Settings page, each feature once', (tester) async {
      await tester.pumpWidget(app(const SettingsScreen()));
      await tester.pumpAndSettle();

      for (final label in ['APPEARANCE', 'NOTIFICATIONS', 'SUPPORT', 'LEGAL', 'DELETE ACCOUNT']) {
        await tester.ensureVisible(find.text(label));
        expect(find.text(label), findsOneWidget, reason: label);
      }
      // The profile lives on the Account tab, not here.
      expect(find.text('ACCOUNT'), findsNothing);
      expect(find.text('Rehema Hassan'), findsNothing);
      expect(find.byKey(const Key('settings-theme-system')), findsOneWidget);
      expect(find.byKey(const Key('settings-share')), findsOneWidget);
      expect(find.byKey(const Key('settings-row-feedback')), findsOneWidget);
      expect(find.byKey(const Key('settings-sign-out')), findsOneWidget);
    });

    testWidgets('Share copies the real link', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied.add((call.arguments as Map)['text'] as String);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      await tester.pumpWidget(app(const SettingsScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('settings-share')));
      await tester.tap(find.byKey(const Key('settings-share')));
      await tester.pump();
      expect(copied, ['https://meek-marzipan-3fc8ef.netlify.app']);
    });

    testWidgets('feedback says so honestly when no support contact is set', (tester) async {
      await tester.pumpWidget(app(const SettingsScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('settings-row-feedback')));
      await tester.tap(find.byKey(const Key('settings-row-feedback')));
      await tester.pumpAndSettle();

      expect(find.textContaining('once SomaSmart has added its support contact'), findsOneWidget);
      expect(find.byKey(const Key('settings-feedback-whatsapp')), findsNothing);
    });

    testWidgets('feedback sends through the admin-set contact once written', (tester) async {
      await tester.pumpWidget(app(
        const SettingsScreen(),
        contact: const SupportContact(phone: '+255712345678', email: 'help@example.co.tz'),
      ));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('settings-row-feedback')));
      await tester.tap(find.byKey(const Key('settings-row-feedback')));
      await tester.pumpAndSettle();

      FilledButton whatsapp() => tester.widget<FilledButton>(find.byKey(const Key('settings-feedback-whatsapp')));
      expect(whatsapp().onPressed, isNull, reason: 'nothing to send yet');
      await tester.enterText(find.byKey(const Key('settings-feedback-text')), 'Great notes');
      await tester.pump();
      expect(whatsapp().onPressed, isNotNull);
      expect(find.byKey(const Key('settings-feedback-email')), findsOneWidget);
    });

    testWidgets('choosing System saves it', (tester) async {
      await tester.pumpWidget(app(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings-theme-system')));
      await tester.pumpAndSettle();
      expect(prefs.getString('somasmart_theme_mode'), 'system');
    });

    testWidgets('account deletion is a request to support, not a fake delete button', (tester) async {
      await tester.pumpWidget(app(const SettingsScreen()));
      await tester.pumpAndSettle();

      final row = find.byKey(const Key('settings-row-delete'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('settings-delete-contact')), findsOneWidget);
      expect(find.text('Yes, Delete'), findsNothing);
      expect(find.text('Account deletion request submitted.'), findsNothing);
    });

    testWidgets('sign out asks for confirmation first', (tester) async {
      await tester.pumpWidget(app(const SettingsScreen()));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('settings-sign-out')));
      await tester.tap(find.byKey(const Key('settings-sign-out')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-confirm-sign-out')), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('settings-confirm-sign-out')), findsNothing);
    });

    testWidgets('lays out without overflow on a small phone in Swahili', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(app(const SettingsScreen(), lang: 'sw', theme: AppTheme.darkTheme));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('settings-row-delete')));
      await tester.pumpAndSettle();
    });
  });
}

class _TestLanguageNotifier extends StateNotifier<String> implements LanguageNotifier {
  _TestLanguageNotifier(super.state);

  @override
  Future<void> setLanguage(String lang) async => state = lang;
}

class _MockProfileNotifier extends UserProfileNotifier {
  final UserProfile? _profile;
  _MockProfileNotifier(this._profile);

  @override
  Future<UserProfile?> build() async => _profile;
}

class _FailingProfileNotifier extends UserProfileNotifier {
  @override
  Future<UserProfile?> build() async => throw Exception('offline');
}
