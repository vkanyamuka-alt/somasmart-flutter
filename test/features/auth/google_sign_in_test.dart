import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/config/env.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/auth/data/google_profile.dart';
import 'package:somasmart_flutter/features/auth/presentation/controllers/auth_controller.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/complete_profile_screen.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:somasmart_flutter/features/auth/presentation/widgets/google_sign_in_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

User _user(Map<String, dynamic> appMetadata, {List<UserIdentity>? identities}) => User(
      id: 'u1',
      appMetadata: appMetadata,
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '2026-11-07T00:00:00Z',
      identities: identities,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('google_profile', () {
    final google = _user({'provider': 'google', 'providers': ['google']});
    final email = _user({'provider': 'email', 'providers': ['email']});
    final linked = _user({'provider': 'email', 'providers': ['email', 'google']});

    test('signedInWithGoogle reads providers or provider', () {
      expect(signedInWithGoogle(google), isTrue);
      expect(signedInWithGoogle(linked), isTrue);
      expect(signedInWithGoogle(_user({'provider': 'google'})), isTrue);
      expect(signedInWithGoogle(email), isFalse);
      expect(signedInWithGoogle(null), isFalse);
    });

    test('only a Google student without a phone must finish the profile', () {
      expect(needsProfileCompletion(google, null), isTrue);
      expect(needsProfileCompletion(google, ''), isTrue);
      expect(needsProfileCompletion(google, '  '), isTrue);
      expect(needsProfileCompletion(google, '+255712345678'), isFalse);
      // Older email accounts without a phone are left alone.
      expect(needsProfileCompletion(email, null), isFalse);
      expect(needsProfileCompletion(null, null), isFalse);
    });
  });

  test('a build made without any --dart-define has Google sign-in', () {
    // Guards against shipping the old sign-in screen again.
    expect(Env.googleWebClientId, endsWith('.apps.googleusercontent.com'));
    expect(Env.googleSignInConfigured, isTrue);
    // Release builds without --dart-define still point at production.
    expect(Env.supabaseUrl, 'https://jgdsinabjhytasybgtix.supabase.co');
  });

  test('a phone number taken by another account gets its own message', () {
    expect(
      AuthController.getLocalizedErrorMessage(AuthController.phoneTakenCode, 'en'),
      contains('already has a SomaSmart account'),
    );
    expect(
      AuthController.getLocalizedErrorMessage(AuthController.phoneTakenCode, 'sw'),
      contains('tayari ina akaunti'),
    );
  });

  group('screens', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      prefs = await SharedPreferences.getInstance();
    });

    Widget app(Widget home) => ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(home: Scaffold(body: home)),
        );

    testWidgets('the login screen shows Continue with Google', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: LoginScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('google-sign-in')), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('the Google section draws nothing when turned off', (tester) async {
      await tester.pumpWidget(app(GoogleSignInSection(onError: (_) {}, enabledOverride: false)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('google-sign-in')), findsNothing);
    });

    testWidgets('the Google section draws the divider and button when configured', (tester) async {
      await tester.pumpWidget(app(GoogleSignInSection(onError: (_) {}, enabledOverride: true)));
      await tester.pumpAndSettle();
      expect(find.text('or'), findsOneWidget);
      expect(find.byKey(const Key('google-sign-in')), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('finishing the profile needs a valid phone number and a form', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const MaterialApp(home: CompleteProfileScreen()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Finish your account'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('complete-name')), 'Asha Juma');
      await tester.enterText(find.byKey(const Key('complete-phone')), '0712');
      await tester.ensureVisible(find.byKey(const Key('complete-profile-submit')));
      await tester.tap(find.byKey(const Key('complete-profile-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid phone number (e.g. 07XXXXXXXX).'), findsOneWidget);
      expect(find.text('Please choose your form.'), findsOneWidget);
    });
  });
}
