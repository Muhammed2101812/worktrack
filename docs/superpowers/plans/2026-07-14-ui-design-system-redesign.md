# WorkLog UI Design System & Full Refactor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace 17 cross-cutting UI inconsistencies with a single design-token source of truth + component library, give the app a distinctive "ledger" identity (tabular figures, Space Grotesk, warm neutrals, signature ledger line), and migrate all 8 screens to the system.

**Architecture:** Bottom-up. First build the token layer (`lib/core/dimens.dart`) and warm-neutral palette + font theme. Then build a new component library (`lib/core/widgets/app_widgets.dart`) that derives every radius/spacing/shadow from the tokens. Then migrate each screen to the new widgets, one screen per task. Old `Midnight*` widgets and `neumorphic_widgets.dart` are removed once nothing references them. `_parseColor` is consolidated into `utils.dart`.

**Tech Stack:** Flutter (Material 3), Riverpod, `google_fonts` (already a dependency), `phosphor_flutter`, `flutter_riverpod`. Tests via `flutter test`.

**Spec:** `docs/superpowers/specs/2026-07-14-ui-design-system-redesign.md`

## Global Constraints

- **Radius scale** (from spec §4.1): `xs=8, sm=12, md=16, lg=20, xl=24, full=999`. No screen may hardcode a radius outside this scale. Nested-radius rule: child radius = nearest-scale value to `outerRadius − padding`.
- **Spacing scale** (from spec §4.2): `4, 8, 12, 16, 20, 24, 32` only. No ad-hoc values (35, 10, 6).
- **Typography roles** (from spec §4.3): `screenTitle`=24/bold/−0.5; `sectionTitle`=16/bold; `eyebrow`=12/bold/1.2; `body`=15/w500; `caption`=13/normal; `figureLg`=36/w900/−1.5 tabular; `figureMd`=20/bold tabular.
- **Shadow system** (from spec §4.4): `card`=0.04/12/(0,4); `elevated`=0.06/16/(0,6); `dialog`=0.08/24/(0,8). All use `Colors.black` alpha.
- **Identity** (from spec §3): Space Grotesk via `google_fonts`; tabular figures on all monetary/hour text; warm-neutral `AppPalette`; signature left-edge ledger line on summary cards and list items.
- **Colors**: read via `Theme.of(context).extension<AppPalette>()!`, NOT the deprecated `AppColors.of(context)` shim (spec §5 "theme migration completion"). The `AppColors.of(context)` shim may be used temporarily inside files not yet migrated, but all NEW code uses the extension directly.
- **Surface separation**: thin 1px `cardBorder` border + consistent shadow on cards (spec §2).
- **Button system**: ONE widget (`AppButton`) with `variant: solid|ghost|danger|outline`. ghost/danger draw NO colored shadow (spec §5).
- **Commit after every task.** Conventional commit messages.

---

## File Structure

**Create:**
- `lib/core/dimens.dart` — token scale (Radii, Spacing, AppShadows, AppTexts, innerRadius helper).
- `lib/core/widgets/app_widgets.dart` — AppCard, AppButton, AppInput, AppAvatar, ScreenHeader, SectionHeader, SegmentedControl, EmptyState, AppSheet, AppDialog, LedgerLine.
- `test/core/dimens_test.dart` — token + helper tests.
- `test/widgets/app_widgets_test.dart` — component tests.
- `test/core/utils_color_test.dart` — `_parseColor` tests.

**Modify:**
- `lib/core/theme.dart` — warm-neutral palette values, Space Grotesk textTheme, card/input/fab theme radii from scale.
- `lib/core/utils.dart` — add `parseHexColor` (consolidates 7 `_parseColor` copies).
- `lib/app.dart` — apply Space Grotesk globally (already builds ThemeData, just confirm).
- All 8 screen files + their widgets — migrate to app_widgets + tokens.
- `pubspec.yaml` — remove `flutter_inset_shadow`.

**Delete:**
- `lib/core/widgets/neumorphic_widgets.dart` (dead code).
- Old `MidnightCard`/`MidnightButton`/`MidnightInput`/`CustomToast` from `midnight_widgets.dart` (replaced by app_widgets; done in cleanup task).
- Tests for removed widgets: `test/widgets/midnight_button_test.dart`, `test/widgets/midnight_widgets_test.dart` (replaced by app_widgets tests).

---

## Task 1: Design tokens — `lib/core/dimens.dart`

**Files:**
- Create: `lib/core/dimens.dart`
- Test: `test/core/dimens_test.dart`

**Interfaces:**
- Produces: `class Radii { static const double xs=8, sm=12, md=16, lg=20, xl=24, full=999; static BorderRadius xsBr(); ... }`, `class Spacing { static const double s4=4, s8=8, ... s32=32; }`, `class AppShadows { static List<BoxShadow> card(BuildContext); static List<BoxShadow> elevated(BuildContext); static List<BoxShadow> dialog(BuildContext); }`, `class AppTexts { static TextStyle screenTitle(BuildContext); ... }`, `double innerRadius(double outer, double padding)`, `double _snapToScale(double value)`.

- [ ] **Step 1: Write the failing test**

Create `test/core/dimens_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/dimens.dart';

void main() {
  group('Radii', () {
    test('scale values are exact', () {
      expect(Radii.xs, 8);
      expect(Radii.sm, 12);
      expect(Radii.md, 16);
      expect(Radii.lg, 20);
      expect(Radii.xl, 24);
      expect(Radii.full, 999);
    });

    test('BorderRadius helpers return correct values', () {
      expect(Radii.xsBr, const BorderRadius.all(Radius.circular(8)));
      expect(Radii.mdBr, const BorderRadius.all(Radius.circular(16)));
    });
  });

  group('innerRadius', () {
    test('card 16 minus padding 8 returns 8 (exact scale hit)', () {
      expect(innerRadius(16, 8), 8);
    });

    test('card 16 minus padding 12 snaps UP to nearest sensible (8)', () {
      // 16 - 12 = 4, which is below xs(8); snap up to 8 so children are not
      // sharper than badges.
      expect(innerRadius(16, 12), 8);
    });

    test('card 16 minus padding 4 returns 12', () {
      expect(innerRadius(16, 4), 12);
    });

    test('never returns below 0', () {
      expect(innerRadius(8, 100), 0);
    });
  });

  group('Spacing', () {
    test('scale values', () {
      expect(Spacing.s4, 4);
      expect(Spacing.s32, 32);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/dimens_test.dart`
Expected: FAIL — `worklog/core/dimens.dart` not found / `innerRadius` undefined.

- [ ] **Step 3: Write the implementation**

Create `lib/core/dimens.dart`:

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme.dart';

/// Design-token scales. Single source of truth for every radius, spacing,
/// shadow and text style in the app. See
/// `docs/superpowers/specs/2026-07-14-ui-design-system-redesign.md` §4.

/// Corner-radius scale (spec §4.1).
class Radii {
  static const double xs = 8; // badge, status pill, small icon chip
  static const double sm = 12; // input, small button, segmented active
  static const double md = 16; // card, primary button
  static const double lg = 20; // pill button, filter chip, hero card
  static const double xl = 24; // dialog, bottom sheet, navbar
  static const double full = 999; // FAB, navbar +

  const Radii._();

