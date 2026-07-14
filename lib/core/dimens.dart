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
  const scale = [0.0, 8.0, 12.0, 16.0, 20.0, 24.0];
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
