import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/welcome_screen.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/signup_screen.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/forgot_password_screen.dart';

/// Flutter tests draw text in a block font (every letter a full square), far
/// wider than a phone's. For the screen-size checks, load a real system font as
/// "Roboto" when one is available so text measures like on a device.
Future<bool> _loadDeviceLikeFont() async {
  const candidates = [
    'C:/Windows/Fonts/segoeui.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/System/Library/Fonts/Supplemental/Arial.ttf',
  ];
  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) continue;
    final bytes = file.readAsBytesSync();
    final loader = FontLoader('Roboto')..addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
    return true;
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'somasmart_language': 'sw'});
    prefs = await SharedPreferences.getInstance();
  });

  group('WelcomeScreen Widget Tests', () {
    Widget welcome(SharedPreferences p, {ThemeData? theme}) => ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(p)],
          child: MaterialApp(theme: theme, home: const WelcomeScreen()),
        );

    testWidgets('renders brand, Swahili headline, features, Get Started and Log in', (tester) async {
      await tester.pumpWidget(welcome(prefs));
      await tester.pumpAndSettle();

      expect(find.text('SomaSmart', findRichText: true), findsOneWidget);
      expect(find.text('Mustakabali mzuri\nunaanzia hapa'), findsOneWidget);
      expect(find.text('Anza Sasa'), findsOneWidget);
      expect(find.byKey(const Key('welcome-login')), findsOneWidget);
      expect(find.text('Una akaunti tayari? Ingia', findRichText: true), findsOneWidget);
      expect(find.text('Muhtasari\nwa masomo'), findsOneWidget);
      expect(find.text('Video\nza masomo'), findsOneWidget);
      expect(find.text('Majaribio\nya maabara'), findsOneWidget);
      expect(find.text('Mwalimu\nwa AI'), findsOneWidget);
      expect(find.text('SW'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
    });

    testWidgets('renders in English when language is en', (tester) async {
      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final enPrefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(welcome(enPrefs));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('A brighter future\nstarts here'), findsOneWidget);
      expect(find.text('Already have an account? Log in', findRichText: true), findsOneWidget);
      expect(find.text('Study\nnotes'), findsOneWidget);
      expect(find.text('AI\ntutor'), findsOneWidget);
    });

    testWidgets('the language switch changes the language', (tester) async {
      await tester.pumpWidget(welcome(prefs));
      await tester.pumpAndSettle();
      expect(find.text('Anza Sasa'), findsOneWidget);

      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.text('Get Started'), findsOneWidget);
      expect(prefs.getString('somasmart_language'), 'en');
    });

    testWidgets('renders in Dark Theme without crashing and preserves light-only visuals', (tester) async {
      await tester.pumpWidget(welcome(prefs, theme: ThemeData.dark()));
      await tester.pumpAndSettle();

      expect(find.text('SomaSmart', findRichText: true), findsOneWidget);
      expect(find.text('Muhtasari\nwa masomo'), findsOneWidget);
    });

    // Real phone and tablet sizes (logical pixels). Any overflow fails the test.
    const sizes = <String, Size>{
      'small phone 320x568': Size(320, 568),
      'phone 360x640': Size(360, 640),
      'phone 390x844': Size(390, 844),
      'large phone 412x915': Size(412, 915),
      'tablet 768x1024': Size(768, 1024),
      'phone landscape 844x390': Size(844, 390),
      'tablet landscape 1280x800': Size(1280, 800),
    };
    var realisticFont = false;
    setUpAll(() async => realisticFont = await _loadDeviceLikeFont());

    for (final entry in sizes.entries) {
      testWidgets('lays out without overflow on ${entry.key}', (tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(welcome(prefs));
        await tester.pumpAndSettle();

        final button = find.byKey(const Key('welcome-get-started'));
        expect(button, findsOneWidget);
        final portrait = entry.value.height > entry.value.width;
        if (portrait && realisticFont) {
          // With device-like text, Get Started sits near the bottom and fully on screen.
          final rect = tester.getRect(button);
          expect(rect.bottom, lessThanOrEqualTo(entry.value.height));
          expect(rect.top, greaterThan(entry.value.height * 0.70));
        } else {
          // Otherwise it must at least be reachable by scrolling.
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          expect(tester.getRect(button).bottom, lessThanOrEqualTo(entry.value.height));
        }
      });
    }
  });

  group('LoginScreen Widget Tests', () {
    testWidgets('renders login form, branding, and validates empty input fields',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('SomaSmart'), findsOneWidget);
      expect(find.text('Karibu Tena'), findsOneWidget);
      expect(find.text('Ingia'), findsOneWidget);
      expect(find.text('Nikumbuke'), findsOneWidget);
      expect(find.text('Umesahau nenosiri?'), findsOneWidget);

      // Tap Sign In without filling form
      await tester.tap(find.text('Ingia'));
      await tester.pumpAndSettle();

      expect(find.text('Tafadhali weka nambari yako ya simu.'), findsOneWidget);
    });

    testWidgets('renders login in English when language is en',
        (tester) async {
      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final enPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(enPrefs),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue your learning journey.'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);

      // Guest access was removed: every app route needs a session.
      expect(find.text('Continue as Guest'), findsNothing);
    });

    testWidgets('validates invalid phone number format', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, '123');
      await tester.enterText(find.byType(TextFormField).last, '123456');

      await tester.tap(find.text('Ingia'));
      await tester.pumpAndSettle();

      expect(find.text('Nambari ya simu si sahihi.'), findsOneWidget);
    });
  });

  group('SignUpScreen Widget Tests', () {
    testWidgets('renders only Full Name, Phone, Password, and collapsible optional Email (no Form Level)',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: SignUpScreen(),
          ),
        ),
      );

      expect(find.text('Fungua Akaunti Mpya'), findsOneWidget);
      expect(find.text('Jisajili'), findsOneWidget);

      // Confirm required fields
      expect(find.text('Jina Kamili *'), findsOneWidget);
      expect(find.text('Nambari ya Simu *'), findsOneWidget);
      expect(find.text('Nenosiri *'), findsOneWidget);

      // Confirm Form Level / Class picker is removed
      expect(find.text('Darasa / Kidato'), findsNothing);
      expect(find.text('Academic Form Level'), findsNothing);
      expect(find.text('Kidato cha 4 (O-Level)'), findsNothing);

      // Verify instructional placeholders exist
      expect(find.text('Weka jina lako kamili'), findsOneWidget);
      expect(find.text('Weka nambari yako ya simu'), findsOneWidget);
      expect(find.text('Tengeneza nenosiri'), findsOneWidget);

      // Email field is initially collapsed
      expect(find.text('+ Ongeza Barua Pepe (Si lazima)'), findsOneWidget);

      // Tap + Add Email to reveal email input
      await tester.tap(find.text('+ Ongeza Barua Pepe (Si lazima)'));
      await tester.pumpAndSettle();

      expect(find.text('Barua Pepe'), findsOneWidget);
      expect(find.text('Weka barua pepe yako'), findsOneWidget);

      // Tap close icon to collapse again
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('+ Ongeza Barua Pepe (Si lazima)'), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('renders reset password tabs, phone input, and contact support card',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      expect(find.text('Umesahau Nenosiri?'), findsOneWidget);
      expect(find.text('Simu (SMS)'), findsOneWidget);
      expect(find.text('Barua Pepe'), findsOneWidget);
      expect(find.text('Endelea'), findsOneWidget);
      expect(find.text('Tuma Nambari ya OTP'), findsNothing);
      expect(find.text('Wasiliana na Msaada'), findsOneWidget);
    });

    testWidgets('phone reset sends no OTP and points to support instead', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, '0712345678');
      await tester.ensureVisible(find.text('Endelea'));
      await tester.tap(find.text('Endelea'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Kuweka upya nenosiri kwa SMS hakupatikani bado'), findsOneWidget);
      expect(find.text('Nambari ya OTP ya SMS'), findsNothing);
    });
  });
}
