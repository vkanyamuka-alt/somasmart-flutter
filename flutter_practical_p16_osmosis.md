# P16 — Biology Practical Engine: Osmosis in Potato Tissues
## Implementation & Verification Report

---

### 1. React Codebase Audit
A thorough inspection was performed across the React Student Web codebase (`src/pages/BiologyLab.jsx`, `PracticalModeSelection.jsx`, `constants/practicals.js`, `LanguageContext.jsx`, `ScoringEngine.js`):
- **Practical ID:** `osmosis-bio` (catalog key `osmosis-bio` / `osmosis`)
- **Route:** `/practical/simulation/osmosis-bio`
- **Title:** "Osmosis in Potato Tissues" / "Mchakato wa Osmosis Kwenye Viazi"
- **Subject / Level:** Biology / O-Level (Form III / Form IV NECTA & East African curriculum)
- **Duration / Difficulty:** 30–45 min / Medium

#### A. Existing / Migrated React Functionality
- Practical catalog metadata (ID, category, title, duration, description, objectives).
- Route parameters and mode selection flow (`guidedPractice`, `examMode`, `freeExploration`).
- Entitlement rules (free trial, subscription gating, admin override).
- Bilingual language support (English & Swahili text tokens).

#### B. Missing React Functionality (Newly Built in Flutter)
- **Interactive biology lab canvas:** React contained only placeholder metadata cards without an interactive simulation.
- **Specimen preparation engine:** Cork borer cylinder cutting ($50\text{ mm} \times 8\text{ mm}$) and potato skin trimming.
- **Virtual electronic balance:** Real tare weighing simulation for initial ($m_0$) and final ($m_1$) cylinder mass.
- **Physical water potential model:** Scientifically accurate osmotic flux based on sucrose concentrations ($0.0\text{M}$ to $0.8\text{M}$).
- **Interactive canvas workbench:** Custom wooden rack with 5 labeled boiling tubes (A–E), fluid meniscuses, potato cylinders, animated flux arrows, and filter paper blotting station.
- **Observation table & Graph engine:** Interactive data table and Cartesian graph ($\%\Delta m$ vs Concentration) with least-squares linear regression and zero-crossing isotonic point determination ($C_{\text{iso}} \approx 0.36\text{M}$).
- **Comprehensive scoring engine:** 5-tier competency rubric generating `PracticalScoreResult` with distinctions and achievements.

---

### 2. Scientific Experiment Model
The simulation accurately implements the biological principles of osmosis in plant storage parenchyma tissues (*Solanum tuberosum*):
$$\text{Water Potential } (\Psi) = \Psi_s + \Psi_p$$
- **Hypotonic Environment ($0.0\text{M}$ distilled water, $0.2\text{M}$ sucrose):** External water potential $\Psi_{\text{sol}} > \Psi_{\text{potato}}$. Endosmosis occurs as water molecules enter potato cells via selectively permeable tonoplast and plasma membranes, increasing cell turgor pressure ($\Delta m > 0$, cylinder becomes turgid and rigid).
- **Hypertonic Environment ($0.6\text{M}, 0.8\text{M}$ sucrose):** External water potential $\Psi_{\text{sol}} < \Psi_{\text{potato}}$. Exosmosis occurs as water leaves vacuolar sap into hypertonic solution, decreasing mass ($\Delta m < 0$, tissue undergoes plasmolysis and becomes flaccid/limp).
- **Isotonic Equilibrium Point ($C_{\text{iso}} \approx 0.36\text{M}$):** Net osmotic flux is zero ($\Delta m = 0\%$). The internal cell sap solute potential matches the external sucrose solution.

#### Experimental Formulae:
1. **Mass Change ($\Delta m$):**
   $$\Delta m = m_1 - m_0 \text{ (g)}$$
2. **Percentage Change in Mass ($\%\Delta m$):**
   $$\%\Delta m = \left(\frac{m_1 - m_0}{m_0}\right) \times 100\%$$
3. **Least Squares Isotonic Zero-Crossing ($C_{\text{iso}}$):**
   $$y = m \cdot x + c \implies \text{At } y = 0, \quad C_{\text{iso}} = -\frac{c}{m}$$

