import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/welcome_screen.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/signup_screen.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/forgot_password_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'somasmart_language': 'sw'});
    prefs = await SharedPreferences.getInstance();
  });

  group('WelcomeScreen Widget Tests', () {
    testWidgets('renders official S logo mark, SomaSmart branding, Swahili headline & value proposition, and Get Started button',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      // Logo and background image assets
      expect(find.byType(Image), findsNWidgets(2));
      expect(find.text('Soma', findRichText: true), findsOneWidget);
      expect(find.text('Smart', findRichText: true), findsOneWidget);
      expect(find.text('Mustakabali\nMzuri Unaanzia\nHapa'), findsOneWidget);
      expect(find.text('Anza Sasa'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
      expect(
        find.text(
          'Muhtasari wa masomo ya O-Level na A-Level, Video,\nmajaribio ya maabara na mwalimu wa AI.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Jifunze kwa ufanisi. Fika mbali na SomaSmart.'),
        findsOneWidget,
      );
      // 4 Feature Pillars (Swahili)
      expect(find.text('Muhtasari\nwa Masomo'), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      expect(find.text('Majaribio ya\nMaabara'), findsOneWidget);
      expect(find.text('Msaada wa\nMwalimu wa AI'), findsOneWidget);
      // Ensure no Sign In button or pagination dots on WelcomeScreen
      expect(find.text('Sign In'), findsNothing);
      expect(find.text('Ingia kwenye Akaunti'), findsNothing);
    });

    testWidgets('renders in English when language is en', (tester) async {
      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final enPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(enPrefs),
          ],
          child: const MaterialApp(
            home: WelcomeScreen(),
          ),
        ),
      );

      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('A Brighter\nFuture Starts\nHere'), findsOneWidget);
      expect(
        find.text(
          'O-level & A-level notes, Videos,\npractical simulations and AI tutor.',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Study smarter. Go further with SomaSmart.'),
        findsOneWidget,
      );
      // 4 Feature Pillars (English)
      expect(find.text('Comprehensive\nNotes'), findsOneWidget);
      expect(find.text('Videos'), findsOneWidget);
      expect(find.text('Practical\nSimulations'), findsOneWidget);
      expect(find.text('AI Tutor\nSupport'), findsOneWidget);
      // Ensure no Sign In button on WelcomeScreen
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('renders in Dark Theme without crashing and preserves light-only visuals', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const WelcomeScreen(),
          ),
        ),
      );

      expect(find.text('Soma', findRichText: true), findsOneWidget);
      expect(find.text('Smart', findRichText: true), findsOneWidget);
      expect(find.text('Muhtasari\nwa Masomo'), findsOneWidget);
    });
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
    testWidgets('renders reset password tabs, phone OTP input, and contact support card',
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
      expect(find.text('Tuma Nambari ya OTP'), findsOneWidget);
      expect(find.text('Wasiliana na Msaada'), findsOneWidget);
    });
  });
}
