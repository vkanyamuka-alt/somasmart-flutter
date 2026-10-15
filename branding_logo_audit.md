# SomaSmart Branding & Official Logo Audit

## 1. Executive Summary
This audit documents all logo assets, branding references, launcher icons, favicons, and UI header representations across the SomaSmart Flutter mobile application prior to integrating the official SomaSmart "S" logo mark.

---

## 2. Official Logo Specification
- **Official Asset**: SomaSmart "S" mark (single source of truth from uploaded artwork).
- **Artwork Structure**:
  - Upper & Lower sweeping blue curves forming the "S".
  - Golden/amber four-pointed central star & accent ribbons.
  - White inner highlights preserved as integral vector/bitmap artwork.
- **Wordmark Rule**: The word "SomaSmart" is **NOT** baked into the image. It is rendered exclusively as **live Flutter text typography** alongside the logo mark `[S LOGO] + SomaSmart text` to preserve sharpness and responsiveness across all device pixel densities.

---

## 3. Current Logo & Branding Locations Audit

| Location / File | Current Implementation | Status / Action Required |
|---|---|---|
| `assets/images/logo.png` | Old uncropped 2752x1536 PNG canvas | **REPLACE** with high-resolution, cropped transparent official S mark. |
| `lib/core/widgets/app_top_bar.dart` | Hardcoded `Image.asset('assets/images/logo.png')` + `Text('SomaSmart')` | **UPDATE** to use reusable `SomaSmartLogo` component. |
| `lib/core/widgets/side_menu_drawer.dart` | Generic circular container with fallback 'S' text | **ENHANCE** to use `SomaSmartLogo(markOnly: true)` or branded avatar. |
| `lib/core/widgets/soma_smart_logo.dart` | *Does not exist yet* | **CREATE** reusable, configurable branding widget supporting mark-only, mark+text, sizing, and theme awareness. |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | Default Flutter icon (48x48) | **REPLACE** with official S mark launcher icon. |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | Default Flutter icon (72x72) | **REPLACE** with official S mark launcher icon. |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | Default Flutter icon (96x96) | **REPLACE** with official S mark launcher icon. |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | Default Flutter icon (144x144) | **REPLACE** with official S mark launcher icon. |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | Default Flutter icon (192x192) | **REPLACE** with official S mark launcher icon. |
| `web/favicon.png` | Default Flutter favicon | **REPLACE** with official S mark favicon. |
| `web/icons/Icon-*.png` | Default Flutter web icons | **REPLACE** with official S mark web icons. |

---

## 4. Protected Surfaces & Scope Lock
- **Practical Simulation Engines (P11–P18)**: Untouched.
- **Quiz & Exam Engines**: Untouched.
- **Supabase Authentication & Backend**: Untouched.
- **Navigation & Routing**: Preserved 100%.

---

## 5. Implementation Roadmap
1. Generate pixel-perfect transparent PNG assets for `assets/images/logo.png`, Android mipmaps, and Web icons.
2. Implement `SomaSmartLogo` reusable widget under `lib/core/widgets/soma_smart_logo.dart`.
3. Integrate `SomaSmartLogo` in `AppTopBar` and related branding locations.
4. Execute `flutter analyze` and `flutter test`.
5. Launch on physical Pixel 4a 5G (`0B261JECB18979`) and verify runtime rendering.
