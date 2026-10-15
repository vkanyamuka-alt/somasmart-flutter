import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/practical_model.dart';

class StepItem {
  final int number;
  final String titleEn;
  final String titleSw;
  final String descEn;
  final String descSw;

  const StepItem({
    required this.number,
    required this.titleEn,
    required this.titleSw,
    required this.descEn,
    required this.descSw,
  });
}

class WorkflowStepBar extends StatefulWidget {
  final int currentStepIndex;
  final bool isCompleted;
  final PracticalMode mode;
  final bool isSwahili;
  final bool isDark;
  final ValueChanged<int> onStepTap;

  const WorkflowStepBar({
    super.key,
    required this.currentStepIndex,
    required this.isCompleted,
    required this.mode,
    required this.isSwahili,
    required this.isDark,
    required this.onStepTap,
  });

  static const List<StepItem> steps = [
    StepItem(
      number: 1,
      titleEn: 'Inspect Setup',
      titleSw: 'Kagua Vifaa',
      descEn: 'Inspect apparatus & reagents.',
      descSw: 'Kagua vifaa na kemikali.',
    ),
    StepItem(
      number: 2,
      titleEn: 'Fill Burette',
      titleSw: 'Jaza Burette',
      descEn: 'Fill burette with 0.10M NaOH.',
      descSw: 'Jaza burette na 0.10M NaOH.',
    ),
    StepItem(
      number: 3,
      titleEn: 'Pipette HCl',
      titleSw: 'Pima HCl kwa Pipette',
      descEn: 'Transfer 25.0 mL 0.10M HCl into flask.',
      descSw: 'Weka 25.0 mL 0.10M HCl kwenye chupa.',
    ),
    StepItem(
      number: 4,
      titleEn: 'Add Indicator',
      titleSw: 'Weka Kielelezo',
      descEn: 'Add 3 drops phenolphthalein.',
      descSw: 'Weka matone 3 ya phenolphthalein.',
    ),
    StepItem(
      number: 5,
      titleEn: 'Position Flask',
      titleSw: 'Weka Chupa',
      descEn: 'Place flask on ceramic tile.',
      descSw: 'Weka chupa juu ya kigae cheupe.',
    ),
    StepItem(
      number: 6,
      titleEn: 'Titrate Dropwise',
      titleSw: 'Dondosha Titrant',
      descEn: 'Add NaOH slowly while watching color.',
      descSw: 'Dondosha NaOH polepole ukiangalia rangi.',
    ),
    StepItem(
      number: 7,
      titleEn: 'Observe Endpoint',
      titleSw: 'Chunguza Kilele',
      descEn: 'Detect pale pink endpoint.',
      descSw: 'Tambua rangi ya waridi ya kilele.',
    ),
    StepItem(
      number: 8,
      titleEn: 'Record Readings',
      titleSw: 'Rekodi Vipimo',
      descEn: 'Record initial & final burette readings.',
      descSw: 'Rekodi ujazo wa mwanzo na mwisho.',
    ),
    StepItem(
      number: 9,
      titleEn: 'Calculations',
      titleSw: 'Mahesabu ya Molarity',
      descEn: 'Calculate acid concentration (M1V1 = M2V2).',
      descSw: 'Hesabu ukolezi wa asidi (M1V1 = M2V2).',
    ),
  ];

  @override
  State<WorkflowStepBar> createState() => _WorkflowStepBarState();
}

class _WorkflowStepBarState extends State<WorkflowStepBar> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final currentStep = widget.currentStepIndex < WorkflowStepBar.steps.length
        ? WorkflowStepBar.steps[widget.currentStepIndex]
        : WorkflowStepBar.steps.last;

    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header toggle button
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${currentStep.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.isSwahili ? "Hatua" : "Step"} ${currentStep.number} / 9: ${widget.isSwahili ? currentStep.titleSw : currentStep.titleEn}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: widget.isDark ? Colors.white : AppColors.heroNavyDark,
                          ),
                        ),
                        Text(
                          widget.isSwahili ? currentStep.descSw : currentStep.descEn,
                          style: TextStyle(
                            fontSize: 11,
                            color: widget.isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expanded step list
          if (_isExpanded)
            Container(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ...WorkflowStepBar.steps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final step = entry.value;
                    final isCurrent = index == widget.currentStepIndex && !widget.isCompleted;
                    final isDone = widget.isCompleted || index < widget.currentStepIndex;
                    final canClick = widget.mode == PracticalMode.freeExploration || isDone || isCurrent;

                    return InkWell(
                      onTap: canClick
                          ? () {
                              widget.onStepTap(index);
                              setState(() {
                                _isExpanded = false;
                              });
                            }
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : isDone
                                  ? const Color(0x1010B981)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.primary
                                : isDone
                                    ? const Color(0x3310B981)
                                    : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppColors.primary
                                    : isDone
                                        ? const Color(0xFF10B981)
                                        : (widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: isDone
                                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                                  : Text(
                                      '${step.number}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isCurrent ? Colors.white : (widget.isDark ? Colors.white70 : Colors.black87),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.isSwahili ? step.titleSw : step.titleEn,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                  color: isCurrent
                                      ? AppColors.primary
                                      : isDone
                                          ? (widget.isDark ? Colors.white70 : AppColors.heroNavyDark)
                                          : (widget.isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                                ),
                              ),
                            ),
                            if (isDone)
                              const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF10B981)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