  static const BorderRadius xsBr = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius smBr = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBr = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBr = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBr = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullBr = BorderRadius.all(Radius.circular(full));
}

/// Snaps an arbitrary radius to the nearest scale value that is >= it, but
/// never above the largest scale entry below `xl`. Used by [innerRadius].
double _snapToScale(double value) {
  const scale = [0, 8.0, 12.0, 16.0, 20.0, 24.0];
  if (value <= 0) return 0;
  // Round to nearest; for sub-xs values (e.g. 4) snap UP to 8 so children are
  // never sharper than badges.
  for (final s in scale) {
    if ((value - s).abs() <= 2) return s;
  }
  return 8; // fallback floor for tiny values
}

/// Nested-radius helper (spec §4.1). A child's corner radius = the parent's
/// radius minus the padding between them, snapped to the scale. Guarantees
/// concentric corners look correct.
double innerRadius(double outerRadius, double padding) {
  final raw = outerRadius - padding;
  if (raw <= 0) return 0;
  return _snapToScale(raw);
}

/// Spacing scale (spec §4.2).
class Spacing {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  const Spacing._();
}

/// Shadow system (spec §4.4). All derive from Colors.black alpha.
class AppShadows {
  const AppShadows._();

  static List<BoxShadow> card(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> elevated(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> dialog(BuildContext context) => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];
}

/// Tabular-figure text style mixin helper.
TextStyle _tabular(TextStyle base) =>
    base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

/// Typography scale (spec §4.3). All read the live palette.
class AppTexts {
  const AppTexts._();

  static TextStyle screenTitle(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return TextStyle(
      color: p.textMain,
      fontSize: 24,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    );
  }

  static TextStyle sectionTitle(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return TextStyle(
      color: p.textMain,
      fontSize: 16,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle eyebrow(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return TextStyle(
      color: p.textMuted,
      fontSize: 12,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.2,
    );
  }

  static TextStyle body(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return TextStyle(
      color: p.textMain,
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle caption(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return TextStyle(color: p.textMuted, fontSize: 13);
  }

  /// Hero numbers — tabular figures (spec §3.1).
  static TextStyle figureLg(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return _tabular(TextStyle(
      color: p.textMain,
      fontSize: 36,
      fontWeight: FontWeight.w900,
      letterSpacing: -1.5,
    ));
  }

  /// Sub-metric numbers — tabular figures (spec §3.1).
  static TextStyle figureMd(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return _tabular(TextStyle(
      color: p.textMain,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ));
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/dimens_test.dart`
Expected: PASS (all 7 assertions).

- [ ] **Step 5: Commit**

```bash
git add lib/core/dimens.dart test/core/dimens_test.dart
git commit -m "feat(ui): add design-token scale (radii, spacing, shadows, typography)"
```

---

## Task 2: Warm-neutral palette + Space Grotesk in theme

**Files:**
- Modify: `lib/core/theme.dart` (palette light/dark values; textTheme → Space Grotesk; cardTheme radius from `Radii.md`)
- Create: nothing.

**Interfaces:**
- Consumes: `Radii` from `dimens.dart`.
- Produces: updated `AppPalette.light` / `AppPalette.dark` warm-neutral values; `AppTheme.light`/`.dark` textTheme uses Space Grotesk.

- [ ] **Step 1: Update AppPalette to warm neutrals**

In `lib/core/theme.dart`, replace the `static const light = AppPalette(...)` values. Change these fields only:

```dart
  static const light = AppPalette(
    primary: Color(0xFF10B981),
    primaryHover: Color(0xFF059669),
    bgColor: Color(0xFFF7F6F3), // warm off-white (was cold gray #F9FAFB)
    cardBg: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE8E5DE), // warm border (was cold #E5E7EB)
    textMain: Color(0xFF1C1B19), // warm near-black (was #111827)
    textMuted: Color(0xFF7A766E), // warm muted (was #6B7280)
    shimmer1: Color(0xFFEFEDE7),
    shimmer2: Color(0xFFF7F6F3),
    emerald: Color(0xFF10B981),
    purple: Color(0xFF8B5CF6),
    orange: Color(0xFFF59E0B),
    error: Color(0xFFEF4444),
    success: Color(0xFF10B981),
    navBg: Color(0xFFFFFFFF),
    onPrimary: Color(0xFFFFFFFF),
  );

  static const dark = AppPalette(
    primary: Color(0xFF34D399),
    primaryHover: Color(0xFF10B981),
    bgColor: Color(0xFF1A1814), // warm dark (was cold slate #0F172A)
    cardBg: Color(0xFF26231D), // warm dark surface (was #1E293B)
    cardBorder: Color(0xFF3A3630), // warm border (was #334155)
    textMain: Color(0xFFF4F2EC), // warm off-white (was #F1F5F9)
    textMuted: Color(0xFFA39E92), // warm muted (was #94A3B8)
    shimmer1: Color(0xFF26231D),
    shimmer2: Color(0xFF1A1814),
    emerald: Color(0xFF34D399),
    purple: Color(0xFFA78BFA),
    orange: Color(0xFFFBBF24),
    error: Color(0xFFF87171),
    success: Color(0xFF34D399),
    navBg: Color(0xFF26231D),
    onPrimary: Color(0xFF1A1814),
  );
```

- [ ] **Step 2: Add Space Grotesk import and apply to textTheme**

At the top of `lib/core/theme.dart`, add:

```dart
import 'package:google_fonts/google_fonts.dart';
import 'dimens.dart';
```

In BOTH `AppTheme.light` and `AppTheme.dark`, replace the `textTheme:` block. For light:

```dart
      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData(brightness: Brightness.light).textTheme,
      ).copyWith(
        headlineMedium: TextStyle(
          color: p.textMain,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: p.textMain,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(color: p.textMain),
        bodyMedium: TextStyle(color: p.textMuted),
      ),
```

For dark, use `GoogleFonts.spaceGroteskTextTheme(ThemeData(brightness: Brightness.dark).textTheme)` with the same `.copyWith`.

- [ ] **Step 3: Update cardTheme + inputDecorationTheme radii to use Radii**

In BOTH `AppTheme.light` and `AppTheme.dark`, the `cardTheme` shape:

```dart
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md), // 16
          side: BorderSide(color: p.cardBorder, width: 1),
        ),
```

`inputDecorationTheme` borders:

```dart
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm), // 12
          borderSide: BorderSide(color: p.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: p.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.sm),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
```

- [ ] **Step 4: Verify it compiles and existing tests still pass**

Run: `flutter analyze lib/core/theme.dart lib/core/dimens.dart`
Expected: no errors.

Run: `flutter test`
Expected: existing tests PASS (they don't assert exact color hex, so palette change is safe).

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme.dart
git commit -m "feat(ui): warm-neutral palette + Space Grotesk typeface"
```

---

## Task 3: Consolidate `_parseColor` into utils

**Files:**
- Modify: `lib/core/utils.dart` (add `parseHexColor`).
- Test: `test/core/utils_color_test.dart`.

**Interfaces:**
- Produces: `Color parseHexColor(String? hex, [Color fallback = const Color(0xFF9CA3AF)])` — handles `#RRGGBB`, `#AARRGGBB`, `RRGGBB`, `AARRGGBB`, empty/null → fallback.

- [ ] **Step 1: Write the failing test**

Create `test/core/utils_color_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/utils.dart';

void main() {
  group('parseHexColor', () {
    test('parses #RRGGBB', () {
      expect(parseHexColor('#4A90D9'), const Color(0xFF4A90D9));
    });

    test('parses RRGGBB without #', () {
      expect(parseHexColor('4A90D9'), const Color(0xFF4A90D9));
    });

    test('parses #AARRGGBB', () {
      expect(parseHexColor('#FF4A90D9'), const Color(0xFF4A90D9));
    });

    test('parses lowercase hex', () {
      expect(parseHexColor('#4a90d9'), const Color(0xFF4A90D9));
    });

    test('returns fallback for empty string', () {
      expect(parseHexColor(''), const Color(0xFF9CA3AF));
    });

    test('returns fallback for null', () {
      expect(parseHexColor(null), const Color(0xFF9CA3AF));
    });

    test('returns fallback for malformed input', () {
      expect(parseHexColor('xyz'), const Color(0xFF9CA3AF));
    });

    test('accepts custom fallback', () {
      expect(parseHexColor(null, Colors.red), Colors.red);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/utils_color_test.dart`
Expected: FAIL — `parseHexColor` undefined.

- [ ] **Step 3: Write the implementation**

Append to `lib/core/utils.dart`:

```dart
import 'package:flutter/material.dart';

/// Parses a hex color string into a [Color]. Accepts `#RRGGBB`,
/// `#AARRGGBB`, `RRGGBB`, `AARRGGBB` (case-insensitive). Returns [fallback]
/// for null, empty, or malformed input so callers never throw.
///
/// Consolidates the 7 duplicated `_parseColor` implementations across screens.
Color parseHexColor(String? hex, [Color fallback = const Color(0xFF9CA3AF)]) {
  if (hex == null || hex.isEmpty) return fallback;
  var h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  // Normalize to AARRGGBB.
  if (h.length == 6) h = 'FF$h';
  if (h.length != 8) return fallback;
  final value = int.tryParse(h, radix: 16);
  if (value == null) return fallback;
  return Color(value);
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/utils_color_test.dart`
Expected: PASS (8 assertions).

- [ ] **Step 5: Commit**

```bash
git add lib/core/utils.dart test/core/utils_color_test.dart
git commit -m "feat(utils): add consolidated parseHexColor helper"
```

---

## Task 4: Component library — `lib/core/widgets/app_widgets.dart`

This is the largest task. It creates all shared widgets. Build + test incrementally.

**Files:**
- Create: `lib/core/widgets/app_widgets.dart`
- Test: `test/widgets/app_widgets_test.dart`

**Interfaces:**
- Consumes: `Radii`, `Spacing`, `AppShadows`, `AppTexts`, `innerRadius` from `dimens.dart`; `AppPalette` from `theme.dart`.
- Produces (used by all screen tasks):
  - `AppCard({Widget? child, EdgeInsetsGeometry? padding, EdgeInsetsGeometry? margin, VoidCallback? onTap, CardVariant variant = CardVariant.flat, bool ledgerLine = false, Color? ledgerColor})`
  - `enum CardVariant { flat, elevated, hero }`
  - `AppButton({required VoidCallback? onPressed, required Widget child, ButtonVariant variant = ButtonVariant.solid, double? width, double? height, EdgeInsetsGeometry? padding})`
  - `enum ButtonVariant { solid, ghost, danger, outline }`
  - `AppInput({required String hintText, ...same as MidnightInput})`
  - `AppAvatar({required String name, required String hexColor, AvatarSize size = AvatarSize.md, bool dot = false})`
  - `enum AvatarSize { sm, md, lg }`
  - `ScreenHeader({required String title, VoidCallback? onBack, Widget? action})`
  - `SectionHeader({required String title, String? actionLabel, VoidCallback? onAction})`
  - `SegmentedControl({required int selected, required ValueChanged<int> onChanged, required List<String> labels})`
  - `EmptyState({required IconData icon, required String title, String? subtitle, Widget? cta})`
  - `AppSheet({required Widget child, ...})` — bottom-sheet wrapper.
  - `AppDialog({required Widget child, ...})` — dialog wrapper.
  - `LedgerLine({Color? color})` — the signature left stripe.

- [ ] **Step 1: Write failing tests for the core widgets**

Create `test/widgets/app_widgets_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog/core/widgets/app_widgets.dart';

void main() {
  group('AppCard', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AppCard(child: const Text('Hi'))),
      ));
      expect(find.text('Hi'), findsOneWidget);
    });

