import 'package:flutter/material.dart';

/// How a practical screen arranges its bench and its step controls: stacked
/// on phones, side by side from 1100 px (bench on the left, controls on the
/// right) so a tablet or desktop shows the bench and the controls together.
/// Shared by the practical screens so each one lays out the same way.
class PracticalSplitLayout extends StatelessWidget {
  final Widget bench;
  final Widget controls;
  final EdgeInsets padding;
  /// The current step: on a phone the page goes back to the top when it changes.
  final Object? step;

  const PracticalSplitLayout({
    super.key,
    required this.bench,
    required this.controls,
    this.padding = const EdgeInsets.all(12),
    this.step,
  });

  // Below this the step controls (which need about 500 px) would be squeezed.
  static const double wideBreakpoint = 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < wideBreakpoint) {
          return StepScrollView(
            step: step,
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

/// A practical's page that scrolls back to the top whenever [step] changes,
/// so on a phone the bench, and the hand doing the next action, is in view
/// after the student taps Next lower down.
class StepScrollView extends StatefulWidget {
  final Object? step;
  final EdgeInsetsGeometry? padding;
  final Widget child;

  const StepScrollView({super.key, required this.step, this.padding, required this.child});

  @override
  State<StepScrollView> createState() => _StepScrollViewState();
}

class _StepScrollViewState extends State<StepScrollView> {
  final _controller = ScrollController();

  @override
  void didUpdateWidget(StepScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step == widget.step) return;
    // after the new step's controls are laid out, which may change the height
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients || _controller.offset <= 0) return;
      _controller.animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SingleChildScrollView(controller: _controller, padding: widget.padding, child: widget.child);
}
