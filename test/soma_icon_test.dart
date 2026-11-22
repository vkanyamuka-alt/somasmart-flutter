import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/core/widgets/soma_icon.dart';
import 'package:somasmart_flutter/core/widgets/soma_icon_data.dart';

void main() {
  test('only the Ask me mark is drawn (subjects have no icons)', () {
    expect(somaIconPaths.keys.toList(), ['ask']);
  });

  test('the SVG uses the ink and gold colours', () {
    final svg = SomaIcon.svg('ask', const Color(0xFF184E78));
    expect(svg, contains('stroke="#184e78"'));
    expect(svg, contains('fill="#db9e3d"'));
  });

  testWidgets('SomaIcon draws at the asked size', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Center(child: SomaIcon('ask', size: 32))),
    );
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.getSize(find.byType(SomaIcon)), const Size(32, 32));
  });
}
