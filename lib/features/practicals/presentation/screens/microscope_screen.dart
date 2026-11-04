import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/microscope_state.dart';
import '../../data/models/practical_model.dart';
import '../controllers/microscope_controller.dart';
import '../widgets/practical_layout.dart';
import '../widgets/microscope_viewfinder_painter.dart';
import '../widgets/microscope_slide_painter.dart';
import '../widgets/lab_hand.dart';
import '../widgets/titration_completion_card.dart';
import '../../../../core/utils/learning_language.dart';

class MicroscopeScreen extends ConsumerStatefulWidget {
  final PracticalMode mode;

  const MicroscopeScreen({
    super.key,
    required this.mode,
  });

  @override
  ConsumerState<MicroscopeScreen> createState() => _MicroscopeScreenState();
}

class _MicroscopeScreenState extends ConsumerState<MicroscopeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(microscopeControllerProvider(widget.mode));
    final controller = ref.read(microscopeControllerProvider(widget.mode).notifier);
    final language = learningLanguage();
    final isSwahili = language == 'sw';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmationDialog(context, isDark, isSwahili);
      },
      child: Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFF184E78),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isSwahili ? 'Darubini ya Mwanga & Seli' : 'Light Microscope Cell Staining',
              style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            // the mode under the title, so the title has the full width
            Row(
              children: [
                _buildModeBadge(state.mode, isSwahili),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isSwahili ? 'Biolojia • O-Level' : 'O-Level Biology',
                    style: TextStyle(fontSize: 11.5, color: Colors.white.withValues(alpha: 0.85)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: isSwahili ? 'Daftari la Maabara' : 'Lab Notebook',
            onPressed: () => _showLabNotebook(context, isSwahili, state),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: isSwahili ? 'Anza Upya' : 'Reset Simulation',
            onPressed: () => controller.resetPractical(widget.mode),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Workflow Progression Step Bar
            _buildWorkflowHeader(state, controller, isSwahili, isDark),

            // 2. Real-time Observation Banner
            _buildObservationBanner(state, isSwahili, isDark),

            // 3. Central Simulation Viewport / Workbench
            Expanded(
              child: StepScrollView(
                step: state.currentStep,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: state.currentStep == MicroscopeStep.completed && state.scoreResult != null
                    ? TitrationCompletionCard(
                        scoreResult: state.scoreResult!,
                        isDark: isDark,
                        isSwahili: isSwahili,
                        onRepeat: () => controller.resetPractical(widget.mode),
                        onFinish: () => Navigator.of(context).pop(),
                      )
                    : Column(
                        children: [
                          if (state.currentStep.stepNumber <= 5 &&
                              state.mode != PracticalMode.freeExploration)
                            _buildSlidePreparationWorkbench(state, controller, isSwahili, isDark)
                          else
                            _buildMicroscopyObservationStation(state, controller, isSwahili, isDark),

                          const SizedBox(height: 16.0),

                          // Controls / Actions Card
                          _buildControlsCard(state, controller, isSwahili, isDark),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void _showExitConfirmationDialog(BuildContext context, bool isDark, bool isSwahili) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          isSwahili ? 'Ondoka kwenye Maabara?' : 'Leave Laboratory?',
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        content: Text(
          isSwahili
              ? 'Maendeleo yako ya sasa ya darubini hayatahifadhiwa.'
              : 'Your current microscope practical progress will be lost.',
          style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text(isSwahili ? 'Ondoka' : 'Leave', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildModeBadge(PracticalMode mode, bool isSwahili) {
    String label;
    Color color;
    switch (mode) {
      case PracticalMode.guidedPractice:
        label = isSwahili ? 'Mazoezi' : 'Guided';
        color = const Color(0xFF06B6D4);
        break;
      case PracticalMode.examMode:
        label = isSwahili ? 'Mtihani' : 'Exam';
        color = const Color(0xFFEF4444);
        break;
      case PracticalMode.freeExploration:
        label = isSwahili ? 'Hurubani' : 'Free';
        color = const Color(0xFF10B981);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 1.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 1.0),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }

  Widget _buildWorkflowHeader(
    MicroscopeState state,
    MicroscopeController controller,
    bool isSwahili,
    bool isDark,
  ) {
    final activeSteps = MicroscopeStep.values.where((s) => s != MicroscopeStep.completed).toList();

    return Container(
      height: 52.0,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        itemCount: activeSteps.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8.0),
        itemBuilder: (context, idx) {
          final s = activeSteps[idx];
          final isDone = state.currentStep.stepNumber > s.stepNumber;
          final isCurrent = state.currentStep == s;

          return InkWell(
            onTap: state.mode == PracticalMode.freeExploration ? () => controller.setStep(s) : null,
            borderRadius: BorderRadius.circular(10.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF184E78).withValues(alpha: 0.15)
                    : (isDone ? const Color(0xFF10B981).withValues(alpha: 0.12) : Colors.transparent),
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: isCurrent
                      ? const Color(0xFF184E78)
                      : (isDone ? const Color(0xFF10B981) : Colors.grey.withValues(alpha: 0.3)),
                  width: isCurrent ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 18.0,
                    height: 18.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? const Color(0xFF10B981)
                          : (isCurrent ? const Color(0xFF184E78) : Colors.grey.shade400),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, size: 12.0, color: Colors.white)
                          : Text(
                              '${s.stepNumber}',
                              style: const TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 6.0),
                  Text(
                    isSwahili ? s.titleSw : s.titleEn,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                      color: isCurrent
                          ? const Color(0xFF184E78)
                          : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildObservationBanner(MicroscopeState state, bool isSwahili, bool isDark) {
    final text = isSwahili ? state.observationSw : state.observationEn;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFDBEAFE),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.isInFocus ? Icons.check_circle_rounded : Icons.info_outline_rounded,
            color: state.isInFocus ? const Color(0xFF10B981) : const Color(0xFF184E78),
            size: 20.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E3A8A),
              ),
            ),
          ),
          if (state.isSlideOnStage && state.isLightOn) ...[
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: state.isInFocus
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFFF59E0B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: state.isInFocus ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                  width: 1.0,
                ),
              ),
              child: Text(
                '${(state.sharpness * 100).toStringAsFixed(0)}% ${isSwahili ? 'Ubora' : 'Sharpness'}',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: state.isInFocus ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- Step 1-4: Slide Preparation Workbench ---
  Widget _buildSlidePreparationWorkbench(
    MicroscopeState state,
    MicroscopeController controller,
    bool isSwahili,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  isSwahili ? 'Meza ya Kutayarisha Kiolezo' : 'Slide Preparation Workbench',
                  style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFA855F7).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  isSwahili ? 'Kitunguu Maji' : 'Onion Bulb',
                  style: const TextStyle(
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFA855F7),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14.0),

          // The slide on a white tile, prepared by the student's hand
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: AspectRatio(
              aspectRatio: MicroscopeSlidePainter.width / MicroscopeSlidePainter.height,
              child: LabHandPaint(
                watch: MicroscopeSlidePainter.handKeys(state),
                painter: (hands) => MicroscopeSlidePainter(state: state, hands: hands),
              ),
            ),
          ),
          const SizedBox(height: 14.0),

          // Apparatus Checklist
          Text(
            isSwahili ? 'Hatua za Kutayarisha:' : 'Preparation Checklist:',
            style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              _buildPrepChip(
                label: isSwahili ? '1. Kagua Vifaa' : '1. Inspect Apparatus',
                isDone: state.inspectedItems.length >= 4,
                onTap: () => _showApparatusInspectionModal(context, state, controller, isSwahili),
              ),
              _buildPrepChip(
                label: isSwahili ? '2. Weka Kiolezo' : '2. Mount Specimen',
                isDone: state.isSpecimenPlaced,
                onTap: state.inspectedItems.length >= 4 ? controller.placeSpecimen : null,
              ),
              _buildPrepChip(
                label: isSwahili ? '3. Weka Rangi (Iodine)' : '3. Apply Iodine',
                isDone: state.appliedStain != StainType.none,
                onTap: state.isSpecimenPlaced ? () => controller.applyStain(StainType.iodine) : null,
              ),
              _buildPrepChip(
                label: isSwahili ? '4. Funika Coverslip' : '4. Mount Coverslip',
                isDone: state.isCoverslipMounted,
                onTap: state.appliedStain != StainType.none ? controller.mountCoverslip : null,
              ),
              _buildPrepChip(
                label: isSwahili ? '5. Weka Kwenye Meza' : '5. Place on Stage',
                isDone: state.isSlideOnStage,
                onTap: state.isCoverslipMounted ? controller.placeSlideOnStage : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrepChip({
    required String label,
    required bool isDone,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isDone
              ? const Color(0xFF10B981).withValues(alpha: 0.15)
              : (onTap != null
                  ? const Color(0xFF184E78).withValues(alpha: 0.10)
                  : Colors.grey.withValues(alpha: 0.10)),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: isDone
                ? const Color(0xFF10B981)
                : (onTap != null ? const Color(0xFF184E78) : Colors.grey.shade400),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              size: 14.0,
              color: isDone
                  ? const Color(0xFF10B981)
                  : (onTap != null ? const Color(0xFF184E78) : Colors.grey),
            ),
            const SizedBox(width: 6.0),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDone
                    ? const Color(0xFF10B981)
                    : (onTap != null ? const Color(0xFF184E78) : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 5-9: Microscopy Observation Station ---
  Widget _buildMicroscopyObservationStation(
    MicroscopeState state,
    MicroscopeController controller,
    bool isSwahili,
    bool isDark,
  ) {
    return Column(
      children: [
        // Optical Eyepiece Viewport
        Center(
          child: Container(
            width: 270.0,
            height: 270.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16.0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                return CustomPaint(
                  painter: MicroscopeViewfinderPainter(
                    state: state,
                    isDark: isDark,
                    animationValue: _animController.value,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // Objective Selector (4x, 10x, 40x)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: MicroscopeObjective.values.map((obj) {
              final isSelected = state.selectedObjective == obj;
              Color color;
              switch (obj) {
                case MicroscopeObjective.low4x:
                  color = const Color(0xFFEF4444); // Red ring
                  break;
                case MicroscopeObjective.medium10x:
                  color = const Color(0xFFF59E0B); // Yellow ring
                  break;
                case MicroscopeObjective.high40x:
                  color = const Color(0xFF3B82F6); // Blue ring
                  break;
              }

              return InkWell(
                onTap: () => controller.setObjective(obj),
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.20) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10.0,
                        height: 10.0,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        '${obj.magnification}× (${MicroscopeState.eyepieceMagnification * obj.magnification}×)',
                        style: TextStyle(
                          fontSize: 12.0,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? (isDark ? Colors.white : color)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14.0),

        // Focus and Light Tuning Controls
        Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Coarse Focus Slider
              Row(
                children: [
                  SizedBox(
                    width: 95.0,
                    child: Text(
                      isSwahili ? 'Lengo Kuu (Coarse):' : 'Coarse Focus:',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: state.coarseFocus,
                      min: 0.0,
                      max: 100.0,
                      activeColor: const Color(0xFF184E78),
                      onChanged: (val) => controller.setCoarseFocus(val),
                    ),
                  ),
                  Text(
                    state.coarseFocus.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              // Fine Focus Slider
              Row(
                children: [
                  SizedBox(
                    width: 95.0,
                    child: Text(
                      isSwahili ? 'Lengo Dogo (Fine):' : 'Fine Focus:',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: state.fineFocus,
                      min: 0.0,
                      max: 100.0,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) => controller.setFineFocus(val),
                    ),
                  ),
                  Text(
                    state.fineFocus.toStringAsFixed(0),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              // Illumination Slider
              Row(
                children: [
                  SizedBox(
                    width: 95.0,
                    child: Row(
                      children: [
                        Icon(
                          state.isLightOn ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                          size: 14.0,
                          color: state.isLightOn ? Colors.amber : Colors.grey,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          isSwahili ? 'Mwanga:' : 'Light:',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: state.lightIntensity,
                      min: 0.0,
                      max: 100.0,
                      activeColor: Colors.amber,
                      onChanged: (val) => controller.setLightIntensity(val),
                    ),
                  ),
                  Text(
                    '${state.lightIntensity.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Organelle Identification & Calculations Card ---
  Widget _buildControlsCard(
    MicroscopeState state,
    MicroscopeController controller,
    bool isSwahili,
    bool isDark,
  ) {
    if (state.currentStep.stepNumber < 7 && state.mode != PracticalMode.freeExploration) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Utambuzi wa Sehemu za Seli' : 'Organelle Identification & Data',
                style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w800),
              ),
              Text(
                '${state.identifiedOrganelleIds.length}/${kIdentifiableOrganelles.length}',
                style: const TextStyle(
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF184E78),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            isSwahili
                ? 'Gusa sehemu za seli zilizotambuliwa chini ya darubini:'
                : 'Select cellular structures observed under microscopy:',
            style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12.0),

          // Organelle selection chips
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: kIdentifiableOrganelles.map((org) {
              final isSelected = state.identifiedOrganelleIds.contains(org.id);
              return FilterChip(
                label: Text(isSwahili ? org.nameSw : org.nameEn),
                selected: isSelected,
                onSelected: (_) => controller.toggleOrganelleSelection(org.id),
                selectedColor: const Color(0xFF184E78).withValues(alpha: 0.2),
                checkmarkColor: const Color(0xFF184E78),
                labelStyle: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF184E78)
                      : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF334155)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16.0),

          // Action Button: Submit Observations / Complete Practical
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.calculate_rounded),
              label: Text(
                isSwahili ? 'Hesabu & Kamilisha Jaribio' : 'Calculate & Complete Practical',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF184E78),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13.0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              ),
              onPressed: () => _showCalculationDialog(context, state, controller, isSwahili),
            ),
          ),
        ],
      ),
    );
  }

  // Calculation Modal
  void _showCalculationDialog(
    BuildContext context,
    MicroscopeState state,
    MicroscopeController controller,
    bool isSwahili,
  ) {
    final calcController = TextEditingController(text: '${state.totalMagnification}');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(isSwahili ? 'Hesabu ya Kukuza kwa Darubini' : 'Magnification Calculation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSwahili
                    ? 'Fomula ya Ukuzaji Kamili (Total Magnification):\n'
                        'M = Ukuzaji wa Eyepiece (10×) × Ukuzaji wa Lenzi (${state.selectedObjective.magnification}×)'
                    : 'Total Optical Magnification Formula:\n'
                        'M = Eyepiece (10×) × Objective Lens (${state.selectedObjective.magnification}×)',
                style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14.0),
              TextField(
                controller: calcController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isSwahili ? 'Ukuzaji Kamili (M)' : 'Total Magnification (×)',
                  suffixText: '×',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF184E78),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final calculated = int.tryParse(calcController.text) ?? state.totalMagnification;
                Navigator.of(ctx).pop();
                controller.submitObservations(calculated);
              },
              child: Text(isSwahili ? 'Wasilisha' : 'Submit Score'),
            ),
          ],
        );
      },
    );
  }

  // Apparatus Inspection Modal
  void _showApparatusInspectionModal(
    BuildContext context,
    MicroscopeState state,
    MicroscopeController controller,
    bool isSwahili,
  ) {
    final items = [
      {'id': 'microscope', 'en': 'Compound Light Microscope', 'sw': 'Darubini ya Mwangaza'},
      {'id': 'glass_slide', 'en': 'Glass Slides & Coverslips', 'sw': 'Vioo vya Slide na Coverslip'},
      {'id': 'mounted_needle', 'en': 'Mounted Needle (45°)', 'sw': 'Sindano ya Kufunikia'},
      {'id': 'onion_peel', 'en': 'Fresh Onion Bulb (Allium cepa)', 'sw': 'Kitunguu Maji Safi'},
      {'id': 'iodine_dropper', 'en': 'Dilute Iodine Solution', 'sw': 'Rangi ya Iodini'},
      {'id': 'filter_paper', 'en': 'Filter / Blotting Paper', 'sw': 'Karatasi ya Kukaushia'},
    ];

    String? selected;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            // read afresh on each rebuild, so the ticks show as items are inspected
            final live = ref.read(microscopeControllerProvider(widget.mode));
            return Container(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSwahili ? 'Ukaguzi wa Vifaa vya Maabara' : 'Apparatus & Reagent Inspection',
                    style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    isSwahili
                        ? 'Gusa kifaa ili kukikagua kabla ya kuanza jaribio (Vifaa 4 vinahitajika):'
                        : 'Tap equipment to inspect before starting the practical (4 required):',
                    style: const TextStyle(fontSize: 12.0, color: Colors.grey),
                  ),
                  const SizedBox(height: 12.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: AspectRatio(
                      aspectRatio: MicroscopeApparatusPainter.width / MicroscopeApparatusPainter.height,
                      child: CustomPaint(painter: MicroscopeApparatusPainter(selected: selected)),
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  ...items.map((item) {
                    final isInspected = live.inspectedItems.contains(item['id']);
                    return ListTile(
                      dense: true,
                      selected: selected == item['id'],
                      selectedTileColor: const Color(0x1FDB9E3D),
                      selectedColor: const Color(0xFF184E78),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                      leading: Icon(
                        isInspected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                        color: isInspected ? const Color(0xFF10B981) : Colors.grey,
                      ),
                      title: Text(
                        isSwahili ? item['sw']! : item['en']!,
                        style: TextStyle(
                          fontWeight: isInspected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        controller.inspectItem(item['id']!);
                        setModalState(() => selected = item['id']);
                      },
                    );
                  }),
                  const SizedBox(height: 12.0),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF184E78),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(isSwahili ? 'Nimemaliza Kukagua' : 'Done Inspecting'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Lab Notebook Sheet
  void _showLabNotebook(BuildContext context, bool isSwahili, MicroscopeState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.70,
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isSwahili ? 'Daftari la Maabara (Lab Notebook)' : 'Laboratory Notebook & Theory',
                      style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const Divider(),
                Text(
                  isSwahili ? '1. Kanuni za Kisayansi (Biological Theory)' : '1. Biological Theory',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF184E78)),
                ),
                const SizedBox(height: 6.0),
                Text(
                  isSwahili
                      ? '• Kiolezo: Seli za kitunguu maji (Allium cepa) ni mfano mzuri wa seli za mmea za aina ya parenchyma.\n'
                          '• Upakaji Rangi: Myeyusho wa Iodini hutumika kuweka rangi kwenye seli za mimea ili kufanya kiini (nucleus) kionekane wazi na kuta za seli (cell wall) zionekane zenye umbo thabiti.\n'
                          '• Kuzuia Mapovu ya Hewa: Kioo kidogo cha coverslip kinatakiwa kuteremshwa kwa kutumia sindano ya maabara kwa pembe ya 45° ili kuzuia hewa kubana katikati.'
                      : '• Specimen: Onion epidermal cells (Allium cepa) represent typical plant parenchyma tissue.\n'
                          '• Staining: Iodine solution stains starch grains, makes nuclei prominent (dark amber brown), and enhances cell wall contrast.\n'
                          '• Air Bubble Prevention: Coverslip must be lowered at 45° using a mounted needle to prevent artifact air bubbles.',
                  style: const TextStyle(fontSize: 12.0, height: 1.5),
                ),
                const SizedBox(height: 14.0),
                Text(
                  isSwahili ? '2. Fomula ya Ukuzaji (Magnification)' : '2. Magnification Calculations',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF184E78)),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Total Magnification = Eyepiece Magnification (10×) × Objective Lens Magnification (4×, 10×, 40×)',
                  style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
