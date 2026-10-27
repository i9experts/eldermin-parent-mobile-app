# Photo auth: what was duplicated from the teacher app

The photo auth look (splash, login, OTP, create account, email sign in) was built first in `eldermin-teacher-app`
(branch `design/auth-motion`) and **copied** here (branch `design/auth-photo`). These pieces are candidates for a shared
package (`eldermin_auth_design`) later. Until then, a fix in one app needs the same fix in the other.

Copied files (teacher path → parent path, both under `lib/`). "Changed" = what differs from the teacher copy.

| Piece | Parent path | Changed |
|---|---|---|
| Overlay tokens (`EmPhotoOverlay`: stops, alpha, worst-case colour, strong line, contrast pairs) | `core/design/tokens/em_photo_overlay.dart` | accent pair is 4.5:1 (AA at any size on the parent's navy) instead of 3:1 large-only |
| Motion tokens (`EmMotion`) | `core/design/tokens/em_motion.dart` | none |
| Radius / spacing / shadow tokens | `core/design/tokens/em_{radius,spacing,shadows}.dart` | none |
| Typography (`EmType`, Plus Jakarta Sans) | `core/design/tokens/em_typography.dart` | none |
| **Colour tokens** (`EmColors`) | `core/design/tokens/em_colors.dart` | **new**: mapped onto the parent's own `AppColors` (navy `#0A3158`, amber `#F5A623`), not the teacher's `#18457A` / `#EE9F27` |
| `EmPhotoBackdrop`, `EmPhotoImage`, `EmPhotoOverlayLayer`, `EmAuthPhotos` (precache) | `core/design/widgets/em_photo_backdrop.dart` | photo asset names (`parent_1..3.webp`); `EmPhotoCarouselBackdrop` is **not** copied (the parent app has no onboarding) |
| `EmLogoTile` | `core/design/widgets/em_logo_tile.dart` | none |
| `EmLogomark` + logo SVGs | `core/design/widgets/em_logomark.dart`, `assets/brand/logomark{,_reversed}.svg` | none |
| Logo network painter (link charge, dash drift, pulse, palette morph) + geometry | `core/design/motion/{node_network_painter,logomark_geometry}.dart` | the logo's own colours moved to `EmLogoColors` (the logo palette is not the app navy) |
| Ripple rings painter (`EmRippleRings`) | `core/design/motion/em_ripple_rings.dart` | none |
| Morph button (`EmMorphButton`, `CheckPainter`) | `core/design/widgets/em_morph_button.dart` | dimmed when `onPressed` is null (OTP "Verify" before 6 digits) |
| Entrance / stagger / shake (`EmEntranceHost`, `EmEntrance`, `EmStagger`, `EmShake`) | `core/design/motion/em_entrance.dart` | the logo hand-off wait removed (no splash overlay here) |
| `EmReduceMotion`, `EmAnimatedSize` | `core/design/motion/reduce_motion.dart` | none |
| Contrast helper | `core/design/contrast.dart` | none |
| Plus Jakarta Sans (Regular / Medium / SemiBold / Bold) + OFL licence + licence registration | `assets/fonts/`, `core/design/font_license.dart`, `pubspec.yaml` | none |
| Splash logo PNG for the native splash | `assets/splash/splash_logo.png` | none |
| Photo-auth layout shell (`AuthPageShell`, `AuthPhotoSize`) | `app/modules/auth/widgets/auth_page_shell.dart` | rewritten for the parent (no logo anchor / hand-off, optional eyebrow, no glyph); the field, label, message and password-toggle widgets live in the same file |
| Splash screen | `app/modules/splash/views/splash_screen.dart` | no logo flight (the parent gate has no overlay): it crossfades to login instead (`AnimatedSwitcher` in `main.dart`) |

Not copied: onboarding (the parent app has none), forgot / reset password (the parent app has none: it signs in with a
WhatsApp OTP or an email account), `EmAssembleGlyph`, `EmStrengthNodes`, the logo hand-off (`EmLogoHandoff`).

Fonts: Plus Jakarta Sans is used **only** by these auth screens (via `EmType`); the app theme (Inter through
`google_fonts`) and every other screen are unchanged. `test/design/photo_auth_test.dart` fails if `EmType` or
`PlusJakartaSans` appears outside `lib/core/design`, `lib/app/modules/auth`, `lib/app/modules/splash` and `lib/main.dart`.

Photos: `assets/images/auth/parent_{1,2,3}.webp` (1706 × 3688, ≤ 240 KB; upscaled 2x from 853 px originals with
Real-ESRGAN). Only `parent_1` is used today (splash, login, and the screens pushed from it); `parent_2` / `parent_3` are
kept for an onboarding if the parent app ever gets one.
