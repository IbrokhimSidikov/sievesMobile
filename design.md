# Sieves Mobile — Design System

> Single source of truth for how screens in `sieves_mob` should look and behave in **light** and **dark** mode.
> Every new screen, and every screen that gets touched, follows this document. Where the current code disagrees with it, the code is the thing that changes.

- App: `sieves_mob` (Flutter ≥ 3.8, Material 3 widgets, `flutter_screenutil` sizing, Nunito via `google_fonts`)
- Owners: mobile team
- Status: v1 — written from an audit of the codebase on 2026‑09‑04. Section 9 lists what the audit found and the migration order.

---

## 0. TL;DR (the ten rules)

1. **One brand primary in both modes.** Indigo. Light `#4F46E5`, dark `#6366F1`. Nothing else is "the app color".
2. **Feature accents are allowed, but only in three places**: the header icon tile, the back‑button tint, and the page's primary CTA. Never the whole page chrome.
3. **No `isDark ? … : …` in feature code.** Read semantic tokens from `context.tokens` (a `ThemeExtension`, §3). Feature code never contains a hex value.
4. **Flat surfaces, one shadow level per role.** Gradients are reserved for hero headers and the primary CTA. Cards are flat with a hairline border.
5. **4‑pt spacing grid.** Page gutter 20, card padding 16, gap between cards 12, gap between sections 24.
6. **Radius scale**: 8 (chips, small tiles), 12 (buttons, inputs, icon tiles), 16 (cards), 20 (hero cards, dialogs), 28 (bottom sheets top edge).
7. **Type scale** (Nunito): 28/22/18/16/14/12/11. No 13, 15, 11.5 or 12.5.
8. **Every screen has four states**: loading (shimmer), error (icon + message + retry), empty (icon + title + hint), content. Same layout in both modes.
9. **All user‑facing strings go through `AppLocalizations`.** No `Text('Retry')`.
10. **Touch targets ≥ 44×44, secondary text ≥ 4.5:1 contrast, press feedback on every tappable.**

---

## 1. Design principles

**Calm, dense, trustworthy.** This is an operations app used by restaurant and kitchen staff many times a day, often one‑handed, often in bright kitchens or dim back rooms. It has to be legible at a glance and boringly consistent from screen to screen.

- **Consistency over novelty.** A user who learned the Attendance page should already know how the Break Records page works.
- **Content first, chrome second.** Backgrounds and cards are quiet neutrals. Color is spent on meaning: status, action, feature identity.
- **Same skeleton in both modes.** Dark mode is a palette swap, not a redesign. Layout, spacing, radius, elevation *roles* and type are identical; only token values change.
- **Predictable feedback.** Every tap has a press state. Every network call has loading, error and empty states. Every mutation confirms with a snackbar.

---

## 2. Color

### 2.1 Brand & semantic palette

| Token | Light | Dark | Use |
|---|---|---|---|
| `primary` | `#4F46E5` | `#6366F1` | Primary CTA, links, selected state, focus ring |
| `onPrimary` | `#FFFFFF` | `#FFFFFF` | Text/icon on primary |
| `primaryContainer` | `#EEF2FF` | `#312E81` | Tinted chip / selected row background |
| `success` | `#10B981` | `#34D399` | Online, approved, completed |
| `warning` | `#F59E0B` | `#FBBF24` | Pending, cached data, caution |
| `error` | `#DC2626` | `#EF4444` | Destructive, failed, required |
| `info` | `#2563EB` | `#60A5FA` | Informational chips, hints |

Contrast on the mode's card surface: all of the above pass **AA for icons and bold ≥ 14 pt**. For *normal‑weight body text* on the primary color, use `onPrimary`, never colored body text.

### 2.2 Neutrals

