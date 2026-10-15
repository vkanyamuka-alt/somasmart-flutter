# P17 — Rates of Chemical Reactions Practical Audit

**Subject:** Chemistry  
**Level:** O-Level (Form 4 / NECTA CSEE & Cambridge IGCSE Syllabus Standard)  
**Practical Title:** Rates of Chemical Reactions (Thiosulfate & Acid) / *Kasi ya Miitikio ya Kikemia*  
**Engine ID:** `rates_of_reaction` (with aliases `reaction-rates`, `rates-of-reaction`, `reaction_rates`)  
**Practical ID:** `reaction-rates`

---

## 1. Actual React Behavior

| Area | Findings in React Codebase (`SomaSmart App`) |
| :--- | :--- |
| **Catalog Listing** | `ChemistryLab.jsx` (Lines 338–350) defines O-Level Practical #6: `id: "reaction-rates"`, `title: "Rates of Chemical Reactions"`, `route: "/practical/mode-selection/reaction-rates"`, `thumbnailType: "reaction-rates"`. |
| **Thumbnail SVG** | `ChemistryLab.jsx` (Lines 175–192) renders a dedicated SVG showing a conical flask placed directly over a black cross ($X$), sulfur precipitate cloudiness ($\text{S(s)}$ turbidity), a stopwatch reading `00:42.5 s`, and the chemical equation $\text{Na}_2\text{S}_2\text{O}_3 + \text{HCl} \rightarrow \text{S(s) turbidity}$. |
| **Reaction Engine** | `ReactionEngine.jsx` contains a general 9-step chemistry evaluation decision pipeline with 16 parameter checks, but does not provide a dedicated interactive virtual bench for the sodium thiosulfate disappearing cross experiment. |
| **Mode Selection** | `PracticalModeSelection.jsx` presented the 3 modes (Guided Practice, Exam Mode, Free Exploration), but redirected all launches to Acid–Base Titration. |
| **Scoring Engine** | `ScoringEngine.js` defined a generalized 100-point 5-competency rubric structure reused by all practicals. |
| **Bilingual Support** | `LanguageContext` provided English/Kiswahili dictionary strings. |
| **Entitlement** | Server-authoritative Supabase subscription/trial verification via `verifySubscription`. |

---

## 2. New Flutter Functionality Required

1. **Dedicated Rates of Reaction Engine (`RatesOfReactionEngine`):**
   - Implements `PracticalSimulationEngine<RatesOfReactionState, RatesOfReactionAction>`.
   - Pre-registered in `PracticalEngineRegistry` under `rates_of_reaction` and `reaction-rates`.
2. **Deterministic Kinetics State Machine:**
   - Supports 5 serial dilution concentrations of $\text{Na}_2\text{S}_2\text{O}_3$ ($0.04\text{ M}, 0.08\text{ M}, 0.12\text{ M}, 0.16\text{ M}, 0.20\text{ M}$).
   - Dynamic real-time stopwatch and turbidity opacity simulation ($\text{S(s)}$ precipitate formation).
   - Accurate disappearing cross endpoint trigger.
3. **Interactive Visual Laboratory Bench (`RatesOfReactionBenchPainter`):**
   - CustomPainter depicting:
     - 5 Conical flasks on white tile over laminated bold black cross ($X$).
     - Real-time colloidal sulfur turbidity rendering (clear $\rightarrow$ milky-yellow $\rightarrow$ opaque).
     - Top-down viewpoint of the disappearing cross under the flask.
     - Digital stopwatch with Start/Pause/Reset controls.
     - Measuring cylinders for thiosulfate, water, and acid.
4. **Interactive Results Table & Kinetic Graph (`RatesOfReactionGraphWidget`):**
   - Real-time calculation of $[Na_2S_2O_3]$, time $t$, rate $1/t$ ($\text{s}^{-1}$), and linear regression slope ($k'$).
   - CustomPainter plotting $1/t$ vs $[Na_2S_2O_3]$ with linear trendline through origin $(0,0)$.
5. **Mode Support:**
   - **Guided Practice:** Step-by-step lock with guidance prompts and assisted timing.
   - **Exam Mode:** Independent assessment without hints, strict timing, and evaluation against theoretical rate law.
   - **Free Exploration:** Unrestricted concentration selection and free trials.
6. **Bilingual & Theme Support:**
   - Complete English and Kiswahili localization.
   - High-contrast Light and Dark mode rendering.