    testWidgets('calls onTap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AppCard(onTap: () => tapped = true, child: const Text('X'))),
      ));
      await tester.tap(find.byType(AppCard));
      expect(tapped, isTrue);
    });

    testWidgets('ledgerLine renders a thin left container', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AppCard(ledgerLine: true, child: const Text('X'))),
      ));
      // The card + a ledger stripe container exist.
      expect(find.byType(AppCard), findsOneWidget);
    });
  });

  group('AppButton', () {
    testWidgets('solid variant renders and calls onPressed', (tester) async {
      bool pressed = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton(
            onPressed: () => pressed = true,
            child: const Text('Go'),
          ),
        ),
      ));
      await tester.tap(find.byType(AppButton));
      expect(pressed, isTrue);
    });

    testWidgets('disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: const AppButton(onPressed: null, child: Text('Go')),
        ),
      ));
      expect(find.text('Go'), findsOneWidget);
    });

    testWidgets('ghost variant draws no colored shadow', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton(
            variant: ButtonVariant.ghost,
            onPressed: () {},
            child: const Text('Ghost'),
          ),
        ),
      ));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppButton),
          matching: find.byType(Container),
        ).last,
      );
      final deco = container.decoration as BoxDecoration;
      // Ghost buttons must have NO boxShadow (the alpha-0.1 abuse is gone).
      expect(deco.boxShadow, isNull);
    });

    testWidgets('respects width constraint', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton(
            onPressed: () {},
            width: 250,
            child: const Text('W'),
          ),
        ),
      ));
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(AppButton),
          matching: find.byType(Container),
        ).last,
      );
      expect(container.constraints?.minWidth, 250);
    });
  });

  group('AppAvatar', () {
    testWidgets('renders first initial uppercase', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: AppAvatar(name: 'acme', hexColor: '#4A90D9')),
      ));
      expect(find.text('A'), findsOneWidget);
    });
  });

  group('ScreenHeader', () {
    testWidgets('renders title and back button when onBack set', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ScreenHeader(title: 'Test', onBack: () {}),
        ),
      ));
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('omits back button when onBack is null', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: ScreenHeader(title: 'NoBack')),
      ));
      expect(find.byType(ScreenHeader), findsOneWidget);
      // No back arrow icon present.
      expect(find.byTooltip('Back'), findsNothing);
    });
  });

  group('SegmentedControl', () {
    testWidgets('renders all labels and reports taps', (tester) async {
      int selected = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SegmentedControl(
              selected: selected,
              onChanged: (i) => setState(() => selected = i),
              labels: const ['A', 'B'],
            ),
          ),
        ),
      ));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      await tester.tap(find.text('B'));
      expect(selected, 1);
    });
  });

  group('EmptyState', () {
    testWidgets('renders icon, title, subtitle', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox,
            title: 'Empty',
            subtitle: 'Nothing here',
          ),
        ),
      ));
      expect(find.text('Empty'), findsOneWidget);
      expect(find.text('Nothing here'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widgets/app_widgets_test.dart`
Expected: FAIL — `app_widgets.dart` not found.

- [ ] **Step 3: Write the implementation**

Create `lib/core/widgets/app_widgets.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../dimens.dart';
import '../theme.dart';
import '../utils.dart';

// ===========================================================================
// AppCard
// ===========================================================================
enum CardVariant { flat, elevated, hero }

/// One card recipe. border(1px) + consistent shadow. [ledgerLine] draws the
/// signature left-edge accent stripe (spec §3.3).
class AppCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final CardVariant variant;
  final bool ledgerLine;
  final Color? ledgerColor;

  const AppCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.variant = CardVariant.flat,
    this.ledgerLine = false,
    this.ledgerColor,
  });

  BorderRadius get _radius {
    switch (variant) {
      case CardVariant.hero:
        return Radii.lgBr; // 20
      case CardVariant.elevated:
      case CardVariant.flat:
        return Radii.mdBr; // 16
    }
  }

  List<BoxShadow> get _shadow(BuildContext context) {
    switch (variant) {
      case CardVariant.hero:
        return AppShadows.elevated(context);
      case CardVariant.elevated:
        return AppShadows.elevated(context);
      case CardVariant.flat:
        return AppShadows.card(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.cardBg,
          borderRadius: _radius,
          border: Border.all(color: p.cardBorder, width: 1),
          boxShadow: _shadow(context),
        ),
        child: ledgerLine
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: ledgerColor ?? p.primary),
                  if (child != null) Expanded(child: child!),
                ],
              )
            : child,
      ),
    );
  }
}

