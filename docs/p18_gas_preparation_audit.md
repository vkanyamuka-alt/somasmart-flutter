# P18 — Laboratory Preparation of Gases Practical Audit

**Subject:** Chemistry  
**Level:** O-Level (Form 2 / Form 4 NECTA CSEE & Cambridge IGCSE Syllabus Standard)  
**Practical Title:** Laboratory Preparation of Gases / *Utayarishaji wa Gesi Maabarani*  
**Engine ID:** `gas_preparation` (Aliases: `gas-prep`, `gas_prep`, `gas-preparation`)  
**Practical ID:** `gas-prep`

---

## 1. Actual React Behavior

| Area | Findings in React Codebase (`SomaSmart App`) |
| :--- | :--- |
| **Catalog Listing** | `ChemistryLab.jsx` (Lines 352–364) defines O-Level Practical #7: `id: "gas-prep"`, `title: "Laboratory Preparation of Gases"`, `route: "/practical/mode-selection/gas-prep"`, `thumbnailType: "gas-prep"`. |
| **Thumbnail SVG** | `ChemistryLab.jsx` (Lines 193–209) renders a dedicated SVG depicting a conical flask with thistle funnel, delivery tube leading to a gas collection jar, gas bubbles evolving ($\text{CO}_2 / \text{O}_2\text{ Gas}$), downward delivery/water displacement. |
| **Mode Selection** | `PracticalModeSelection.jsx` presented the 3 modes (Guided Practice, Exam Mode, Free Exploration), but redirected launches to Titration. |
| **Scoring Engine** | `ScoringEngine.js` provided standard 100-point competency rubric architecture. |
| **Bilingual Support** | `LanguageContext` provided English/Kiswahili dictionary strings. |
| **Entitlement** | Server-authoritative Supabase subscription/trial verification via `verifySubscription`. |

---

## 2. New Flutter Functionality Required

1. **Dedicated Gas Preparation Engine (`GasPreparationEngine`):**
   - Implements `PracticalSimulationEngine<GasPreparationState, GasPreparationAction>`.
   - Registered in `PracticalEngineRegistry` under `gas_preparation` and `gas-prep`.
2. **Multi-Gas Generation State Machine:**
   - **Oxygen ($\text{O}_2$):** $\text{H}_2\text{O}_2 + \text{MnO}_2 \rightarrow \text{H}_2\text{O} + \text{O}_2$ (Over water collection $\rightarrow$ Relights glowing splint).
   - **Carbon Dioxide ($\text{CO}_2$):** $\text{CaCO}_3 + 2\text{HCl} \rightarrow \text{CaCl}_2 + \text{H}_2\text{O} + \text{CO}_2$ (Downward delivery $\rightarrow$ Limewater turns cloudy white).
   - **Hydrogen ($\text{H}_2$):** $\text{Zn} + 2\text{HCl} \rightarrow \text{ZnCl}_2 + \text{H}_2$ (Over water collection $\rightarrow$ Squeaky pop sound with burning splint).
3. **Interactive Visual Laboratory Bench (`GasPreparationBenchPainter`):**
   - CustomPainter depicting:
     - Flat-bottom conical generation flask with thistle funnel and side-arm delivery tube.
     - Reagent addition (liquid through thistle funnel onto solid catalyst/reactant).
     - Animated effervescence & gas bubble stream.
     - Water trough with beehive shelf and inverted graduated gas jar (for $\text{O}_2$ and $\text{H}_2$), or upward upright gas jar (for $\text{CO}_2$).
     - Real-time gas volume collection ($0\text{ mL} \rightarrow 100\text{ mL}$).
     - Gas testing tool (Glowing splint, Burning splint, Limewater bubbler).
4. **Step Workflow (5 Steps):**
   - 1. Inspect Apparatus & Safety Check
   - 2. Select Gas & Charge Flask with Reactants
   - 3. Add Liquid Reagent & Monitor Effervescence
   - 4. Collect Gas in Gas Jar (Displacement)
   - 5. Confirmatory Gas Tests & Observations (Splint / Limewater) $\rightarrow$ Scorecard
5. **Mode Support:**
   - **Guided Practice:** Step-by-step lock with guidance prompts and assisted delivery.
   - **Exam Mode:** Independent assessment without hints, strict gas identification and equation testing.
   - **Free Exploration:** Unrestricted gas switching and unlimited trial resets.
6. **Bilingual & Theme Support:**
   - Full English and Kiswahili localization.
   - High-contrast Light and Dark theme rendering.
