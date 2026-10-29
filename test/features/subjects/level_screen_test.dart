import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  Future<void> pump(WidgetTester tester, String level, {double width = 390, String lang = 'sw'}) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      languageProvider.overrideWith((ref) => _Lang(lang)),
      userProfileProvider.overrideWith(() => _Profile()),
      // Form 1 Biology has 5 notes/lessons; everything else is still empty.
      lessonCountsProvider.overrideWith((ref) async => {'biology|1': 5}),
    ]);
    addTearDown(container.dispose);
    final theme = AppTheme.lightTheme;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme.copyWith(textTheme: theme.textTheme.apply(fontFamily: 'Roboto')),
        home: LevelScreen(level: level),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('O-Level opens on four form cards; a form shows its subjects as medium cards, two to a row', (tester) async {
    await pump(tester, 'o-level');
    for (final f in [1, 2, 3, 4]) {
      expect(find.text('Kidato cha $f'), findsOneWidget);
    }
    expect(find.text('Hisabati'), findsNothing, reason: 'no subjects until a form is chosen');

    await tester.tap(find.text('Kidato cha 1'));
    await tester.pumpAndSettle();
    expect(container.read(selectedFormLevelProvider), 1, reason: 'the subject page reads the chosen form');
    expect(find.text('Hisabati'), findsOneWidget);
    expect(find.text('Maudhui 5'), findsWidgets, reason: 'real lesson counts (Biology, and the Form 1 card)');
    expect(find.text('Inakuja'), findsWidgets, reason: 'subjects with no lessons yet say so');

    final maths = tester.getRect(find.text('Hisabati'));
    final physics = tester.getRect(find.text('Fizikia'));
    expect((maths.top - physics.top).abs(), lessThan(2), reason: 'two subjects share a row on a phone');
    expect(tester.takeException(), isNull, reason: 'no overflow');
  });

  testWidgets('A-Level opens on two stream cards with the same subjects as the web', (tester) async {
    await pump(tester, 'a-level', lang: 'en');
    expect(find.text('Science'), findsOneWidget);
    expect(find.text('Arts & Business'), findsOneWidget);

    await tester.tap(find.text('Arts & Business'));
    await tester.pumpAndSettle();
    expect(container.read(selectedFormLevelProvider), 5);
    for (final name in ['History', 'Economics', 'Commerce', 'English Language', 'Kiswahili', 'Geography']) {
      expect(find.text(name), findsOneWidget, reason: name);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('wider screens fit more subjects to a row and still do not overflow', (tester) async {
    await pump(tester, 'o-level', width: 1024);
    await tester.tap(find.text('Kidato cha 2'));
    await tester.pumpAndSettle();
    final a = tester.getRect(find.text('Hisabati'));
    final d = tester.getRect(find.text('Biolojia'));
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
