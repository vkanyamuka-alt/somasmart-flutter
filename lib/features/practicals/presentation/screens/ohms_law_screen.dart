import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/practical_model.dart';
import '../../data/models/ohms_law_state.dart';
import '../controllers/ohms_law_controller.dart';
import '../../domain/ohms_law_engine.dart';
import '../widgets/circuit_bench_painter.dart';
import '../widgets/lab_hand.dart';
import '../widgets/practical_layout.dart';
import '../widgets/ohms_law_graph_widget.dart';
import '../widgets/titration_completion_card.dart';
import '../../../../core/utils/learning_language.dart';

class OhmsLawScreen extends ConsumerStatefulWidget {
  final PracticalMode mode;

  const OhmsLawScreen({
    super.key,
    required this.mode,
  });

  @override
  ConsumerState<OhmsLawScreen> createState() => _OhmsLawScreenState();
}

class _OhmsLawScreenState extends ConsumerState<OhmsLawScreen>
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late final LabHandRuns _hands = LabHandRuns(this);

  final _slopeCtrl = TextEditingController();
  final _resistanceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _hands.dispose();
    _slopeCtrl.dispose();
    _resistanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = learningLanguage();
    final isSwahili = language == 'sw';

    final ohmsState = ref.watch(ohmsLawControllerProvider(widget.mode));
    final controller = ref.read(ohmsLawControllerProvider(widget.mode).notifier);
    // The student's hand joins the wires, moves the cell clip and pushes the plug key.
    _hands.enabled = !MediaQuery.disableAnimationsOf(context);
    _hands.watch('wired', ohmsState.circuitConnected);
    _hands.watch('cells', ohmsState.cells);
    _hands.watch('key', ohmsState.isSwitchClosed);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExitSimulation(context, isDark, isSwahili);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isSwahili ? 'Uhakiki wa Sheria ya Ohm' : "Ohm's Law Verification",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => _confirmExitSimulation(context, isDark, isSwahili),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu_book_rounded),
              tooltip: isSwahili ? 'Daftari la Maabara' : 'Lab Notebook',
              onPressed: () => _showNotebookDialog(context, ohmsState, isDark, isSwahili),
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: isSwahili ? 'Rudia Mwanzo' : 'Reset Experiment',
              onPressed: () => _confirmResetDialog(context, controller, isDark, isSwahili),
            ),
          ],
        ),
        body: ohmsState.isCompleted && ohmsState.scoreResult != null
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: TitrationCompletionCard(
                  scoreResult: ohmsState.scoreResult!,
                  isDark: isDark,
                  isSwahili: isSwahili,
                  onRepeat: () => controller.resetPractical(widget.mode),
                  onFinish: () => context.pop(),
                ),
              )
            // Bench and step controls: stacked on phones, side by side when wide.
            : PracticalSplitLayout(
                padding: const EdgeInsets.all(14),
                bench: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode & Time Status Bar
                    _buildStatusBar(ohmsState, isDark, isSwahili),
                    const SizedBox(height: 12),

                    // Guided Workflow Step Indicators
                    if (widget.mode != PracticalMode.freeExploration) ...[
                      _buildStepBar(ohmsState, controller, isDark, isSwahili),
                      const SizedBox(height: 12),
                    ],

                    // Circuit Workspace Canvas
                    _buildCircuitCanvas(ohmsState, controller, isDark, isSwahili),
                  ],
                ),
                controls: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Contextual Action Card according to Current Step
                    _buildStepControls(ohmsState, controller, isDark, isSwahili),
                    const SizedBox(height: 14),

                    // Experimental Readings Data Table
                    _buildReadingsTable(ohmsState, controller, isDark, isSwahili),
                    const SizedBox(height: 14),

                    // Graph Plotting Card
                    OhmsLawGraphWidget(
                      readings: ohmsState.recordedReadings,
                      isDarkMode: isDark,
                      isKiswahili: isSwahili,
                    ),
                    const SizedBox(height: 14),

                    // Calculations & Submission Card (Step 5 or anytime in free exploration)
                    _buildCalculationsCard(ohmsState, controller, isDark, isSwahili),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStatusBar(OhmsLawState state, bool isDark, bool isSwahili) {
    String modeName;
    Color modeColor;
    switch (state.mode) {
      case PracticalMode.guidedPractice:
        modeName = isSwahili ? 'Mazoezi Yaliyoongozwa' : 'Guided Practice';
        modeColor = const Color(0xFF3B82F6);
        break;
      case PracticalMode.examMode:
        modeName = isSwahili ? 'Mtihani Halisi' : 'Exam Mode';
        modeColor = const Color(0xFFE11D48);
        break;
      case PracticalMode.freeExploration:
        modeName = isSwahili ? 'Majaribio Huria' : 'Free Exploration';
        modeColor = const Color(0xFF10B981);
        break;
    }

    final minutes = (state.elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (state.elapsedSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: modeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                modeName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: modeColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 14,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                '$minutes:$seconds',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepBar(OhmsLawState state, OhmsLawController controller, bool isDark, bool isSwahili) {
    final stepLabels = isSwahili
        ? ['Vifaa', 'Unganisha', 'Ufunguo', 'Pima', 'Data', 'Hesabu']
        : ['Inspect', 'Connect', 'Key', 'Measure', 'Data', 'Calculate'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(6, (index) {
          final isCurrent = state.currentStepIndex == index;
          final isPast = state.currentStepIndex > index;

          return InkWell(
            onTap: () {
              if (state.mode == PracticalMode.freeExploration || isPast || state.canAdvanceStep()) {
                controller.setStep(index);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isCurrent
                    ? const Color(0xFF3B82F6)
                    : (isPast
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isCurrent
                      ? const Color(0xFF3B82F6)
                      : (isPast ? const Color(0xFF10B981) : Colors.transparent),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 9,
                    backgroundColor: isCurrent
                        ? Colors.white
                        : (isPast ? const Color(0xFF10B981) : Colors.grey.shade400),
                    child: isPast
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? const Color(0xFF3B82F6) : Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    stepLabels[index],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent
                          ? Colors.white
                          : (isPast
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCircuitCanvas(
    OhmsLawState state,
    OhmsLawController controller,
    bool isDark,
    bool isSwahili,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF3B82F6)),
                    const SizedBox(width: 6),
                    Text(
                      isSwahili ? 'Saketi ya Maabara' : 'Laboratory Circuit Bench',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: state.isCircuitActive
                        ? const Color(0xFF10B981).withValues(alpha: 0.15)
                        : const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: state.isCircuitActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Text(
                    state.isCircuitActive
                        ? (isSwahili ? 'IMEFUNGWA / INAFANYA KAZI' : 'ACTIVE / ENERGIZED')
                        : (isSwahili ? 'IMEFUNGULIWA / IMEZIMWA' : 'DE-ENERGIZED'),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: state.isCircuitActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _animController,
              builder: (context, _) {
                // The bench is drawn from above, upright (360 x 400), and kept
                // short enough on wide screens for the controls to stay in reach.
                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
                    child: AspectRatio(
                      aspectRatio: CircuitBenchPainter.width / CircuitBenchPainter.height,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CustomPaint(
                          painter: CircuitBenchPainter(
                            isConnected: state.circuitConnected,
                            isSwitchClosed: state.isSwitchClosed,
                            cells: state.cells,
                            measuredVoltage: state.measuredVoltage,
                            measuredCurrent: state.measuredCurrent,
                            animationProgress: _animController.value,
                            isDarkMode: isDark,
                            hands: _hands,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tips_and_updates_outlined, size: 16, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isSwahili ? state.observationMessageSw : state.observationMessageEn,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Four large buttons, one per number of cells, each with its e.m.f.
  Widget _buildCellChoice(OhmsLawState state, OhmsLawController controller, bool isDark) {
    const navy = Color(0xFF184E78);
    const navyOnDark = Color(0xFF7FB2DA);
    return Row(
      children: List.generate(OhmsLawEngine.maxCells, (i) {
        final n = i + 1;
        final on = state.cells == n;
        final volts = (n * OhmsLawEngine.cellVolts).toStringAsFixed(1);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: n < OhmsLawEngine.maxCells ? 8 : 0),
            child: Semantics(
              selected: on,
              button: true,
              label: '$n dry cell${n == 1 ? '' : 's'}, $volts volts',
              excludeSemantics: true,
              child: InkWell(
                key: ValueKey('ohms-cells-$n'),
                onTap: () => controller.setVoltage(n * OhmsLawEngine.cellVolts),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 56),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: on ? navy.withValues(alpha: isDark ? 0.35 : 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: on ? (isDark ? navyOnDark : navy) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      width: on ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$n',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: on ? (isDark ? navyOnDark : navy) : (isDark ? Colors.white : const Color(0xFF0F172A)))),
                      Text('$volts V', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepControls(
    OhmsLawState state,
    OhmsLawController controller,
    bool isDark,
    bool isSwahili,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isSwahili ? 'Vidhibiti vya Majaribio' : 'Experimental Controls',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // Step 0: Inspection Items
            if (state.currentStepIndex == 0) ...[
              Text(
                isSwahili
                    ? 'Gusa kila kifaa ili kukagua sifa zake kabla ya kuanza saketi:'
                    : 'Tap each apparatus item to inspect its specifications before assembling:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildInspectChip('battery', isSwahili ? 'Seli kavu' : 'Dry cells', state, controller, isDark),
                  _buildInspectChip('resistor', isSwahili ? 'Kikinza R' : 'Resistor R', state, controller, isDark),
                  _buildInspectChip('ammeter', isSwahili ? 'Mita ya Ampea' : 'Ammeter', state, controller, isDark),
                  _buildInspectChip('voltmeter', isSwahili ? 'Mita ya Volteji' : 'Voltmeter', state, controller, isDark),
                  _buildInspectChip('switch', isSwahili ? 'Ufunguo (K)' : 'Key (K)', state, controller, isDark),
                  _buildInspectChip('wires', isSwahili ? 'Nyaya' : 'Connecting wires', state, controller, isDark),
                ],
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: state.canAdvanceStep() ? () => controller.nextStep() : null,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(isSwahili ? 'Hatua Inayofuata (Unganisha)' : 'Next Step (Assemble Circuit)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],

            // Step 1: Connect Circuit
            if (state.currentStepIndex == 1) ...[
              if (!state.circuitConnected) ...[
                Text(
                  isSwahili
                      ? 'Unganisha seli, ufunguo, ammita na kikinza mfululizo; voltimita sambamba na kikinza. Terminali nyekundu (+) za mita zielekee + ya seli.'
                      : "Join the cells, key, ammeter and resistor in one loop (series), and the voltmeter across the resistor (parallel). The meters' red + terminals go towards the + of the cells.",
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => controller.connectCircuit(),
                  icon: const Icon(Icons.cable_rounded, size: 18),
                  label: Text(isSwahili ? 'Unganisha Saketi Yote' : 'Connect Laboratory Circuit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 18, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isSwahili ? 'Saketi imeunganishwa ipasavyo!' : 'Circuit successfully assembled and verified!',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => controller.nextStep(),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(isSwahili ? 'Endelea (Funga Ufunguo)' : 'Proceed (Close the Key)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],

            // Step 2, 3, 4: Switch, Voltage Slider & Recording Readings
            if (state.currentStepIndex >= 2 && state.currentStepIndex <= 4 || widget.mode == PracticalMode.freeExploration) ...[
              // Switch Toggle Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isSwahili ? 'Ufunguo K:' : 'Key K:',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  ElevatedButton.icon(
                    onPressed: state.circuitConnected
                        ? () => controller.toggleSwitch(!state.isSwitchClosed)
                        : null,
                    icon: Icon(
                      state.isSwitchClosed ? Icons.power_settings_new_rounded : Icons.power_off_rounded,
                      size: 16,
                    ),
                    label: Text(
                      state.isSwitchClosed
                          ? (isSwahili ? 'FUNGUA UFUNGUO' : 'OPEN THE KEY')
                          : (isSwahili ? 'FUNGA UFUNGUO' : 'CLOSE THE KEY'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.isSwitchClosed ? const Color(0xFFE11D48) : const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Dry cells in the circuit: the crocodile clip picks 1 to 4 cells.
              Text(
                isSwahili ? 'Seli kavu kwenye saketi:' : 'Dry cells in the circuit:',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildCellChoice(state, controller, isDark),
              const SizedBox(height: 14),

              // Record Reading Button
              ElevatedButton.icon(
                onPressed: state.isCircuitActive ? () => controller.recordCurrentReading() : null,
                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                label: Text(
                  isSwahili
                      ? 'Rekodi Kipimo (V = ${state.measuredVoltage.toStringAsFixed(1)}V, I = ${state.measuredCurrent.toStringAsFixed(3)}A)'
                      : 'Record Reading (V = ${state.measuredVoltage.toStringAsFixed(1)}V, I = ${state.measuredCurrent.toStringAsFixed(3)}A)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),

              if (widget.mode != PracticalMode.freeExploration) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (state.currentStepIndex > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => controller.previousStep(),
                          child: Text(isSwahili ? 'Nyuma' : 'Back'),
                        ),
                      ),
                    if (state.currentStepIndex > 0) const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: state.canAdvanceStep() ? () => controller.nextStep() : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        child: Text(isSwahili ? 'Mbele (Hesabu)' : 'Next (Calculations)'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInspectChip(
    String key,
    String label,
    OhmsLawState state,
    OhmsLawController controller,
    bool isDark,
  ) {
    final isInspected = state.inspectedItems.contains(key);
    return ActionChip(
      avatar: Icon(
        isInspected ? Icons.check_circle_rounded : Icons.info_outline_rounded,
        size: 16,
        color: isInspected ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
      ),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: isInspected
          ? const Color(0xFF10B981).withValues(alpha: 0.12)
          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
      side: BorderSide(
        color: isInspected ? const Color(0xFF10B981) : const Color(0xFF3B82F6).withValues(alpha: 0.3),
      ),
      onPressed: () => controller.inspectItem(key),
    );
  }

  Widget _buildReadingsTable(
    OhmsLawState state,
    OhmsLawController controller,
    bool isDark,
    bool isSwahili,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSwahili ? 'Jedwali la Vipimo vya Majaribio' : 'Experimental Readings Table',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (state.recordedReadings.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => controller.resetReadings(),
                    icon: const Icon(Icons.clear_all, size: 16, color: Color(0xFFEF4444)),
                    label: Text(
                      isSwahili ? 'Futa Yote' : 'Clear All',
                      style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (state.recordedReadings.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Text(
                    isSwahili
                        ? 'Hakuna vipimo vilivyorekodiwa bado. Washa swichi na ubonyeze "Rekodi Kipimo".'
                        : 'No readings recorded yet. Close the key and tap "Record Reading".',
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
                  columnSpacing: 20,
                  headingRowHeight: 36,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 40,
                  columns: [
                    DataColumn(label: Text(isSwahili ? 'Jaribio' : 'Trial', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text(isSwahili ? 'Volteji V (V)' : 'Voltage V (V)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text(isSwahili ? 'Mkondo I (A)' : 'Current I (A)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text(isSwahili ? 'Kikinza R = V/I (Ω)' : 'Resistance R = V/I (Ω)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    const DataColumn(label: Text('')),
                  ],
                  rows: state.recordedReadings.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final r = entry.value;
                    return DataRow(
                      cells: [
                        DataCell(Text('#${r.trialNumber}', style: const TextStyle(fontSize: 12))),
                        DataCell(Text('${r.voltage.toStringAsFixed(2)} V', style: const TextStyle(fontSize: 12))),
                        DataCell(Text('${r.current.toStringAsFixed(3)} A', style: const TextStyle(fontSize: 12))),
                        DataCell(Text('${r.calculatedResistance.toStringAsFixed(2)} Ω', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)))),
                        DataCell(
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)),
                            onPressed: () => controller.deleteReading(idx),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationsCard(
    OhmsLawState state,
    OhmsLawController controller,
    bool isDark,
    bool isSwahili,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate_rounded, size: 20, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Text(
                  isSwahili ? 'Uhesabuji wa Kikinza na Alama' : 'Resistance Calculation & Final Submission',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              isSwahili
                  ? 'Kutoka kwenye grafu au jedwali: R = ΔV / ΔI. Andika thamani uliyopata ya kikinza sanifu (Ω):'
                  : 'From your graph slope or table: R = ΔV / ΔI. Enter your determined resistance for the standard resistor (Ω):',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _slopeCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: isSwahili ? 'Mteremko wa Grafu (Slope = ΔV/ΔI)' : 'Graph Slope (ΔV/ΔI)',
                hintText: isSwahili ? 'Weka mteremko' : 'Enter slope value',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.trending_up, size: 18),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _resistanceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: isSwahili ? 'Kikinza cha Mwisho R (Ω)' : 'Final Calculated Resistance R (Ω)',
                hintText: isSwahili ? 'Weka thamani ya kikinza' : 'Enter calculated resistance',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.speed_rounded, size: 18),
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                if (_resistanceCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isSwahili ? 'Tafadhali andika thamani ya kikinza R kabla ya kutuma.' : 'Please enter your calculated resistance R before submitting.'),
                    ),
                  );
                  return;
                }
                controller.submitCalculation(
                  _slopeCtrl.text.trim(),
                  _resistanceCtrl.text.trim(),
                );
              },
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: Text(isSwahili ? 'Kamilisha na Pata Matokeo' : 'Submit Calculations & Complete Practical'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotebookDialog(BuildContext context, OhmsLawState state, bool isDark, bool isSwahili) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (_, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSwahili ? 'Daftari la Maabara (Physics Logs)' : 'Physics Lab Notebook',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: state.notebookLogs.length,
                      itemBuilder: (context, i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            state.notebookLogs[i],
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                              height: 1.4,
                            ),
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

  void _confirmResetDialog(
    BuildContext context,
    OhmsLawController controller,
    bool isDark,
    bool isSwahili,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSwahili ? 'Rudia Jaribio Mwanzo?' : 'Reset Practical?'),
        content: Text(
          isSwahili
              ? 'Je, una uhakika unataka kufuta vipimo vyote na kuanza upya?'
              : 'Are you sure you want to clear all readings and reset the experiment?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.resetPractical(widget.mode);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: Text(isSwahili ? 'Rudia' : 'Reset'),
          ),
        ],
      ),
    );
  }

  void _confirmExitSimulation(BuildContext context, bool isDark, bool isSwahili) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isSwahili ? 'Ondoka kwenye Jaribio?' : 'Exit Practical?'),
        content: Text(
          isSwahili
              ? 'Maendeleo yako ya sasa hayatahifadhiwa usipokamilisha.'
              : 'Your current practical progress will be lost if you exit without completing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isSwahili ? 'Endelea' : 'Continue Experiment'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: Text(isSwahili ? 'Ondoka' : 'Exit'),
          ),
        ],
      ),
    );
  }
}
