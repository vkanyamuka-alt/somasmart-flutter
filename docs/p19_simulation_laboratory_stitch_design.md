# P19 — SomaSmart Simulation Laboratory Stitch Design Specification

## 1. Executive Summary & Design Exploration Overview
This document records the visual design exploration conducted using **Google Stitch MCP** for the **SomaSmart Simulation Laboratory** landing page and the **O-Level Subject Laboratory** selection flow.

### Stitch MCP Exploration Record:
- **Project ID:** `projects/14840810005345914656` (*SomaSmart Simulation Laboratory Redesign*)
- **Design System Asset:** `assets/aafc2fe22bbc43e0b5e041b917677bba` (*SomaSmart Virtual Laboratory*)
- **Variations Explored via Stitch MCP:**
  1. **Variation 1 (Clean Academic Bench):** Prominent realistic laboratory workbench hero panel, clear "Choose Your Academic Level" section with large O-Level & A-Level cards.
  2. **Variation 2 (Immersive Laboratory Station):** Realistic workbench hero with subtle curriculum/offline status chips, stacked level selection, and a secondary discipline preview footer.
  3. **Variation 3 (Dark Mode Deep Slate Lab):** High-contrast Deep Slate (`#0F172A`) dark theme with luminous Royal Blue accents, realistic illuminated laboratory glassware, and crisp slate surface cards.
  4. **Screen 2 (O-Level Subject Laboratories):** "O-Level Laboratory" hub featuring three specialized laboratory entry cards ("Enter Chemistry Laboratory", "Enter Physics Laboratory", "Enter Biology Laboratory").

---

## 2. Selected Design Direction

### **Direction Selected:** *Modern Academic Workbench (Hybrid of Variation 1 & 2)*
The chosen direction combines the clarity and focus of the **Clean Academic Bench** with the realistic workbench atmosphere of the **Immersive Laboratory Station**, ensuring zero cognitive clutter on mobile while delivering an immediate sense of entering a real digital science laboratory.

### Core Visual Principles:
1. **Realistic Laboratory Atmosphere:** The hero section presents a physical, believable laboratory workbench with carefully composed instruments (Erlenmeyer flask, measuring cylinder, test tubes in rack, microscope) rather than generic tech abstract graphics or emoji icons.
2. **Strict Purpose Hierarchy:**
   - **Primary Goal:** Select Academic Level (O-Level vs A-Level).
   - **Secondary Preview:** Subtle non-competing discipline indicators (Chemistry, Physics, Biology) to build anticipation without distracting from level selection.
3. **Unified SomaSmart Visual Family:**
   - Dominant Royal Scholar Blue (`#0058BE`).
   - Deep Slate typography (`#0F172A`) and Slate borders (`#E2E8F0`).
   - Clean White (`#FFFFFF`) card surfaces on Light Slate (`#F8FAFC`) canvas.
   - Zero rainbow colors; semantic discipline accents remain restrained and harmonious.

---

## 3. Screen 1 Design Specification: SomaSmart Simulation Laboratory

### Layout Structure (Top to Bottom):
1. **App Bar:**
   - Title: `SomaSmart Simulation Laboratory` / `Maabara ya Vitendo ya SomaSmart`
   - Leading: Back navigation arrow (to previous app tab)
   - Action: Language / Theme toggle support
2. **Hero Workbench Panel (Realistic Digital Lab Table):**
   - **Visual Background:** Slate-to-Royal-Navy gradient (`#0F172A` to `#0058BE`) or high-clarity rendered workbench tabletop.
   - **Composition:** Realistic glassware (conical flask, beaker with graduation marks, test tube rack, thermometer) with soft natural reflections.
   - **Tagline:** *"Practice. Experiment. Understand."* / *"Jifunze. Jaribu. Elewa."*
   - **Badge:** NECTA Standard Laboratory Simulation / *Viwango vya NECTA*
