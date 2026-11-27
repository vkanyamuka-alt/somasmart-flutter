import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/gas_preparation_state.dart';
import '../../data/models/practical_model.dart';
import '../controllers/gas_preparation_controller.dart';
import '../controllers/lab_inspect_provider.dart';
import '../widgets/practical_layout.dart';
import '../widgets/gas_preparation_bench_painter.dart';
import '../widgets/lab_hand.dart';
import '../widgets/titration_completion_card.dart';
import '../../../../core/utils/learning_language.dart';
import '../../../../core/theme/app_colors.dart';

class GasPreparationScreen extends ConsumerStatefulWidget {
  final PracticalMode mode;

  const GasPreparationScreen({super.key, required this.mode});

  @override
  ConsumerState<GasPreparationScreen> createState() => _GasPreparationScreenState();
}

class _GasPreparationScreenState extends ConsumerState<GasPreparationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gasPreparationControllerProvider.notifier).initializeForMode(widget.mode);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gasPreparationControllerProvider);
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
                child: StepScrollView(
                  step: state.step,
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
    GasPreparationState state,
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
                      ? AppColors.primary.withValues(alpha: 0.15)
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
                        ? AppColors.primary
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
            isSwahili ? 'Utayarishaji wa Gesi Maabarani' : 'Laboratory Preparation of Gases',
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
            ref.read(gasPreparationControllerProvider.notifier).reset(widget.mode);
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
    GasPreparationState state,
    bool isDark,
    bool isSwahili,
  ) {
    return Container(
      height: 44,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        itemCount: GasPrepStep.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final step = GasPrepStep.values[index];
          final isSelected = state.step == step;
          final isUnlocked = widget.mode == PracticalMode.freeExploration ||
              index <= _highestUnlockedStep(state);

          return InkWell(
            onTap: isUnlocked
                ? () => ref.read(gasPreparationControllerProvider.notifier).setStep(step)
                : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.15)
                    : (isUnlocked
                        ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC))),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
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
                          ? (isDark ? AppColors.primaryLight : AppColors.primary)
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

  int _highestUnlockedStep(GasPreparationState state) {
    if (state.scoreResult != null) return 4;
    if (state.isGasJarFull || state.isTestPerformed) return 4;
    if (state.isLiquidAdded || state.isGenerating) return 3;
    if (state.isSolidAdded) return 2;
    if (state.allApparatusInspected) return 2;
    return 1;
  }

  // ---------------------------------------------------------------------------
  // Instructions Banner
  // ---------------------------------------------------------------------------
  Widget _buildInstructionsBanner(
    GasPreparationState state,
    bool isDark,
    bool isSwahili,
  ) {
    String instruction;
    switch (state.step) {
      case GasPrepStep.selectGas:
        instruction = isSwahili
            ? 'Chagua gesi unayotaka kutayarisha (Oksijeni O₂, Dioksidi ya Kaboni CO₂, au Haidrojeni H₂).'
            : 'Select target gas to synthesize (Oxygen O₂, Carbon Dioxide CO₂, or Hydrogen H₂).';
        break;
      case GasPrepStep.inspectApparatus:
        instruction = isSwahili
            ? 'Kagua vifaa vyote 6 maabarani ili kuelewa kazi ya kila kifaa kabla ya kuanza.'
            : 'Inspect all 6 apparatus components to verify safe experimental setup.';
        break;
      case GasPrepStep.assembleAndReact:
        instruction = isSwahili
            ? 'Weka kitendanishi kigumu kwenye chupa, kisha mimina kimiminika kupitia mpare/thistle funnel kuanzisha mmenyuko.'
            : 'Add solid reactant to generator flask, then pour liquid reagent down thistle funnel to begin effervescence.';
        break;
      case GasPrepStep.collectGas:
        instruction = isSwahili
            ? 'Tazama gesi ikikusanywa juu ya maji au kwa kushusha hewa hadi chupa ya gesi ijae (100 mL).'
            : 'Observe gas collection over water or downward delivery until gas jar is completely filled (100 mL).';
        break;
      case GasPrepStep.testAndScore:
        instruction = isSwahili
            ? 'Fanya kipimo cha uthibitisho (kijiti chenye cheche / maji ya chokaa / sauti ya pop) na wasilisha ripoti ya maabara.'
            : 'Conduct diagnostic confirmatory test (glowing splint / limewater / pop test) and submit lab scorecard.';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : AppColors.primarySoft,
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.primary,
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
  Widget _buildLaboratoryCanvas(GasPreparationState state, bool isDark) {
    final inspected =
        state.step == GasPrepStep.inspectApparatus ? ref.watch(labInspectedProvider('gas')) : null;
    return Container(
      height: 250,
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
            return LabHandPaint(
              size: const Size(double.infinity, 250),
              watch: GasPreparationBenchPainter.handKeys(state),
              painter: (hands) => GasPreparationBenchPainter(
                state: state,
                isDark: isDark,
                animationValue: _pulseController.value,
                hands: hands,
                inspectedItemKey: inspected,
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
    GasPreparationState state,
    bool isDark,
    bool isSwahili,
  ) {
    switch (state.step) {
      case GasPrepStep.selectGas:
        return _buildSelectGasWorkspace(ref, state, isDark, isSwahili);
      case GasPrepStep.inspectApparatus:
        return _buildInspectWorkspace(ref, state, isDark, isSwahili);
      case GasPrepStep.assembleAndReact:
        return _buildAssembleWorkspace(ref, state, isDark, isSwahili);
      case GasPrepStep.collectGas:
        return _buildCollectWorkspace(ref, state, isDark, isSwahili);
      case GasPrepStep.testAndScore:
        return _buildTestAndScoreWorkspace(context, ref, state, isDark, isSwahili);
    }
  }

  // ---------------------------------------------------------------------------
  // Step 1: Select Gas Workspace
  // ---------------------------------------------------------------------------
  Widget _buildSelectGasWorkspace(
    WidgetRef ref,
    GasPreparationState state,
    bool isDark,
    bool isSwahili,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          isSwahili ? 'Chagua Gesi ya Kutayarisha:' : 'Select Target Gas to Prepare:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        ...PreparedGasType.values.map((gas) {
          final isSelected = state.selectedGas == gas;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => ref.read(gasPreparationControllerProvider.notifier).selectGas(gas),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            gas.formula,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF0F172A)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSwahili ? gas.nameSw : gas.nameEn,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              gas.equation,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: isDark ? AppColors.primaryLight : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Inspect Workspace
  // ---------------------------------------------------------------------------
  Widget _buildInspectWorkspace(
    WidgetRef ref,
    GasPreparationState state,
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
              isSwahili
                  ? 'Vifaa Vilivyokaguliwa: $inspectedCount/6'
                  : 'Apparatus Inspected: $inspectedCount/6',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            if (widget.mode == PracticalMode.guidedPractice && !state.allApparatusInspected)
              TextButton.icon(
                onPressed: () =>
                    ref.read(gasPreparationControllerProvider.notifier).inspectAll(),
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: Text(
                  isSwahili ? 'Kagua Vyote' : 'Inspect All',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...state.apparatus.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  ref.read(gasPreparationControllerProvider.notifier).inspectItem(item.id);
                  ref.read(labInspectedProvider('gas').notifier).state = item.id;
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: item.inspected
                        ? (isDark
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFECFDF5))
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: item.inspected
                          ? const Color(0xFF10B981)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.inspected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: item.inspected
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white38 : Colors.black38),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isSwahili ? item.nameSw : item.nameEn,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isSwahili ? item.specSw : item.specEn,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 3: Assemble & React Workspace
  // ---------------------------------------------------------------------------
  Widget _buildAssembleWorkspace(
    WidgetRef ref,
    GasPreparationState state,
    bool isDark,
    bool isSwahili,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chemical Equation Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSwahili ? 'Mlinganyo wa Kikemia:' : 'Chemical Reaction Equation:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                state.selectedGas.equation,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Action 1: Add Solid Reactant
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: state.isSolidAdded
                ? null
                : () => ref.read(gasPreparationControllerProvider.notifier).addSolidReactant(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: state.isSolidAdded
                    ? (isDark ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFECFDF5))
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.isSolidAdded
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isSolidAdded ? Icons.check_circle_rounded : Icons.science_outlined,
                    color: state.isSolidAdded ? const Color(0xFF10B981) : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSwahili
                              ? '1. Weka ${state.selectedGas.solidNameSw}'
                              : '1. Add ${state.selectedGas.solidNameEn}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          isSwahili ? 'Weka kitendanishi chini ya chupa' : 'Place solid bed inside flask base',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!state.isSolidAdded)
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(gasPreparationControllerProvider.notifier).addSolidReactant(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 36),
                      ),
                      child: Text(isSwahili ? 'Weka' : 'Add'),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Action 2: Add Liquid Reactant
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (!state.isSolidAdded || state.isLiquidAdded)
                ? null
                : () => ref.read(gasPreparationControllerProvider.notifier).addLiquidReactant(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: state.isLiquidAdded
                    ? (isDark ? const Color(0xFF10B981).withValues(alpha: 0.12) : const Color(0xFFECFDF5))
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.isLiquidAdded
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    state.isLiquidAdded ? Icons.check_circle_rounded : Icons.water_drop_outlined,
                    color: state.isLiquidAdded ? const Color(0xFF10B981) : AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSwahili
                              ? '2. Mimina ${state.selectedGas.liquidNameSw}'
                              : '2. Pour ${state.selectedGas.liquidNameEn}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          isSwahili ? 'Mimina kupitia thistle funnel kuanza kutoa gesi' : 'Add via thistle funnel to trigger effervescence',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (state.isSolidAdded && !state.isLiquidAdded)
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(gasPreparationControllerProvider.notifier).addLiquidReactant(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(60, 36),
                      ),
                      child: Text(isSwahili ? 'Mimina' : 'Pour'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 4: Collect Gas Workspace
  // ---------------------------------------------------------------------------
  Widget _buildCollectWorkspace(
    WidgetRef ref,
    GasPreparationState state,
    bool isDark,
    bool isSwahili,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSwahili ? 'Kiasi cha Gesi Kilichokusanywa:' : 'Collected Gas Volume:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${state.collectedVolumeMl.toInt()} / 100 mL',
                    style: const TextStyle(
                      fontSize: 15,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: state.collectedVolumeMl / 100.0,
                  minHeight: 12,
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    state.isGasJarFull ? const Color(0xFF10B981) : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isSwahili
                    ? 'Njia ya Ukusanyaji: ${state.selectedGas.collectionMethodSw}'
                    : 'Collection Method: ${state.selectedGas.collectionMethodEn}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isSwahili
                    ? 'Sababu: ${state.selectedGas.collectionReasonSw}'
                    : 'Reason: ${state.selectedGas.collectionReasonEn}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!state.isGasJarFull)
          ElevatedButton.icon(
            onPressed: () =>
                ref.read(gasPreparationControllerProvider.notifier).completeGasCollection(),
            icon: const Icon(Icons.fast_forward_rounded),
            label: Text(isSwahili ? 'Kamilisha Ukusanyaji Mara Moja' : 'Fast-Forward Collection'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step 5: Test & Score Workspace
  // ---------------------------------------------------------------------------
  Widget _buildTestAndScoreWorkspace(
    BuildContext context,
    WidgetRef ref,
    GasPreparationState state,
    bool isDark,
    bool isSwahili,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Test description card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSwahili
                    ? 'Kipimo cha Uthibitisho wa Gesi:'
                    : 'Confirmatory Diagnostic Gas Test:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isSwahili ? state.selectedGas.testDescriptionSw : state.selectedGas.testDescriptionEn,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),
              if (state.isTestPerformed) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isSwahili
                              ? 'Uchunguzi: ${state.selectedGas.testObservationSw}'
                              : 'Observation: ${state.selectedGas.testObservationEn}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        if (!state.isTestPerformed)
          ElevatedButton.icon(
            onPressed: () => ref.read(gasPreparationControllerProvider.notifier).performGasTest(),
            icon: const Icon(Icons.local_fire_department_rounded),
            label: Text(isSwahili ? 'Fanya Kipimo cha Gesi' : 'Perform Gas Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          )
        else ...[
          ElevatedButton.icon(
            onPressed: () {
              ref.read(gasPreparationControllerProvider.notifier).submit();
              _showScorecardModal(context, ref, isDark, isSwahili);
            },
            icon: const Icon(Icons.assignment_turned_in_rounded),
            label: Text(isSwahili ? 'Wasilisha na Tazama Matokeo' : 'Submit & View Scorecard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Bottom Action Bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar(
    BuildContext context,
    WidgetRef ref,
    GasPreparationState state,
    bool isDark,
    bool isSwahili,
  ) {
    final currentIndex = state.step.index;
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < GasPrepStep.values.length - 1;

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
                final prevStep = GasPrepStep.values[currentIndex - 1];
                ref.read(gasPreparationControllerProvider.notifier).setStep(prevStep);
              },
              icon: const Icon(Icons.chevron_left_rounded, size: 20),
              label: Text(isSwahili ? 'Nyuma' : 'Back'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(90, 48),
              ),
            )
          else
            const SizedBox(width: 90),

          if (hasNext)
            ElevatedButton.icon(
              onPressed: () {
                final nextStep = GasPrepStep.values[currentIndex + 1];
                ref.read(gasPreparationControllerProvider.notifier).setStep(nextStep);
              },
              icon: const Icon(Icons.chevron_right_rounded, size: 20),
              label: Text(isSwahili ? 'Endelea' : 'Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(100, 48),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                ref.read(gasPreparationControllerProvider.notifier).submit();
                _showScorecardModal(context, ref, isDark, isSwahili);
              },
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text(isSwahili ? 'Wasilisha' : 'Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                minimumSize: const Size(110, 48),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lab Notebook Modal
  // ---------------------------------------------------------------------------
  void _showLabNotebookModal(BuildContext context, bool isDark, bool isSwahili) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isSwahili ? 'Daftari la Maabara: Utayarishaji wa Gesi' : 'Lab Notebook: Gas Preparation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildNotebookSection(
                    title: isSwahili ? '1. Utayarishaji wa Oksijeni (O₂)' : '1. Oxygen Preparation (O₂)',
                    body: isSwahili
                        ? '• Mmenyuko: 2H₂O₂ (aq) → 2H₂O (l) + O₂ (g) [Kichocheo cha MnO₂]\n'
                          '• Ukusanyaji: Juu ya maji (Downward displacement of water) kwa sababu O₂ huyeyuka kidogo sana kwenye maji.\n'
                          '• Jaribio: Huwasha tena kijiti chenye cheche (Relights a glowing splint).'
                        : '• Reaction: 2H₂O₂ (aq) → 2H₂O (l) + O₂ (g) [Catalyzed by MnO₂]\n'
                          '• Collection: Over water (Downward displacement of water) because O₂ is only slightly soluble in water.\n'
                          '• Test: Relights a glowing wooden splint.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildNotebookSection(
                    title: isSwahili ? '2. Utayarishaji wa Dioksidi ya Kaboni (CO₂)' : '2. Carbon Dioxide Preparation (CO₂)',
                    body: isSwahili
                        ? '• Mmenyuko: CaCO₃ (s) + 2HCl (aq) → CaCl₂ (aq) + H₂O (l) + CO₂ (g)\n'
                          '• Ukusanyaji: Kushusha hewa (Downward delivery) kwa sababu CO₂ ni nzito kuliko hewa na huyeyuka katika maji.\n'
                          '• Jaribio: Hufanya maji ya chokaa kuwa na ukungu (Turns limewater milky white).'
                        : '• Reaction: CaCO₃ (s) + 2HCl (aq) → CaCl₂ (aq) + H₂O (l) + CO₂ (g)\n'
                          '• Collection: Downward delivery (Upward displacement of air) because CO₂ is denser than air and soluble in water.\n'
                          '• Test: Turns limewater (calcium hydroxide) milky white precipitate.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildNotebookSection(
                    title: isSwahili ? '3. Utayarishaji wa Haidrojeni (H₂)' : '3. Hydrogen Preparation (H₂)',
                    body: isSwahili
                        ? '• Mmenyuko: Zn (s) + 2HCl (aq) → ZnCl₂ (aq) + H₂ (g)\n'
                          '• Ukusanyaji: Juu ya maji kwa sababu H₂ haiyeyuki katika maji na ni nyepesi kuliko hewa.\n'
                          '• Jaribio: Huwaka na kutoa sauti ya "pop" mbele ya kijiti kinachowaka moto.'
                        : '• Reaction: Zn (s) + 2HCl (aq) → ZnCl₂ (aq) + H₂ (g)\n'
                          '• Collection: Over water because H₂ is insoluble in water and lighter than air.\n'
                          '• Test: Burns with a characteristic squeaky "pop" sound with a lit wooden splint.',
                    isDark: isDark,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNotebookSection({
    required String title,
    required String body,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Scorecard Modal
  // ---------------------------------------------------------------------------
  void _showScorecardModal(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    bool isSwahili,
  ) {
    final state = ref.read(gasPreparationControllerProvider);
    final scoreResult = state.scoreResult;
    if (scoreResult == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TitrationCompletionCard(
                      scoreResult: scoreResult,
                      isDark: isDark,
                      isSwahili: isSwahili,
                      onRepeat: () {
                        Navigator.pop(ctx);
                        ref.read(gasPreparationControllerProvider.notifier).reset(widget.mode);
                      },
                      onFinish: () {
                        Navigator.pop(ctx);
                        context.pop();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
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
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Text(
          isSwahili ? 'Ondoka kwenye Maabara?' : 'Leave Laboratory?',
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
        content: Text(
          isSwahili
              ? 'Maendeleo yako ya sasa ya utayarishaji wa gesi hayatahifadhiwa.'
              : 'Your current gas preparation simulation progress will be lost.',
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
}
