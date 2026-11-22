import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/core/widgets/soma_icon.dart';
import 'package:somasmart_flutter/core/widgets/soma_icon_data.dart';
import 'package:somasmart_flutter/features/subjects/presentation/controllers/subjects_controller.dart';

void main() {
  test('every subject in the app has its own SomaSmart drawing', () {
    final keys = <String>{};
    for (final s in initialSubjects) {
      expect(s.somaIcon, isNot('default'), reason: s.nameEn);
      expect(somaIconPaths.containsKey(s.somaIcon), isTrue, reason: s.nameEn);
      keys.add(s.somaIcon);
    }
    expect(keys.length, initialSubjects.length);
  });

  test('subject names, Swahili names and database ids find the same icon as the website', () {
    expect(subjectIconKey('Biology (QA)'), 'biology');
    expect(subjectIconKey('Fizikia'), 'physics');
    expect(subjectIconKey('Hisabati ya Tahasusi'), 'basic_applied_mathematics');
    expect(subjectIconKey('58d0421e-1f7c-473d-bd83-aa1e8f25b290'), 'biology');
    expect(subjectIconKey('Astrology'), 'default');
    expect(subjectIconKey(null), 'default');
  });

  test('the SVG carries the ink colour and the gold accent', () {
    final svg = SomaIcon.svg('chemistry', const Color(0xFF184E78));
    expect(svg, contains('stroke="#184e78"'));
    expect(svg, contains('fill="#db9e3d"'));
  });

  testWidgets('draws as an SVG picture', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Center(child: SomaIcon('civics', size: 32))));
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.getSize(find.byType(SomaIcon)), const Size(32, 32));
  });
}
