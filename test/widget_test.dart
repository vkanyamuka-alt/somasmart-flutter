import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somasmart_flutter/app.dart';
import 'package:somasmart_flutter/core/theme/theme_provider.dart';

void main() {
  testWidgets('SomaSmartApp smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const SomaSmartApp(),
      ),
    );

    expect(find.byType(SomaSmartApp), findsOneWidget);
  });
}
