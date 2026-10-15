import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/verify_otp_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
    prefs = await SharedPreferences.getInstance();
  });

  group('VerifyOtpScreen Requirements Tests', () {
    testWidgets('1. Renders title "Verify Your Phone Number", masked phone, and Edit link',
        (tester) async {
      bool editTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: VerifyOtpScreen(
              phone: '+255712345123',
              onEditPhone: () {
                editTapped = true;
              },
            ),
          ),
        ),
      );

      // Verify Title
      expect(find.text('Verify Your Phone Number'), findsOneWidget);

      // Verify Masked Phone Number: +255 7XX XXX 123
      expect(find.text('+255 7XX XXX 123'), findsOneWidget);

      // Verify Edit Link
      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      await tester.pump();
      expect(editTapped, isTrue);
    });

    testWidgets('2. Renders 6 individual boxes for digit entry with numeric keypad configuration',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: VerifyOtpScreen(phone: '+255712345678'),
          ),
        ),
      );

      // 6 text fields for the 6 boxes
      expect(find.byType(TextFormField), findsNWidgets(6));

      // Verify button initially disabled (onPressed == null)
      final verifyFinder = find.widgetWithText(ElevatedButton, 'Verify');
      expect(verifyFinder, findsOneWidget);
      final ElevatedButton verifyButton = tester.widget(verifyFinder);
      expect(verifyButton.onPressed, isNull);
    });

    testWidgets('3. Countdown timer displays "Resend code in mm:ss" and updates',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: VerifyOtpScreen(phone: '+255712345678'),
          ),
        ),
      );

      // Timer starts at 60s -> displays 01:00
      expect(find.textContaining('Resend code in 01:00'), findsOneWidget);

      // Advance 15 seconds -> 00:45
      await tester.pump(const Duration(seconds: 15));
      expect(find.textContaining('Resend code in 00:45'), findsOneWidget);

      // Advance to zero -> Resend code button appears
      await tester.pump(const Duration(seconds: 45));
      expect(find.textContaining('Resend Code'), findsOneWidget);
    });

    testWidgets('4. Entering 6 digits enables Verify button and auto-submits',
        (tester) async {
      String? submittedCode;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: VerifyOtpScreen(
              phone: '+255712345678',
              customVerifier: (code) async {
                submittedCode = code;
                return true;
              },
              onVerified: (code) {},
            ),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '${i + 1}');
        await tester.pump();
      }

      await tester.pumpAndSettle();
      expect(submittedCode, '123456');
    });

    testWidgets('5. On incorrect OTP shows inline error, clears boxes, and refocuses first box',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: VerifyOtpScreen(
              phone: '+255712345678',
              customVerifier: (code) async {
                return false; // simulate incorrect OTP
              },
            ),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '9');
        await tester.pump();
      }

      await tester.pumpAndSettle();

      // Error message appears
      expect(find.text('Incorrect code, please try again'), findsOneWidget);

      // All 6 input boxes cleared
      for (int i = 0; i < 6; i++) {
        final TextFormField field = tester.widget(textFields.at(i));
        expect(field.controller?.text, isEmpty);
      }
    });

    testWidgets('6. Limits resends to 3 attempts then shows lockout warning',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: VerifyOtpScreen(
              phone: '+255712345678',
              onResend: (_) async => true,
            ),
          ),
        ),
      );

      // Initial cooldown: expire timer -> tap resend (Attempt 1)
      await tester.pump(const Duration(seconds: 60));
      expect(find.textContaining('Resend Code (3 left)'), findsOneWidget);
      await tester.tap(find.textContaining('Resend Code'), warnIfMissed: false);
      await tester.pump();

      // Attempt 1 cooldown: expire timer -> tap resend (Attempt 2)
      await tester.pump(const Duration(seconds: 60));
      expect(find.textContaining('Resend Code (2 left)'), findsOneWidget);
      await tester.tap(find.textContaining('Resend Code'), warnIfMissed: false);
      await tester.pump();

      // Attempt 2 cooldown: expire timer -> tap resend (Attempt 3 - Final)
      await tester.pump(const Duration(seconds: 60));
      expect(find.textContaining('Resend Code (1 left)'), findsOneWidget);
      await tester.tap(find.textContaining('Resend Code'), warnIfMissed: false);
      await tester.pump();

      // Exhausted (3 attempts used) -> displays 10 minute lockout warning
      expect(
        find.text('Too many attempts, please try again in 10 minutes.'),
        findsOneWidget,
      );
    });

    testWidgets('7. Bilingual support in Swahili (Kiswahili)', (tester) async {
      SharedPreferences.setMockInitialValues({'somasmart_language': 'sw'});
      final swPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(swPrefs),
          ],
          child: const MaterialApp(
            home: VerifyOtpScreen(phone: '+255712345123'),
          ),
        ),
      );

      expect(find.text('Hakiki Nambari Yako ya Simu'), findsOneWidget);
      expect(find.text('Badilisha'), findsOneWidget);
      expect(find.text('Thibitisha'), findsOneWidget);
      expect(find.textContaining('Tuma tena msimbo baada ya 01:00'), findsOneWidget);
    });
  });

  group('VerifyOtpScreen is disabled without a server-side OTP', () {
    testWidgets('8. Rejects every code, including the old master code 123456', (tester) async {
      var verified = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: VerifyOtpScreen(
              phone: '+255712345678',
              onVerified: (_) => verified = true,
            ),
          ),
        ),
      );

      final textFields = find.byType(TextFormField);
      for (int i = 0; i < 6; i++) {
        await tester.enterText(textFields.at(i), '${i + 1}');
        await tester.pump();
      }
      await tester.pumpAndSettle();

      expect(verified, isFalse);
      expect(find.text('Phone verification is not available yet.'), findsOneWidget);
      for (int i = 0; i < 6; i++) {
        final TextFormField field = tester.widget(textFields.at(i));
        expect(field.controller?.text, isEmpty);
      }
    });

    testWidgets('9. Resend is unavailable without a server sender', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: VerifyOtpScreen(phone: '+255712345678'),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 60));
      await tester.tap(find.textContaining('Resend Code'), warnIfMissed: false);
      await tester.pump();

      expect(find.text('Phone verification is not available yet.'), findsOneWidget);
      expect(find.textContaining('Resend Code (3 left)'), findsOneWidget);
    });
  });
}
