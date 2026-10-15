import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/core/widgets/soma_smart_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SomaSmartLogo Widget Tests', () {
    testWidgets('renders official S logo mark with live SomaSmart wordmark',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SomaSmartLogo(size: 34),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('SomaSmart'), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('SomaSmart'));
      expect(textWidget.style?.fontWeight, FontWeight.w800);
      expect(textWidget.style?.fontSize, 20.0);
    });

    testWidgets('renders mark-only when markOnly constructor is used',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SomaSmartLogo.markOnly(size: 40),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('SomaSmart'), findsNothing);

      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.height, 40);
      expect(imageWidget.width, 40);
    });

    testWidgets('renders correctly in Dark Mode theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: SomaSmartLogo(size: 28),
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('SomaSmart'), findsOneWidget);
    });

    testWidgets('supports custom text styling and custom size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SomaSmartLogo(
              size: 48,
              fontSize: 24,
              textColor: Colors.amber,
              spacing: 16,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('SomaSmart'));
      expect(textWidget.style?.fontSize, 24.0);
      expect(textWidget.style?.color, Colors.amber);
    });
  });
}
