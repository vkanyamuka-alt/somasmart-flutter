import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/optics_state.dart';
import '../../data/models/practical_model.dart';
import '../controllers/optics_controller.dart';
import '../widgets/optics_bench_painter.dart';
import '../widgets/lab_hand.dart';
import '../widgets/practical_layout.dart';
import '../widgets/optics_graph_widget.dart';
import '../widgets/titration_completion_card.dart';
import '../../../../core/utils/learning_language.dart';

class OpticsScreen extends ConsumerWidget {
  final PracticalMode mode;

  const OpticsScreen({
    super.key,
    this.mode = PracticalMode.guidedPractice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(opticsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = learningLanguage();
    final isSwahili = currentLocale == 'sw';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context, ref, state, isDark, isSwahili),
      body: SafeArea(
        child: Column(
          children: [
            // Mode Banner & Step Indicator
            _buildStepTabBar(ref, state, isDark, isSwahili),

            // Main Laboratory Viewport & Step Content
            // Bench and step controls: stacked on phones, side by side when wide.
            Expanded(
              child: PracticalSplitLayout(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                bench: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHintBanner(state, isDark, isSwahili),
                    const SizedBox(height: 10),
                    _buildOpticsBench(context, ref, state, isDark, isSwahili),
                  ],
                ),
                controls: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStepContentCard(context, ref, state, isDark, isSwahili),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Actions
            _buildBottomNavigation(context, ref, state, isDark, isSwahili),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // App Bar
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    WidgetRef ref,
    OpticsState state,
    bool isDark,
    bool isSwahili,
  ) {
    final mins = state.experimentDurationSeconds ~/ 60;
    final secs = state.experimentDurationSeconds % 60;
    final timeStr = '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => _showExitConfirmationDialog(context, isDark, isSwahili),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  mode.labelEn.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isSwahili ? 'Mche wa Kioo (Optics)' : 'Refraction & Prism',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Live Experiment Timer
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          margin: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF0284C7)),
              const SizedBox(width: 4),
              Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Lab Notebook Button
        IconButton(
          icon: const Icon(Icons.menu_book_outlined, color: Color(0xFF0284C7)),
          tooltip: isSwahili ? 'Daftari la Maabara' : 'Lab Notebook',
          onPressed: () => _openLabNotebook(context, state, isDark, isSwahili),
        ),

        // Reset Experiment
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: isSwahili ? 'Weka Upya' : 'Reset Experiment',
          onPressed: () => ref.read(opticsControllerProvider.notifier).resetExperiment(mode),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step Tab Bar
  // ---------------------------------------------------------------------------
  Widget _buildStepTabBar(WidgetRef ref, OpticsState state, bool isDark, bool isSwahili) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: OpticsStep.values.length,
        itemBuilder: (context, index) {
          final step = OpticsStep.values[index];
          final isActive = state.step == step;
          final isPast = state.step.index > index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPast)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                    ),
                  Text(
                    isSwahili ? step.titleSw : step.titleEn,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? Colors.white
                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
              selected: isActive,
              selectedColor: const Color(0xFF0058BE),
              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              side: BorderSide(
                color: isActive
                    ? const Color(0xFF0058BE)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              onSelected: (_) {
                ref.read(opticsControllerProvider.notifier).setStep(step);
              },
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hint Banner
  // ---------------------------------------------------------------------------
  Widget _buildHintBanner(OpticsState state, bool isDark, bool isSwahili) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, size: 16, color: Color(0xFF0284C7)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isSwahili ? state.step.descriptionSw : state.step.descriptionEn,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDark ? const Color(0xFFE0F2FE) : const Color(0xFF0369A1),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Virtual Optics Laboratory Bench Viewport
  // ---------------------------------------------------------------------------
  Widget _buildOpticsBench(
    BuildContext context,
    WidgetRef ref,
    OpticsState state,
    bool isDark,
    bool isSwahili,
  ) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // CustomPainter for Drawing Board, Prism, Light Ray, Pins, Protractor
            Positioned.fill(
              child: LabHandPaint(
                watch: OpticsBenchPainter.handKeys(state),
                painter: (hands) => OpticsBenchPainter(state: state, isDark: isDark, hands: hands),
              ),
            ),

            // Top-Right Real-Time Optical Readout Pill
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildReadoutBadge('i', '${state.incidentAngleDeg.toStringAsFixed(1)}°', const Color(0xFF06B6D4)),
                    const SizedBox(width: 8),
                    _buildReadoutBadge('r', '${state.refractedAngleDeg.toStringAsFixed(1)}°', const Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    _buildReadoutBadge('D', '${state.deviationAngleDeg.toStringAsFixed(1)}°', const Color(0xFFEC4899)),
                  ],
                ),
              ),
            ),

            // Bottom-Left Floating Overlay Controls
            Positioned(
              bottom: 8,
              left: 10,
              child: Row(
                children: [
                  _buildToggleIconButton(
                    icon: Icons.straighten,
                    label: isSwahili ? 'Kipimapembe' : 'Protractor',
                    isActive: state.showProtractor,
                    onTap: () => ref.read(opticsControllerProvider.notifier).toggleProtractor(),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildToggleIconButton(
                    icon: Icons.alt_route,
                    label: isSwahili ? 'Msambamba' : 'Normal',
                    isActive: state.showNormalLines,
                    onTap: () => ref.read(opticsControllerProvider.notifier).toggleNormalLines(),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildToggleIconButton(
                    icon: Icons.pin_drop_outlined,
                    label: isSwahili ? 'Pini' : 'Pins',
                    isActive: state.showOpticalPins,
                    onTap: () => ref.read(opticsControllerProvider.notifier).toggleOpticalPins(),
                    isDark: isDark,
                  ),
                  const SizedBox(width: 6),
                  _buildToggleIconButton(
                    icon: Icons.highlight,
                    label: isSwahili ? 'Laser' : 'Laser',
                    isActive: state.laserActive,
                    onTap: () => ref.read(opticsControllerProvider.notifier).toggleLaser(),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadoutBadge(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          '$label = ',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            fontFamily: 'monospace',
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleIconButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF0284C7).withValues(alpha: 0.2)
              : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? const Color(0xFF0284C7) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? const Color(0xFF0284C7) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF0284C7) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step Content Card
  // ---------------------------------------------------------------------------
  Widget _buildStepContentCard(
    BuildContext context,
    WidgetRef ref,
    OpticsState state,
    bool isDark,
    bool isSwahili,
  ) {
    switch (state.step) {
      case OpticsStep.inspectApparatus:
        return _buildApparatusInspectionStep(ref, state, isDark, isSwahili);
      case OpticsStep.alignPrismAndNormal:
        return _buildPrismAlignmentStep(ref, state, isDark, isSwahili);
      case OpticsStep.setIncidentAngle:
        return _buildAngleAdjustmentStep(ref, state, isDark, isSwahili);
      case OpticsStep.placePinsAndTraceRay:
        return _buildPinTracingStep(context, ref, state, isDark, isSwahili);
      case OpticsStep.observationTable:
        return _buildObservationTableStep(ref, state, isDark, isSwahili);
      case OpticsStep.graphAnalysis:
        return OpticsGraphWidget(state: state, isDark: isDark, isSwahili: isSwahili);
      case OpticsStep.calculateRefractiveIndex:
        return _buildCalculationStep(context, ref, state, isDark, isSwahili);
    }
  }

  // Step 1: Apparatus Inspection
  Widget _buildApparatusInspectionStep(
    WidgetRef ref,
    OpticsState state,
    bool isDark,
    bool isSwahili,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Kagua Vifaa vya Maabara' : 'Inspect Laboratory Equipment',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: state.allApparatusInspected
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${state.apparatusItems.where((i) => i.isInspected).length}/${state.apparatusItems.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: state.allApparatusInspected ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...state.apparatusItems.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: item.isInspected
                      ? const Color(0xFF10B981).withValues(alpha: 0.4)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Icon(
                    item.isInspected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: item.isInspected ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    size: 20,
                  ),
                  title: Text(
                    isSwahili ? item.nameSw : item.nameEn,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    isSwahili ? item.descriptionSw : item.descriptionEn,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  onTap: () {
                    ref.read(opticsControllerProvider.notifier).inspectApparatus(item.id);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Step 2: Prism Alignment
  Widget _buildPrismAlignmentStep(WidgetRef ref, OpticsState state, bool isDark, bool isSwahili) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSwahili ? 'Mpangilio wa Mche na Msambamba' : 'Prism & Normal Alignment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSwahili
                ? 'Mche wa kioo una pembe ya mgawanyiko A = 60.0°. Mstari msambamba (N₁) umechorwa kwa pembe ya 90° kwenye uso wa kwanza (AB).'
                : 'The equilateral triangular glass prism has a refracting angle A = 60.0°. The perpendicular normal (N₁) is constructed at 90° on refracting face AB.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildInfoMetricBox(
                  title: isSwahili ? 'Pembe ya Mche (A)' : 'Prism Angle (A)',
                  value: '60.0°',
                  color: const Color(0xFF0284C7),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildInfoMetricBox(
                  title: isSwahili ? 'Aina ya Kioo' : 'Glass Type',
                  value: 'Crown Glass',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 3: Set Incident Angle
  Widget _buildAngleAdjustmentStep(WidgetRef ref, OpticsState state, bool isDark, bool isSwahili) {
    const presets = [30.0, 35.0, 40.0, 45.0, 50.0, 60.0];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Rekebisha Pembe ya Mwale (i)' : 'Adjust Angle of Incidence (i)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'i = ${state.incidentAngleDeg.toStringAsFixed(1)}°',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF06B6D4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slider
          Slider(
            value: state.incidentAngleDeg,
            min: 20.0,
            max: 70.0,
            divisions: 50,
            activeColor: const Color(0xFF0058BE),
            inactiveColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            onChanged: (val) {
              ref.read(opticsControllerProvider.notifier).setIncidentAngle(val);
            },
          ),
          const SizedBox(height: 8),

          // Quick Presets
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: presets.map((angle) {
              final isSelected = (state.incidentAngleDeg - angle).abs() < 0.5;
              return ChoiceChip(
                label: Text('${angle.toStringAsFixed(0)}°'),
                selected: isSelected,
                selectedColor: const Color(0xFF0058BE),
                onSelected: (_) {
                  ref.read(opticsControllerProvider.notifier).setIncidentAngle(angle);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Step 4: Pin Tracing & Measurements
  Widget _buildPinTracingStep(
    BuildContext context,
    WidgetRef ref,
    OpticsState state,
    bool isDark,
    bool isSwahili,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Vipimo vya Mwale kwa Pembe ya Sasa' : 'Current Ray Measurements',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(opticsControllerProvider.notifier).recordTrial();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isSwahili ? 'Kipimo kimehifadhiwa kwenye jedwali!' : 'Observation recorded to table!',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.bookmark_add, size: 16),
                label: Text(isSwahili ? 'Hifadhi Jaribio' : 'Record Trial'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0058BE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 4 Grid Metric Cards
          Row(
            children: [
              Expanded(
                child: _buildInfoMetricBox(
                  title: isSwahili ? 'Pembe ya Kuingia (i)' : 'Angle of Incidence (i)',
                  value: '${state.incidentAngleDeg.toStringAsFixed(1)}°',
                  color: const Color(0xFF06B6D4),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoMetricBox(
                  title: isSwahili ? 'Pembe ya Kupinda (r)' : 'Angle of Refraction (r)',
                  value: '${state.refractedAngleDeg.toStringAsFixed(1)}°',
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoMetricBox(
                  title: isSwahili ? 'Pembe ya Kutoka (e)' : 'Angle of Emergence (e)',
                  value: '${state.emergentAngleDeg.toStringAsFixed(1)}°',
                  color: const Color(0xFF10B981),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoMetricBox(
                  title: isSwahili ? 'Mchepuko (D)' : 'Deviation Angle (D)',
                  value: '${state.deviationAngleDeg.toStringAsFixed(1)}°',
                  color: const Color(0xFFEC4899),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoMetricBox(
                  title: 'sin(i)',
                  value: state.sinI.toStringAsFixed(3),
                  color: const Color(0xFF06B6D4),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoMetricBox(
                  title: 'sin(r)',
                  value: state.sinR.toStringAsFixed(3),
                  color: const Color(0xFFF59E0B),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 5: Observation Table
  Widget _buildObservationTableStep(WidgetRef ref, OpticsState state, bool isDark, bool isSwahili) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Jedwali la Majaribio ya Mchepuko' : 'Observation Trials Table',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(opticsControllerProvider.notifier).recordTrial();
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text(isSwahili ? 'Hifadhi Pembe Hii' : 'Record Current'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0058BE),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (state.recordedTrials.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  isSwahili
                      ? 'Hakuna majaribio bado. Weka pembe ya i kisha gonga "Hifadhi Pembe Hii".'
                      : 'No trials recorded yet. Adjust angle i and tap "Record Current".',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 38,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 40,
                columnSpacing: 16,
                columns: [
                  DataColumn(label: Text(isSwahili ? 'Jaribio' : 'Trial')),
                  const DataColumn(label: Text('i (°)')),
                  const DataColumn(label: Text('r (°)')),
                  const DataColumn(label: Text('e (°)')),
                  const DataColumn(label: Text('D (°)')),
                  const DataColumn(label: Text('sin(i)')),
                  const DataColumn(label: Text('sin(r)')),
                  const DataColumn(label: Text('n')),
                  const DataColumn(label: Text('')),
                ],
                rows: state.recordedTrials.map((trial) {
                  return DataRow(
                    cells: [
                      DataCell(Text('#${trial.trialNumber}')),
                      DataCell(Text(trial.incidentAngleDeg.toStringAsFixed(1))),
                      DataCell(Text(trial.refractedAngleDeg.toStringAsFixed(1))),
                      DataCell(Text(trial.emergentAngleDeg.toStringAsFixed(1))),
                      DataCell(Text(trial.deviationAngleDeg.toStringAsFixed(1))),
                      DataCell(Text(trial.sinI.toStringAsFixed(3))),
                      DataCell(Text(trial.sinR.toStringAsFixed(3))),
                      DataCell(
                        Text(
                          trial.calculatedIndex.toStringAsFixed(3),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                          onPressed: () {
                            ref.read(opticsControllerProvider.notifier).removeTrial(trial.trialNumber);
                          },
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Step 7: Refractive Index Calculations & Submission
  Widget _buildCalculationStep(
    BuildContext context,
    WidgetRef ref,
    OpticsState state,
    bool isDark,
    bool isSwahili,
  ) {
    if (state.isCompleted && state.scoreResult != null) {
      return TitrationCompletionCard(
        scoreResult: state.scoreResult!,
        isDark: isDark,
        isSwahili: isSwahili,
        onRepeat: () => ref.read(opticsControllerProvider.notifier).resetExperiment(mode),
        onFinish: () => context.pop(),
      );
    }

    final slope = state.regressionSlope;
    final expN = state.experimentalRefractiveIndex;
    final err = state.percentageError;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isSwahili ? 'Uhesabuji wa Kielezo cha Kioo (n)' : 'Determination of Refractive Index (n)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSwahili
                ? 'Tumia mteremko wa grafu m = Δsin(i)/Δsin(r) kupata kielezo cha kioo cha mche.'
                : 'Use linear slope m = Δsin(i)/Δsin(r) to calculate the experimental refractive index.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 14),

          // Analysis Summary Container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildSummaryRow(isSwahili ? 'Mteremko wa Grafu (m):' : 'Plotted Gradient (m):', slope.toStringAsFixed(3)),
                const SizedBox(height: 6),
                _buildSummaryRow(
                  isSwahili ? 'Kielezo cha Majaribio (n = m):' : 'Calculated Refractive Index (n):',
                  expN.toStringAsFixed(3),
                  valueColor: const Color(0xFF10B981),
                ),
                const SizedBox(height: 6),
                _buildSummaryRow(
                  isSwahili ? 'Thamani Halisi ya Kioo:' : 'Accepted Reference Index:',
                  '1.500 (Crown Glass)',
                ),
                const SizedBox(height: 6),
                _buildSummaryRow(
                  isSwahili ? 'Kosa la Asilimia (%):' : 'Percentage Error (%):',
                  '${err.toStringAsFixed(2)}%',
                  valueColor: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Student Input Field
          TextFormField(
            initialValue: expN.toStringAsFixed(3),
            decoration: InputDecoration(
              labelText: isSwahili ? 'Weka Kielezo Chako (n)' : 'Enter Your Calculated Index (n)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: const Icon(Icons.calculate),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) {
              final parsed = double.tryParse(val);
              if (parsed != null && parsed > 0) {
                ref.read(opticsControllerProvider.notifier).calculateRefractiveIndex(parsed);
              }
            },
          ),
          const SizedBox(height: 14),

          // Submit & Complete Button
          ElevatedButton.icon(
            onPressed: () {
              ref.read(opticsControllerProvider.notifier).submitCalculations();
            },
            icon: const Icon(Icons.fact_check),
            label: Text(isSwahili ? 'Wasilisha na Kamilisha Jaribio' : 'Submit & Complete Practical'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0058BE),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF0284C7),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoMetricBox({
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Navigation Actions
  // ---------------------------------------------------------------------------
  Widget _buildBottomNavigation(
    BuildContext context,
    WidgetRef ref,
    OpticsState state,
    bool isDark,
    bool isSwahili,
  ) {
    if (state.isCompleted && state.scoreResult != null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          if (state.step.index > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => ref.read(opticsControllerProvider.notifier).previousStep(),
                icon: const Icon(Icons.arrow_back),
                label: Text(isSwahili ? 'Hatua Iliyopita' : 'Previous Step'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          if (state.step.index > 0) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: state.step.index < OpticsStep.values.length - 1
                  ? () => ref.read(opticsControllerProvider.notifier).nextStep()
                  : () => ref.read(opticsControllerProvider.notifier).submitCalculations(),
              icon: const Icon(Icons.arrow_forward),
              label: Text(
                state.step == OpticsStep.calculateRefractiveIndex
                    ? (isSwahili ? 'Kamilisha Jaribio' : 'Complete Practical')
                    : (isSwahili ? 'Hatua Inayofuata' : 'Next Step'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0058BE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lab Notebook Bottom Sheet
  // ---------------------------------------------------------------------------
  void _openLabNotebook(
    BuildContext context,
    OpticsState state,
    bool isDark,
    bool isSwahili,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSwahili ? 'Daftari la Maabara (Optics Log)' : 'Optics Laboratory Notebook',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isSwahili
                        ? 'Kanuni: n₁ · sin(i) = n₂ · sin(r)\nKwa hewa hadi kioo: n = sin(i) / sin(r)\nPembe ya mche: A = 60.0°\nMchepuko: D = i + e - A'
                        : 'Principle: n₁ · sin(i) = n₂ · sin(r)\nAir to glass: n = sin(i) / sin(r)\nPrism angle: A = 60.0°\nDeviation: D = i + e - A',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSwahili ? 'Majaribio Yaliyorekodiwa:' : 'Recorded Trials:',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (state.recordedTrials.isEmpty)
                    Text(
                      isSwahili ? 'Bado hakuna majaribio.' : 'No trials recorded yet.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  else
                    ...state.recordedTrials.map((t) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'Trial #${t.trialNumber}: i=${t.incidentAngleDeg}°, r=${t.refractedAngleDeg}°, sin(i)=${t.sinI}, sin(r)=${t.sinR} => n=${t.calculatedIndex}',
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showExitConfirmationDialog(BuildContext context, bool isDark, bool isSwahili) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkBgSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Text(isSwahili ? 'Ondoka Kwenye Jaribio?' : 'Exit Laboratory?'),
          ],
        ),
        content: Text(
          isSwahili
              ? 'Je, una uhakika unataka kuondoka kwenye jaribio hili la Mche wa Kioo?'
              : 'Are you sure you want to exit the Refraction & Prism virtual laboratory?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isSwahili ? 'Endelea' : 'Continue Lab'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: Text(isSwahili ? 'Ondoka' : 'Exit'),
          ),
        ],
      ),
    );
  }
}