3. **Academic Level Selection Section:**
   - Header: `CHOOSE YOUR ACADEMIC LEVEL` / `CHAGUA NGAZI YA MASOMO`
   - Subtitle: *"Select your educational tier to access curriculum-aligned practical experiments."*
   - **Card 1: O-LEVEL SECONDARY**
     - Title: `O-Level Secondary` / `Kidato cha 1–4 (O-Level)`
     - Subtitle: `Form 1 – Form 4 NECTA Practicals`
     - Description: Foundational laboratory experiments across Chemistry, Physics, and Biology.
     - Real Data Badge: `8 Simulations Available` / `Majaribio 8 Yapo` (Emerald / Sky tag)
     - Imagery: Realistic secondary lab glassware apparatus (burette, flask, circuit meter, optical slide).
     - Action: Primary Royal Blue button `"Enter O-Level Laboratory"` with chevron.
     - Border: 1.5px solid Royal Scholar Blue highlight.
   - **Card 2: A-LEVEL ADVANCED**
     - Title: `A-Level Advanced` / `Kidato cha 5–6 (A-Level)`
     - Subtitle: `Form 5 – Form 6 Advanced Lab`
     - Description: Advanced investigations in reaction kinetics, wave mechanics, and cytology.
     - Real Status Badge: `In Development / Inatengenezwa` (Muted slate tag)
     - Imagery: Advanced analytical laboratory apparatus.
     - Action: Secondary outline card with informative preview dialog.
4. **Subtle Secondary Subject Preview Strip:**
   - Small horizontal preview pills at the bottom: `Chemistry (3 Labs)` • `Physics (3 Labs)` • `Biology (2 Labs)` in unified Royal Blue/Slate styling.

---

## 4. Screen 2 Design Specification: O-Level Subject Laboratories

### Layout Structure (Top to Bottom):
1. **App Bar:**
   - Title: `O-Level Laboratory` / `Maabara ya O-Level`
   - Leading: Back button (returns naturally to Simulation Laboratory Hub)
2. **Subject Lab Selection Header:**
   - Title: `Select Subject Laboratory` / `Chagua Maabara ya Somo`
   - Subtitle: *"Choose a specialized science discipline to begin your interactive experiments."*
3. **Three Prominent Subject Laboratory Cards:**
   - **1. Chemistry Laboratory Card:**
     - Title: `Chemistry Laboratory` / `Maabara ya Kemia`
     - Topics: *Volumetric Analysis, Gas Preparation, Reaction Kinetics*
     - Badge: `3 Practicals Available`
     - Imagery: Realistic chemical bench — Erlenmeyer flask with solution, test tubes, burette stand in Royal Blue line-art.
     - Action: `"Enter Chemistry Laboratory"` → navigates to `/practical/o-level/chemistry`.
   - **2. Physics Laboratory Card:**
     - Title: `Physics Laboratory` / `Maabara ya Fizikia`
     - Topics: *Ohm's Law, Prism Refraction, Harmonic Pendulum*
     - Badge: `3 Practicals Available`
     - Imagery: Realistic physics bench — Circuit board, ammeter dial, glass prism with refracted light, pendulum stand.
     - Action: `"Enter Physics Laboratory"` → navigates to `/practical/o-level/physics`.
   - **3. Biology Laboratory Card:**
     - Title: `Biology Laboratory` / `Maabara ya Biolojia`
     - Topics: *Microscopy & Cell Staining, Osmosis in Plant Tissues*
     - Badge: `2 Practicals Available`
     - Imagery: Realistic biology bench — Compound optical microscope, specimen slide, potato osmometer tubes.
     - Action: `"Enter Biology Laboratory"` → navigates to `/practical/o-level/biology`.

---

## 5. Design System Tokens & Specs

