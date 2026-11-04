import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/pendulum_state.dart';
import '../../data/models/practical_model.dart';
import '../controllers/pendulum_controller.dart';
import '../widgets/pendulum_bench_painter.dart';
import '../widgets/lab_hand.dart';
import '../widgets/practical_layout.dart';
import '../widgets/pendulum_graph_widget.dart';
import '../widgets/titration_completion_card.dart';
import '../../../../core/utils/learning_language.dart';

class PendulumScreen extends ConsumerStatefulWidget {
  final PracticalMode mode;

  const PendulumScreen({
    super.key,
    required this.mode,
  });

  @override
  ConsumerState<PendulumScreen> createState() => _PendulumScreenState();
}

class _PendulumScreenState extends ConsumerState<PendulumScreen> with TickerProviderStateMixin {
  late final LabHandRuns _hands = LabHandRuns(this);

  /// The metre rule is on the bench only while the length is set.
  static bool _showRule(PendulumState s) => s.currentStepIndex <= 1;

  /// The hand holds the bob at the release angle until it is let go.
  /// The hand holds the bob out at the release angle while it is set, and
  /// on through the timing step until the student presses Start.
  static bool _holding(PendulumState s) =>
      !s.isOscillating && (s.currentStepIndex == 2 || (s.currentStepIndex == 3 && s.stopwatchElapsedSec == 0));
  final TextEditingController _gradientController = TextEditingController();
  final TextEditingController _gravityController = TextEditingController();

  final List<ApparatusInspectItem> _inspectItems = const [
    ApparatusInspectItem(
      key: 'stand',
      nameEn: 'Retort Stand & Clamp',
      nameSw: 'Standi na Kishikio cha Chuma',
      roleEn: 'Provides a rigid, stable vertical support for the pendulum pivot.',
      roleSw: 'Inashikilia kishikio cha juu bila kutetereka wakati wa mtetemo.',
      icon: '🏗️',
    ),
    ApparatusInspectItem(
      key: 'bob',
      nameEn: 'Heavy Metallic Bob',
      nameSw: 'Tufe ya Metali Nzito',
      roleEn: 'High-density brass sphere providing a concentrated point mass and minimizing air drag.',
      roleSw: 'Tufe nzito ya shaba inayopunguza msuguano wa hewa wakati wa mtetemo.',
      icon: '⚪',
    ),
    ApparatusInspectItem(
      key: 'thread',
      nameEn: 'Inextensible Nylon Thread',
      nameSw: 'Uzi Usionyooka wa Nailoni',
      roleEn: 'Light inextensible string ensuring constant length during oscillation.',
      roleSw: 'Uzi mwepesi usionyooka unaodumisha urefu thabiti wakati wa mtetemo.',
      icon: '🧵',
    ),
    ApparatusInspectItem(
      key: 'ruler',
      nameEn: 'Metre Rule (0–100 cm)',
      nameSw: 'Rula ya Mita (cm 0–100)',
      roleEn: 'Measures length L accurately from the suspension point to the center of the bob.',
      roleSw: 'Inapima urefu L kutoka eneo la kuning’inizia hadi katikati ya tufe.',
      icon: '📏',
    ),
    ApparatusInspectItem(
      key: 'stopwatch',
      nameEn: 'Digital Precision Stopwatch',
      nameSw: 'Saa ya Kidijitali ya Kupimia',
      roleEn: 'Times 20 complete oscillations with 0.01s electronic accuracy.',
      roleSw: 'Inapima muda wa mitetemo 20 kamili kwa usahihi wa sekunde 0.01.',
      icon: '⏱️',
    ),
  ];

  @override
  void dispose() {
    _gradientController.dispose();
    _gravityController.dispose();
    _hands.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pendulumControllerProvider(widget.mode));
    _hands.enabled = !MediaQuery.disableAnimationsOf(context);
    _hands.watch('rule', _showRule(state));
    _hands.watch('hold', _holding(state));
    _hands.watch('watch', state.isOscillating);
    _hands.watch('length', state.pendulumLengthCm);
    final notifier = ref.read(pendulumControllerProvider(widget.mode).notifier);
    final language = learningLanguage();
    final isSwahili = language == 'sw';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final stepTitlesEn = [
      '1. Inspect Apparatus',
      '2. Set String Length',
      '3. Deflect Bob',
      '4. Time Oscillations',
      '5. Trials Table',
      '6. T²-L Graph',
      '7. Calculate Gravity (g)',
    ];