| Token | Light | Dark | Use |
|---|---|---|---|
| `background` | `#F5F5F7` | `#0F0F14` | Scaffold |
| `surface` | `#FFFFFF` | `#1A1A24` | Cards, sheets, dialogs, app bar |
| `surfaceElevated` | `#FFFFFF` | `#252532` | Nested card inside a card, menus, snackbar |
| `surfaceTint` | `#F3F4F6` | `#20202B` | Input fill, inactive chip, skeleton base |
| `outline` | `#E5E7EB` | `#2E2E3D` | Hairline borders, dividers |
| `outlineStrong` | `#D1D5DB` | `#374151` | Input border, focused card border |
| `textPrimary` | `#0F172A` | `#E8E8F0` | Titles, values |
| `textSecondary` | `#6B7280` | `#9CA3AF` | Labels, subtitles, metadata |
| `textTertiary` | `#9CA3AF` | `#6B7280` | Placeholders, disabled — **never for content** |
| `textOnAccent` | `#FFFFFF` | `#FFFFFF` | Text on primary / accent / gradient headers |
| `scrim` | `rgba(0,0,0,.45)` | `rgba(0,0,0,.65)` | Dialog / sheet barrier |
| `shadow` | `rgba(15,23,42,.06)` | `rgba(0,0,0,.35)` | Card shadow color (see §5) |

Contrast checks that drove these values:

| Pair | Ratio | Verdict |
|---|---|---|
| `#6B7280` on `#FFFFFF` | 4.8 : 1 | AA body text ✔ |
| `#A1A1A6` (current `cxSilverTint`) on `#FFFFFF` | 2.6 : 1 | ✘ — do not use for text |
| `#9CA3AF` on `#1A1A24` | 6.9 : 1 | AA ✔ |
| `#6B7280` on `#1A1A24` | 3.7 : 1 | placeholders only |
| `#6366F1` on `#FFFFFF` | 4.5 : 1 | borderline → light mode uses `#4F46E5` (6.3 : 1) |

### 2.3 Feature accents

Each module owns one accent. It appears in the module's Home tile, its header icon tile, its back‑button tint and its primary CTA. It does **not** tint the page background, all card borders, or body text.

| Module | Accent (light / dark) |
|---|---|
| Profile, HR, Feedback | primary indigo |
| Attendance, Face verification | teal `#0D9488` / `#2DD4BF` |
| Break records, Break order | orange `#EA580C` / `#FB923C` |
| History, Calendar | blue `#2563EB` / `#60A5FA` |
| Learning (LMS, exams, trainings) | violet `#7C3AED` / `#A78BFA` |
| Wallet, Salary | green `#059669` / `#34D399` |
| Qualification matrix | purple `#9333EA` / `#C084FC` |
| Tasks, Productivity, Checklist | slate `#475569` / `#94A3B8` |
| Order cancel | red `#DC2626` / `#F87171` |

Tinted backgrounds derived from an accent use fixed alphas: **12 %** for a tile/chip fill, **20 %** for its border, **30 %** for its glow shadow. Same alphas in both modes.

### 2.4 Gradients (restricted)

Allowed only for:
- The **hero header** of a page (accent → accent at 80 %), and
- The **primary CTA** when the page uses a hero header.

Not allowed on cards, chips, back buttons, list rows, toggles or backgrounds. The page background is the flat `background` token — the current white → `#F5F7F9` page gradient goes away.

---

## 3. Tokens in code

Feature code reads tokens from a `ThemeExtension`. This is what makes "same pattern in both modes" enforceable: a screen that never branches on brightness cannot drift.

