import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';
import '../../data/models/practical_model.dart';
import '../../data/models/titration_state.dart';
import '../controllers/titration_controller.dart';
import '../widgets/burette_reading_lens.dart';
import '../widgets/titration_bench_painter.dart';
import '../widgets/titration_completion_card.dart';
import '../widgets/workflow_step_bar.dart';

class TitrationScreen extends ConsumerStatefulWidget {
  final PracticalMode mode;

  const TitrationScreen({
    super.key,
    required this.mode,
  });

  @override
  ConsumerState<TitrationScreen> createState() => _TitrationScreenState();
}

class _TitrationScreenState extends ConsumerState<TitrationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // Step 8 Form inputs
  final _initialReadingCtrl = TextEditingController(text: '0.00');
  final _finalReadingCtrl = TextEditingController();
  final _titreVolumeCtrl = TextEditingController();
  final String _selectedColor = 'Permanent Pale Pink';

  // Step 9 Form inputs
  final _calcTitreCtrl = TextEditingController();
  final _calcMolarityCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    _initialReadingCtrl.dispose();
    _finalReadingCtrl.dispose();
    _titreVolumeCtrl.dispose();
    _calcTitreCtrl.dispose();
    _calcMolarityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final language = ref.watch(languageProvider);
    final isSwahili = language == 'sw';

    final titrationState = ref.watch(titrationControllerProvider(widget.mode));
    final controller = ref.read(titrationControllerProvider(widget.mode).notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _confirmExitSimulation(context, isDark, isSwahili);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isSwahili ? 'Titration ya Asidi na Besi' : 'Acid–Base Titration',
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
              onPressed: () => _showNotebookDialog(context, titrationState, isDark, isSwahili),
            ),
            IconButton(
              icon: const Icon(Icons.restart_alt_rounded),
              tooltip: isSwahili ? 'Rudia Mwanzo' : 'Reset Experiment',
              onPressed: () => _confirmResetDialog(context, controller, isDark, isSwahili),
            ),
          ],
        ),
        body: titrationState.isCompleted
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: TitrationCompletionCard(
                  scoreResult: titrationState.scoreResult!,
                  isDark: isDark,
                  isSwahili: isSwahili,
                  onRepeat: () => controller.reset(),
                  onFinish: () => context.pop(),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mode & Time Status Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBgSurface : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
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
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isSwahili ? widget.mode.labelSw : widget.mode.labelEn,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                              const SizedBox(width: 4),
                              Text(
                                _formatDuration(titrationState.elapsedSeconds),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Collapsible Workflow Step Tracker
                    WorkflowStepBar(
                      currentStepIndex: titrationState.currentStepIndex,
                      isCompleted: titrationState.isCompleted,
                      mode: widget.mode,
                      isSwahili: isSwahili,
                      isDark: isDark,
                      onStepTap: (step) => controller.jumpToStep(step),
                    ),
                    const SizedBox(height: 12),

                    // Interactive Laboratory Canvas with Reading Lens Overlay
                    Container(
                      height: 240,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // CustomPainter Canvas
                          AnimatedBuilder(
                            animation: _animController,
                            builder: (context, _) {
                              return CustomPaint(
                                size: const Size(double.infinity, 240),
                                painter: TitrationBenchPainter(
                                  state: titrationState,
                                  isDark: isDark,
                                  animationValue: _animController.value,
                                ),
                              );
                            },
                          ),

                          // Burette Reading Magnifier Lens (Top Right)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: BuretteReadingLens(
                              volumeDelivered: titrationState.volumeDelivered,
                              isDark: isDark,
                              isSwahili: isSwahili,
                            ),
                          ),

                          // Reagents & Apparatus Quick-tap Hints (Bottom Left)
                          Positioned(
                            bottom: 6,
                            left: 10,
                            child: Text(
                              isSwahili ? 'Gusa chupa au vifaa kukagua' : 'Tap apparatus to inspect',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Live Observation & Guidance Callout
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.psychology_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSwahili ? 'Uchunguzi wa Maabara:' : 'Laboratory Observation:',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isSwahili ? titrationState.observationMessageSw : titrationState.observationMessageEn,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.heroNavyDark,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Step Control Actions Card
                    _buildStepControlsCard(
                      context: context,
                      state: titrationState,
                      controller: controller,
                      isDark: isDark,
                      isSwahili: isSwahili,
                    ),
                    const SizedBox(height: 14),

                    // Next / Prev Step Navigation Bar
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: titrationState.currentStepIndex > 0
                                ? () => controller.prevStep()
                                : null,
                            icon: const Icon(Icons.chevron_left_rounded, size: 18),
                            label: Text(isSwahili ? 'Hatua Iliyopita' : 'Previous Step'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: titrationState.canAdvanceStep() && titrationState.currentStepIndex < 8
                                ? () => controller.nextStep()
                                : null,
                            icon: const Icon(Icons.chevron_right_rounded, size: 18),
                            label: Text(isSwahili ? 'Hatua Inayofuata' : 'Next Step'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildStepControlsCard({
    required BuildContext context,
    required TitrationState state,
    required TitrationController controller,
    required bool isDark,
    required bool isSwahili,
  }) {
    switch (state.currentStepIndex) {
      // Step 1: Inspect Setup
      case 0:
        return _CardShell(
          title: isSwahili ? 'Hatua 1: Kagua Vifaa na Kemikali' : 'Step 1: Inspect Apparatus & Reagents',
          subtitle: isSwahili
              ? 'Gusa angalau vifaa 4 ili kuhakiki usafi na utayari.'
              : 'Inspect at least 4 items on the bench to verify apparatus readiness.',
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InspectButton(
                    label: isSwahili ? 'Burette (50 mL)' : 'Burette (50 mL)',
                    isInspected: state.inspectedItems.contains('burette'),
                    onTap: () => controller.inspectItem('burette'),
                  ),
                  _InspectButton(
                    label: isSwahili ? 'Conical Flask (250 mL)' : 'Conical Flask (250 mL)',
                    isInspected: state.inspectedItems.contains('flask'),
                    onTap: () => controller.inspectItem('flask'),
                  ),
                  _InspectButton(
                    label: isSwahili ? 'Pipette (25.0 mL)' : 'Pipette (25.0 mL)',
                    isInspected: state.inspectedItems.contains('pipette'),
                    onTap: () => controller.inspectItem('pipette'),
                  ),
                  _InspectButton(
                    label: isSwahili ? '0.10M NaOH (Besi)' : '0.10M NaOH (Base)',
                    isInspected: state.inspectedItems.contains('naoh'),
                    onTap: () => controller.inspectItem('naoh'),
                  ),
                  _InspectButton(
                    label: isSwahili ? 'HCl (Asidi)' : 'HCl Solution (Acid)',
                    isInspected: state.inspectedItems.contains('hcl'),
                    onTap: () => controller.inspectItem('hcl'),
                  ),
                  _InspectButton(
                    label: isSwahili ? 'Phenolphthalein' : 'Phenolphthalein Indicator',
                    isInspected: state.inspectedItems.contains('indicator'),
                    onTap: () => controller.inspectItem('indicator'),
                  ),
                  _InspectButton(
                    label: isSwahili ? 'Kigae Cheupe' : 'White Tile',
                    isInspected: state.inspectedItems.contains('tile'),
                    onTap: () => controller.inspectItem('tile'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: state.inspectedItems.length >= 4 ? () => controller.nextStep() : null,
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: Text(
                  '${isSwahili ? "Thibitisha Ukaguzi" : "Confirm Inspection"} (${state.inspectedItems.length}/4)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        );

      // Step 2: Fill Burette
      case 1:
        return _CardShell(
          title: isSwahili ? 'Hatua 2: Jaza Burette na 0.10M NaOH' : 'Step 2: Fill Burette with 0.10M NaOH',
          subtitle: isSwahili
              ? 'Weka titrant ya sodium hydroxide hadi kwenye alama ya 0.00 mL.'
              : 'Fill burette with standard NaOH solution to the 0.00 mL initial graduation.',
          isDark: isDark,
          child: ElevatedButton.icon(
            onPressed: state.buretteFilled ? null : () => controller.fillBurette(),
            icon: const Icon(Icons.water_drop_rounded, size: 16),
            label: Text(
              state.buretteFilled
                  ? (isSwahili ? 'Burette Imejazwa (0.00 mL)' : 'Burette Filled (0.00 mL)')
                  : (isSwahili ? 'Jaza Burette Sasa' : 'Fill Burette Now'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );

      // Step 3: Pipette HCl Sub-engine
      case 2:
        return _CardShell(
          title: isSwahili ? 'Hatua 3: Pima 25.0 mL HCl kwa Pipette' : 'Step 3: Pipette 25.0 mL HCl Solution',
          subtitle: isSwahili
              ? 'Tumia pipette kupima 25.0 mL ya asidi na kuiweka kwenye conical flask.'
              : 'Accurately draw 25.0 mL HCl and transfer into the conical flask.',
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pipette: ${state.pipetteVolume.toStringAsFixed(1)} / 25.0 mL',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Flask: ${state.flaskVolume.toStringAsFixed(1)} / 25.0 mL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: state.flaskVolume >= 25.0 ? const Color(0xFF10B981) : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              if (state.pipetteStep == 0)
                ElevatedButton.icon(
                  onPressed: () => controller.selectPipette(),
                  icon: const Icon(Icons.science_rounded, size: 16),
                  label: Text(isSwahili ? '1. Chagua Pipette (25.0 mL)' : '1. Select 25.0 mL Pipette'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              if (state.pipetteStep == 1)
                ElevatedButton.icon(
                  onPressed: () => controller.attachPipetteBulb(),
                  icon: const Icon(Icons.touch_app_rounded, size: 16),
                  label: Text(isSwahili ? '2. Funga Mpira wa Kuvutia' : '2. Attach Suction Bulb'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              if (state.pipetteStep == 2)
                ElevatedButton.icon(
                  onPressed: () => controller.insertPipetteInHCl(),
                  icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                  label: Text(isSwahili ? '3. Weka Pipette kwenye HCl' : '3. Insert Pipette in HCl'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              if (state.pipetteStep == 3)
                ElevatedButton.icon(
                  onPressed: state.isDrawingLiquid ? null : () => controller.drawHCl(),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                  label: Text(state.isDrawingLiquid ? (isSwahili ? 'Inavuta...' : 'Drawing HCl...') : (isSwahili ? '4. Vuta 25.0 mL HCl' : '4. Draw 25.0 mL HCl')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              if (state.pipetteStep == 4)
                ElevatedButton.icon(
                  onPressed: () => controller.positionPipetteAboveFlask(),
                  icon: const Icon(Icons.open_with_rounded, size: 16),
                  label: Text(isSwahili ? '5. Weka Pipette Juu ya Flask' : '5. Position Above Flask'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              if (state.pipetteStep == 5)
                ElevatedButton.icon(
                  onPressed: state.isTransferringLiquid ? null : () => controller.transferHClToFlask(),
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(state.isTransferringLiquid ? (isSwahili ? 'Inahamisha...' : 'Transferring...') : (isSwahili ? '6. Fungua Valve Kuweka Flask' : '6. Release Valve to Flask')),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              if (state.pipetteStep >= 6)
                ElevatedButton.icon(
                  onPressed: () => controller.nextStep(),
                  icon: const Icon(Icons.check_circle_rounded, size: 16),
                  label: Text(isSwahili ? '7. HCl Imehamishwa — Endelea' : '7. Transfer Complete — Proceed'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                ),
            ],
          ),
        );

      // Step 4: Add Indicator
      case 3:
        return _CardShell(
          title: isSwahili ? 'Hatua 4: Weka Kielelezo cha Phenolphthalein' : 'Step 4: Add Phenolphthalein Indicator',
          subtitle: isSwahili
              ? 'Weka matone 3 ya phenolphthalein kwenye conical flask.'
              : 'Add exactly 3 drops of phenolphthalein indicator to the analyte.',
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${isSwahili ? "Matone Yaliyowekwa" : "Drops Added"}: ${state.indicatorDropsCount} / 3',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (state.indicatorStep == 0)
                ElevatedButton.icon(
                  onPressed: () => controller.selectIndicatorBottle(),
                  icon: const Icon(Icons.opacity_rounded, size: 16),
                  label: Text(isSwahili ? 'Chagua Kielelezo' : 'Select Indicator Bottle'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              if (state.indicatorStep == 1)
                ElevatedButton.icon(
                  onPressed: () => controller.positionDropperAboveFlask(),
                  icon: const Icon(Icons.layers_rounded, size: 16),
                  label: Text(isSwahili ? 'Weka Juu ya Conical Flask' : 'Position Dropper Above Flask'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              if (state.indicatorStep >= 2)
                ElevatedButton.icon(
                  onPressed: state.indicatorDropsCount >= 3 || state.isDroppingIndicator
                      ? null
                      : () => controller.addIndicatorDrop(),
                  icon: const Icon(Icons.water_drop_rounded, size: 16),
                  label: Text(
                    state.indicatorDropsCount >= 3
                        ? (isSwahili ? 'Matone 3 Yamewekwa' : '3 Drops Added')
                        : '${isSwahili ? "Weka Tone la" : "Add Drop"} ${state.indicatorDropsCount + 1}/3',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.indicatorDropsCount >= 3 ? const Color(0xFF10B981) : const Color(0xFFEC4899),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        );

      // Step 5: Position Flask on Tile
      case 4:
        return _CardShell(
          title: isSwahili ? 'Hatua 5: Weka Chupa Juu ya Kigae Cheupe' : 'Step 5: Position Flask on White Tile',
          subtitle: isSwahili
              ? 'Weka conical flask chini ya burette juu ya kigae cheupe ili uone rangi vizuri.'
              : 'Place conical flask on the white ceramic tile directly beneath the burette stopcock.',
          isDark: isDark,
          child: ElevatedButton.icon(
            onPressed: state.flaskPositioned ? null : () => controller.positionFlaskOnTile(),
            icon: const Icon(Icons.place_rounded, size: 16),
            label: Text(
              state.flaskPositioned
                  ? (isSwahili ? 'Chupa Imewekwa Chini ya Burette' : 'Flask Positioned on Tile')
                  : (isSwahili ? 'Weka Chupa Sasa' : 'Position Flask Now'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );

      // Step 6: Titrate Dropwise
      case 5:
        return _CardShell(
          title: isSwahili ? 'Hatua 6: Titrate kwa Kudondosha NaOH' : 'Step 6: Titrate Dropwise with NaOH',
          subtitle: isSwahili
              ? 'Fungua stopcock polepole kuongeza NaOH huku ukichunguza mabadiliko ya rangi.'
              : 'Deliver titrant slowly while watching for transient color flashes near 24.00 mL.',
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.setContinuousFlow(),
                      icon: const Icon(Icons.play_arrow_rounded, size: 14),
                      label: Text(isSwahili ? 'Mtiririko wa Haraka' : 'Continuous Flow'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.stopcockState == StopcockState.flow ? AppColors.primary : Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.setSlowFlow(),
                      icon: const Icon(Icons.water_drop_outlined, size: 14),
                      label: Text(isSwahili ? 'Mtiririko wa Polepole' : 'Slow Flow'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: state.stopcockState == StopcockState.slow ? AppColors.primary : Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.deliverSingleDrop(),
                      icon: const Icon(Icons.water_drop_rounded, size: 14),
                      label: Text(isSwahili ? 'Tone Moja (0.05 mL)' : 'Single Drop (0.05 mL)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.stopcockState == StopcockState.closed ? null : () => controller.closeStopcock(),
                      icon: const Icon(Icons.pause_rounded, size: 14),
                      label: Text(isSwahili ? 'Funga Stopcock' : 'Close Stopcock'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        foregroundColor: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      // Step 7: Observe Endpoint & Swirl
      case 6:
        return _CardShell(
          title: isSwahili ? 'Hatua 7: Chunguza Kilele na Tikisa Chupa' : 'Step 7: Observe Endpoint & Swirl Flask',
          subtitle: isSwahili
              ? 'Tikisa conical flask kuhakikisha rangi ya waridi haipotei (permanent pale pink).'
              : 'Swirl conical flask to verify whether the pink color persists after mixing.',
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFDF2F8),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFEC4899).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.color_lens_outlined, color: Color(0xFFEC4899), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isSwahili ? state.colorStageNameSw : state.colorStageNameEn,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEC4899)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isSwirling ? null : () => controller.swirlFlask(),
                      icon: const Icon(Icons.rotate_right_rounded, size: 16),
                      label: Text(state.isSwirling ? (isSwahili ? 'Inatikiswa...' : 'Swirling...') : (isSwahili ? 'Tikisa Chupa' : 'Swirl Flask')),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: state.volumeDelivered >= 24.45 && state.hasSwirledAtCurrentVolume
                          ? () => controller.confirmEndpoint()
                          : null,
                      icon: const Icon(Icons.check_circle_rounded, size: 16),
                      label: Text(isSwahili ? 'Thibitisha Kilele' : 'Confirm Endpoint'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

      // Step 8: Record Readings Form
      case 7:
        return _CardShell(
          title: isSwahili ? 'Hatua 8: Rekodi Vipimo vya Burette' : 'Step 8: Record Burette Readings',
          subtitle: isSwahili
              ? 'Weka ujazo wa mwanzo na wa mwisho wa titrant uliyotumia.'
              : 'Enter observed initial reading, final reading, and calculated titre volume.',
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _initialReadingCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: isSwahili ? 'Ujazo wa Mwanzo (mL)' : 'Initial Reading (mL)',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _finalReadingCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: isSwahili ? 'Ujazo wa Mwisho (mL)' : 'Final Reading (mL)',
                        hintText: isSwahili ? 'Weka ujazo wa mwisho' : 'Enter final reading',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _titreVolumeCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isSwahili ? 'Ujazo Uliotumika (Titre mL)' : 'Titre Volume (mL)',
                  hintText: isSwahili ? 'Weka ujazo uliotumika' : 'Enter titre volume',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final initial = _initialReadingCtrl.text.trim();
                  final finalR = _finalReadingCtrl.text.trim().isNotEmpty
                      ? _finalReadingCtrl.text.trim()
                      : state.volumeDelivered.toStringAsFixed(2);
                  final titre = _titreVolumeCtrl.text.trim().isNotEmpty
                      ? _titreVolumeCtrl.text.trim()
                      : state.volumeDelivered.toStringAsFixed(2);

                  controller.submitReadings(
                    initialReading: initial,
                    finalReading: finalR,
                    titreVolume: titre,
                    observedColor: _selectedColor,
                  );
                },
                icon: const Icon(Icons.save_rounded, size: 16),
                label: Text(isSwahili ? 'Wasilisha Vipimo' : 'Submit Readings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ],
          ),
        );

      // Step 9: Calculations Form
      case 8:
        return _CardShell(
          title: isSwahili ? 'Hatua 9: Hesabu Ukolezi wa Asidi (Molar)' : 'Step 9: Calculate Acid Molarity',
          subtitle: isSwahili
              ? 'Tumia fomula: M_acid = (0.10 × V_base) / 25.0 kuhesabu molarity ya HCl.'
              : 'Formula: M_acid = (M_base × V_base) / V_acid = (0.10 × V_base) / 25.0',
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _calcTitreCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isSwahili ? 'Ujazo wa NaOH (V_base mL)' : 'NaOH Titre Volume (V_base mL)',
                  hintText: isSwahili ? 'Weka ujazo wa NaOH' : 'Enter NaOH volume',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _calcMolarityCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isSwahili ? 'Ukolezi Uliohesabiwa wa HCl (M)' : 'Calculated HCl Molarity (M)',
                  hintText: isSwahili ? 'Weka molarity uliyohesabu' : 'Enter calculated molarity',
                  hintStyle: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  final titre = _calcTitreCtrl.text.trim().isNotEmpty
                      ? _calcTitreCtrl.text.trim()
                      : state.volumeDelivered.toStringAsFixed(2);
                  final molarity = _calcMolarityCtrl.text.trim().isNotEmpty
                      ? _calcMolarityCtrl.text.trim()
                      : '0.0980';

                  controller.submitCalculations(
                    calculatedTitre: titre,
                    calculatedMolarity: molarity,
                  );
                },
                icon: const Icon(Icons.calculate_rounded, size: 16),
                label: Text(isSwahili ? 'Hesabu na Maliza Jaribio' : 'Submit Calculations & Score'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _showNotebookDialog(BuildContext context, TitrationState state, bool isDark, bool isSwahili) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkBgSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.menu_book_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(isSwahili ? 'Daftari la Maabara' : 'Student Lab Notebook'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: state.notebookLogs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        state.notebookLogs[i],
                        style: const TextStyle(fontSize: 12, height: 1.3),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isSwahili ? 'Funga' : 'Close'),
          ),
        ],
      ),
    );
  }

  void _confirmExitSimulation(BuildContext context, bool isDark, bool isSwahili) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkBgSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isSwahili ? 'Toka Kwenye Jaribio?' : 'Exit Practical Session?'),
        content: Text(
          isSwahili
              ? 'Ukiondoka sasa, maendeleo yako ya titration yatasitishwa.'
              : 'Are you sure you want to exit? Your current titration session progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text(isSwahili ? 'Toka' : 'Exit'),
          ),
        ],
      ),
    );
  }

  void _confirmResetDialog(
    BuildContext context,
    TitrationController controller,
    bool isDark,
    bool isSwahili,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkBgSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isSwahili ? 'Rudia Mwanzo?' : 'Reset Practical?'),
        content: Text(
          isSwahili
              ? 'Hii itasafisha burette na conical flask na kuanza upya.'
              : 'This will reset all glassware, burette readings, and start from Step 1.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isSwahili ? 'Ghairi' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              controller.reset();
            },
            child: Text(isSwahili ? 'Rudia' : 'Reset'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _CardShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget child;

  const _CardShell({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.heroNavyDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InspectButton extends StatelessWidget {
  final String label;
  final bool isInspected;
  final VoidCallback onTap;

  const _InspectButton({
    required this.label,
    required this.isInspected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: Icon(
        isInspected ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 14,
        color: isInspected ? const Color(0xFF10B981) : AppColors.primary,
      ),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      backgroundColor: isInspected ? const Color(0x1510B981) : null,
    );
  }
}