    final stepTitlesSw = [
      '1. Kagua Vifaa',
      '2. Weka Urefu wa Uzi',
      '3. Vuta Tufe',
      '4. Pima Mitetemo',
      '5. Jedwali la Majaribio',
      '6. Grafu ya T²-L',
      '7. Hesabu Mvuto (g)',
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmationDialog(context, isDark, isSwahili);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _showExitConfirmationDialog(context, isDark, isSwahili),
          ),
          titleSpacing: 0,
          // Mode and session time above the title, so the title has the full width.
          title: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      widget.mode.id.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.timer_outlined, size: 13, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(
                    _formatTime(state.elapsedSeconds),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : AppColors.heroNavyDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                isSwahili ? 'Penduli Rahisi (g)' : 'Simple Pendulum (g)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.heroNavyDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            // Lab Notebook Button
            IconButton(
              icon: const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 20),
              tooltip: isSwahili ? 'Kitabu cha Maabara' : 'Lab Notebook',
              onPressed: () => _showNotebookBottomSheet(context, state, isDark, isSwahili),
            ),
            // Reset Button
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20),
              tooltip: isSwahili ? 'Weka Upya' : 'Reset Experiment',
              onPressed: () => notifier.resetExperiment(widget.mode),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Workflow Step Bar
              _buildStepTabBar(state, notifier, isSwahili ? stepTitlesSw : stepTitlesEn, isDark),

              // Bench and step controls: stacked on phones, side by side when wide.
              Expanded(
                child: PracticalSplitLayout(
                  step: state.currentStepIndex,
                  bench: _buildLaboratoryWorkbench(state, isDark, isSwahili),
                  controls: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildStepWorkspace(state, notifier, isDark, isSwahili),
                      const SizedBox(height: 16),
                      _buildBottomStepNavigation(state, notifier, isDark, isSwahili),
                      const SizedBox(height: 24),
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

  Widget _buildStepTabBar(
    PendulumState state,
    PendulumController notifier,
    List<String> stepTitles,
    bool isDark,
  ) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: stepTitles.length,
        itemBuilder: (context, index) {
          final isSelected = state.currentStepIndex == index;
          final isPassed = state.currentStepIndex > index;

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () => notifier.jumpToStep(index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isPassed
                          ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                ),
                child: Row(
                  children: [
                    if (isPassed) ...[
                      const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      stepTitles[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : AppColors.heroNavyDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLaboratoryWorkbench(PendulumState state, bool isDark, bool isSwahili) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // The bench, cropped to the apparatus and upright enough to fill a
      // phone, with what is happening written underneath it.
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.55),
                child: AspectRatio(
                  aspectRatio: PendulumBenchPainter.cropWidth / 380,
                  child: CustomPaint(
                    painter: PendulumBenchPainter(
                      lengthCm: state.pendulumLengthCm,
                      // While the bob is held, show it out at the release angle.
                      angleDeg: _holding(state) ? state.deflectionAngleDeg : state.currentAngleDeg,
                      releaseAngleDeg: state.deflectionAngleDeg,
                      isOscillating: state.isOscillating,
                      isDark: isDark,
                      stopwatchSeconds: state.stopwatchElapsedSec,
                      oscillations: state.currentOscillations,
                      targetOscillations: state.targetOscillations,
                      inspectedItemKey: state.currentStepIndex == 0 ? state.selectedInspectItemKey : null,
                      showRule: _showRule(state),
                      holding: _holding(state),
                      hands: _hands,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // What is happening on the bench
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (isDark ? const Color(0xFF0F172A) : Colors.white).withValues(alpha: 0.90),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isSwahili ? state.observationMessageSw : state.observationMessageEn,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.heroNavyDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildStepWorkspace(
    PendulumState state,
    PendulumController notifier,
    bool isDark,
    bool isSwahili,
  ) {
    switch (state.currentStepIndex) {
      case 0:
        return _buildApparatusInspectionCard(state, notifier, isDark, isSwahili);
      case 1:
        return _buildLengthAdjustmentCard(state, notifier, isDark, isSwahili);
      case 2:
        return _buildDeflectionAngleCard(state, notifier, isDark, isSwahili);
      case 3:
        return _buildStopwatchTimingCard(state, notifier, isDark, isSwahili);
      case 4:
        return _buildTrialsTableCard(state, notifier, isDark, isSwahili);
      case 5:
        return PendulumGraphWidget(
          trials: state.recordedTrials,
          calculatedSlope: state.calculatedRegressionSlope,
          calculatedGravity: state.calculatedExperimentalGravity,
          isDark: isDark,
          isSwahili: isSwahili,
        );
      case 6:
        return _buildGravityCalculationCard(state, notifier, isDark, isSwahili);
      default:
        return const SizedBox.shrink();
    }
  }

  // Step 0: Apparatus Inspection Card
  Widget _buildApparatusInspectionCard(
    PendulumState state,
    PendulumController notifier,
    bool isDark,
    bool isSwahili,
  ) {
    final textColor = isDark ? Colors.white : AppColors.heroNavyDark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Vifaa vya Maabara' : 'Laboratory Apparatus',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${state.inspectedItems.length} / ${_inspectItems.length} ${isSwahili ? 'Vimekaguliwa' : 'Inspected'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isSwahili
                ? 'Gusa kila kifaa ili kukagua na kujifunza jukumu lake katika jaribio:'
                : 'Tap each apparatus component to inspect and verify its role in the experiment:',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _inspectItems.map((item) {
              final isInspected = state.inspectedItems.contains(item.key);
              final isSelected = state.selectedInspectItemKey == item.key;

              return InkWell(
                onTap: () => notifier.inspectItem(item.key),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isInspected
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        isSwahili ? item.nameSw : item.nameEn,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white : AppColors.heroNavyDark),
                        ),
                      ),
                      if (isInspected) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Step 1: Length Adjustment Card
  Widget _buildLengthAdjustmentCard(
    PendulumState state,
    PendulumController notifier,
    bool isDark,
    bool isSwahili,
  ) {
    final textColor = isDark ? Colors.white : AppColors.heroNavyDark;
    const presets = [20.0, 40.0, 60.0, 80.0, 100.0];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Kuweka Urefu wa Uzi (L)' : 'Set String Length (L)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'L = ${state.pendulumLengthCm.toStringAsFixed(1)} cm (${(state.pendulumLengthCm / 100).toStringAsFixed(2)} m)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isSwahili
                ? 'Rekebisha urefu wa uzi kwa kutelezesha kitelezi au kuchagua thamani za haraka:'
                : 'Adjust length from pivot to center of bob using the slider or quick presets:',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // Length Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              thumbColor: AppColors.primary,
              trackHeight: 4,
            ),
            child: Slider(
              value: state.pendulumLengthCm,
              min: 20.0,
              max: 100.0,
              divisions: 16,
              label: '${state.pendulumLengthCm.toStringAsFixed(1)} cm',
              onChanged: (val) => notifier.setLength(val),
            ),
          ),

          // Preset Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: presets.map((preset) {
              final isSelected = (state.pendulumLengthCm - preset).abs() < 0.1;
              return InkWell(
                onTap: () => notifier.setLength(preset),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Text(
                    '${preset.toInt()} cm',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : AppColors.heroNavyDark),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Step 2: Small Angle Deflection Card
  Widget _buildDeflectionAngleCard(
    PendulumState state,
    PendulumController notifier,
    bool isDark,
    bool isSwahili,
  ) {
    final textColor = isDark ? Colors.white : AppColors.heroNavyDark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Pembe ya Mvuto (θ)' : 'Deflection Amplitude (θ)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'θ = ${state.deflectionAngleDeg.toStringAsFixed(1)}° (SHM)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isSwahili
                ? 'Kanuni ya SHM inahitaji pembe ndogo (θ ≤ 10°) ili sin(θ) ≈ θ katika rediani.'
                : 'Simple harmonic motion requires small amplitude (θ ≤ 10°) so that sin(θ) ≈ θ in radians.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // Slider
          Slider(
            value: state.deflectionAngleDeg,
            min: 2.0,
            max: 10.0,
            divisions: 8,
            label: '${state.deflectionAngleDeg.toStringAsFixed(1)}°',
            onChanged: (val) => notifier.setDeflectionAngle(val),
          ),
        ],
      ),
    );
  }

  // Step 3: Stopwatch Timing Card
  Widget _buildStopwatchTimingCard(
    PendulumState state,
    PendulumController notifier,
    bool isDark,
    bool isSwahili,
  ) {
    final textColor = isDark ? Colors.white : AppColors.heroNavyDark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Kipimio cha Muda (Saa ya Mkononi)' : 'Digital Stopwatch & Timing',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'n = ${state.targetOscillations} ${isSwahili ? 'Mitetemo' : 'Oscillations'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Big Stopwatch Display Box
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: state.isOscillating
                    ? const Color(0xFF06B6D4)
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${state.stopwatchElapsedSec.toStringAsFixed(2)} s',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: state.isOscillating ? const Color(0xFF06B6D4) : textColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSwahili
                      ? 'Mitetemo Iliyokamilika: ${state.currentOscillations} / ${state.targetOscillations}'
                      : 'Completed Oscillations: ${state.currentOscillations} / ${state.targetOscillations}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Stopwatch Action Buttons
          Row(
            children: [
              // Start / Stop Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (state.isOscillating) {
                      notifier.stopOscillation();
                    } else {
                      notifier.startOscillation();
                    }
                  },
                  icon: Icon(
                    state.isOscillating ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 18,
                  ),
                  label: Text(
                    state.isOscillating
                        ? (isSwahili ? 'Simamisha' : 'Stop Timing')
                        : (isSwahili ? 'Anza Mitetemo' : 'Start Oscillations'),
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        state.isOscillating ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Record Trial Button
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    notifier.recordTrial();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isSwahili
                              ? 'Jaribio limehifadhiwa kwenye jedwali!'
                              : 'Trial recorded into observation table!',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bookmark_add_rounded, size: 18),
                  label: Text(
                    isSwahili ? 'Hifadhi Jaribio' : 'Record Trial',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Reset Stopwatch Button
              IconButton(
                onPressed: () => notifier.resetOscillation(),
                icon: const Icon(Icons.replay_rounded),
                tooltip: isSwahili ? 'Weka Upya Saa' : 'Reset Stopwatch',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Step 4: Multi-Trial Table Card
  Widget _buildTrialsTableCard(
    PendulumState state,
    PendulumController notifier,
    bool isDark,
    bool isSwahili,
  ) {
    final textColor = isDark ? Colors.white : AppColors.heroNavyDark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Jedwali la Majaribio' : 'Observation Trials Table',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
              ElevatedButton.icon(
                onPressed: () => notifier.recordTrial(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  isSwahili ? 'Ongeza Hivi Sasa' : 'Record Current',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (state.recordedTrials.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.table_rows_rounded,
                      size: 36, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                  const SizedBox(height: 8),
                  Text(
                    isSwahili
                        ? 'Bado hakuna majaribio yaliyohifadhiwa. Pima muda na ubonyeze "Hifadhi Jaribio".'
                        : 'No trials recorded yet. Time oscillations and tap "Record Trial".',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                horizontalMargin: 8,
                headingRowHeight: 36,
                dataRowMinHeight: 34,
                dataRowMaxHeight: 40,
                columns: [
                  DataColumn(
                    label: Text(
                      isSwahili ? 'Jaribio' : 'Trial',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'L (cm)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'L (m)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      't₂₀ (s)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'T (s)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text(
                      'T² (s²)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const DataColumn(
                    label: Text('', style: TextStyle(fontSize: 11)),
                  ),
                ],
                rows: state.recordedTrials.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final t = entry.value;

                  return DataRow(
                    cells: [
                      DataCell(Text('#${t.trialNumber}', style: const TextStyle(fontSize: 11))),
                      DataCell(Text(t.lengthCm.toStringAsFixed(1), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(t.lengthMeters.toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(t.timeSeconds.toStringAsFixed(2), style: const TextStyle(fontSize: 11))),
                      DataCell(Text(t.periodSeconds.toStringAsFixed(3), style: const TextStyle(fontSize: 11))),
                      DataCell(
                        Text(
                          t.periodSquared.toStringAsFixed(3),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                          onPressed: () => notifier.deleteTrial(idx),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Step 6: Gravity Calculation & Evaluation Card
  Widget _buildGravityCalculationCard(
    PendulumState state,
    PendulumController notifier,
    bool isDark,
    bool isSwahili,
  ) {
    final textColor = isDark ? Colors.white : AppColors.heroNavyDark;
    final expSlope = state.calculatedRegressionSlope;
    final expGravity = state.calculatedExperimentalGravity;
    final pctError = state.percentageError;

    if (state.isCompleted && state.scoreResult != null) {
      return TitrationCompletionCard(
        scoreResult: state.scoreResult!,
        isDark: isDark,
        isSwahili: isSwahili,
        onRepeat: () => notifier.resetExperiment(widget.mode),
        onFinish: () => context.pop(),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSwahili ? 'Uhesabuji wa Kani ya Mvuto (g)' : 'Determination of Acceleration Due to Gravity (g)',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 6),
          Text(
            isSwahili
                ? 'Tumia mteremko wa grafu m = Δ(T²)/ΔL kuhesabu thamani ya kani ya mvuto g kwa fomula g = 4π² / m:'
                : 'Use graph gradient m = Δ(T²)/ΔL to calculate local gravity g using the formula g = 4π² / m:',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Theoretical Values Readout Box
          if (expSlope != null && expGravity != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSwahili ? 'Mteremko wa Grafu (m):' : 'Plotted Gradient (m):',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${expSlope.toStringAsFixed(3)} s²/m',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSwahili ? 'Kani ya Mvuto (g = 4π²/m):' : 'Calculated Gravity (g = 4π²/m):',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${expGravity.toStringAsFixed(2)} m/s²',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  if (pctError != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isSwahili ? 'Hitilafu ya Asilimia (% Error):' : 'Percentage Error (%):',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${pctError.toStringAsFixed(2)}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Student Input Form (Optional for Exam Mode)
          TextFormField(
            controller: _gravityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: isSwahili ? 'Ingiza Thamani Yako ya g (m/s²)' : 'Enter Your Calculated g (m/s²)',
              hintText: isSwahili ? 'Weka thamani ya g' : 'Enter calculated g',
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: (val) => notifier.setStudentInputs(gravity: val),
          ),
          const SizedBox(height: 14),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () {
                notifier.submitCalculations();
              },
              icon: const Icon(Icons.fact_check_rounded, size: 20),
              label: Text(
                isSwahili ? 'Wasilisha na Kamilisha Jaribio' : 'Submit & Complete Practical',
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStepNavigation(
    PendulumState state,
    PendulumController notifier,
    bool isDark,
    bool isSwahili,
  ) {
    return Row(
      children: [
        if (state.currentStepIndex > 0) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => notifier.previousStep(),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(
                isSwahili ? 'Hatua Iliyopita' : 'Previous Step',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white70 : AppColors.heroNavyDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
        if (state.currentStepIndex < 6) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => notifier.nextStep(),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(
                isSwahili ? 'Hatua Inayofuata' : 'Next Step',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showNotebookBottomSheet(
    BuildContext context,
    PendulumState state,
    bool isDark,
    bool isSwahili,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkBgSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            isSwahili ? 'Daftari la Maabara (Lab Notebook)' : 'Physics Laboratory Notebook',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.heroNavyDark,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      itemCount: state.notebookLogs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (_, idx) {
                        final log = state.notebookLogs[idx];
                        return Text(
                          log,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        );
                      },
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
              ? 'Je, una uhakika unataka kuondoka kwenye jaribio hili la Penduli Rahisi?'
              : 'Are you sure you want to exit the Simple Pendulum virtual laboratory?',
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

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