```dart
// lib/core/theme/app_tokens.dart
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.primary, required this.primaryContainer,
    required this.success, required this.warning, required this.error, required this.info,
    required this.background, required this.surface, required this.surfaceElevated,
    required this.surfaceTint, required this.outline, required this.outlineStrong,
    required this.textPrimary, required this.textSecondary, required this.textTertiary,
    required this.shadow,
  });

  final Color primary, primaryContainer, success, warning, error, info;
  final Color background, surface, surfaceElevated, surfaceTint, outline, outlineStrong;
  final Color textPrimary, textSecondary, textTertiary, shadow;

  static const light = AppTokens(
    primary: Color(0xFF4F46E5), primaryContainer: Color(0xFFEEF2FF),
    success: Color(0xFF10B981), warning: Color(0xFFF59E0B),
    error: Color(0xFFDC2626), info: Color(0xFF2563EB),
    background: Color(0xFFF5F5F7), surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFFFFFFF), surfaceTint: Color(0xFFF3F4F6),
    outline: Color(0xFFE5E7EB), outlineStrong: Color(0xFFD1D5DB),
    textPrimary: Color(0xFF0F172A), textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF), shadow: Color(0x0F0F172A),
  );

  static const dark = AppTokens(
    primary: Color(0xFF6366F1), primaryContainer: Color(0xFF312E81),
    success: Color(0xFF34D399), warning: Color(0xFFFBBF24),
    error: Color(0xFFEF4444), info: Color(0xFF60A5FA),
    background: Color(0xFF0F0F14), surface: Color(0xFF1A1A24),
    surfaceElevated: Color(0xFF252532), surfaceTint: Color(0xFF20202B),
    outline: Color(0xFF2E2E3D), outlineStrong: Color(0xFF374151),
    textPrimary: Color(0xFFE8E8F0), textSecondary: Color(0xFF9CA3AF),
    textTertiary: Color(0xFF6B7280), shadow: Color(0x59000000),
  );

  @override
  AppTokens copyWith({/* … */}) => this; // generate or write out
  @override
  AppTokens lerp(AppTokens? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension AppTokensX on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
```

Register in both themes: `ThemeData(..., extensions: const [AppTokens.light])` / `[AppTokens.dark]`.

Feature accents live in one map, `AppAccents.forModule(ModuleId)`, returning a light/dark pair. Pages ask for their accent once at the top of `build`.

**Rules**
- `AppColors.cx…` hex‑named constants are legacy. Do not add to them. Replace on touch.
- `Colors.white`, `Colors.black`, `Colors.grey.shadeN`, `Colors.red` etc. are banned in feature code. Use tokens. (`Colors.transparent` is fine.)
- `theme.colorScheme.*` remains valid for Material widgets that read it (inputs, switches, progress). Keep `ColorScheme` and `AppTokens` in sync — they are two views of one palette.

---

## 4. Typography

Family: **Nunito** (already loaded via `google_fonts`). Sizes are `.sp`. Line height 1.25 for titles, 1.4 for body.

| Role | Size | Weight | Letter‑spacing | Color token | Used for |
|---|---|---|---|---|---|
| `display` | 28 | 700 | ‑0.5 | textPrimary | Page title on Home / Profile |
| `headline` | 22 | 700 | ‑0.3 | textPrimary | Page title in header row |
| `title` | 18 | 700 | 0 | textPrimary | Card title, dialog title, big number label |
| `subtitle` | 16 | 600 | 0 | textPrimary | Row title, section heading, button label |
| `body` | 14 | 500 | 0 | textPrimary / textSecondary | Default text, row value |
| `caption` | 12 | 500 | 0 | textSecondary | Metadata, timestamps, chip label |
| `overline` | 11 | 700 | +0.6, uppercase | textSecondary | Status pills (ONLINE), column headers |
| `numeral` | 22–32 | 800 | ‑0.5 | textPrimary / accent | Hours, money, scores. Use `FontFeature.tabularFigures()` |

Rules
- Buttons use `subtitle` (16 / 600). Small buttons use `body` (14 / 600).
- Header **title** is `headline` 22; the current spread of 20 / 22 / 26 / 28 collapses to 22 (inner pages) and 28 (Home, Profile).
- Never color body text with an accent for emphasis. Emphasize with weight (600 → 700) or a chip.
- Max two weights per component.
- Respect the OS text scale up to 1.3× (`MediaQuery.textScaler` clamp in `MaterialApp.builder`). Lay out so 1.3× does not overflow: `Expanded` + `maxLines` + `ellipsis` on every title.

Map the roles onto `TextTheme` so `Theme.of(context).textTheme.titleMedium` etc. work, and fix the wiring bug in `main.dart` (§9.1) so the theme's text colors actually reach widgets.

