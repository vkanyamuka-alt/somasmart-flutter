import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/app_theme.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/settings/presentation/controllers/settings_controller.dart';
import 'package:somasmart_flutter/features/subjects/presentation/controllers/subjects_controller.dart';
import 'package:somasmart_flutter/features/subjects/presentation/screens/level_screen.dart';

Future<void> _loadDeviceLikeFont() async {
  for (final path in ['C:/Windows/Fonts/segoeui.ttf', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf', '/System/Library/Fonts/Supplemental/Arial.ttf']) {
    final file = File(path);
    if (!file.existsSync()) continue;
    await (FontLoader('Roboto')..addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)))).load();
    return;
  }
}

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUpAll(_loadDeviceLikeFont);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  // The level screens inside the app's routes, starting at [location].
  Future<void> pump(WidgetTester tester, String location, {double width = 390, String lang = 'sw'}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      languageProvider.overrideWith((ref) => _Lang(lang)),
      userProfileProvider.overrideWith(() => _Profile()),
    ]);
    addTearDown(container.dispose);
    final router = GoRouter(initialLocation: location, routes: [
      GoRoute(path: '/subjects', builder: (c, s) => LevelScreen(level: s.uri.queryParameters['level'] ?? 'o-level')),
      GoRoute(
        path: '/subjects/:level/:choice',
        builder: (c, s) => LevelScreen(level: s.pathParameters['level']!, choice: s.pathParameters['choice']),
      ),
      GoRoute(path: '/subjects/:id', builder: (c, s) => Scaffold(body: Text('subject ${s.pathParameters['id']}'))),
    ]);
    final theme = AppTheme.lightTheme;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: theme.copyWith(textTheme: theme.textTheme.apply(fontFamily: 'Roboto')),
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('O-Level shows four form cards, names only, in English even when the app is in Swahili', (tester) async {
    await pump(tester, '/subjects?level=o-level');
    for (final f in [1, 2, 3, 4]) {
      expect(find.text('Form $f'), findsOneWidget);
    }
    expect(find.textContaining('subjects'), findsNothing, reason: 'no counts on form cards');
    expect(find.textContaining('lesson'), findsNothing);
    expect(find.text('Mathematics'), findsNothing, reason: 'subjects are on the form screen');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a form opens its own screen with its subjects, two to a row, and Back returns to the forms', (tester) async {
    await pump(tester, '/subjects?level=o-level');
    await tester.tap(find.text('Form 1'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Form 1'), findsOneWidget, reason: 'the form is its own screen');
    expect(find.text('Form 2'), findsNothing);
    expect(find.text('Mathematics'), findsOneWidget);
    expect(find.text('Hisabati'), findsNothing, reason: 'learning screens are in English');
    expect(find.text('Coming soon'), findsNothing, reason: 'subject cards carry a name only');
    final maths = tester.getRect(find.text('Mathematics'));
    final physics = tester.getRect(find.text('Physics'));
    expect((maths.top - physics.top).abs(), lessThan(2), reason: 'two subjects share a row on a phone');

    await tester.tap(find.text('Biology'));
    await tester.pumpAndSettle();
    expect(container.read(selectedFormLevelProvider), 1, reason: 'the subject page reads the chosen form');
    expect(find.text('subject 4'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator).last).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Form 3'), findsOneWidget, reason: 'Back returns to the form cards');
    expect(tester.takeException(), isNull);
  });

  testWidgets('A-Level streams open with the same subjects as the web', (tester) async {
    await pump(tester, '/subjects?level=a-level', lang: 'en');
    expect(find.text('Science'), findsOneWidget);
    expect(find.text('Arts & Business'), findsOneWidget);

    await tester.tap(find.text('Arts & Business'));
    await tester.pumpAndSettle();
    for (final name in ['History', 'Economics', 'Commerce', 'English Language', 'Kiswahili', 'Geography']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    await tester.tap(find.text('Economics'));
    await tester.pumpAndSettle();
    expect(container.read(selectedFormLevelProvider), 5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wider screens fit more subjects to a row and still do not overflow', (tester) async {
    await pump(tester, '/subjects/o-level/2', width: 1024);
    final a = tester.getRect(find.text('Mathematics'));
    final d = tester.getRect(find.text('Biology'));
    expect((a.top - d.top).abs(), lessThan(2), reason: 'four to a row at 1024px');
    expect(tester.takeException(), isNull);
  });
}

class _Lang extends StateNotifier<String> implements LanguageNotifier {
  _Lang(super.state);
  @override
  Future<void> setLanguage(String lang) async => state = lang;
}

class _Profile extends UserProfileNotifier {
  @override
  Future<UserProfile?> build() async => UserProfile(
        id: 'u',
        email: 'u@x.tz',
        fullName: 'Student',
        phone: '',
        role: 'student',
        subscriptionStatus: 'free',
        createdAt: DateTime.now().toUtc(),
      );
}