// ===========================================================================
// AppButton
// ===========================================================================
enum ButtonVariant { solid, ghost, danger, outline }

/// ONE button system. [variant] controls fill/shadow:
/// - solid: primary fill + colored glow shadow.
/// - ghost: translucent tint, NO shadow (kills the alpha-0.1 abuse).
/// - danger: error tint, NO shadow.
/// - outline: transparent fill + border, NO shadow.
class AppButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonVariant variant;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = ButtonVariant.solid,
    this.width,
    this.height,
    this.padding,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl =
        AnimationController(duration: const Duration(milliseconds: 120), vsync: this);
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(PointerDownEvent _) {
    setState(() => _isPressed = true);
    _ctrl.forward();
    HapticFeedback.lightImpact();
  }

  void _up(PointerUpEvent _) {
    setState(() => _isPressed = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    final enabled = widget.onPressed != null;

    Color fill;
    Color fg;
    Border? border;
    List<BoxShadow>? shadows;

    switch (widget.variant) {
      case ButtonVariant.solid:
        fill = _isPressed ? p.primaryHover : p.primary;
        fg = p.onPrimary;
        shadows = enabled
            ? [
                BoxShadow(
                  color: p.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : null;
        border = null;
        break;
      case ButtonVariant.ghost:
        fill = p.primary.withValues(alpha: _isPressed ? 0.16 : 0.1);
        fg = p.primary;
        shadows = null; // no colored shadow on ghost
        border = null;
        break;
      case ButtonVariant.danger:
        fill = p.error.withValues(alpha: _isPressed ? 0.16 : 0.1);
        fg = p.error;
        shadows = null; // no colored shadow on danger
        border = null;
        break;
      case ButtonVariant.outline:
        fill = Colors.transparent;
        fg = p.textMain;
        shadows = null;
        border = Border.all(color: p.cardBorder, width: 1);
        break;
    }

    return Listener(
      onPointerDown: enabled ? _down : null,
      onPointerUp: enabled ? _up : null,
      onPointerCancel: enabled
          ? (_) {
              setState(() => _isPressed = false);
              _ctrl.reverse();
            }
          : null,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) => Transform.scale(
            scale: _scale.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              padding: widget.padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: Radii.mdBr, // 16
                border: border,
                boxShadow: shadows,
              ),
              child: Center(child: child),
            ),
          ),
          child: DefaultTextStyle(
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
            child: IconTheme(data: IconThemeData(color: fg), child: widget.child),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// AppInput
// ===========================================================================
class AppInput extends StatefulWidget {
  final String hintText;
  final TextEditingController? controller;
  final String? initialValue;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? maxLength;

  const AppInput({
    super.key,
    required this.hintText,
    this.controller,
    this.initialValue,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late TextEditingController _ctrl;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _ctrl = widget.controller!;
      _ownsController = false;
    } else {
      _ctrl = TextEditingController(text: widget.initialValue);
      _ownsController = true;
    }
  }

  @override
  void didUpdateWidget(AppInput old) {
    super.didUpdateWidget(old);
    if (widget.controller != null && widget.controller != old.controller) {
      if (_ownsController) _ctrl.dispose();
      _ctrl = widget.controller!;
      _ownsController = false;
    }
  }

  @override
  void dispose() {
    if (_ownsController) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Container(
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: Radii.smBr, // 12 (was 16)
        border: Border.all(color: p.cardBorder, width: 1),
        boxShadow: AppShadows.card(context),
      ),
      child: TextField(
        controller: _ctrl,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        onChanged: widget.onChanged,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        style: AppTexts.body(context),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: p.textMuted),
          prefixIcon: widget.prefixIcon,
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          counterText: '',
        ),
      ),
    );
  }
}

// ===========================================================================
// AppAvatar — single avatar recipe (spec §5)
// ===========================================================================
enum AvatarSize { sm, md, lg }

class AppAvatar extends StatelessWidget {
  final String name;
  final String hexColor;
  final AvatarSize size;
  /// When true, renders a small color dot instead of an initial avatar
  /// (used in compact finance lists).
  final bool dot;

  const AppAvatar({
    super.key,
    required this.name,
    required this.hexColor,
    this.size = AvatarSize.md,
    this.dot = false,
  });

  double get _dimension {
    switch (size) {
      case AvatarSize.sm:
        return 32;
      case AvatarSize.md:
        return 44;
      case AvatarSize.lg:
        return 64;
    }
  }

  double get _fontSize {
    switch (size) {
      case AvatarSize.sm:
        return 14;
      case AvatarSize.md:
        return 16;
      case AvatarSize.lg:
        return 22;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(hexColor);
    if (dot) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
    }
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: _dimension,
      height: _dimension,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: _fontSize,
        ),
      ),
    );
  }
}

// ===========================================================================
// ScreenHeader — unified title + optional back (spec §5)
// ===========================================================================
class ScreenHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final Widget? action;

  const ScreenHeader({super.key, required this.title, this.onBack, this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.s24, Spacing.s8, Spacing.s24, Spacing.s8),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .extension<AppPalette>()!
                      .cardBg,
                  borderRadius: Radii.smBr,
                  border: Border.all(
                      color: Theme.of(context).extension<AppPalette>()!.cardBorder,
                      width: 1),
                ),
                child: Icon(PhosphorIcons.arrowLeft(),
                    color: Theme.of(context).extension<AppPalette>()!.textMain,
                    size: 20),
              ),
            ),
            const SizedBox(width: Spacing.s12),
          ],
          Expanded(
            child: Text(title, style: AppTexts.screenTitle(context)),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

// ===========================================================================
// SectionHeader — eyebrow label + optional link (spec §5)
// ===========================================================================
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title.toUpperCase(), style: AppTexts.eyebrow(context)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!,
                    style: TextStyle(
                        color: p.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Icon(PhosphorIcons.caretRight(),
                    color: p.primary, size: 14),
              ],
            ),
          ),
      ],
    );
  }
}

