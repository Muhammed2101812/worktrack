# WorkLog UI Design System & Full Refactor

**Date:** 2026-07-14
**Status:** Approved (design phase)
**Goal:** Eliminate the 17 cross-cutting UI inconsistencies and establish a single design-token source of truth + component library, while giving the app a distinctive identity that avoids the generic "AI-template" look.

---

## 1. Motivation

A full audit (see Section 8) found the UI is internally inconsistent:

- **Card radii** appear in 4 different values (16 / 20 / 24 / 14); chips/badges in 5+ (6 / 8 / 10 / 12 / 20).
- **3 button systems** are active simultaneously (`MidnightButton` r16, `ElevatedButton` r12, `OutlinedButton` r12, FAB) for the same actions.
- **Screen titles** use 4 font sizes (22 / 24 / 26 / 32), all hand-rolled `TextStyle`.
- **The "Kalan Alacak" hero number** is rendered 3 ways (32 / 40 / different letterSpacing).
- **Client avatars** appear in 6 size/shape/border combinations.
- **Section labels** use 5 distinct styles (10–14 px, varying letterSpacing).
- **`_parseColor`** is duplicated 7 times; the **segmented control** is copy-pasted twice.
- **Nested-radius violations**: in-card buttons/chips do not account for their parent's radius and padding.
- **Dead code**: `neumorphic_widgets.dart` is unused but still shipped, dragging `flutter_inset_shadow`.
- Half-finished theme migration: most code uses the deprecated `AppColors.of(context)` shim instead of `Theme.of(context).extension<AppPalette>()!`.

The user also wants the app to **stand apart from the flood of generic AI-generated UIs** (Inter font + emerald/slate + identical card grids). The redesign therefore introduces a distinctive but clean identity.

---

## 2. Design Decisions (locked from brainstorming)

| Decision | Choice | Rationale |
|---|---|---|
| Approach depth | **Design system + full refactor** | Fixes root causes; prevents regression |
| Visual direction | **Refine aesthetics** (same palette family, better hierarchy) | Evolve, don't break |
| Surface separation | **Thin 1px border + consistent shadow** | Closest to current look; one recipe |
| Radius feel | **Soft** (8 / 12 / 16 / 20 / 24) | Matches existing; nested-radius rule applied |
| Identity | **Distinctive, not AI-generic** | Tabular ledger figures, warm neutrals, signature ledger line |

---

## 3. Design Identity — "The Ledger"

WorkLog is a time-and-money tracking app. **Numbers are the hero.** The identity is built around that fact, with three deliberate moves that set it apart from template UIs:

### 3.1 Typographic hero — Space Grotesk + tabular figures
- **Space Grotesk** (via existing `google_fonts` dep) replaces the implicit default. Geometric, characterful, clean-but-not-generic.
- **Tabular figures** (`fontFeatures: [FontFeature.tabularFigures()]`) on ALL monetary/hour figures. Digits align in columns → a "ledger/account-book" feel. This is rare in template apps and perfectly fits a finance/time app.

### 3.2 Warm neutral surfaces (not cold slate/gray)
Replace the generic Tailwind gray-50 / slate palette with warm neutrals:
- Light: warm off-white background, warm-tinted whites for cards. Emerald accent **kept** (brand color).
- Dark: warm-tinted dark instead of cold pure slate.

These are `AppPalette` updates — accessed via `Theme.of(context).extension<AppPalette>()!`.

### 3.3 Signature motif — the ledger line
A thin accent stripe/alignment line on the left edge of summary cards and list items. Repeating visual signature: "this is WorkLog," not a template. Implemented as an optional property on `AppCard`.

---

## 4. Token System — `lib/core/dimens.dart`

Single source of truth. No screen hardcodes `borderRadius: 14` anymore; every value derives from this scale.

### 4.1 Radius scale + nested-radius helper
```
Radii.xs   = 8    // badge, status pill, small icon chip, tab-active
Radii.sm   = 12   // input, small button, square avatar, segmented control active
Radii.md   = 16   // card, primary button, avatar container
Radii.lg   = 20   // pill button, filter chip, hero card
Radii.xl   = 24   // dialog, bottom sheet, navbar bar
Radii.full = 999  // FAB, navbar +
```

**Nested-radius rule (enforced via helper):** a child's radius = `outerRadius − padding`, clamped to the nearest scale value that stays sensible.
```dart
double innerRadius(double outerRadius, double padding) {
  return max(outerRadius - padding, 0).clampToScale();
}
```
Example: card(r16) with padding(12) → inner button/input = r4 → snaps up to **xs(8)** per scale. card(r16) + padding(4) → inner = r12.

