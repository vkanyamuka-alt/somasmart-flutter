# P18 — Laboratory Preparation of Gases: Implementation & Physical Device Verification Report

**Practical ID:** `gas-prep`  
**Simulation Engine ID:** `gas_preparation`  
**Subject:** Chemistry (O-Level, Form 2/3/4)  
**Level:** O-Level / NECTA Practical Syllabus  
**Target Device:** Google Pixel 4a 5G (`0B261JECB18979`)  
**Final Status:** **P18 VERIFIED COMPLETE**

---

## 1. Executive Summary

Practical P18 (**Laboratory Preparation of Gases — Oxygen, Carbon Dioxide, and Hydrogen**) has been audited from the legacy React student web codebase, fully architected into a mobile-first native Flutter laboratory simulation engine, tested with unit and widget test suites, and verified on a physical Google Pixel 4a 5G Android smartphone.

As instructed, P18 marks the **final practical** in the current practical implementation milestone. All practical development is now concluded and paused.

---

## 2. React Audit Summary vs. Native Flutter Implementation

| Aspect | Legacy React State | Native Flutter Implementation |
| :--- | :--- | :--- |
| **Catalog Metadata** | Catalog card in `constants/practicals.js` (O-Level Chemistry #7) | Registered in `PracticalRepositoryImpl` with `simulationEngineId: 'gas_preparation'`. |
| **Scientific Breadth** | Oxygen & Hydrogen preparation references | Full stoichiometric support for 3 foundational NECTA gases: $\text{O}_2$, $\text{CO}_2$, $\text{H}_2$. |
| **Reagents & Generation** | Static text description | Interactive solid bed charging ($\text{MnO}_2$, $\text{CaCO}_3$, $\text{Zn}$) & liquid funnel addition ($\text{H}_2\text{O}_2$, $\text{HCl}$) with animated bubbling effervescence. |
| **Collection Systems** | Text description of over-water collection | Dynamic pneumatic water trough with beehive shelf & inverted gas jar (downward displacement of water for $\text{O}_2$, $\text{H}_2$) and upright gas jar (downward delivery / air displacement for $\text{CO}_2$). |
| **Confirmatory Gas Tests** | Static theory notes | Interactive testing module: Glowing wooden splint relighting for $\text{O}_2$, limewater turning milky precipitate for $\text{CO}_2$, and lit splint popping explosion for $\text{H}_2$. |
| **Guidance Modes** | Desktop mode card selector | Guided Practice (sequential locking & hints), Exam Mode (independent examination timing), and Free Exploration (unrestricted synthesis). |
| **Scoring & Rubric** | Generic rubric in React scoring | Multi-competency rubric in `PracticalScoreResult` evaluating assembly, stoichiometry, delivery, collection, and confirmatory diagnostics. |
| **Bilingual Support** | Partial Swahili strings in JSON | Complete English and Kiswahili localizations across all titles, chemical names, procedures, observations, apparatus, and feedback. |
| **Mobile UX** | Fixed-dimension desktop layout | Touch-first laboratory bench, $\ge 48\text{dp}$ touch targets, smooth CustomPainter rendering, and `DraggableScrollableSheet` scorecard. |

---

## 3. Scientific Models & Chemical Equations

### A. Oxygen Gas ($\text{O}_2$)
- **Reaction:** Catalytic decomposition of hydrogen peroxide.
  $$2\text{H}_2\text{O}_2\text{ (aq)} \xrightarrow{\text{MnO}_2} 2\text{H}_2\text{O}\text{ (l)} + \text{O}_2\text{ (g)}\uparrow$$
- **Collection:** Over water (downward displacement of water) because $\text{O}_2$ is only slightly soluble in water.
- **Diagnostic Test:** Insertion of glowing wooden splint $\rightarrow$ **Relights and bursts into bright flame**.

### B. Carbon Dioxide Gas ($\text{CO}_2$)
- **Reaction:** Acid-carbonate neutralization.
  $$\text{CaCO}_3\text{ (s)} + 2\text{HCl}\text{ (aq)} \rightarrow \text{CaCl}_2\text{ (aq)} + \text{H}_2\text{O}\text{ (l)} + \text{CO}_2\text{ (g)}\uparrow$$
- **Collection:** Downward delivery (upward displacement of air) because $\text{CO}_2$ is denser than air and moderately soluble in water.
- **Diagnostic Test:** Bubbling gas through clear limewater ($\text{Ca(OH)}_2$) $\rightarrow$ **Turns cloudy / milky white precipitate**.

### C. Hydrogen Gas ($\text{H}_2$)
- **Reaction:** Single replacement reaction between active metal and dilute acid.
  $$\text{Zn}\text{ (s)} + 2\text{HCl}\text{ (aq)} \rightarrow \text{ZnCl}_2\text{ (aq)} + \text{H}_2\text{ (g)}\uparrow$$
- **Collection:** Over water because $\text{H}_2$ is virtually insoluble in water and lighter than air.
- **Diagnostic Test:** Lit wooden splint brought to jar mouth $\rightarrow$ **Burns with a sharp squeaky 'pop' sound**.

---

## 4. Files Created and Modified

### Files Created:
1. `docs/p18_gas_preparation_audit.md` — Detailed audit of legacy React gas preparation metadata.
2. `lib/features/practicals/data/models/gas_preparation_state.dart` — Immutable domain state, gas models ($\text{O}_2, \text{CO}_2, \text{H}_2$), apparatus items, and step enums.
3. `lib/features/practicals/domain/gas_preparation_engine.dart` — Domain simulation engine implementing `PracticalSimulationEngine`.
4. `lib/features/practicals/presentation/controllers/gas_preparation_controller.dart` — StateNotifier controller with duration and gas evolution timers.
5. `lib/features/practicals/presentation/widgets/gas_preparation_bench_painter.dart` — CustomPainter laboratory bench with animated effervescence, pneumatic trough, beehive shelf, gas jars, and flame tests.
6. `lib/features/practicals/presentation/screens/gas_preparation_screen.dart` — 5-step touch-optimized laboratory screen with bilingual instructions, Lab Notebook modal, exit dialog, and scorecard modal.
7. `test/features/practicals/gas_preparation_engine_test.dart` — Comprehensive unit test suite for state transitions, gas evolution, and scoring.
8. `test/features/practicals/gas_preparation_screen_test.dart` — Widget test suite for apparatus inspection, reaction triggers, bilingual text, and dark theme.
9. `docs/p18_gas_preparation_implementation.md` — Final implementation and physical verification documentation.

### Files Modified:
1. `lib/features/practicals/data/models/practical_score_result.dart` — Added `calculateGasPreparationScore` rubric evaluator.
2. `lib/features/practicals/domain/practical_engine_registry.dart` — Registered `GasPreparationEngine` for `gas_preparation`, `gas-prep`, `gas_prep`, and `gas-preparation`.
3. `lib/features/practicals/data/repositories/practical_repository_impl.dart` — Set `simulationEngineId: 'gas_preparation'` for practical item #7 `gas-prep`.
4. `lib/core/router/app_router.dart` — Added routing for `gas-prep` and `gas_preparation` to `GasPreparationScreen`.

---

## 5. Automated Verification Results

### A. Static Analysis
Command: `flutter analyze`
```
Analyzing somasmart_flutter...
No issues found! (ran in 13.9s)
```

### B. Practical Test Suite
Command: `flutter test test/features/practicals/`
```
00:33 +116: All tests passed!
```
- Total Passing Tests: **116 / 116**
- Covers all practical engines P11–P18 (Titration, Ohm's Law, Microscope, Pendulum, Optics & Prism, Osmosis in Potato Tissues, Reaction Rates, and Laboratory Preparation of Gases).

---

## 6. Physical Device Verification on Google Pixel 4a 5G

**Device Serial:** `0B261JECB18979`  
**Display Resolution:** $1080 \times 2340$  
**Session ID:** `task-21`

| Verification Step | Tested Action | Device Result | Status |
| :--- | :--- | :--- | :--- |
| **1. Home Navigation** | Tap `Practicals` quick action card | Navigated to `/practicals` (`PracticalLevelScreen`) | **PASS** |
| **2. Academic Tier** | Select `O-Level Virtual Laboratory` | Navigated to `/practical/o-level` (`PracticalSubjectScreen`) | **PASS** |
| **3. Catalog Entry** | Scroll down to Practical 7: *Laboratory Preparation of Gases* | Displayed with `ACTIVE SIM` badge and *Start Simulation →* | **PASS** |
| **4. Mode Selection** | Tap practical card | Navigated to `/practical/mode-selection/gas-prep` with apparatus requirements | **PASS** |
| **5. Guided Mode Launch** | Tap *Launch Simulation (Guided Practice)* | Opened `GasPreparationScreen` in Guided Mode | **PASS** |
| **6. Step 1: Select Gas** | Selected $\text{O}_2, \text{CO}_2, \text{H}_2$ cards | Updated chemical formula, equation, and collection apparatus seamlessly | **PASS** |
| **7. Step 2: Inspection** | Tap *Inspect All* (or individual apparatus items) | Checked off all 6 glassware components ($6/6$) | **PASS** |
| **8. Step 3: Synthesis** | Tap *Add Solid* ($\text{MnO}_2$) $\rightarrow$ *Pour Liquid* ($\text{H}_2\text{O}_2$) | Generator flask charged; animated effervescence bubbles started | **PASS** |
| **9. Step 4: Collection** | Water displacement filling inverted gas jar | Jar volume filled to $100\text{ mL}$; progress bar reached $100\%$ | **PASS** |
| **10. Step 5: Gas Test** | Tap *Perform Gas Test* | Glowing splint relit with flame animation; confirmatory note displayed | **PASS** |
| **11. Scorecard Modal** | Tap *Submit & View Scorecard* | Opened draggable scorecard modal ($100/100$, Distinction, 5 competencies) | **PASS** |
| **12. Exam Mode** | Launched from Mode Selection | Displayed purple badge `EXAM MODE` with live timer and independent controls | **PASS** |
| **13. Lab Notebook** | Tap notebook icon on App Bar | Bottom sheet showed detailed theory for $\text{O}_2, \text{CO}_2, \text{H}_2$ | **PASS** |
| **14. Bilingual Mode** | Swahili localization | All UI titles, apparatus, instructions, and equations translated accurately | **PASS** |
| **15. Dark Theme** | Dark mode contrast check | Crisp glassware borders, dark palette (#0F172A), zero visual clipping | **PASS** |
| **16. Exit Protection** | Back arrow / Android back gesture | Dialog popped with *Leave / Cancel* options | **PASS** |
| **17. Runtime Health** | Log inspection | **0 runtime exceptions, 0 RenderFlex overflows, 0 crashes** | **PASS** |

---

## 7. Status Declaration

**P18 VERIFIED COMPLETE**

As directed in the prompt instructions:
- Practical development is now **STOPPED**.
- No subsequent practicals (such as P19) will be started without explicit instruction.