---

## 5. Spacing, radius, elevation

### 5.1 Spacing (4‑pt grid, `.w` / `.h`)

| Token | Value | Use |
|---|---|---|
| `xs` | 4 | icon ↔ label inside a chip |
| `sm` | 8 | between icon and text, between chips |
| `md` | 12 | gap between cards in a grid / list |
| `lg` | 16 | card inner padding, list row padding |
| `xl` | 20 | page horizontal gutter |
| `xxl` | 24 | between page sections |
| `xxxl` | 32 | empty‑state padding, top of a centered state |

Page body: `EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomSafeArea)`.

### 5.2 Radius (`.r`)

| Token | Value | Use |
|---|---|---|
| `r8` | 8 | chip, small tile, skeleton line, tab pill |
| `r12` | 12 | button, input, icon tile, back button |
| `r16` | 16 | card, snackbar, list group |
| `r20` | 20 | hero card, dialog, bento tile |
| `r28` | 28 | bottom sheet top corners |
| `full` | 999 | status pill, avatar, toggle |

### 5.3 Elevation

Three levels. Shadow color is the `shadow` token, so light casts a faint slate shadow and dark casts a deeper black one, with **identical geometry**.

| Level | Blur / y‑offset | Border | Use |
|---|---|---|---|
| `flat` | none | 1 px `outline` | Default card, list group, input |
| `raised` | 12 / 4 | 1 px `outline` | Card that is tappable, header icon tile, bottom sheet |
| `floating` | 24 / 8 | none | Dialog, FAB, sticky CTA bar |

Accent glow (30 % accent, blur 12, y 6) is allowed **only** on the primary CTA and on a *selected* option.

---

## 6. Iconography & imagery

- Material Icons only, **`_rounded` variants** (`Icons.calendar_today_rounded`, not `_outlined` / `_sharp`). Remove the unused `iconsax` dependency.
- Sizes: 16 inside chips, 20 in buttons and rows, 24 in headers and app bars, 28 in header icon tiles, 56–64 in empty / error states.
- Icon tiles (the colored square behind a header icon): 44×44, `r12`, fill accent 12 %, border accent 20 %, icon 24 in accent.
- Avatars: circle, 2 px ring in accent 25 %, fallback = `person_rounded` on accent 12 %.
- Illustrations / photos: `r16`, always with a `surfaceTint` placeholder and an `errorBuilder`.
- The Instagram‑style story ring on Home is a deliberate exception and keeps its multi‑stop gradient.

---

## 7. Components

Each component has one canonical widget in `lib/core/widgets/`. Pages compose these; they do not re‑implement them. Where the widget does not exist yet, this section is its spec.

### 7.1 Page scaffold — `AppPage`

```
Scaffold(background)
└─ SafeArea
   └─ Column
      ├─ AppHeader(...)             // §7.2
      └─ Expanded(body)             // one of: content | loading | error | empty
```

- Background is the flat `background` token. No page gradient.
- Scroll physics: `BouncingScrollPhysics` on iOS defaults; use `RefreshIndicator` on every list page.
- Bottom CTA, when present, is a sticky bar: `surface`, top hairline `outline`, padding 16/20, `floating` shadow, respects the home indicator.

### 7.2 Header — `AppHeader`

Two variants. Pick one per page; never both.

**Standard** (default for inner pages)
```
[◀ back tile]  Title (headline 22)                       [action tile] [action tile]
```
- Height 56. Back tile 44×44, `surface`, `r12`, `raised`, arrow `arrow_back_ios_new_rounded` 20 in **page accent**.
- Action tiles share the back tile style. Max two. Icon 22 in accent.
- Below it, optional subtitle row: `caption` in textSecondary.

**Hero** (for pages with a strong identity: Qualification matrix, Salary, Wallet, test results)
```
┌──────────────────────────────────────────────────┐
│ ◀   [icon tile]  Title (headline, onAccent)   (i) │  ← accent gradient, r20 bottom corners
│                  subtitle (caption 90 %)          │
└──────────────────────────────────────────────────┘
```
- Gradient accent → accent 80 %, `floating` shadow in accent 30 %.
- All text and icons `textOnAccent`. Icon tile = white 18 % fill, white 28 % border.
- Same gradient in dark mode; do **not** dim the accent in dark (current code multiplies by 0.6–0.8, which makes dark headers look muddy).

