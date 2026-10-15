# P17 — Rates of Chemical Reactions Implementation & Physical Verification Report

**Subject:** Chemistry  
**Level:** O-Level (Form 4 / NECTA CSEE & Cambridge IGCSE Syllabus Standard)  
**Practical Title:** Rates of Chemical Reactions (Thiosulfate & Acid) / *Kasi ya Miitikio ya Kikemia*  
**Engine ID:** `rates_of_reaction` (Aliases: `reaction-rates`, `rates-of-reaction`, `reaction_rates`)  
**Practical ID:** `reaction-rates`  
**Physical Device:** Google Pixel 4a 5G (`0B261JECB18979`, Android 14 / API 34)  
**Status:** **P17 VERIFIED COMPLETE**

---

## 1. React Audit Findings & Architecture Comparison

- **React Origin:**
  - `ChemistryLab.jsx` defined O-Level Practical #6: `id: "reaction-rates"`, `title: "Rates of Chemical Reactions"`, with an inline SVG depicting a conical flask over a bold black cross ($X$), sulfur precipitate formation ($\text{S(s)}$ turbidity), stopclock readout `00:42.5 s`, and reaction equation $\text{Na}_2\text{S}_2\text{O}_3 + \text{HCl} \rightarrow \text{S(s) turbidity}$.
  - In React, `PracticalModeSelection.jsx` presented the 3 mode cards (Guided Practice, Exam Mode, Free Exploration), but redirected launches to Titration.
- **Native Flutter Architecture:**
  - Designed and implemented a dedicated `RatesOfReactionEngine` implementing `PracticalSimulationEngine<RatesOfReactionState, RatesOfReactionAction>`.
  - Registered in `PracticalEngineRegistry` and routed dynamically via `AppRouter` (`/practical/simulation/reaction-rates`).
  - Implemented custom hardware-accelerated canvas rendering for the disappearing cross, real-time sulfur colloid accumulation, dynamic timer, kinetic results table, and reciprocal rate graph ($1/t$ vs $[\text{Na}_2\text{S}_2\text{O}_3]$).

---

## 2. Scientific Formulas & Kinetics Model

$$\text{Na}_2\text{S}_2\text{O}_3\text{ (aq)} + 2\text{HCl (aq)} \longrightarrow 2\text{NaCl (aq)} + \text{SO}_2\text{ (g)} + \text{S (s)}\downarrow + \text{H}_2\text{O (l)}$$

- **Serial Dilutions (5 Flasks):**
  - **Flask 1:** $50\text{ mL } \text{Na}_2\text{S}_2\text{O}_3 + 0\text{ mL } \text{H}_2\text{O} \rightarrow [\text{Na}_2\text{S}_2\text{O}_3] = 0.20\text{ M} \rightarrow t_{\text{exp}} = 20.0\text{ s} \rightarrow \text{Rate } 1/t = 0.050\text{ s}^{-1}$
  - **Flask 2:** $40\text{ mL } \text{Na}_2\text{S}_2\text{O}_3 + 10\text{ mL } \text{H}_2\text{O} \rightarrow [\text{Na}_2\text{S}_2\text{O}_3] = 0.16\text{ M} \rightarrow t_{\text{exp}} = 25.0\text{ s} \rightarrow \text{Rate } 1/t = 0.040\text{ s}^{-1}$
  - **Flask 3:** $30\text{ mL } \text{Na}_2\text{S}_2\text{O}_3 + 20\text{ mL } \text{H}_2\text{O} \rightarrow [\text{Na}_2\text{S}_2\text{O}_3] = 0.12\text{ M} \rightarrow t_{\text{exp}} = 33.3\text{ s} \rightarrow \text{Rate } 1/t = 0.030\text{ s}^{-1}$
  - **Flask 4:** $20\text{ mL } \text{Na}_2\text{S}_2\text{O}_3 + 30\text{ mL } \text{H}_2\text{O} \rightarrow [\text{Na}_2\text{S}_2\text{O}_3] = 0.08\text{ M} \rightarrow t_{\text{exp}} = 50.0\text{ s} \rightarrow \text{Rate } 1/t = 0.020\text{ s}^{-1}$
  - **Flask 5:** $10\text{ mL } \text{Na}_2\text{S}_2\text{O}_3 + 40\text{ mL } \text{H}_2\text{O} \rightarrow [\text{Na}_2\text{S}_2\text{O}_3] = 0.04\text{ M} \rightarrow t_{\text{exp}} = 100.0\text{ s} \rightarrow \text{Rate } 1/t = 0.010\text{ s}^{-1}$
- **Linear Rate Law & Slope:**
  - $\text{Rate} = \frac{1}{t} = k' \cdot [\text{Na}_2\text{S}_2\text{O}_3]^1$
  - Slope $k' = 0.250\text{ s}^{-1}\text{M}^{-1}$ (1st order kinetics with respect to thiosulfate).

---

## 3. Files Created & Modified

