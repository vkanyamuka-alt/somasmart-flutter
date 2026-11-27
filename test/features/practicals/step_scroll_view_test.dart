import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somasmart_flutter/features/practicals/presentation/widgets/practical_layout.dart';

void main() {
  Widget page(int step, double height) => MaterialApp(
        home: Scaffold(
          body: StepScrollView(step: step, child: SizedBox(height: height, child: Text('step $step'))),
        ),
      );

  testWidgets('goes back to the top when the step changes', (tester) async {
    await tester.pumpWidget(page(1, 3000));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1200));
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scrollable.position.pixels, greaterThan(0));

    // The next step's controls are shorter, as on the osmosis Cut step.
    await tester.pumpWidget(page(2, 1400));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels, 0);
  });

  testWidgets('stays where it is while the step is the same', (tester) async {
    await tester.pumpWidget(page(1, 3000));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();
    final before = tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels;

    await tester.pumpWidget(page(1, 3000));
    await tester.pumpAndSettle();
    expect(tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels, before);
  });
}