Back navigation: `context.pop()` if the page can pop, otherwise `context.go('/home')`. Never hard‑code `/home` on a pushed page.

### 7.3 Cards — `AppCard`

- `surface`, `r16`, 1 px `outline`, `flat`. Padding 16. Add `raised` and an `InkWell` ripple when the whole card is tappable.
- Card title row: `title` 18 / 700 left, optional trailing chip or icon button right. 12 below the title.
- Key‑value rows inside a card: label `body` textSecondary left, value `body` 600 textPrimary right, 10 between rows, hairline `outline` divider between groups only.
- Stat cards (hours, bonus, balance): `numeral` value, `caption` label, 44 icon tile in accent at top‑left. Two per row, gap 12.
- Do not nest a shadowed card inside a shadowed card. Inner blocks use `surfaceTint` fill with `r12` and no shadow.

### 7.4 Home bento tiles — `BentoTile`

Keep the layout (2/3 + 1/3 stacks). Restyle so Home matches the rest of the app:
- Fill `surface`, border `outline`, `r20`, `raised`.
- Icon tile in the **module accent** (12 % fill, 20 % border).
- Title `subtitle` 16 / 700 textPrimary; subtitle `caption` textSecondary.
- Press: scale 0.96 over 120 ms, `easeOut`. Keep.
- Drop the taupe/brown per‑tile colors and the gold border in dark; those belong to no other screen.

### 7.5 Buttons

| Kind | Style | Height | Use |
|---|---|---|---|
| Primary | fill `primary` (or page accent on hero pages), `onPrimary` text, `r12`, `subtitle` 16/600, glow allowed | 52 | One per screen. Submit, Save, Confirm |
| Secondary | `surfaceTint` fill, 1 px `outlineStrong`, textPrimary | 52 | Cancel, Later, Back |
| Tertiary | text only in `primary`, 14/600 | 44 | Inline actions, "View all" |
| Destructive | fill `error`, white text | 52 | Logout, Delete — always behind a confirm dialog |
| Icon button | 44×44 tile, see header tiles | 44 | Header actions, row actions |

Rules
- Use `FilledButton`, `OutlinedButton`, `TextButton` with the theme, or the `AppButton` wrapper. `GestureDetector` is only for custom pressables that need scale feedback; wrap those in `Semantics(button: true)`.
- Loading state: keep the button size, swap the label for a 20 px `CircularProgressIndicator` in the label color, disable taps.
- Disabled: 40 % opacity on the whole button, never a different color.
- Full‑width on forms; intrinsic width in rows and dialogs.

### 7.6 Chips, pills, badges

- **Chip** (role, position, filter): `r8`, 12 % accent fill, accent text `caption` 600, optional 14 icon. Height 28. Selected filter = `primary` fill with `onPrimary` text.
- **Status pill** (ONLINE / OFFLINE, task state): `full` radius, solid semantic color, `overline` white text, 6 px dot on the left. Height 24.
- **Count badge** (unread): `error` fill, white `overline`, 1.5 px `background` ring, min 18×18, `99+` cap.
- **Cache indicator**: `warning` 16 icon `offline_bolt_rounded` in the header, with a tooltip. Never a whole banner.

### 7.7 Inputs

- Filled, `surfaceTint` fill, 1 px `outlineStrong`, `r12`, height 52, padding 16/14.
- Focus: 2 px `primary` border. Error: 1 px `error` border + `caption` error text below. Same in both modes.
- Label above the field (`caption` 600 textSecondary, 6 above), placeholder in textTertiary.
- Dropdown / pickers open a **bottom sheet** (§7.8), not a Material menu, when there are more than 5 options or the list is searchable (e.g., employee picker).