### Created Files
1. `docs/p17_rates_reaction_audit.md` — Complete Phase 1 audit document.
2. `lib/features/practicals/data/models/rates_of_reaction_state.dart` — State machine, apparatus items, and trial data models.
3. `lib/features/practicals/domain/rates_of_reaction_engine.dart` — Domain kinetics simulation engine and action processor.
4. `lib/features/practicals/presentation/controllers/rates_of_reaction_controller.dart` — Riverpod StateNotifier controller.
5. `lib/features/practicals/presentation/widgets/rates_of_reaction_bench_painter.dart` — CustomPainter rendering the disappearing cross tile, conical flask, sulfur turbidity, and top-down portal.
6. `lib/features/practicals/presentation/widgets/rates_of_reaction_graph_widget.dart` — CustomPainter plotting rate ($1/t$) vs concentration ($[\text{Na}_2\text{S}_2\text{O}_3]$).
7. `lib/features/practicals/presentation/screens/rates_of_reaction_screen.dart` — Comprehensive 5-step laboratory screen.
8. `test/features/practicals/rates_of_reaction_engine_test.dart` — Domain engine unit tests.
9. `test/features/practicals/rates_of_reaction_screen_test.dart` — UI widget and touch tests.
10. `docs/p17_rates_reaction_implementation.md` — Final implementation & verification report.

### Modified Files
1. `lib/features/practicals/data/models/practical_score_result.dart` — Added `calculateRatesOfReactionScore` evaluation rubric.
2. `lib/features/practicals/domain/practical_engine_registry.dart` — Registered `RatesOfReactionEngine` under `rates_of_reaction` and alias lookups.
3. `lib/features/practicals/data/repositories/practical_repository_impl.dart` — Configured `simulationEngineId: 'rates_of_reaction'`.
4. `lib/core/router/app_router.dart` — Bound `/practical/simulation/reaction-rates` to `RatesOfReactionScreen`.

---

## 4. Automated Testing & Static Analysis Results

| Command | Target | Result |
| :--- | :--- | :--- |
| `flutter analyze` | Entire Flutter codebase | **No issues found!** (0 errors, 0 warnings, 0 lints) |
| `flutter test test/features/practicals/rates_of_reaction_engine_test.dart test/features/practicals/rates_of_reaction_screen_test.dart` | P17 Unit & Widget Tests | **13 / 13 passed** |
| `flutter test test/features/practicals/` | All Practical Engines (P11–P17) | **99 / 99 passed** |

---

## 5. Physical Device Verification (Pixel 4a 5G)

| Test Item | Result | Verification Evidence |
| :--- | :---: | :--- |
| **Route Resolution** | **PASS** | Navigated from `/home` $\rightarrow$ `/practicals` $\rightarrow$ `/practical/o-level` $\rightarrow$ Chemistry $\rightarrow$ Rates of Chemical Reactions $\rightarrow$ Mode Selection $\rightarrow$ `/practical/simulation/reaction-rates`. |
| **Apparatus Inspection** | **PASS** | All 6 apparatus items inspected with real-time feedback and count tracking. |
| **Dilution Preparation** | **PASS** | Diluted Flasks 1–5 to $0.20\text{ M}, 0.16\text{ M}, 0.12\text{ M}, 0.08\text{ M}, 0.04\text{ M}$. |
| **Timing & Disappearing Cross** | **PASS** | Added $5.0\text{ mL } \text{HCl}$, observed progressive sulfur turbidity ($0\% \rightarrow 100\%$) and cross disappearance; recorded endpoints accurately. |
| **Results Table** | **PASS** | Kinetic table populated with $V_{\text{thio}}$, $V_{\text{water}}$, $[\text{Na}_2\text{S}_2\text{O}_3]$, time $t$, and rate $1/t$. |
| **Interactive Graph** | **PASS** | Rate graph plotted $1/t$ vs $[\text{Na}_2\text{S}_2\text{O}_3]$ with linear trendline passing through $(0,0)$ and slope $k \approx 0.250\text{ s}^{-1}\text{M}^{-1}$. |
| **Scorecard & Rubric** | **PASS** | Generated Grade A+ (100/100) distinction scorecard with 5 competencies and badges. |
| **Modes (Guided / Exam / Free)** | **PASS** | Step progression locking in Guided, independent assessment in Exam, unrestricted access in Free mode. |
| **Bilingual Support (EN / SW)** | **PASS** | Full English & Swahili UI switching (*Kasi ya Miitikio ya Kikemia*, *Kagua Vifaa*, *Pima Myeyusho*, *Jedwali la Matokeo*, *Kanuni ya Kasi*). |
| **Theme (Light / Dark)** | **PASS** | High-contrast readability, no clipped cards, clear canvas borders, sharp graph grid. |
| **Navigation Safety** | **PASS** | `PopScope` confirmation prevents accidental experiment exit; back buttons return cleanly. |
| **Runtime Stability** | **PASS** | 0 runtime exceptions, 0 assertion errors, 0 `RenderFlex` overflows, 0 crashes on device. |

---

## 6. Final Status

**P17 VERIFIED COMPLETE**