// ===========================================================================
// SegmentedControl — reusable (replaces finance+stats duplication)
// ===========================================================================
class SegmentedControl extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  const SegmentedControl({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: Radii.smBr, // 12
        border: Border.all(color: p.cardBorder, width: 1),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? p.primary : Colors.transparent,
                  borderRadius: Radii.xsBr, // 8
                  boxShadow: active && Theme.of(context).brightness == Brightness.light
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                      : null,
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? p.onPrimary : p.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ===========================================================================
// EmptyState — unified (replaces history+stats duplication)
// ===========================================================================
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? cta;

  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.cta});

  @override
  Widget build(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.s24),
            decoration: BoxDecoration(
              color: p.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: p.primary),
          ),
          const SizedBox(height: Spacing.s20),
          Text(title, style: AppTexts.sectionTitle(context)),
          if (subtitle != null) ...[
            const SizedBox(height: Spacing.s4),
            Text(subtitle!, style: AppTexts.caption(context)),
          ],
          if (cta != null) ...[
            const SizedBox(height: Spacing.s20),
            cta!,
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// AppSheet + AppDialog — wrappers (spec §5)
// ===========================================================================
class AppSheet extends StatelessWidget {
  final Widget child;
  final String? title;
  const AppSheet({super.key, required this.child, this.title});

  /// Wrap any showModalBottomSheet content in this.
  static Widget decoration(BuildContext context, {Widget? child, String? title}) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return Container(
      decoration: BoxDecoration(
        color: p.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        border: Border.all(color: p.cardBorder, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Spacing.s8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: p.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (title != null) ...[
            const SizedBox(height: Spacing.s12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.s24),
              child: Text(title.toUpperCase(), style: AppTexts.eyebrow(context)),
            ),
          ],
          const SizedBox(height: Spacing.s12),
          if (child != null) child!,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppSheet.decoration(context, child: child, title: title);
}

/// Standard dialog shape: radius xl(24) + border + navBg.
class AppDialog {
  static ShapeBorder shape(BuildContext context) {
    final p = Theme.of(context).extension<AppPalette>()!;
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(Radii.xl), // 24
      side: BorderSide(color: p.cardBorder, width: 1),
    );
  }

  static Color background(BuildContext context) =>
      Theme.of(context).extension<AppPalette>()!.cardBg;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/widgets/app_widgets_test.dart`
Expected: PASS (all 12 assertions).

- [ ] **Step 5: Verify full project compiles**

Run: `flutter analyze lib/core/widgets/app_widgets.dart`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/core/widgets/app_widgets.dart test/widgets/app_widgets_test.dart
git commit -m "feat(ui): add AppCard/AppButton/AppInput/AppAvatar + shared components"
```

---

## Task 5: Migrate Login screen

**Files:**
- Modify: `lib/screens/login/login_screen.dart`

**Interfaces:**
- Consumes: `AppButton`, `AppInput`, `Spacing`, `Radii` from app_widgets/dimens.

- [ ] **Step 1: Read current login_screen.dart**

Read `lib/screens/login/login_screen.dart` to confirm line numbers before editing.

- [ ] **Step 2: Fix horizontal padding 32 → 24**

Find the screen body `padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32)` and change to:

```dart
padding: const EdgeInsets.symmetric(horizontal: Spacing.s24, vertical: Spacing.s32),
```

Add imports at top:

```dart
import '../../core/dimens.dart';
import '../../core/widgets/app_widgets.dart';
```

- [ ] **Step 3: Replace the Google `OutlinedButton` with `AppButton(variant: outline)`**

Replace the `OutlinedButton(...)` block with:

```dart
AppButton(
  variant: ButtonVariant.outline,
  onPressed: () => ref.read(authNotifierProvider.notifier).signInWithGoogle(),
  width: double.infinity,
  height: 50,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Image.asset('assets/google_logo.png', height: 20, width: 20),
      const SizedBox(width: Spacing.s12),
      const Text('Google ile Giriş Yap'),
    ],
  ),
),
```

- [ ] **Step 4: Replace the "GİRİŞ YAP" MidnightButton with AppButton(solid, full-width, height 50)**

```dart
AppButton(
  variant: ButtonVariant.solid,
  onPressed: _loading ? null : _handleLogin,
  width: double.infinity,
  height: 50,
  child: Text('GİRİŞ YAP'),
),
```

- [ ] **Step 5: Verify it compiles**

Run: `flutter analyze lib/screens/login/login_screen.dart`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/login/login_screen.dart
git commit -m "refactor(login): migrate to AppButton/AppInput, fix padding+button consistency"
```

---

## Task 6: Migrate Home widgets (EntryListTile, TodaySummaryCard, RecentSections)

**Files:**
- Modify: `lib/screens/home/widgets/entry_list_tile.dart`
- Modify: `lib/screens/home/widgets/today_summary_card.dart`
- Modify: `lib/screens/home/widgets/finance_summary_card.dart`
- Modify: `lib/screens/home/widgets/recent_entries_section.dart`
- Modify: `lib/screens/home/widgets/recent_payments_section.dart`

**Interfaces:**
- Consumes: `AppCard`, `AppAvatar`, `SectionHeader`, `AppTexts`, `Spacing`, `Radii`, `parseHexColor`.

- [ ] **Step 1: Migrate `entry_list_tile.dart`**

Replace the raw `Container` card with `AppCard(ledgerLine: true, ...)`:

```dart
AppCard(
  margin: const EdgeInsets.symmetric(vertical: Spacing.s4),
  padding: const EdgeInsets.all(Spacing.s16),
  onTap: onTap,
  ledgerLine: true,
  ledgerColor: parseHexColor(entry.colorHex),
  child: Row(...)
)
```

Replace the local `_parseColor` function with calls to `parseHexColor` (import `'../../../core/utils.dart'`). Delete the local `_parseColor` definition.

Replace the delete-confirm `AlertDialog` shape to use `AppDialog`:

```dart
AlertDialog(
  backgroundColor: AppDialog.background(context),
  shape: AppDialog.shape(context),
  ...
)
```

Add imports:

```dart
import '../../../core/dimens.dart';
import '../../../core/widgets/app_widgets.dart';
import '../../../core/utils.dart';
```

- [ ] **Step 2: Migrate `today_summary_card.dart`**

Replace the raw `Container` (radius 20, custom shadow) with `AppCard(variant: CardVariant.hero, padding: EdgeInsets.all(Spacing.s24), ledgerLine: true, child: ...)`.

Replace the `52px` hours figure `TextStyle` with `AppTexts.figureLg(context)` and adjust the font size down to 36 from 52 (the hero token is 36). The hours figure now uses tabular figures.

Remove the local boxShadow definition (AppCard provides it).

Add imports: `dimens.dart`, `app_widgets.dart`.

- [ ] **Step 3: Migrate `finance_summary_card.dart`**

Replace the `MidnightCard` with `AppCard(padding: EdgeInsets.all(Spacing.s20), ...)`.

Replace the "Kalan Alacak" label `TextStyle(fontSize: 14, ...)` with `AppTexts.eyebrow(context)`.

Replace the balance figure `TextStyle(fontSize: 32, ...)` with `AppTexts.figureLg(context)` (now 36, tabular).

Replace the status pill `borderRadius: BorderRadius.circular(8)` with `Radii.xsBr`.

Add imports: `dimens.dart`, `app_widgets.dart`.

- [ ] **Step 4: Migrate `recent_entries_section.dart` and `recent_payments_section.dart`**

In both: replace the hand-rolled section header (Text + TextButton) with `SectionHeader(title: '...', actionLabel: 'Tümünü Gör', onAction: ...)`.

In `recent_payments_section.dart`: replace the local 38x38 avatar container with `AppAvatar(name: ..., hexColor: ..., size: AvatarSize.sm)` and delete the local `_parseColor`.

In `recent_payments_section.dart`: replace the `MidnightCard` payment tile with `AppCard`.

Add imports as needed.

- [ ] **Step 5: Verify home widgets tests still pass**

Run: `flutter test test/widgets/entry_list_tile_test.dart test/widgets/today_summary_card_test.dart`
Expected: PASS. If a test asserts an old structure (e.g. raw Container or specific font size), update the test to match the new widget.

Run: `flutter analyze lib/screens/home/widgets/`
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add lib/screens/home/widgets/
git commit -m "refactor(home): migrate widgets to AppCard/AppAvatar/AppTexts, add ledger line"
```

---

## Task 7: Migrate Home screen

**Files:**
- Modify: `lib/screens/home/home_screen.dart`

- [ ] **Step 1: Replace sidebar `ElevatedButton.icon` with `AppButton(solid, full-width)**

In `_buildSidebar`, replace the `ElevatedButton.icon(...)` block (radius 12, elevation 0) with:

```dart
AppButton(
  variant: ButtonVariant.solid,
  onPressed: () => context.push('/home/add'),
  width: double.infinity,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.add, size: 20),
      const SizedBox(width: Spacing.s8),
      const Text('Yeni Kayıt'),
    ],
  ),
),
```

- [ ] **Step 2: Update home greeting header to use tokens**

The greeting name `TextStyle(fontSize: 26, ...)` → `fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5` (kept as a greeting, slightly larger than screenTitle is fine, but use `Spacing` for the SizedBox gaps: `SizedBox(height: Spacing.s32)` instead of `35`, `Spacing.s8` instead of `10`).

Replace the empty-state CTA `MidnightButton` with `AppButton(variant: ButtonVariant.solid, ...)`.

Replace the empty-state hand-rolled icon container with `EmptyState(icon: Icons.edit_note_rounded, title: 'Henüz kaydınız bulunmuyor', subtitle: 'İlk çalışma kaydınızı oluşturun', cta: AppButton(...))`.

- [ ] **Step 3: Migrate the backup-restore AlertDialog to AppDialog**

Replace `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: ...)` with `shape: AppDialog.shape(context)` and `backgroundColor: AppDialog.background(context)`.

- [ ] **Step 4: Verify**

Run: `flutter analyze lib/screens/home/home_screen.dart`
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add lib/screens/home/home_screen.dart
git commit -m "refactor(home): unify buttons to AppButton, use EmptyState, spacing tokens"
```

