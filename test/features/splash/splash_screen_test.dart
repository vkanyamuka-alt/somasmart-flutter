import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/splash/presentation/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'somasmart_language': 'sw'});
    prefs = await SharedPreferences.getInstance();
  });

  group('SplashScreen Widget Tests', () {
    testWidgets('renders official S logo mark, SomaSmart title, and Swahili tagline by default',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: SplashScreen(
              autoNavigate: false,
              animationDuration: Duration(milliseconds: 100),
              holdDuration: Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      // Fast forward animation
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('SomaSmart'), findsOneWidget);
      expect(find.text('Jifunze Haraka. Elewa Zaidi.\nMudu Kila Mada.'), findsOneWidget);
      expect(find.text('Mfumo wa Kisasa wa Kujisomea'), findsOneWidget);
    });

    testWidgets('renders English tagline when language is en', (tester) async {
      SharedPreferences.setMockInitialValues({'somasmart_language': 'en'});
      final enPrefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(enPrefs),
          ],
          child: const MaterialApp(
            home: SplashScreen(
              autoNavigate: false,
              animationDuration: Duration(milliseconds: 100),
              holdDuration: Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Learn Fast. Understand Deeply.\nMaster Every Topic.'), findsOneWidget);
      expect(find.text('Modern Learning Platform'), findsOneWidget);
    });

    testWidgets('renders smoothly in dark theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const SplashScreen(
              autoNavigate: false,
              animationDuration: Duration(milliseconds: 100),
              holdDuration: Duration(milliseconds: 50),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('SomaSmart'), findsOneWidget);
    });
  });
}