### 7.8 Bottom sheets — `AppSheet`

- `surface`, top corners `r28`, `raised` shadow upward, max height 85 %.
- Grab handle 36×4, `outlineStrong`, 12 from the top, 16 above content.
- Header row: title `title` 18 left, optional close tile right. Search field directly under the header when the sheet is a picker.
- Content padding 20 horizontal; bottom padding = 20 + safe area.
- Barrier = `scrim` token. `isScrollControlled: true` always.

### 7.9 Dialogs — `AppDialog`

- `surface`, `r20`, `floating`, max width 400, padding 24.
- Optional 56 icon tile centered at the top (semantic color for confirm / destructive).
- Title `title` 18 / 700 centered; body `body` textSecondary centered, line height 1.5.
- Actions: two buttons in a row, secondary left, primary/destructive right, gap 12, full width each.
- Blur behind (`BackdropFilter` σ 10) is reserved for the force‑update dialog.

### 7.10 Snackbars

Only through `SnackbarHelper` (already exists). Floating, `r12`, margin 16/12, icon 22 + message `body` 500 in white, solid semantic fill (`success`, `error`, `warning`, `info`). Duration 3 s, 5 s when an action is attached. Replace the raw `SnackBar(backgroundColor: Colors.red)` calls in `main.dart` and `onboard.dart`.

### 7.11 Lists & rows

- Row height ≥ 56, padding 16 horizontal / 12 vertical, leading 40 icon tile or avatar, title `subtitle`, subtitle `caption`, trailing value or chevron 20 textTertiary.
- Groups sit in a card (`r16`), rows separated by hairline `outline` inset 16 from the left, no divider after the last row.
- Timeline lists (History): 2 px line in `outline`, 12 dot in the event's semantic color, card per event.
- Tables (Attendance): header row `overline` textSecondary on `surfaceTint`, zebra rows off, right‑align numerals, `tabularFigures`.

### 7.12 Tabs & segmented control

- Pill tabs in a `surfaceTint` track, `r8`, height 40; selected pill = `surface` with `raised` shadow in light and `surfaceElevated` in dark, text `body` 600.
- Count badge inside the tab uses the chip style, not the notification badge.

### 7.13 Loading, error, empty — `AppStateView`

All three render inside the page body at the same position in both modes.

| State | Layout |
|---|---|
| Loading | `Shimmer` over the *real* layout's silhouette (cards, rows). Base `surfaceTint`, highlight `surface` (light) / `surfaceElevated` (dark). Period 1.5 s. Never a bare centered spinner on a list page. |
| Error | 64 `error_outline_rounded` in `error`, title `title` (localized "Couldn't load …"), message `body` textSecondary, primary button "Retry". |
| Empty | 64 icon in textTertiary, title `title`, hint `body` textSecondary, optional tertiary action. Pull‑to‑refresh still works (wrap in an always‑scrollable `ListView`). |

### 7.14 Toggles & switches

- Theme and language switchers in the Home app bar become plain 44×44 icon tiles (`dark_mode_rounded`, a flag/`language_rounded`) that open a small sheet. The gradient pill toggle is retired; Material `Switch` (themed) is used inside settings cards.

### 7.15 Charts (fl_chart)

- Series colors come from semantic / accent tokens, never raw hex. Grid lines `outline`, labels `caption` textSecondary, tooltip = `surfaceElevated` with `r8`.
- Pie / donut: 4–6 slices max, legend below as chips.

---

## 8. Motion, feedback & accessibility