---

### 3. Virtual Laboratory Apparatus & Setup
The laboratory bench contains 6 interactive apparatus items:
1. **Fresh Potato Tuber (*Solanum tuberosum*):** Uniform parenchyma tissue.
2. **Cork Borer (#4, 8mm) & Ceramic Cutting Tile:** Cuts uniform cylinders.
3. **Surgical Scalpel & Millimeter Ruler:** Trims cylinders to equal 40 mm lengths, removing skin.
4. **Electronic Digital Balance ($0.01\text{g}$):** High-precision digital scale.
5. **5 Boiling Tubes in Wooden Rack:** Graded sucrose solutions ($0.0\text{M}, 0.2\text{M}, 0.4\text{M}, 0.6\text{M}, 0.8\text{M}$).
6. **Filter Paper Station & Forceps:** Blots surface meniscus droplets prior to re-weighing.

---

### 4. Step-by-Step Simulation Workflow
1. **Step 1 — Inspect Apparatus:** Inspect all 6 equipment items and review safety protocols.
2. **Step 2 — Cut & Prepare Cylinders:** Core 5 cylinders with cork borer, trim to 40 mm, and remove epidermal skin.
3. **Step 3 — Initial Weighing ($m_0$):** Place cylinders A–E on the electronic balance and record $m_0 \approx 2.00\text{g}$.
4. **Step 4 — Immerse & Incubate:** Immerse cylinders in boiling tubes A–E and run the 30-second incubation timer with animated water particle fluxes.
5. **Step 5 — Blot & Final Weighing ($m_1$):** Retrieve cylinders, gently blot excess surface moisture on filter paper, and record $m_1$.
6. **Step 6 — Observation Table:** Review complete experimental dataset ($m_0$, $m_1$, $\Delta m$, $\%\Delta m$, and tissue condition).
7. **Step 7 — Graph & Isotonic Point:** Plot experimental data points, observe the negative linear trend, determine $C_{\text{iso}}$, and submit for scoring.

---

### 5. Architectural Implementation
- **Domain State Model:** `lib/features/practicals/data/models/osmosis_state.dart` (`OsmosisState`, `PotatoSample`, `OsmosisApparatusItem`, `OsmosisStep`).
- **Simulation Engine:** `lib/features/practicals/domain/osmosis_engine.dart` (Implements `PracticalSimulationEngine<OsmosisState, OsmosisAction>`).
- **Registry Integration:** `lib/features/practicals/domain/practical_engine_registry.dart` (Aliases `osmosis` and `osmosis-bio`).
- **State Notifier Controller:** `lib/features/practicals/presentation/controllers/osmosis_controller.dart`.
- **Canvas Bench Painter:** `lib/features/practicals/presentation/widgets/osmosis_bench_painter.dart`.
- **Interactive Graph Widget:** `lib/features/practicals/presentation/widgets/osmosis_graph_widget.dart`.
- **User Interface Screen:** `lib/features/practicals/presentation/screens/osmosis_screen.dart`.
- **Routing:** `lib/core/router/app_router.dart` (Routes `osmosis-bio` and `osmosis` to `OsmosisScreen`).

---

### 6. Automated Testing & Code Quality
- **`flutter analyze lib/ test/`:** **0 issues found** (100% clean).
- **`flutter test`:** **112/112 tests passing** (100% pass rate).
  - `osmosis_engine_test.dart` (8 comprehensive unit tests).
  - `osmosis_screen_test.dart` (5 widget tests across English/Swahili, Light/Dark, and interaction flows).
  - Regression verified: P11 (Titration), P12 (Ohm's Law), P13 (Microscope), P14 (Pendulum), P15 (Refraction & Prism) all pass.

---

### 7. Verification Status
- **Automated Tests:** PASS (112/112)
- **Static Analysis:** PASS (0 issues)
- **Status:** **P16 IMPLEMENTED — PHYSICAL VERIFICATION PENDING** (Physical Pixel 4a 5G test ready to run upon device connection).
