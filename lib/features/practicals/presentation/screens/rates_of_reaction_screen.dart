import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/practical_model.dart';
import '../../data/models/rates_of_reaction_state.dart';
import '../controllers/rates_of_reaction_controller.dart';
import '../widgets/rates_of_reaction_bench_painter.dart';
import '../widgets/rates_of_reaction_graph_widget.dart';
import '../widgets/titration_completion_card.dart';
import '../../../../core/utils/learning_language.dart';

class RatesOfReactionScreen extends ConsumerStatefulWidget {
  final PracticalMode mode;

  const RatesOfReactionScreen({super.key, required this.mode});

  @override
  ConsumerState<RatesOfReactionScreen> createState() => _RatesOfReactionScreenState();
}

class _RatesOfReactionScreenState extends ConsumerState<RatesOfReactionScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final TextEditingController _slopeInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ratesOfReactionControllerProvider.notifier).initializeForMode(widget.mode);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slopeInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ratesOfReactionControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSwahili = learningLanguage() == 'sw';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmationDialog(context, isDark, isSwahili);
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: _buildAppBar(context, ref, state, isDark, isSwahili),
        body: SafeArea(
          child: Column(
            children: [
              // 1. Step Tab Bar
              _buildStepTabBar(ref, state, isDark, isSwahili),

              // 2. Info / Instructions Banner
              _buildInstructionsBanner(state, isDark, isSwahili),

              // 3. Main Workspace Area
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Virtual Laboratory Bench Canvas
                      _buildLaboratoryCanvas(state, isDark),
                      const SizedBox(height: 16),

                      // Dynamic Step Controls
                      _buildStepWorkspace(context, ref, state, isDark, isSwahili),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // 4. Bottom Navigation Action Bar
              _buildBottomActionBar(context, ref, state, isDark, isSwahili),
            ],
          ),
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
    RatesOfReactionState state,
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.mode == PracticalMode.guidedPractice
                      ? const Color(0xFF38BDF8).withValues(alpha: 0.15)
                      : (widget.mode == PracticalMode.examMode
                          ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                          : const Color(0xFF10B981).withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.mode.labelEn.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: widget.mode == PracticalMode.guidedPractice
                        ? const Color(0xFF0284C7)
                        : (widget.mode == PracticalMode.examMode
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF059669)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isSwahili ? 'Kasi ya Miitikio ya Kikemia' : 'Rates of Chemical Reactions',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.menu_book_rounded, size: 20),
          tooltip: isSwahili ? 'Daftari la Maabara' : 'Lab Notebook',
          onPressed: () => _showLabNotebookModal(context, isDark, isSwahili),
        ),
        IconButton(
          icon: const Icon(Icons.restart_alt_rounded, size: 20),
          tooltip: isSwahili ? 'Anza Upya' : 'Reset Experiment',
          onPressed: () {
            ref.read(ratesOfReactionControllerProvider.notifier).reset(widget.mode);
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step Tab Bar
  // ---------------------------------------------------------------------------
  Widget _buildStepTabBar(
    WidgetRef ref,
    RatesOfReactionState state,
    bool isDark,
    bool isSwahili,
  ) {
    return Container(
      height: 44,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: RatesOfReactionStep.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final step = RatesOfReactionStep.values[index];
          final isSelected = state.step == step;
          final isUnlocked = widget.mode == PracticalMode.freeExploration ||
              index <= _highestUnlockedStep(state);

          return InkWell(
            onTap: isUnlocked
                ? () => ref.read(ratesOfReactionControllerProvider.notifier).setStep(step)
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.25 : 0.15)
                    : (isUnlocked
                        ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF38BDF8)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUnlocked) ...[
                    Icon(Icons.lock_outline_rounded,
                        size: 12, color: isDark ? Colors.white30 : Colors.black26),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    isSwahili ? step.labelSw : step.labelEn,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7))
                          : (isUnlocked
                              ? (isDark ? Colors.white70 : const Color(0xFF475569))
                              : (isDark ? Colors.white30 : Colors.black26)),
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

  int _highestUnlockedStep(RatesOfReactionState state) {
    if (state.scoreResult != null) return 4;
    if (state.allTrialsCompleted) return 4;
    if (state.allTrialsPrepared) return 2;
    if (state.allApparatusInspected) return 1;
    return 0;
  }

  // ---------------------------------------------------------------------------
  // Instructions Banner
  // ---------------------------------------------------------------------------
  Widget _buildInstructionsBanner(
    RatesOfReactionState state,
    bool isDark,
    bool isSwahili,
  ) {
    String instruction;
    switch (state.step) {
      case RatesOfReactionStep.inspectApparatus:
        instruction = isSwahili
            ? 'Kagua vifaa vyote 6 maabarani ili kuelewa utendaji kazi wake kabla ya kuanza.'
            : 'Inspect all 6 apparatus items to understand their specifications before starting.';
        break;
      case RatesOfReactionStep.prepareSolutions:
        instruction = isSwahili
            ? 'Pima ujazo sahihi wa Na₂S₂O₃ na maji (H₂O) kwenye chupa 5 za koni ili kupata ukolezi tofauti.'
            : 'Measure and dilute sodium thiosulfate with distilled water across 5 conical flasks (0.04 M to 0.20 M).';
        break;
      case RatesOfReactionStep.runReactionTrials:
        instruction = isSwahili
            ? 'Weka chupa juu ya msalaba, ongeza 5 mL za HCl, washa saa, na bonyeza "Msalaba Umetoweka" mara ukungu unapouficha kabisa.'
            : 'Place flask over cross, add 5 mL HCl, start timer, and tap "Cross Obscured" the instant the cross disappears.';
        break;
      case RatesOfReactionStep.resultsTable:
        instruction = isSwahili
            ? 'Kagua jedwali la matokeo ya muda (t) na kasi (1/t) kwa kila chupa ya mmenyuko.'
            : 'Review the recorded reaction times (t) and calculated kinetic rates (1/t) for all 5 flasks.';
        break;
      case RatesOfReactionStep.graphAnalysis:
        instruction = isSwahili
            ? 'Chora grafu ya kasi (1/t) dhidi ya ukolezi [Na₂S₂O₃] na uamue mteremko (k) wa kanuni ya kasi.'
            : 'Analyze the linear rate plot (1/t vs [Na₂S₂O₃]), estimate slope k, and deduce the 1st-order rate law.';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFE0F2FE),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF0284C7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF0369A1),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Laboratory Canvas
  // ---------------------------------------------------------------------------
  Widget _buildLaboratoryCanvas(RatesOfReactionState state, bool isDark) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return CustomPaint(
              size: const Size(double.infinity, 240),
              painter: RatesOfReactionBenchPainter(
                state: state,
                isDark: isDark,
                animationValue: _pulseController.value,
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step Workspace Switcher
  // ---------------------------------------------------------------------------
  Widget _buildStepWorkspace(
    BuildContext context,
    WidgetRef ref,
    RatesOfReactionState state,
    bool isDark,
    bool isSwahili,
  ) {
    switch (state.step) {
      case RatesOfReactionStep.inspectApparatus:
        return _buildInspectWorkspace(ref, state, isDark, isSwahili);
      case RatesOfReactionStep.prepareSolutions:
        return _buildPrepareWorkspace(ref, state, isDark, isSwahili);
      case RatesOfReactionStep.runReactionTrials:
        return _buildReactionTrialsWorkspace(ref, state, isDark, isSwahili);
      case RatesOfReactionStep.resultsTable:
        return _buildResultsTableWorkspace(ref, state, isDark, isSwahili);
      case RatesOfReactionStep.graphAnalysis:
        return _buildGraphWorkspace(context, ref, state, isDark, isSwahili);
    }
  }

  // ---------------------------------------------------------------------------
  // Step 1: Apparatus Inspection
  // ---------------------------------------------------------------------------
  Widget _buildInspectWorkspace(
    WidgetRef ref,
    RatesOfReactionState state,
    bool isDark,
    bool isSwahili,
  ) {
    final inspectedCount = state.apparatus.where((i) => i.inspected).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isSwahili ? 'Orodha ya Vifaa vya Maabara' : 'Apparatus & Reagents Checklist',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: state.allApparatusInspected
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : const Color(0xFF38BDF8).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$inspectedCount/${state.apparatus.length}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: state.allApparatusInspected
                      ? const Color(0xFF10B981)
                      : const Color(0xFF0284C7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...state.apparatus.map((item) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: item.inspected
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                onTap: () =>
                    ref.read(ratesOfReactionControllerProvider.notifier).inspectItem(item.id),
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: item.inspected
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.inspected ? Icons.check_circle_rounded : Icons.search_rounded,
                    color: item.inspected ? const Color(0xFF10B981) : const Color(0xFF0284C7),
                    size: 18,
                  ),
                ),
                title: Text(
                  isSwahili ? item.nameSw : item.nameEn,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                subtitle: Text(
                  isSwahili ? item.specSw : item.specEn,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }),
        if (widget.mode == PracticalMode.guidedPractice && !state.allApparatusInspected) ...[
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () =>
                ref.read(ratesOfReactionControllerProvider.notifier).inspectAll(),
            icon: const Icon(Icons.done_all_rounded, size: 16),
            label: Text(isSwahili ? 'Kagua Vifaa Vyote' : 'Inspect All Apparatus'),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Prepare Solutions
  // ---------------------------------------------------------------------------
  Widget _buildPrepareWorkspace(
    WidgetRef ref,
    RatesOfReactionState state,
    bool isDark,
    bool isSwahili,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isSwahili ? 'Utayarishaji wa Myeyusho (Chupa 1–5)' : 'Dilution Preparation (Flasks 1–5)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (!state.allTrialsPrepared)
              TextButton.icon(
                onPressed: () =>
                    ref.read(ratesOfReactionControllerProvider.notifier).prepareAllSolutions(),
                icon: const Icon(Icons.auto_fix_high_rounded, size: 14),
                label: Text(
                  isSwahili ? 'Pima Zote' : 'Dilute All',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...state.trials.map((trial) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: trial.isPrepared
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'F${trial.flaskNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trial.volumeThiosulfate.toInt()} mL Na₂S₂O₃ + ${trial.volumeWater.toInt()} mL H₂O',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '[Na₂S₂O₃] = ${trial.concentrationThio.toStringAsFixed(2)} M (Total V = 50 mL)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: trial.isPrepared
                      ? null
                      : () => ref
                          .read(ratesOfReactionControllerProvider.notifier)
                          .prepareSolution(trial.flaskNumber),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: const Color(0xFF38BDF8),
                  ),
                  child: Text(
                    trial.isPrepared
                        ? (isSwahili ? 'Imepimwa' : 'Prepared')
                        : (isSwahili ? 'Pima' : 'Prepare'),
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Reaction & Timing
  // ---------------------------------------------------------------------------
  Widget _buildReactionTrialsWorkspace(
    WidgetRef ref,
    RatesOfReactionState state,
    bool isDark,
    bool isSwahili,
  ) {
    final activeTrial = state.activeTrial;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Flask selector tabs
        Container(
          height: 38,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: List.generate(state.trials.length, (idx) {
              final t = state.trials[idx];
              final isSelected = idx == state.activeTrialIndex;
              return Expanded(
                child: InkWell(
                  onTap: () =>
                      ref.read(ratesOfReactionControllerProvider.notifier).selectTrial(idx),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF38BDF8)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'F${t.flaskNumber} (${t.concentrationThio.toStringAsFixed(2)}M)',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),

        // Stopwatch / Status Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Flask ${activeTrial.flaskNumber}: [Na₂S₂O₃] = ${activeTrial.concentrationThio.toStringAsFixed(2)} M',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        isSwahili
                            ? 'Ukungu wa Kiberiti: ${(state.turbidityOpacity * 100).toInt()}%'
                            : 'Sulfur Turbidity: ${(state.turbidityOpacity * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: state.isStopwatchRunning
                          ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                          : const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: state.isStopwatchRunning
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                    child: Text(
                      '${state.currentStopwatchSeconds.toStringAsFixed(1)} s',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        color: state.isStopwatchRunning
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Progress Bar for Turbidity
              LinearProgressIndicator(
                value: state.turbidityOpacity,
                backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  state.turbidityOpacity >= 1.0 ? const Color(0xFF10B981) : const Color(0xFFFACC15),
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              if (!activeTrial.isAcidAdded && !state.isStopwatchRunning) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(ratesOfReactionControllerProvider.notifier)
                        .addAcidAndStartReaction(activeTrial.flaskNumber),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      isSwahili
                          ? 'Weka 5 mL HCl na Anzisha Mmenyuko'
                          : 'Add 5.0 mL HCl & Start Reaction',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ] else if (state.isStopwatchRunning || activeTrial.isAcidAdded) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => ref
                        .read(ratesOfReactionControllerProvider.notifier)
                        .recordDisappearance(activeTrial.flaskNumber),
                    icon: const Icon(Icons.visibility_off_rounded),
                    label: Text(
                      isSwahili
                          ? 'Msalaba Umetoweka! (Simamisha Saa)'
                          : 'Cross Obscured! (Stop & Record)',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4: Kinetic Results Table
  // ---------------------------------------------------------------------------
  Widget _buildResultsTableWorkspace(
    WidgetRef ref,
    RatesOfReactionState state,
    bool isDark,
    bool isSwahili,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              isSwahili ? 'Jedwali la Majaribio na Kasi (1/t)' : 'Kinetic Trials & Rates Table',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              headingRowHeight: 38,
              dataRowMinHeight: 36,
              dataRowMaxHeight: 40,
              columns: [
                DataColumn(label: Text(isSwahili ? 'Chupa' : 'Flask', style: const TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('V(Na₂S₂O₃) mL', style: const TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('V(H₂O) mL', style: const TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('[Na₂S₂O₃] M', style: const TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text(isSwahili ? 'Muda t (s)' : 'Time t (s)', style: const TextStyle(fontWeight: FontWeight.w700))),
                DataColumn(label: Text('Rate 1/t (s⁻¹)', style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
              rows: state.trials.map((t) {
                final timeStr = t.recordedTimeSeconds != null ? '${t.recordedTimeSeconds!.toStringAsFixed(1)} s' : '—';
                final rateStr = t.calculatedRate != null ? t.calculatedRate!.toStringAsFixed(4) : '—';
                return DataRow(cells: [
                  DataCell(Text('Flask ${t.flaskNumber}')),
                  DataCell(Text('${t.volumeThiosulfate.toInt()}')),
                  DataCell(Text('${t.volumeWater.toInt()}')),
                  DataCell(Text(t.concentrationThio.toStringAsFixed(2))),
                  DataCell(Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(rateStr, style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w700))),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 5: Graph & Rate Law Analysis
  // ---------------------------------------------------------------------------
  Widget _buildGraphWorkspace(
    BuildContext context,
    WidgetRef ref,
    RatesOfReactionState state,
    bool isDark,
    bool isSwahili,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Interactive Graph
        RatesOfReactionGraphWidget(
          state: state,
          isDark: isDark,
          isSwahili: isSwahili,
        ),
        const SizedBox(height: 16),

        // Slope / Rate Law Estimation Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSwahili
                    ? 'Hesabu ya Mteremko na Uwasilishaji'
                    : 'Slope Determination & Submission',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSwahili
                    ? 'Weka thamani ya mteremko wa grafu k = Δ(1/t) / Δ[Na₂S₂O₃] (s⁻¹M⁻¹):'
                    : 'Enter the slope of the kinetic plot k = Δ(1/t) / Δ[Na₂S₂O₃] (s⁻¹M⁻¹):',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _slopeInputController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: isSwahili ? 'Weka mteremko' : 'Enter slope value',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        suffixText: 's⁻¹M⁻¹',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      _slopeInputController.text = state.calculatedSlope.toStringAsFixed(3);
                    },
                    child: Text(isSwahili ? 'Kutoka Grafu' : 'Auto Fill'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final entered = double.tryParse(_slopeInputController.text) ?? state.calculatedSlope;
                    ref.read(ratesOfReactionControllerProvider.notifier).submit(entered);
                    final updatedState = ref.read(ratesOfReactionControllerProvider);
                    if (updatedState.scoreResult != null) {
                      _showScorecardModal(context, updatedState.scoreResult!, isDark, isSwahili);
                    }
                  },
                  icon: const Icon(Icons.assignment_turned_in_rounded),
                  label: Text(
                    isSwahili ? 'Wasilisha Jaribio la Kasi' : 'Submit Kinetics Practical',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Action Bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar(
    BuildContext context,
    WidgetRef ref,
    RatesOfReactionState state,
    bool isDark,
    bool isSwahili,
  ) {
    final curIdx = state.step.index;
    final hasNext = curIdx < RatesOfReactionStep.values.length - 1;
    final hasPrev = curIdx > 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (hasPrev)
            OutlinedButton.icon(
              onPressed: () {
                final prevStep = RatesOfReactionStep.values[curIdx - 1];
                ref.read(ratesOfReactionControllerProvider.notifier).setStep(prevStep);
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: Text(isSwahili ? 'Hatua Iliyopita' : 'Previous Step'),
            )
          else
            const SizedBox.shrink(),
          if (hasNext)
            ElevatedButton.icon(
              onPressed: () {
                final nextStep = RatesOfReactionStep.values[curIdx + 1];
                ref.read(ratesOfReactionControllerProvider.notifier).setStep(nextStep);
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(isSwahili ? 'Hatua Inayofuata' : 'Next Step'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38BDF8),
                foregroundColor: Colors.white,
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scorecard Bottom Sheet
  // ---------------------------------------------------------------------------
  void _showScorecardModal(
    BuildContext context,
    dynamic scoreResult,
    bool isDark,
    bool isSwahili,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TitrationCompletionCard(
                  scoreResult: scoreResult,
                  isDark: isDark,
                  isSwahili: isSwahili,
                  onRepeat: () {
                    context.pop();
                    ref
                        .read(ratesOfReactionControllerProvider.notifier)
                        .reset(widget.mode);
                  },
                  onFinish: () {
                    context.pop();
                    context.pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Lab Notebook Bottom Sheet
  // ---------------------------------------------------------------------------
  void _showLabNotebookModal(BuildContext context, bool isDark, bool isSwahili) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Color(0xFF38BDF8)),
                  const SizedBox(width: 8),
                  Text(
                    isSwahili ? 'Daftari la Nadharia ya Kasi' : 'Reaction Kinetics Theory',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Na₂S₂O₃ (aq) + 2HCl (aq) → 2NaCl (aq) + SO₂ (g) + S (s)↓ + H₂O (l)',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                isSwahili
                    ? '• Kasi ya mmenyuko inalingana moja kwa moja na mgawanyiko wa muda: Kasi ∝ 1/t.\n• Mteremko (k) wa grafu ya 1/t dhidi ya [Na₂S₂O₃] unathibitisha kanuni ya kasi ya daraja la kwanza.\n• Kiberiti (S) kinapojikusanya, hufanya myeyusho kuwa wa maziwa/ukungu na kuficha msalaba.'
                    : '• Reaction rate is directly proportional to the reciprocal of disappearance time: Rate ∝ 1/t.\n• The linear slope (k) of the 1/t vs [Na₂S₂O₃] plot confirms 1st-order kinetics with respect to thiosulfate.\n• Precipitated colloidal sulfur (S) produces opacity that obscures the black cross underneath the flask.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.pop(),
                  child: Text(isSwahili ? 'Funga' : 'Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Exit Confirmation Dialog
  // ---------------------------------------------------------------------------
  void _showExitConfirmationDialog(BuildContext context, bool isDark, bool isSwahili) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          title: Text(isSwahili ? 'Toka kwenye Jaribio?' : 'Exit Practical?'),
          content: Text(
            isSwahili
                ? 'Maendeleo ya sasa ya jaribio la kasi ya mmenyuko yatapotea ukiondoka sasa.'
                : 'Current reaction rates progress will be lost if you leave now.',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(isSwahili ? 'Baki Hapa' : 'Stay'),
            ),
            ElevatedButton(
              onPressed: () {
                context.pop();
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: Text(isSwahili ? 'Toka' : 'Exit'),
            ),
          ],
        );
      },
    );
  }
}