| Aspect | Rule |
|---|---|
| Durations | micro (press, toggle) 120 ms · standard (fade, expand) 200 ms · page/sheet 300 ms · ambient pulse 1500 ms |
| Curves | `easeOut` for enter, `easeIn` for exit, `easeInOut` for loops |
| Press feedback | `InkWell` ripple on rows and cards; scale 0.96 on tiles and custom buttons |
| Haptics | `HapticFeedback.lightImpact()` on primary CTA success, `selectionClick()` on segmented tabs and rating stars, `mediumImpact()` on destructive confirm |
| Page transitions | `go_router` default (platform) for pushes; fade 300 ms only for onboard → home |
| Touch targets | ≥ 44×44. Use `IconButton.constraints` or a `SizedBox` around custom tiles |
| Contrast | body text ≥ 4.5 : 1, large / bold ≥ 3 : 1, icons ≥ 3 : 1 — verified in §2 |
| Text scale | support up to 1.3×; test the Profile and Attendance pages at 1.3× |
| Semantics | every icon‑only button has `tooltip`; custom `GestureDetector` pressables get `Semantics(button: true, label: …)`; images that carry meaning get `semanticLabel` |
| Reduced motion | respect `MediaQuery.disableAnimations` for the pulse and bounce loaders |

---

## 9. Audit — where the code is today, and the migration order

Numbers from a scan of `lib/` on 2026‑09‑04 (153 Dart files, ~58 k lines).

### 9.1 Defects to fix first

1. **Dark text colors never reach the widget tree.** `main.dart` builds the dark theme as `AppTheme.darkTheme.copyWith(textTheme: GoogleFonts.nunitoTextTheme(Theme.of(context).textTheme))`. `Theme.of(context)` at that point is the ambient *light* fallback theme, so the carefully defined dark `TextTheme` colors are overwritten with light ones. Any widget reading `textTheme.bodyLarge?.color` (e.g., the language switcher title) paints dark text on a dark surface. Fix: `GoogleFonts.nunitoTextTheme(AppTheme.darkTheme.textTheme)` and the same for light.
2. **Light theme is a stub.** It defines three text styles and no card, input, button, chip, dialog, sheet or snackbar theme, while the dark theme defines all of them. Every light‑mode screen therefore relies on inline colors. Build the light theme to the same depth from the tokens in §2.
3. **Secondary text fails contrast in light mode.** `cxSilverTint #A1A1A6` is used ~130 times, largely for subtitles on white (2.6 : 1). Replace with `textSecondary #6B7280`.
4. **Two competing primaries.** Light `primary` = Royal Blue `#0071E3`; dark `primary` = Indigo `#6366F1` (194 direct uses); plus teal `#43C19F` on Attendance / Profile / language switcher and `cxPrimary #4A90E2` defined but unused. Pick indigo (§2.1).
5. **Hard‑coded English / Uzbek strings**: `'Retry'`, `'Submit'`, `'Kamera'`, `'Galereya'`, `'Open Shift'`, `'No questions available'`, and more. Route through `AppLocalizations`.

### 9.2 Drift to converge

| Area | Today | Target |
|---|---|---|
| Brightness branching | 121 local `isDark` declarations, ~1 000 inline hex literals in features | 0 in features; tokens via `context.tokens` |
| Dark surfaces | `#1A1A24`, `#1A1A2E`, `#1F1F2E`, `#1E1E2A`, `#12121A`, `#1E1E1E`, `#2F2F2F` all used as "dark card" | `surface #1A1A24`, `surfaceElevated #252532` only |
| Page background | 37 files paint a white → `#F5F7F9` gradient in light and scaffold → surface in dark | flat `background` |
| Gradients | 216 `LinearGradient` uses on cards, chips, toggles, back buttons | hero header + primary CTA only |
| Header pattern | 3 variants: transparent `AppBar`, custom back‑tile row, gradient hero; back‑arrow tint differs per page (teal, indigo, blue, orange, green, white, onSurface) | `AppHeader` standard / hero, tint = page accent |
| Font sizes | 14 · 12 · 13 · 16 · 18 · 15 · 11 · 20 · 10 · 22 · 17 · 24 · 11.5 · 12.5 | 28 · 22 · 18 · 16 · 14 · 12 · 11 |
| Radius | 12 · 16 · 20 · 8 · 10 · 14 · 6 · 4 · 24 · 18 · 22 | 8 · 12 · 16 · 20 · 28 · full |
| Shadows | blur 8–30, opacity `isDark ? 0.3 : 0.05` re‑typed per card | 3 elevation levels with the `shadow` token |
| Pressables | 98 `GestureDetector`, 62 `InkWell`, 34 `ElevatedButton`, 21 `TextButton`, 8 `OutlinedButton`, 5 `FilledButton` | themed buttons + `AppButton`; `GestureDetector` only with scale + `Semantics` |
| Icons | Material only, mixed `_outlined` / `_rounded` / `_sharp`; `iconsax` imported but unused | `_rounded` only; drop `iconsax` |
| Grey shortcuts | `Colors.grey.shade50…800` (33 uses) render the same in both modes | tokens |
| Feedback | `SnackbarHelper` exists but 2 raw red `SnackBar`s remain; 0 haptics; 0 `Semantics`; 0 text‑scale handling | §7.10, §8 |
| Home tiles | taupe/brown per‑tile fills in light, gold `#FFCB74` border in dark — a palette used nowhere else | §7.4 |

