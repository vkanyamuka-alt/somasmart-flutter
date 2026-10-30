import 'package:flutter/material.dart';

/// How a practical screen arranges its bench and its step controls: stacked
/// on phones, side by side from 1100 px (bench on the left, controls on the
/// right) so a tablet or desktop shows the bench and the controls together.
/// Shared by the practical screens so each one lays out the same way.
class PracticalSplitLayout extends StatelessWidget {
  final Widget bench;
  final Widget controls;
  final EdgeInsets padding;

  const PracticalSplitLayout({
    super.key,
    required this.bench,
    required this.controls,
    this.padding = const EdgeInsets.all(12),
  });

  // Below this the step controls (which need about 500 px) would be squeezed.
  static const double wideBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < wideBreakpoint) {
          return SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [bench, const SizedBox(height: 12), controls],
            ),
          );
        }
        return Padding(
          padding: padding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: SingleChildScrollView(child: bench)),
              const SizedBox(width: 16),
              Expanded(child: SingleChildScrollView(child: controls)),
            ],
          ),
        );
      },
    );
  }
}