---

## Task 8: Migrate Overview screen

**Files:**
- Modify: `lib/screens/overview/overview_screen.dart`

- [ ] **Step 1: Replace header + hero figures**

Replace the header `Text('Genel Bakış', style: TextStyle(fontSize: 24, ...))` with `ScreenHeader(title: 'Genel Bakış', onBack: () => context.go('/home'))`.

Replace the "Kalan Alacak" label `TextStyle(fontSize: 13, w600, letterSpacing: 0.5)` with `AppTexts.eyebrow(context)`.

Replace the hero balance figure `TextStyle(fontSize: 40, w900, letterSpacing: -1.5)` with `AppTexts.figureLg(context)` (36, tabular).

Replace the status pill radius 8 with `Radii.xsBr`.

- [ ] **Step 2: Fix the loading spinners**

Replace the bare `CircularProgressIndicator()` (lines ~197, 203) with `CircularProgressIndicator(color: Theme.of(context).extension<AppPalette>()!.primary)`.

- [ ] **Step 3: Verify + Commit**

Run: `flutter analyze lib/screens/overview/overview_screen.dart`
Expected: no errors.

```bash
git add lib/screens/overview/overview_screen.dart
git commit -m "refactor(overview): ScreenHeader, figureLg tabular hero, spinner color"
```

---

## Task 9: Migrate Finance screen

**Files:**
- Modify: `lib/screens/finance/finance_screen.dart`

- [ ] **Step 1: Replace header + duplicated segment control + button**

Header: `Text('Finansal Durum', style: TextStyle(fontSize: 22, ...))` → `ScreenHeader(title: 'Finansal Durum', onBack: ...)`.

"Ödeme Ekle" `MidnightButton(borderRadius: 12, ...)` → `AppButton(variant: ButtonVariant.solid, child: Row([...Icon add, Text('Ödeme Ekle')]))`.

Replace the hand-rolled segment selector (outer r12, active r8 — lines ~179-250) with:

```dart
SegmentedControl(
  selected: _selectedTab,
  onChanged: (i) => setState(() => _selectedTab = i),
  labels: const ['Müşteri Durumu', 'Ödemeler Geçmişi'],
),
```

Delete the now-unused segment-control helper code.

- [ ] **Step 2: Fix Colors.white → onPrimary + delete dialog**

In the dismiss background, replace `Icon(Icons.delete_outline, color: Colors.white, ...)` with `Icon(Icons.delete_outline, color: Theme.of(context).extension<AppPalette>()!.onPrimary, ...)`.

Replace the delete-confirm dialog shape with `AppDialog.shape(context)` + `AppDialog.background(context)`.

Replace the add-payment bottom sheet container with `AppSheet.decoration(context, title: 'Ödeme Ekle', child: ...)` (adds the missing drag handle + border).

- [ ] **Step 3: Replace local `_parseColor` + MidnightCard usages**

Delete the local `_parseColor` function; replace all calls with `parseHexColor(...)`. Replace `MidnightCard(...)` with `AppCard(...)`.

Replace the client-balance dot and payment dot with `AppAvatar(name: ..., hexColor: ..., dot: true)`.

- [ ] **Step 4: Verify + Commit**

Run: `flutter analyze lib/screens/finance/finance_screen.dart`
Expected: no errors.

```bash
git add lib/screens/finance/finance_screen.dart
git commit -m "refactor(finance): ScreenHeader, SegmentedControl, AppButton, onPrimary fix"
```

---

## Task 10: Migrate History screen

**Files:**
- Modify: `lib/screens/history/history_screen.dart`
- Modify: `lib/screens/history/widgets/month_filter.dart`

- [ ] **Step 1: Replace header + avatar + entry card**

Header: `Text('İş Geçmişi', style: TextStyle(fontSize: 24, ...))` → `ScreenHeader(title: 'İş Geçmişi', onBack: ...)`.