### 9.3 Migration order

Do it in this order so every later step gets cheaper.

1. **Foundations** (`lib/core/theme/`): add `AppTokens`, rebuild `AppTheme.light` and `AppTheme.dark` to equal depth from the tokens, fix the `main.dart` text‑theme wiring, add the `textScaler` clamp. Nothing visible changes yet except the dark text bug.
2. **Core widgets** (`lib/core/widgets/`): `AppPage`, `AppHeader` (standard + hero), `AppCard`, `AppButton`, `AppChip`, `AppStatusPill`, `AppSheet`, `AppDialog`, `AppStateView` (loading / error / empty), `AppIconTile`. Each ≤ 150 lines, no `isDark` inside — they read tokens.
3. **Home + Profile** — the two screens everyone sees. Migrate tiles, header, stat cards, language / theme controls. This sets the visual baseline.
4. **Inner pages by traffic**: Attendance → Break records → History → LMS → Tasks → Checklist → Wallet / Salary → Qualification matrix → Face verification → Break order → Order cancel → the rest.
5. **Cleanup**: delete unused `AppColors.cx…` entries, remove `iconsax`, delete the commented‑out `dashboard_card.dart`, grep‑gate the repo (`Color(0x` and `isDark ?` are not allowed under `lib/features/`).

Each page migration is one PR with before/after screenshots in **both** modes at 1.0× and 1.3× text scale.

### 9.4 Definition of done for a screen

- [ ] Uses `AppPage` + `AppHeader`; no custom scaffold chrome
- [ ] No hex literal, no `Colors.*` (except `transparent`), no `isDark` in the file
- [ ] Only sizes from the type, spacing and radius scales
- [ ] Loading, error, empty and content states all present and localized
- [ ] Primary CTA: one, 52 high, loading + disabled states
- [ ] All strings via `AppLocalizations` (en / uz / ru)
- [ ] Icon‑only buttons have tooltips; custom pressables have `Semantics`
- [ ] Screenshots: light + dark, 1.0× + 1.3×, iPhone 13 (393×852 design size) and a small Android

---

## 10. Quick reference card

```
PRIMARY        light #4F46E5   dark #6366F1
SUCCESS        #10B981 / #34D399     WARNING #F59E0B / #FBBF24
ERROR          #DC2626 / #EF4444     INFO    #2563EB / #60A5FA
BACKGROUND     #F5F5F7 / #0F0F14     SURFACE #FFFFFF / #1A1A24
ELEVATED       #FFFFFF / #252532     TINT    #F3F4F6 / #20202B
OUTLINE        #E5E7EB / #2E2E3D     STRONG  #D1D5DB / #374151
TEXT 1/2/3     #0F172A #6B7280 #9CA3AF  /  #E8E8F0 #9CA3AF #6B7280

TYPE  28/700  22/700  18/700  16/600  14/500  12/500  11/700 caps
SPACE 4 8 12 16 20 24 32        gutter 20 · card pad 16 · gap 12 · section 24
RADIUS 8 12 16 20 28 full       ELEV flat · raised(12/4) · floating(24/8)
MOTION 120 · 200 · 300 · 1500 ms
```
