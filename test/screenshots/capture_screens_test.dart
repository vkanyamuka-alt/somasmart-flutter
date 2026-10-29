// Renders real screens to PNG files for visual review (not part of the normal
// suite). Run with:
//   flutter test test/screenshots --dart-define=CAPTURE_DIR=<folder>
// Text uses a system font loaded as "Roboto", because the app's Inter font
// comes from google_fonts, which cannot download inside tests. The run reports
// those font-download errors as failures; the PNG files are still written.
// Without CAPTURE_DIR (the normal test suite) this file does nothing.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/core/theme/app_theme.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';
import 'package:somasmart_flutter/core/widgets/bottom_nav_bar.dart';
import 'package:somasmart_flutter/features/account/presentation/controllers/account_controller.dart';
import 'package:somasmart_flutter/features/home/presentation/screens/home_screen.dart';
import 'package:somasmart_flutter/features/settings/presentation/controllers/settings_controller.dart';
import 'package:somasmart_flutter/features/settings/presentation/screens/settings_screen.dart';
import 'package:somasmart_flutter/features/subjects/presentation/controllers/subjects_controller.dart';
import 'package:somasmart_flutter/features/subjects/presentation/screens/level_screen.dart';

const _captureDir = String.fromEnvironment('CAPTURE_DIR');

Future<void> _loadFonts() async {
  for (final entry in {
    'Roboto': ['C:/Windows/Fonts/segoeui.ttf', 'C:/Windows/Fonts/segoeuib.ttf', 'C:/Windows/Fonts/seguisb.ttf'],
    'MaterialIcons': [],
  }.entries) {
    final loader = FontLoader(entry.key);
    var any = false;
    for (final path in entry.value) {
      if (File(path).existsSync()) {
        loader.addFont(Future.value(ByteData.view(File(path).readAsBytesSync().buffer)));
        any = true;
      }
    }
    if (any) await loader.load();
  }
  // Material icons from the Flutter SDK, so icons draw instead of boxes.
  // flutter_tester lives in <sdk>/bin/cache/artifacts/engine/<platform>/.
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent.path;
  final icons = File('$artifacts/material_fonts/MaterialIcons-Regular.otf');
  if (icons.existsSync()) {
    final loader = FontLoader('MaterialIcons')..addFont(Future.value(ByteData.view(icons.readAsBytesSync().buffer)));
    await loader.load();
  }
}

ThemeData _withDeviceFont(ThemeData t) => t.copyWith(
      textTheme: t.textTheme.apply(fontFamily: 'Roboto'),
      primaryTextTheme: t.primaryTextTheme.apply(fontFamily: 'Roboto'),
    );

void main() {
  if (_captureDir.isEmpty) {
    test('screenshots are only captured with --dart-define=CAPTURE_DIR', () {});
    return;
  }

  final student = UserProfile(
    id: 'demo',
    email: '255711000000@phone.somasmart.com',
    fullName: 'Mwanafunzi SomaSmart',
    phone: '+255711000000',
    role: 'student',
    subscriptionStatus: 'free',
    createdAt: DateTime.now().toUtc(),
  );

  setUpAll(() async {
    // No network in tests: skip Inter downloads; text uses the font loaded above.
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
  });

  Future<void> capture(WidgetTester tester, String name, Widget screen, {required bool dark, required Size size, String lang = 'en', String? tap}) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    tester.view.physicalSize = size * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    final theme = _withDeviceFont(dark ? AppTheme.darkTheme : AppTheme.lightTheme);

    await tester.pumpWidget(RepaintBoundary(
      key: key,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          languageProvider.overrideWith((ref) => _Lang(lang)),
          userProfileProvider.overrideWith(() => _Profile(student)),
          lessonCountsProvider.overrideWith((ref) async => {'mathematics|1': 1, 'physics|1': 1, 'chemistry|1': 2, 'biology|1': 5}),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          home: Scaffold(
            body: screen,
            bottomNavigationBar: SomaSmartBottomNav(currentIndex: screen is SettingsScreen ? 4 : 0, onTap: (_) {}),
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(Scaffold).first);
      await precacheImage(const AssetImage('assets/images/hero-student-v2.png'), ctx);
    });
    await tester.pumpAndSettle();
    if (tap != null) {
      await tester.tap(find.text(tap));
      await tester.pumpAndSettle();
    }
    while (tester.takeException() != null) {}

    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      return (await image.toByteData(format: ui.ImageByteFormat.png))!;
    });
    File('$_captureDir/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    // The only expected errors are Inter not being available offline.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    while (tester.takeException() != null) {}
  }

  const phone = Size(390, 1240);
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('home $mode', (t) => capture(t, 'flutter-home-$mode', const HomeScreen(), dark: dark, size: phone));
    testWidgets('settings $mode', (t) => capture(t, 'flutter-settings-$mode', const SettingsScreen(), dark: dark, size: const Size(390, 1500)));
  }
  for (final dark in [false, true]) {
    final mode = dark ? 'dark' : 'light';
    testWidgets('o-level $mode', (t) => capture(t, 'flutter-olevel-$mode', const LevelScreen(level: 'o-level'), dark: dark, size: const Size(390, 1100), lang: 'sw', tap: 'Kidato cha 1'));
  }
  testWidgets('a-level tablet', (t) => capture(t, 'flutter-alevel-tablet', const LevelScreen(level: 'a-level'), dark: false, size: const Size(820, 900), lang: 'sw', tap: 'Sayansi'));
  testWidgets('home sw small phone', (t) => capture(t, 'flutter-home-sw-320', const HomeScreen(), dark: false, size: const Size(320, 1300), lang: 'sw'));
}

class _Lang extends StateNotifier<String> implements LanguageNotifier {
  _Lang(super.state);
  @override
  Future<void> setLanguage(String lang) async => state = lang;
}

class _Profile extends UserProfileNotifier {
  final UserProfile _p;
  _Profile(this._p);
  @override
  Future<UserProfile?> build() async => _p;
}