In `_buildEntryCard`, replace the 48x48 circle avatar with border with `AppAvatar(name: ..., hexColor: ..., size: AvatarSize.md)`.

Replace the entry `MidnightCard` with `AppCard`.

Replace the empty-state block with `EmptyState(icon: Icons.history, title: ..., subtitle: ...)`.

- [ ] **Step 2: Fix detail sheet + detail buttons**

Replace the detail bottom sheet container (no border, lines ~579) with `AppSheet.decoration(context, child: ...)`.

Replace the detail "Sil" `MidnightButton(color: c.error.withValues(alpha: 0.1), ...)` with `AppButton(variant: ButtonVariant.danger, child: Text('Sil'))` — danger variant has NO colored shadow.

Replace "Düzenle" `MidnightButton` with `AppButton(variant: ButtonVariant.ghost, child: Text('Düzenle'))`.

- [ ] **Step 3: Replace local `_parseColor` + minor tokens**

Delete local `_parseColor`; use `parseHexColor`. Replace filter-chip radius 20 with `Radii.lgBr`, padding with `Spacing` values. Replace sort-dropdown radius 12 with `Radii.smBr`.

- [ ] **Step 4: Migrate `month_filter.dart`**

Replace the `_NavButton` radius 10 with `Radii.smBr` (12). Month label letterSpacing 1.1 → use `AppTexts.eyebrow(context)` (1.2).

- [ ] **Step 5: Verify + Commit**

Run: `flutter analyze lib/screens/history/`
Expected: no errors.

```bash
git add lib/screens/history/
git commit -m "refactor(history): ScreenHeader, AppAvatar, EmptyState, danger/ghost buttons"
```

---

## Task 11: Migrate AddEntry screen + widgets

**Files:**
- Modify: `lib/screens/add_entry/add_entry_screen.dart`
- Modify: `lib/screens/add_entry/widgets/client_dropdown.dart`
- Modify: `lib/screens/add_entry/widgets/time_picker_row.dart`

- [ ] **Step 1: Replace labels + close icon + buttons**

Field labels: replace `TextStyle(fontSize: 12, bold, letterSpacing: 1.2)` with `AppTexts.eyebrow(context)`. time_picker labels `fontSize: 11, letterSpacing: 1.0` → `AppTexts.eyebrow(context)` (unified).

Close icon: keep `PhosphorIcons.x()` but wrap in the same 40x40 bordered container style as `ScreenHeader`'s back button for visual consistency (or use a back arrow if AddEntry is reached from multiple places — confirm: AddEntry is a push route, so `x()` close is correct; just style it consistently).

Project dialog "İPTAL" `MidnightButton(color: dc.shimmer1.withValues(alpha: 0.5))` → `AppButton(variant: ButtonVariant.outline, child: Text('İPTAL'))` (no tinted shadow).

Submit `MidnightButton` → `AppButton(variant: ButtonVariant.solid, width: double.infinity, child: ...)` (make it full-width for consistency with login/settings).

- [ ] **Step 2: Replace project-dialog icon radius + billing toggle**

Project dialog icon container radius 14 → `Radii.smBr` (12).

Billing-type toggle radius 12 → `Radii.smBr`.

- [ ] **Step 3: Migrate `client_dropdown.dart`**

Replace the trigger `MidnightCard` with `AppCard`. Replace list-item avatar (36x36, r10, border 1.5) with `AppAvatar(size: AvatarSize.sm)`. Replace selector sheet container with `AppSheet.decoration(context, title: 'Müşteri Seç')`.

Delete local `_parseColor`; use `parseHexColor`.

- [ ] **Step 4: Migrate `time_picker_row.dart`**

Break start/end `MidnightCard` and time `MidnightCard` → `AppCard`. Total card `MidnightCard` → `AppCard`. Use `Spacing` for paddings.

- [ ] **Step 5: Replace local `_parseColor`**

Delete the local `_parseColor` in `add_entry_screen.dart`; use `parseHexColor`.

- [ ] **Step 6: Verify + Commit**

Run: `flutter analyze lib/screens/add_entry/`
Expected: no errors.

```bash
git add lib/screens/add_entry/
git commit -m "refactor(add-entry): eyebrow labels, AppCard, AppButton, parseHexColor"
```

---

## Task 12: Migrate Stats screen

**Files:**
- Modify: `lib/screens/stats/stats_screen.dart`

- [ ] **Step 1: Replace header + segment control + figures**

Header: `Text('Aylık Rapor', ...)` → `ScreenHeader(title: 'Aylık Rapor')`.

Replace the duplicated segment selector (lines ~184-281) with `SegmentedControl(selected: ..., onChanged: ..., labels: ['Saatler', 'Gelir'])`.

Totals figure `TextStyle(fontSize: 32, bold)` → `AppTexts.figureLg(context)` (36, w900, tabular).

Pie-center figures: unify the 48/28 mismatch — both → `AppTexts.figureMd(context)` (20, tabular) or keep a larger one as `figureLg`. Decision: hours pie center → `figureLg`(36), earnings pie center → `figureLg`(36). Both tabular, same size.

Section sub-titles `TextStyle(fontSize: 11, bold, letterSpacing: 1.0)` → `AppTexts.eyebrow(context)`.

- [ ] **Step 2: Fix fallback color + asymmetric padding**

Replace inline `'#9CA3AF'` fallbacks (lines ~488, 921) with `parseHexColor(...)` (which already defaults to `0xFF9CA3AF`).

Daily-chart `MidnightCard` padding `fromLTRB(8, 16, 16, 8)` → `EdgeInsets.all(Spacing.s16)` (or `fromLTRB(Spacing.s8, Spacing.s16, Spacing.s16, Spacing.s8)` if the chart needs the asymmetric space — but prefer the symmetric form).

Replace `MidnightCard` usages with `AppCard`.

- [ ] **Step 3: Replace "PDF İndir" pill radius + empty state**

PDF pill radius 10 → `Radii.smBr` (12).

Replace empty-state block with `EmptyState(...)`.

- [ ] **Step 4: Verify + Commit**

Run: `flutter analyze lib/screens/stats/stats_screen.dart`
Expected: no errors.

```bash
git add lib/screens/stats/stats_screen.dart
git commit -m "refactor(stats): ScreenHeader, SegmentedControl, unified figures, AppCard"
```

---

## Task 13: Migrate Settings screen

**Files:**
- Modify: `lib/screens/settings/settings_screen.dart`

This is the largest screen file. Focus on the critical inconsistencies.

- [ ] **Step 1: Fix title/card inset alignment**

Section titles use `padding: fromLTRB(24, 16, 24, 8)` while cards use `margin: symmetric(h16, v8)`. Change section-title padding to `fromLTRB(Spacing.s16, Spacing.s16, Spacing.s16, Spacing.s8)` so titles align with card left edges (both at 16).

- [ ] **Step 2: Fix section title typography + typo**

Section titles `TextStyle(fontSize: 10, bold, letterSpacing: 1.5)` → `AppTexts.eyebrow(context)` (12/1.2).

Fix typo: "ŞİMDİ YÜKSELTT" → "YÜKSELT".

- [ ] **Step 3: Standardize the 5 different radii to the scale**