### 4.2 Spacing scale
```
4 → 8 → 12 → 16 → 20 → 24 → 32
```
Every EdgeInsets/margin/SizedBox gap comes from this scale. Ad-hoc values (35, 10, 6) are removed.

### 4.3 Typography scale (`AppTexts`)
Synchronized with theme `textTheme`. ONE style per role:

| Token | Size | Weight | LetterSpacing | Used for |
|---|---|---|---|---|
| `screenTitle` | 24 | bold | −0.5 | All screen titles (fixes Finance 22) |
| `sectionTitle` | 16 | bold | 0 | Section headers ("Son Kayıtlar") |
| `eyebrow` | 12 | bold | 1.2 | ALL-CAPS labels (merges 10/11/12/13/14 styles) |
| `body` | 15 | w500 | 0 | Body text, input text |
| `caption` | 13 | normal | 0 | Subtitles, muted text |
| `figureLg` | 36 | w900 | −1.5 | Hero numbers, **tabular** (merges 32/40) |
| `figureMd` | 20 | bold | 0 | Sub-metric numbers, **tabular** |

### 4.4 Shadow system (`AppShadows`)
Single recipe family; no per-screen shadow re-invention.
```
card:     alpha 0.04, blur 12, offset (0, 4)
elevated: alpha 0.06, blur 16, offset (0, 6)
dialog:   alpha 0.08, blur 24, offset (0, 8)
```

---

## 5. Component Library — `lib/core/widgets/`

Replaces the ad-hoc, duplicated widgets with one consistent set.

| Component | Replaces | Key rules |
|---|---|---|
| **AppCard** | `MidnightCard` + raw Containers in `TodaySummaryCard`, `EntryListTile` | One border(1px)+shadow; `variant: flat/elevated/hero`; optional `ledgerLine` accent stripe; radius from scale |
| **AppButton** | `MidnightButton` + `ElevatedButton` + `OutlinedButton` | `variant: solid/ghost/danger/outline`; ghost/danger draw **no** colored shadow (kills the alpha-0.1 abuse); radius from scale |
| **AppInput** | `MidnightInput` | Radius from scale (sm=12); single shadow recipe |
| **AppAvatar** | 6 avatar implementations | `size: sm(32)/md(44)/lg(64)`; single shape = **circle** for people/clients; single border rule (no border by default, optional `bordered`); tabular initial; `dot` variant (10px color swatch) for compact lists like finance |
| **ScreenHeader** | 5 hand-rolled title/back-button combos | Unified back-arrow + `screenTitle` typography; Settings/Stats gain a back button |
| **SectionHeader** | 5 label styles | `eyebrow` (12/1.2) + optional "Tümünü Gör" link |
| **SegmentedControl** | duplicated code in finance + stats | Reusable widget |
| **EmptyState** | duplicated in history + stats | Unified icon container + title + CTA |
| **AppSheet** | 6 different bottom-sheet decorations | One wrapper: radius xl=24 + border + drag handle |
| **AppDialog** | ~10 dialogs + 1 outlier | One wrapper: radius xl=24 + border + `navBg` |
| **LedgerLine** | (new signature motif) | Left-edge accent stripe |

### Utils migration
- `_parseColor` → `lib/core/utils.dart` (1 implementation, robustly handles 6/8-digit hex + `#`).
- Client color helpers consolidated there.

### Deletions
- `lib/core/widgets/neumorphic_widgets.dart` — dead code (verified zero imports in `lib/`).
- `flutter_inset_shadow` dependency (only the dead file used it).

### Theme migration completion
Finish the half-done migration: widgets read colors via `Theme.of(context).extension<AppPalette>()!` rather than the deprecated `AppColors.of(context)` shim.

---

## 6. Screen-by-Screen Plan

All screens migrate to the system. Critical fixes per screen:

| Screen | Key fixes |
|---|---|
| **Home** | `TodaySummaryCard`/`EntryListTile` raw Containers → AppCard; sidebar button → AppButton; hero figures → tabular `figureLg`; title 26→uses greeting (kept, it's a greeting not a title) |
| **Overview** | "Kalan Alacak" figure 40→`figureLg`(36) tabular; label → `eyebrow`; spinner → `color: primary` |
| **Finance** | Title 22→24 (`screenTitle`); "Ödeme Ekle" radius→scale + nested rule; `Colors.white`→`onPrimary`; segment control → shared `SegmentedControl` |
| **History** | Avatar 48-circle-border → `AppAvatar`; entry card radius→scale; detail "Sil" button → AppButton danger (no tinted shadow); delete dialog → AppDialog |
| **AddEntry** | Close icon `x()`→ consistent; labels → `eyebrow`; project dialog icon radius 14→scale; cancel button tinted-shadow abuse→AppButton ghost; save button full-width |
| **Login** | Padding 32→24; Google OutlinedButton → AppButton outline; both buttons equal height + matching radius |
| **Settings** | Title/card inset alignment (24 vs 16 → unify to 16); "ŞİMDİ YÜKSELTT" typo→"YÜKSELT"; 5 radii→scale; paywall dialog MidnightButton→AppButton in AppDialog; theme migration |
| **Stats** | Title via `screenTitle`; segment control → shared; pie-center 48/28 → single tabular size; fallback color `#9CA3AF`→constant; daily-chart asymmetric padding→scale |

---

## 7. Implementation Order (build sequence)

Phase boundaries are natural verification checkpoints.

1. **Foundation** — `dimens.dart` (tokens), `AppPalette` warm-neutral update, Space Grotesk in theme, utils `_parseColor`, delete neumorphic + dep.
2. **Component library** — AppCard, AppButton, AppInput, AppAvatar, ScreenHeader, SectionHeader, SegmentedControl, EmptyState, AppSheet, AppDialog, LedgerLine. Keep old widgets temporarily for incremental migration.
3. **Migrate screens** (one per build step, compile after each):
   Login → Home (widgets first) → Overview → Finance → History → AddEntry → Stats → Settings.
4. **Cleanup** — remove `MidnightCard`/`MidnightButton`/`MidnightInput` aliases once nothing references them; remove `AppColors`/`MidnightColors` deprecated shims once migrated.
5. **Verify** — `flutter analyze` clean; visual check on emulator.

---

## 8. Audit Reference (source findings)

Concrete file:line evidence backing each change (from the codebase audit):

- **Card radius chaos**: MidnightCard r16 (`midnight_widgets.dart:18`), TodaySummaryCard r20 (`today_summary_card.dart:42`), EntryListTile r16 (`entry_list_tile.dart:63`), dialogs r24 (`home_screen.dart:566`), toast r14 (`midnight_widgets.dart:349`).
- **3 button systems**: MidnightButton r16 (`midnight_widgets.dart:67`), ElevatedButton r12 (`home_screen.dart:211`), OutlinedButton r12 (`login_screen.dart:192`), FAB (`home_screen.dart:793`).
- **Titles**: Finance 22 (`finance_screen.dart:140`), others 24, Home greeting 26 (`home_screen.dart:671`), Login wordmark 32 (`login_screen.dart:109`).
- **Hero number 3 ways**: FinanceSummaryCard 32/−1 (`finance_summary_card.dart:84`), Overview 40/−1.5 (`overview_screen.dart:94`), Stats 32 (`stats_screen.dart:381`).
- **Avatar 6 ways**: entry_list_tile 44/r12/no-border, history 48/circle/border, recent_payments 38/r10, client_dropdown 32/circle + 36/r10/border1.5, stats 32/r8/border.
- **Label styles 5**: settings 10/1.5, add-entry 12/1.2, time-picker 11/1.0, finance-sheet 11, overview 13/0.5, finance-summary 14.
- **Settings inset mismatch**: title `fromLTRB(24,...)` vs card margin `symmetric(h16,...)` (`settings_screen.dart:306-318`).
- **`_parseColor` ×7**: entry_list_tile, finance_screen, history_screen, add_entry_screen, recent_payments_section, settings_screen (×2), client_dropdown.
- **Segment control ×2**: finance_screen:179-250, stats_screen:184-281.
- **Sheet inconsistency**: finance add-payment has border + no handle (`finance_screen.dart:533`), history detail no border (`history_screen.dart:579`), others vary.
- **Dialog outlier**: entry_list_tile r16/no-border (`entry_list_tile.dart:40`) vs standard r24/border.
- **Dead code**: neumorphic_widgets.dart zero imports in lib/.
- **Typo**: "ŞİMDİ YÜKSELTT" (`settings_screen.dart:191`).
- **`Colors.white`**: finance_screen:412 (should be onPrimary).