### Color Palette:
| Token | Light Mode | Dark Mode | Usage |
| :--- | :--- | :--- | :--- |
| **Primary Brand** | `#0058BE` (Royal Scholar Blue) | `#38BDF8` / `#60A5FA` | Primary buttons, active indicators, highlights |
| **Primary Container** | `#E0F2FE` (Ice Blue) | `#1E293B` (Slate-800) | Card backgrounds, badge containers |
| **Canvas Background** | `#F8FAFC` (Slate-50) | `#0F172A` (Deep Slate-900) | Main screen surface |
| **Card Surface** | `#FFFFFF` (Pure White) | `#1E293B` (Slate-800) | Level cards, subject cards |
| **Borders** | `#E2E8F0` (Slate-200) | `#334155` (Slate-700) | 1px hairline structural boundaries |
| **Active Focus Border** | `#0058BE` (1.5px solid) | `#38BDF8` (1.5px solid) | Selected cards, interactive targets |
| **Text Primary** | `#0F172A` (Slate-900) | `#F8FAFC` (Slate-50) | Headings, card titles, key readings |
| **Text Secondary** | `#334155` (Slate-700) | `#94A3B8` (Slate-400) | Subtitles, descriptions, Form ranges |
| **Text Muted** | `#64748B` (Slate-500) | `#64748B` (Slate-500) | Timestamps, durations, inactive labels |

### Typography Scale (Inter / System Sans):
- **Display Hero:** 19px, Bold (`FontWeight.w800`), Line-height: 1.2, Letter-spacing: -0.4px.
- **Section Headings:** 16px, Bold (`FontWeight.w800`), Color: `#0F172A`.
- **Card Titles:** 15.5px, Semi-Bold (`FontWeight.w800`), Line-height: 1.25.
- **Body / Descriptions:** 12px – 13px, Regular (`FontWeight.w400`), Line-height: 1.35.
- **Metadata Chips / Badges:** 10.5px – 11px, Bold (`FontWeight.w700`), Letter-spacing: 0.3px.

### Spatial Spacing & Geometry:
- **Base Spatial Unit:** 4px / 8px grid cadence.
- **Screen Margin:** 16px outer horizontal padding.
- **Card Padding:** 14px – 16px internal padding.
- **Card Gap:** 12px – 14px vertical separation between cards.
- **Corner Radii:**
  - Standard Cards: `16px` radius.
  - Badges & Chips: `6px` radius.
  - Buttons: `8px` – `10px` radius.
  - Touch Targets: Minimum `48px` height for all primary action tap areas.

---

## 6. Realistic Scientific Imagery & Thumbnail Rules

1. **Unified Visual Family:**
   All laboratory apparatus illustrations (Titration burette, Ohm's Law circuit, Microscope, Pendulum, Optics prism, Osmosis test tubes, Reaction flask with disappearing cross, Gas generator with collection vessel) share:
   - Identical `84x84` dp container dimensions.
   - Consistent stroke weight (`1.8px` primary, `1.2px` secondary).
   - Consistent soft blue fluid fill (`#0058BE.withOpacity(0.12)` in light mode, `0.25` in dark mode).
   - Cohesive perspective (straight-on laboratory elevation view).
2. **Zero Inconsistent Art Styles:**
   No cartoon emojis, no mismatched 3D assets, no generic icons. Every instrument is accurately drawn to represent real NECTA secondary laboratory apparatus.

---

## 7. Bilingual & Mobile Responsiveness Strategy

1. **English & Kiswahili Flexibility:**
   - All text containers utilize flexible expansion (`Expanded`, `maxLines: 2`, `overflow: TextOverflow.ellipsis`) to handle longer Kiswahili phrases (e.g., *"Maabara ya Vitendo ya SomaSmart"* vs *"SomaSmart Simulation Laboratory"*).
2. **Narrow Viewport Safety (Pixel 4a 5G / ~390px):**
   - Single-column vertical card stacking avoids horizontal clipping.
   - No fixed widths on text blocks.
   - Horizontal practical cards use a fixed `84px` thumbnail paired with an `Expanded` content column.
   - Zero `RenderFlex` overflow risk on all screen densities.

---

## 8. Summary of Approved Design Deliverables
- **Stitch MCP Exploration Completed:** `projects/14840810005345914656`.
- **Approved Design Direction:** Modern Academic Workbench with realistic laboratory hero, high-contrast Level Cards, and dedicated Subject Laboratory cards.
- **Design Document Path:** `docs/p19_simulation_laboratory_stitch_design.md`.
- **Implementation Status:** Design exploration complete and approved for future Flutter translation.
