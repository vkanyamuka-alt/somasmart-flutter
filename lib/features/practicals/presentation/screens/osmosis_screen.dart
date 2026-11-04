import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/osmosis_state.dart';
import '../../data/models/practical_model.dart';
import '../controllers/lab_inspect_provider.dart';
import '../controllers/osmosis_controller.dart';
import '../widgets/practical_layout.dart';
import '../widgets/osmosis_bench_painter.dart';
import '../widgets/lab_hand.dart';
import '../widgets/osmosis_graph_widget.dart';
import '../widgets/titration_completion_card.dart';
import '../../../../core/utils/learning_language.dart';

class OsmosisScreen extends ConsumerStatefulWidget {
  final PracticalMode mode;

  const OsmosisScreen({super.key, required this.mode});

  @override
  ConsumerState<OsmosisScreen> createState() => _OsmosisScreenState();
}

class _OsmosisScreenState extends ConsumerState<OsmosisScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  final TextEditingController _isotonicInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(osmosisControllerProvider.notifier).initializeForMode(widget.mode);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _isotonicInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(osmosisControllerProvider);
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
                      // Virtual Biology Laboratory Bench Canvas
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
    OsmosisState state,
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.mode.labelEn.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.timer_outlined, size: 13, color: Color(0xFF10B981)),
              const SizedBox(width: 3),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            isSwahili ? 'Osmosisi kwenye Viazi' : 'Osmosis in Potato Tissues',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        // Lab Notebook Button
        IconButton(
          icon: const Icon(Icons.menu_book_outlined, color: Color(0xFF10B981)),
          tooltip: isSwahili ? 'Daftari la Maabara' : 'Lab Notebook',
          onPressed: () => _openLabNotebook(context, state, isDark, isSwahili),
        ),

        // Reset Experiment
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: isSwahili ? 'Weka Upya' : 'Reset Experiment',
          onPressed: () => ref.read(osmosisControllerProvider.notifier).resetExperiment(widget.mode),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Step Tab Bar
  // ---------------------------------------------------------------------------
  Widget _buildStepTabBar(WidgetRef ref, OsmosisState state, bool isDark, bool isSwahili) {
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: OsmosisStep.values.length,
        itemBuilder: (context, index) {
          final step = OsmosisStep.values[index];
          final isActive = state.step == step;
          final isCompleted = step.index < state.step.index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () {
                if (widget.mode == PracticalMode.freeExploration || isCompleted || isActive) {
                  ref.read(osmosisControllerProvider.notifier).setStep(step);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark ? const Color(0xFF047857) : AppColors.primary)
                      : (isCompleted
                          ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary
                        : (isCompleted ? const Color(0xFF10B981) : Colors.transparent),
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    if (isCompleted) ...[
                      const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      isSwahili ? step.labelSw : step.labelEn,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        color: isActive
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF64748B)),
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

  // ---------------------------------------------------------------------------
  // Instructions Banner
  // ---------------------------------------------------------------------------
  Widget _buildInstructionsBanner(OsmosisState state, bool isDark, bool isSwahili) {
    String msgEn = '';
    String msgSw = '';

    switch (state.step) {
      case OsmosisStep.inspectApparatus:
        msgEn = 'Examine the fresh potato tuber, cork borer, scalpel, digital balance, boiling tubes, and filter paper.';
        msgSw = 'Kagua kiazi kibichi, kikatia kizibo, kisu, mzani wa kidijitali, mabomba ya kuchemshia na karatasi ya kuchuja.';
        break;
      case OsmosisStep.prepareSpecimens:
        msgEn = 'Use the cork borer to cut 5 identical potato tissue cylinders (diameter 8mm, length 40mm) and peel skin.';
        msgSw = 'Tumia kikatia kizibo kukata vipande 5 vinavyolingana vya kiazi (urefu mm 40) na kumenya gome.';
        break;
      case OsmosisStep.initialWeighing:
        msgEn = 'Place each potato cylinder on the electronic balance to record initial mass (m₀ ≈ 2.00 g).';
        msgSw = 'Weka kila kipande cha kiazi kwenye mzani wa kidijitali ili kupima uzito wa awali (m₀ ≈ 2.00 g).';
        break;
      case OsmosisStep.immerseIncubate:
        msgEn = 'Immerse cylinders into labelled boiling tubes A–E (0.0M to 0.8M) and start the 30-minute incubation timer.';
        msgSw = 'Loweka vipande kwenye mabomba A–E yenye sukari (0.0M hadi 0.8M) kisha anza kipima-muda cha dakika 30.';
        break;
      case OsmosisStep.blotFinalWeighing:
        msgEn = 'Retrieve cylinders, gently blot excess surface moisture with filter paper, and weigh final mass (m₁).';
        msgSw = 'Toa vipande, kausha unyevu wa juu kwa karatasi ya kuchuja, kisha pima uzito wa mwisho (m₁).';
        break;
      case OsmosisStep.observationTable:
        msgEn = 'Review initial mass (m₀), final mass (m₁), mass change (Δm), % change, and tissue turgidity texture.';
        msgSw = 'Kagua uzito wa awali, wa mwisho, mabadiliko ya uzito (Δm), asilimia, na hali ya ukakamavu wa tishu.';
        break;
      case OsmosisStep.graphAnalysis:
        msgEn = 'Plot % change in mass vs sucrose concentration. Identify the isotonic point (0% mass change) where Ψ_cell = Ψ_solution.';
        msgSw = 'Chora grafu ya % mabadiliko ya uzito dhidi ya ukolezi wa sukari. Tambua eneo la msawazo (0% mabadiliko).';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: isDark ? const Color(0xFF0F172A) : AppColors.primarySoft,
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isSwahili ? msgSw : msgEn,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFFE2E8F0) : AppColors.primary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Canvas Laboratory Bench
  // ---------------------------------------------------------------------------
  Widget _buildLaboratoryCanvas(OsmosisState state, bool isDark) {
    final inspected =
        state.step == OsmosisStep.inspectApparatus ? ref.watch(labInspectedProvider('osmosis')) : null;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
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
          clipBehavior: Clip.antiAlias,
          child: LabHandPaint(
            size: const Size(double.infinity, 250),
            watch: OsmosisBenchPainter.handKeys(state),
            painter: (hands) => OsmosisBenchPainter(
              state: state,
              isDark: isDark,
              animationValue: _pulseController.value,
              hands: hands,
              inspectedItemKey: inspected,
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Step Workspace
  // ---------------------------------------------------------------------------
  Widget _buildStepWorkspace(
    BuildContext context,
    WidgetRef ref,
    OsmosisState state,
    bool isDark,
    bool isSwahili,
  ) {
    switch (state.step) {
      case OsmosisStep.inspectApparatus:
        return _buildStep1Apparatus(ref, state, isDark, isSwahili);
      case OsmosisStep.prepareSpecimens:
        return _buildStep2Specimens(ref, state, isDark, isSwahili);
      case OsmosisStep.initialWeighing:
        return _buildStep3Weighing(ref, state, isDark, isSwahili, isInitial: true);
      case OsmosisStep.immerseIncubate:
        return _buildStep4ImmerseIncubate(ref, state, isDark, isSwahili);
      case OsmosisStep.blotFinalWeighing:
        return _buildStep5BlotAndWeigh(ref, state, isDark, isSwahili);
      case OsmosisStep.observationTable:
        return _buildStep6ObservationTable(ref, state, isDark, isSwahili);
      case OsmosisStep.graphAnalysis:
        return _buildStep7GraphAnalysis(context, ref, state, isDark, isSwahili);
    }
  }

  // Step 1: Apparatus Inspection
  Widget _buildStep1Apparatus(WidgetRef ref, OsmosisState state, bool isDark, bool isSwahili) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${state.apparatus.where((a) => a.inspected).length}/${state.apparatus.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...state.apparatus.map((item) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: item.inspected
                    ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: item.inspected
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    item.inspected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                    color: item.inspected ? const Color(0xFF10B981) : Colors.grey,
                  ),
                  title: Text(
                    isSwahili ? item.nameSw : item.nameEn,
                    style: TextStyle(
                      fontSize: 13,
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
                  onTap: () {
                    ref.read(osmosisControllerProvider.notifier).inspectItem(item.id);
                    ref.read(labInspectedProvider('osmosis').notifier).state = item.id;
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Step 2: Cut & Prepare Potato Cylinders
  Widget _buildStep2Specimens(WidgetRef ref, OsmosisState state, bool isDark, bool isSwahili) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Andaa Vipande 5 vya Viazi' : 'Prepare 5 Potato Cylinders',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => ref.read(osmosisControllerProvider.notifier).prepareAll(),
                icon: const Icon(Icons.content_cut_rounded, size: 14),
                label: Text(isSwahili ? 'Kata Zote' : 'Cut All Cylinders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...state.samples.map((sample) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sample.isPrepared
                    ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFECFDF5))
                    : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sample.isPrepared
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
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      sample.id,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSwahili ? sample.labelSw : sample.labelEn,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          isSwahili
                              ? (sample.isPrepared ? 'Kipande kimekatwa (mm 40, hakina gome)' : 'Bado hakijakatwa')
                              : (sample.isPrepared ? 'Cylinder trimmed to 40mm (skin removed)' : 'Not cut yet'),
                          style: TextStyle(
                            fontSize: 11,
                            color: sample.isPrepared ? const Color(0xFF10B981) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!sample.isPrepared)
                    OutlinedButton(
                      onPressed: () => ref.read(osmosisControllerProvider.notifier).prepareSample(sample.id),
                      child: Text(isSwahili ? 'Kata' : 'Cut'),
                    )
                  else
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Step 3 / 5: Weighing Samples on Balance
  Widget _buildStep3Weighing(
    WidgetRef ref,
    OsmosisState state,
    bool isDark,
    bool isSwahili, {
    required bool isInitial,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isInitial
                    ? (isSwahili ? 'Pima Uzito wa Awali (m₀)' : 'Weigh Initial Mass (m₀)')
                    : (isSwahili ? 'Pima Uzito wa Mwisho (m₁)' : 'Weigh Final Mass (m₁)'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                'Digital Balance: ${state.balanceDisplay.toStringAsFixed(2)} g',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Sample chips to select
          Wrap(
            spacing: 8,
            children: List.generate(state.samples.length, (i) {
              final sample = state.samples[i];
              final isWeighed = isInitial ? sample.isInitialWeighed : sample.isFinalWeighed;
              final isSelected = state.activeSampleIndex == i;

              return ChoiceChip(
                label: Text('${sample.id}: ${sample.concentration}M'),
                selected: isSelected,
                avatar: isWeighed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                selectedColor: const Color(0xFF10B981),
                onSelected: (val) {
                  ref.read(osmosisControllerProvider.notifier).selectSample(i);
                },
              );
            }),
          ),
          const SizedBox(height: 16),

          // Action Card for Active Sample
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isSwahili ? state.activeSample.labelSw : state.activeSample.labelEn,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isInitial
                          ? 'Recorded m₀: ${state.activeSample.initialMass.toStringAsFixed(2)} g'
                          : 'Recorded m₁: ${state.activeSample.finalMass.toStringAsFixed(2)} g',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.read(osmosisControllerProvider.notifier).placeSampleOnBalance(
                          state.activeSample.id,
                          isInitial: isInitial,
                        );
                  },
                  icon: const Icon(Icons.scale_rounded, size: 16),
                  label: Text(isSwahili ? 'Weka Mzanini' : 'Place on Balance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 4: Immerse and Incubate in Solutions A–E
  Widget _buildStep4ImmerseIncubate(WidgetRef ref, OsmosisState state, bool isDark, bool isSwahili) {
    final progress = state.incubationSeconds / state.incubationTargetSeconds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Loweka na Subiri (Dakika 30)' : 'Immerse & 30-Min Incubation',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              if (!state.allImmersed)
                ElevatedButton.icon(
                  onPressed: () => ref.read(osmosisControllerProvider.notifier).immerseAll(),
                  icon: const Icon(Icons.water_drop_rounded, size: 14),
                  label: Text(isSwahili ? 'Loweka Zote' : 'Immerse All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Incubation Progress Bar & Timer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      isSwahili ? 'Kipima-Muda cha Osmosisi:' : 'Osmotic Incubation Timer:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    Text(
                      '${state.incubationSeconds}s / ${state.incubationTargetSeconds}s (Simulated 30 Mins)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF10B981),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: state.isIncubationFinished || state.isIncubating
                            ? null
                            : () => ref.read(osmosisControllerProvider.notifier).startIncubation(),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(isSwahili ? 'Anza Kipima-Muda' : 'Start Incubation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: state.isIncubationFinished
                          ? null
                          : () => ref.read(osmosisControllerProvider.notifier).completeIncubation(),
                      icon: const Icon(Icons.fast_forward_rounded, size: 16),
                      label: Text(isSwahili ? 'Kamilisha Haraka' : 'Fast-Forward'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 5: Blot & Final Weighing
  Widget _buildStep5BlotAndWeigh(WidgetRef ref, OsmosisState state, bool isDark, bool isSwahili) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSwahili ? 'Kausha kwa Karatasi ya Kuchuja' : 'Blot Surface Liquid on Filter Paper',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => ref.read(osmosisControllerProvider.notifier).blotAll(),
                    icon: const Icon(Icons.clean_hands_rounded, size: 14),
                    label: Text(isSwahili ? 'Kausha Zote' : 'Blot All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: state.samples.map((s) {
                  return FilterChip(
                    label: Text('Sample ${s.id} (${s.isBlotted ? "Blotted" : "Wet"})'),
                    selected: s.isBlotted,
                    onSelected: (_) => ref.read(osmosisControllerProvider.notifier).blotSample(s.id),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildStep3Weighing(ref, state, isDark, isSwahili, isInitial: false),
      ],
    );
  }

  // Step 6: Observation Data Table
  Widget _buildStep6ObservationTable(WidgetRef ref, OsmosisState state, bool isDark, bool isSwahili) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isSwahili ? 'Jedwali la Vipimo vya Osmosisi' : 'Osmosis Experimental Data Table',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('5/5 Samples', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              ),
              columns: [
                DataColumn(label: Text(isSwahili ? 'Bomba' : 'Tube', style: const TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text(isSwahili ? 'Ukolezi (M)' : 'Conc (M)', style: const TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text(isSwahili ? 'm₀ (g)' : 'm₀ (g)', style: const TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text(isSwahili ? 'm₁ (g)' : 'm₁ (g)', style: const TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text(isSwahili ? 'Δm (g)' : 'Δm (g)', style: const TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text(isSwahili ? '% Δm' : '% Δm', style: const TextStyle(fontWeight: FontWeight.w800))),
                DataColumn(label: Text(isSwahili ? 'Hali ya Tishu' : 'Tissue Texture', style: const TextStyle(fontWeight: FontWeight.w800))),
              ],
              rows: state.samples.map((sample) {
                final isGain = sample.percentChange >= 0;
                final sign = isGain ? '+' : '';

                return DataRow(
                  cells: [
                    DataCell(Text(sample.id, style: const TextStyle(fontWeight: FontWeight.w800))),
                    DataCell(Text('${sample.concentration} M')),
                    DataCell(Text(sample.initialMass.toStringAsFixed(2))),
                    DataCell(Text(sample.finalMass.toStringAsFixed(2))),
                    DataCell(Text('$sign${sample.massChange.toStringAsFixed(2)}')),
                    DataCell(
                      Text(
                        '$sign${sample.percentChange.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isGain ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    DataCell(Text(isSwahili ? sample.textureSw : sample.textureEn)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Step 7: Graph Analysis & Isotonic Determination
  Widget _buildStep7GraphAnalysis(
    BuildContext context,
    WidgetRef ref,
    OsmosisState state,
    bool isDark,
    bool isSwahili,
  ) {
    if (_isotonicInputController.text.isEmpty && state.enteredIsotonicConcentration != null) {
      _isotonicInputController.text = state.enteredIsotonicConcentration!.toStringAsFixed(2);
    }

    final acceptedIso = state.calculatedIsotonicConcentration;

    return Column(
      children: [
        OsmosisGraphWidget(state: state, isDark: isDark, isSwahili: isSwahili),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isSwahili ? 'Uamuzi wa Eneo la Msawazo (Isotonic Point)' : 'Determination of Isotonic Concentration',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSwahili
                    ? 'Eneo ambalo grafu inakata mstari wa 0% linawakilisha ukolezi wa majimaji ya seli za kiazi ambapo maji hayapungui wala kuongezeka.'
                    : 'The point where the curve intersects the 0% mass change line represents the cell sap equivalent concentration (Ψ_tissue = Ψ_solution).',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isSwahili ? 'Eneo Sahihi la Grafu:' : 'Calculated Intercept (C_iso):'),
                  Text(
                    '≈ $acceptedIso M Sucrose',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _isotonicInputController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isSwahili ? 'Weka Ukolezi wa Msawazo (M)' : 'Enter Your Isotonic Estimate (M)',
                  hintText: isSwahili ? 'Weka thamani ya ukolezi' : 'Enter isotonic estimate',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  prefixIcon: const Icon(Icons.calculate_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null) {
                    ref.read(osmosisControllerProvider.notifier).setEnteredIsotonic(parsed);
                  }
                },
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
    OsmosisState state,
    bool isDark,
    bool isSwahili,
  ) {
    final isFirstStep = state.step == OsmosisStep.inspectApparatus;
    final isLastStep = state.step == OsmosisStep.graphAnalysis;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          if (!isFirstStep)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  final prevIdx = state.step.index - 1;
                  if (prevIdx >= 0) {
                    ref.read(osmosisControllerProvider.notifier).setStep(OsmosisStep.values[prevIdx]);
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: Text(isSwahili ? 'Hatua Iliyopita' : 'Previous Step'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (!isFirstStep) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                if (isLastStep) {
                  final enteredVal = double.tryParse(_isotonicInputController.text) ?? state.calculatedIsotonicConcentration;
                  ref.read(osmosisControllerProvider.notifier).submitPractical(enteredVal);
                  _showScorecardModal(context, ref, isDark, isSwahili);
                } else {
                  final nextIdx = state.step.index + 1;
                  if (nextIdx < OsmosisStep.values.length) {
                    ref.read(osmosisControllerProvider.notifier).setStep(OsmosisStep.values[nextIdx]);
                  }
                }
              },
              icon: Icon(isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_rounded, size: 16),
              label: Text(
                isLastStep
                    ? (isSwahili ? 'Kamilisha Jaribio' : 'Complete Practical')
                    : (isSwahili ? 'Hatua Inayofuata' : 'Next Step'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep ? const Color(0xFF10B981) : AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Lab Notebook Modal Bottom Sheet
  // ---------------------------------------------------------------------------
  void _openLabNotebook(BuildContext context, OsmosisState state, bool isDark, bool isSwahili) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                  isSwahili ? 'Daftari la Maabara (Osmosis Log)' : 'Lab Notebook (Osmosis Log)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Text(
                  isSwahili
                      ? 'Kanuni ya Osmosisi:\n'
                          '• % Δm = ((m₁ - m₀) / m₀) × 100%\n'
                          '• Maji safi (0.0M): Maji huingia ndani (Endosmosis) → Kiazi huvimba na kuwa imara (Turgid).\n'
                          '• Sukari kali (0.8M): Maji hutoka nje (Exosmosis) → Kiazi husinyaa (Plasmolysed/Flaccid).\n'
                          '• Eneo la Msawazo (0% Δm): Ψ_seli = Ψ_myeyusho.'
                      : 'Osmosis Principles:\n'
                          '• % Δm = ((m₁ - m₀) / m₀) × 100%\n'
                          '• Hypotonic (0.0M Distilled Water): Net Endosmosis → Turgid & firm cells.\n'
                          '• Hypertonic (0.8M Sucrose): Net Exosmosis → Flaccid & plasmolysed cells.\n'
                          '• Isotonic Point (0% Δm): Dynamic equilibrium (Ψ_cell sap = Ψ_solution).',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Scorecard Modal
  // ---------------------------------------------------------------------------
  void _showScorecardModal(BuildContext context, WidgetRef ref, bool isDark, bool isSwahili) {
    final state = ref.read(osmosisControllerProvider);
    final scoreResult = state.scoreResult;
    if (scoreResult == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBgSurface : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: TitrationCompletionCard(
            scoreResult: scoreResult,
            isDark: isDark,
            isSwahili: isSwahili,
            onRepeat: () {
              Navigator.of(ctx).pop();
              ref.read(osmosisControllerProvider.notifier).resetExperiment(widget.mode);
            },
            onFinish: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
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
              ? 'Je, una uhakika unataka kuondoka kwenye jaribio hili la Osmosisi?'
              : 'Are you sure you want to exit the Osmosis virtual laboratory?',
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
