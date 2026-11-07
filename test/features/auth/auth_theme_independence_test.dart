import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/features/auth/presentation/widgets/auth_layout.dart';
import 'package:somasmart_flutter/core/theme/app_colors.dart';
import 'package:somasmart_flutter/core/theme/app_theme.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/welcome_screen.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/login_screen.dart';
import 'package:somasmart_flutter/features/auth/presentation/screens/signup_screen.dart';
import 'package:somasmart_flutter/features/splash/presentation/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'somasmart_language': 'en',
      'somasmart_theme_mode': 'dark', // User explicitly selected Dark mode
    });
    prefs = await SharedPreferences.getInstance();
  });

  group('Authentication & Onboarding Screens Light Theme Independence', () {
    testWidgets('SplashScreen renders in light theme even when app is in dark mode', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: Theme(
              data: AppTheme.lightTheme,
              child: const SplashScreen(
                autoNavigate: false,
                animationDuration: Duration(milliseconds: 50),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AppColors.lightBgSurface);
      expect(find.text('SomaSmart'), findsOneWidget);
    });

    testWidgets('WelcomeScreen renders in light theme with white background', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: Theme(
              data: AppTheme.lightTheme,
              child: const WelcomeScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, Colors.white);
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('LoginScreen renders in light theme when wrapped in AppTheme.lightTheme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: Theme(
              data: AppTheme.lightTheme,
              child: const LoginScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AuthColors.page);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('SignUpScreen renders in light theme when wrapped in AppTheme.lightTheme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.dark,
            home: Theme(
              data: AppTheme.lightTheme,
              child: const SignUpScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, AuthColors.page);
      expect(find.byType(SignUpScreen), findsOneWidget);
    });
  });
}
