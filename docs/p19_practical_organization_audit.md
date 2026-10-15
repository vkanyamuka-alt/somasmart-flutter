# P19 — Practical Organization and UX Redesign Audit (Updated)

## 1. Executive Summary
This audit documents the revised navigation architecture, catalog presentation, card structure, and mode-selection flow for the SomaSmart Simulation Laboratory in the Flutter application.

### Key Rules & Constraints:
- **No new practical simulation engines** will be created.
- **Zero alterations** to the scientific logic, physics/chemical calculations, state machines, or scoring logic of the 8 verified engines:
  1. Acid–Base Titration
  2. Ohm's Law
  3. Microscope / Cell Staining
  4. Simple Pendulum
  5. Refraction & Prism
  6. Osmosis
  7. Rates of Chemical Reactions
  8. Laboratory Preparation of Gases
- **Do not start P19**.
- **Subject selection MUST use dedicated Subject Cards** (Chemistry, Physics, Biology) rather than segmented tabs.
- **Practical cards MUST follow the visual reference screenshot**: Horizontal layout with apparatus thumbnail on left, natural student-facing numbering ("Practical 1", "Practical 2", etc.), title, 1-line description, chips, real progress if $>0$, and "Open Practical" button.
- **Mode selection MUST always precede simulation entry**: The student cannot bypass mode selection.

---

## 2. Mandatory Final Navigation Hierarchy
```
SOMASMART SIMULATION LABORATORY (PracticalLevelScreen)
        ↓
┌──────────────┐
│   O-LEVEL    │
└──────────────┘
┌──────────────┐
│   A-LEVEL    │
└──────────────┘
        ↓
SUBJECT SELECTION (PracticalSubjectSelectScreen)
┌──────────────┐
│  CHEMISTRY   │
└──────────────┘
┌──────────────┐
│   PHYSICS    │
└──────────────┘
┌──────────────┐
│   BIOLOGY    │
└──────────────┘
        ↓
PRACTICAL LIST (PracticalSubjectScreen)
Horizontal cards with left thumbnail, chips, title, description, real progress, and "Open Practical"
        ↓
OPEN PRACTICAL
        ↓
PRACTICAL DETAILS & MODE SELECTION (PracticalModeScreen)
Title, concise metadata, 1-sentence objective, short principle, and 3 mode cards:
┌────────────────────┐
│ Guided Practice    │
└────────────────────┘
┌────────────────────┐
│ Exam Mode          │
└────────────────────┘
┌────────────────────┐
│ Free Exploration   │
└────────────────────┘
        ↓
START PRACTICAL
        ↓
SIMULATION ENGINE (Existing P11–P18 engines)
        ↓
RESULTS / SCORECARD
```

---

## 3. Stitch MCP Design System Findings
- **Brand Colors:** Royal Scholar Blue (`#0058BE`), Deep Slate (`#0F172A`), Crisp White (`#FFFFFF`), Slate canvas (`#F8FAFC`), Slate borders (`#E2E8F0` / `#334155`).
- **Unified Thumbnail System:** `84x84` dp container with 1px slate border and custom vector illustrations in Royal Scholar Blue / Slate for all 8 practical apparatuses.
- **Natural Student-Facing Numbering:** Sequential practical numbers ("Practical 1", "Practical 2", "Practical 3") based on catalog index.
- **No Information Overload:** Equipment lists, multi-line procedures, and safety paragraphs are completely removed from cards and mode selection.

---

## 4. Modified & Created Files Summary
1. `lib/features/practicals/presentation/widgets/practical_thumbnail_widget.dart` [NEW]
2. `lib/features/practicals/presentation/screens/practical_level_screen.dart` [MODIFY]
3. `lib/features/practicals/presentation/screens/practical_subject_select_screen.dart` [NEW]
4. `lib/features/practicals/presentation/screens/practical_subject_screen.dart` [MODIFY]
5. `lib/features/practicals/presentation/screens/practical_mode_screen.dart` [MODIFY]
6. `lib/core/router/app_router.dart` [MODIFY]