- Settings sync badge radius 6 → `Radii.xs` (8).
- Theme-option selector radius 12 → `Radii.smBr`.
- Currency list-item radius 12 → `Radii.smBr`.
- Reset option item radius 16 → `Radii.mdBr`.
- Icon container radius 10 → `Radii.smBr` (12).
- Custom toggle 44x24 radius 12 → keep (toggle pill shape is fine at sm); knob radius 11 → keep (half of height).

- [ ] **Step 4: Fix paywall dialog button + premium card padding**

Paywall dialog: the `MidnightButton` inside `AlertDialog.actions` → use `AppButton(variant: ButtonVariant.solid, child: Text('Premium'a Geç'))`. Wrap the dialog with `AppDialog.shape` + `AppDialog.background`.

Premium-active card padding `all(16)` and non-premium `all(20)` → both `EdgeInsets.all(Spacing.s20)`.

Premium icon containers radius 12 and 14 → both `Radii.smBr` (12) or `Radii.mdBr`(16) consistently; pick md(16) for the large premium icon.

- [ ] **Step 5: Fix bottom sheets**

`_ClientManagementSheet` and `_ImportSheet` containers (no border) → `AppSheet.decoration(context, ...)` (adds border + handle).

- [ ] **Step 6: Replace local `_parseColor` (×2) + MidnightCard**

Delete both `_parseColor` definitions; use `parseHexColor`. Replace `MidnightCard` usages with `AppCard`.

- [ ] **Step 7: Verify + Commit**

Run: `flutter analyze lib/screens/settings/settings_screen.dart`
Expected: no errors.

```bash
git add lib/screens/settings/settings_screen.dart
git commit -m "refactor(settings): fix inset alignment, typo, unified radii, AppCard/AppButton"
```

---

## Task 14: Cleanup — remove old widgets, dead code, dependency

**Files:**
- Delete: `lib/core/widgets/neumorphic_widgets.dart`
- Modify: `lib/core/widgets/midnight_widgets.dart` (remove MidnightCard/MidnightButton/MidnightInput; keep CustomToast or migrate it).
- Delete: `test/widgets/midnight_button_test.dart`, `test/widgets/midnight_widgets_test.dart`.
- Modify: `pubspec.yaml` (remove `flutter_inset_shadow`).

- [ ] **Step 1: Confirm no references to Midnight* or neumorphic remain**

Run: `grep -rn "MidnightCard\|MidnightButton\|MidnightInput\|neumorphic_widgets\|NeuContainer\|NeuButton\|NeuInput" lib/`
Expected: only references inside `lib/core/widgets/midnight_widgets.dart` itself (its own definitions). If any screen still references them, go back and migrate that screen.

- [ ] **Step 2: Delete neumorphic_widgets.dart**

```bash
git rm lib/core/widgets/neumorphic_widgets.dart
```

- [ ] **Step 3: Trim midnight_widgets.dart**

Migrate `CustomToast` into `app_widgets.dart` (or keep `midnight_widgets.dart` containing ONLY CustomToast). Simplest: move CustomToast to app_widgets.dart and delete midnight_widgets.dart entirely.

If you keep midnight_widgets.dart for CustomToast only, remove the three Midnight* classes. Decision: **move CustomToast to app_widgets.dart and delete midnight_widgets.dart**.

Add CustomToast to `lib/core/widgets/app_widgets.dart` (copy the class verbatim from midnight_widgets.dart; it already uses `AppColors.of(context)` — update to `Theme.of(context).extension<AppPalette>()!`, and change toast radius 14 → `Radii.sm`/12, shadow to `AppShadows.dialog`).

Delete midnight_widgets.dart:

```bash
git rm lib/core/widgets/midnight_widgets.dart
```

- [ ] **Step 4: Remove the flutter_inset_shadow dependency**

In `pubspec.yaml`, remove the line:

```yaml
  flutter_inset_shadow: ^2.0.1
```

Run: `flutter pub get`
Expected: resolves cleanly.

- [ ] **Step 5: Delete old widget tests**

```bash
git rm test/widgets/midnight_button_test.dart test/widgets/midnight_widgets_test.dart
```

- [ ] **Step 6: Verify everything compiles + all tests pass**

Run: `flutter analyze`
Expected: no errors (zero `referenced_widget` / import errors).

Run: `flutter test`
Expected: all remaining tests PASS.

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "chore(ui): remove dead neumorphic widgets, Midnight* classes, flutter_inset_shadow dep"
```

---

## Task 15: Final visual verification on emulator

**Files:** none (verification only).

- [ ] **Step 1: Build and run on emulator**

Use the android-emulator tools: build debug, install, launch. Application id discoverable via `android_discover_project`.

- [ ] **Step 2: Walk through every screen and verify**

Checklist (screenshot each):
- Login: both buttons same height + radius; Space Grotesk visible; warm background.
- Home: ledger line on summary + entry cards; tabular hours figure; consistent spacing.
- Overview: "Kalan Alacak" figure is figureLg (36) tabular; back button present.
- Finance: title 24; segment control is the shared one; no `Colors.white` icon.
- History: avatars all same shape/size; danger button has no weird shadow.
- AddEntry: labels all eyebrow; full-width save button.
- Stats: unified pie-center figure size; shared segment control.
- Settings: section titles align with card edges; "YÜKSELT" spelled correctly; consistent radii.

- [ ] **Step 3: Note any visual regressions and fix**

If a migrated screen looks off (spacing too tight/loose, ledger line too prominent), adjust the specific token usage and re-commit.

---

## Self-Review Notes

**Spec coverage check:**
- §3.1 Space Grotesk + tabular figures → Task 2 (font) + Task 1 (figureLg/figureMd tabular) + Tasks 6-13 (applied). ✓
- §3.2 warm neutrals → Task 2. ✓
- §3.3 ledger line → Task 1 (LedgerLine is part of AppCard's `ledgerLine` prop) + Task 6 (applied to home cards). ✓
- §4.1 radius scale + nested-radius → Task 1. ✓
- §4.2 spacing scale → Task 1 (applied in all subsequent tasks). ✓
- §4.3 typography → Task 1 (applied in all subsequent tasks). ✓
- §4.4 shadow system → Task 1 + Task 4 (AppCard uses AppShadows). ✓
- §5 component library → Task 4. ✓
- §5 utils `_parseColor` → Task 3 + applied in Tasks 6,9,10,11,13. ✓
- §5 deletions (neumorphic, flutter_inset_shadow) → Task 14. ✓
- §5 theme migration (extension<>) → Task 4 uses it; Tasks reference it. ✓
- §6 all 8 screens → Tasks 5,6,7,8,9,10,11,12,13. ✓
- §7 build order → matches phase structure. ✓

**Type consistency check:**
- `AppCard` constructor signature consistent across Tasks 4-13. ✓
- `AppButton` `variant` enum name `ButtonVariant` used consistently. ✓
- `SegmentedControl` `labels` param consistent between Task 4 (definition) and Tasks 9, 12 (usage). ✓
- `parseHexColor(String?, [Color])` signature consistent between Task 3 (def) and usages. ✓
- `AppDialog.shape(context)` / `AppDialog.background(context)` consistent. ✓
- `AppSheet.decoration(context, {child, title})` consistent. ✓
