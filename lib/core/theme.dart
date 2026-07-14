import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dimens.dart';

/// Theme extension carrying the app's semantic palette. Access from widgets via
/// `Theme.of(context).extension<AppPalette>()!`. Both light and dark instances
/// are registered in [AppTheme].
///
/// The legacy static [AppColors] / [MidnightColors] classes are kept only as
/// deprecated aliases for transitional code; new code MUST use AppPalette so
/// colours respond to the active theme.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color primary;
  final Color primaryHover;
  final Color bgColor;
  final Color cardBg;
  final Color cardBorder;
  final Color textMain;
  final Color textMuted;
  final Color shimmer1;
  final Color shimmer2;
  final Color emerald;
  final Color purple;
  final Color orange;
  final Color error;
  final Color success;
  final Color navBg;
  final Color onPrimary;

  const AppPalette({
    required this.primary,
    required this.primaryHover,
    required this.bgColor,
    required this.cardBg,
    required this.cardBorder,
    required this.textMain,
    required this.textMuted,
    required this.shimmer1,
    required this.shimmer2,
    required this.emerald,
    required this.purple,
    required this.orange,
    required this.error,
    required this.success,
    required this.navBg,
    required this.onPrimary,
  });

  /// Light palette — warm neutrals.
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

  /// Dark palette — warm dark surfaces with the same emerald accent.
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

  @override
  AppPalette copyWith({
    Color? primary,
    Color? primaryHover,
    Color? bgColor,
    Color? cardBg,
    Color? cardBorder,
    Color? textMain,
    Color? textMuted,
    Color? shimmer1,
    Color? shimmer2,
    Color? emerald,
    Color? purple,
    Color? orange,
    Color? error,
    Color? success,
    Color? navBg,
    Color? onPrimary,
  }) =>
      AppPalette(
        primary: primary ?? this.primary,
        primaryHover: primaryHover ?? this.primaryHover,
        bgColor: bgColor ?? this.bgColor,
        cardBg: cardBg ?? this.cardBg,
        cardBorder: cardBorder ?? this.cardBorder,
        textMain: textMain ?? this.textMain,
        textMuted: textMuted ?? this.textMuted,
        shimmer1: shimmer1 ?? this.shimmer1,
        shimmer2: shimmer2 ?? this.shimmer2,
        emerald: emerald ?? this.emerald,
        purple: purple ?? this.purple,
        orange: orange ?? this.orange,
        error: error ?? this.error,
        success: success ?? this.success,
        navBg: navBg ?? this.navBg,
        onPrimary: onPrimary ?? this.onPrimary,
      );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryHover: Color.lerp(primaryHover, other.primaryHover, t)!,
      bgColor: Color.lerp(bgColor, other.bgColor, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textMain: Color.lerp(textMain, other.textMain, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      shimmer1: Color.lerp(shimmer1, other.shimmer1, t)!,
      shimmer2: Color.lerp(shimmer2, other.shimmer2, t)!,
      emerald: Color.lerp(emerald, other.emerald, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      error: Color.lerp(error, other.error, t)!,
      success: Color.lerp(success, other.success, t)!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
    );
  }
}

class AppTheme {
  static ThemeData get light {
    const p = AppPalette.light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: p.bgColor,
      primaryColor: p.primary,
      extensions: const [AppPalette.light],

      colorScheme: ColorScheme.light(
        primary: p.primary,
        secondary: p.primary,
        surface: p.cardBg,
        error: p.error,
        onPrimary: p.onPrimary,
        onSurface: p.textMain,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: p.textMain,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: p.textMain),
      ),

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

      cardTheme: CardThemeData(
        color: p.cardBg,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md), // 16
          side: BorderSide(color: p.cardBorder, width: 1),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 8,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textMuted,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.cardBg,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static ThemeData get dark {
    const p = AppPalette.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: p.bgColor,
      primaryColor: p.primary,
      extensions: const [AppPalette.dark],

      colorScheme: ColorScheme.dark(
        primary: p.primary,
        secondary: p.primary,
        surface: p.cardBg,
        error: p.error,
        onPrimary: p.onPrimary,
        onSurface: p.textMain,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: p.textMain,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: p.textMain),
      ),

      textTheme: GoogleFonts.spaceGroteskTextTheme(
        ThemeData(brightness: Brightness.dark).textTheme,
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

      cardTheme: CardThemeData(
        color: p.cardBg,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md), // 16
          side: BorderSide(color: p.cardBorder, width: 1),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        elevation: 8,
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: p.primary,
        unselectedItemColor: p.textMuted,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.cardBg,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

/// DEPRECATED static colour aliases. These always return the LIGHT palette and
/// do NOT respond to theme changes. New code must obtain colours from
/// `Theme.of(context).extension<AppPalette>()!`. Retained temporarily so the
/// migration can proceed file-by-file without breaking compilation.
@Deprecated('Use Theme.of(context).extension<AppPalette>()! instead.')
class AppColors {
  static const primary = Color(0xFF10B981);
  static const primaryDark = Color(0xFF059669);
  static const primaryLight = Color(0xFFECFDF5);
  static const background = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textMuted = Color(0xFF9CA3AF);
  static const border = Color(0xFFE5E7EB);
  static const error = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);
  // Legacy neumorphic
  static const lightBg = Color(0xFFF9FAFB);
  static const lightShadowDark = Color(0xFFD1D5DB);
  static const lightShadowLight = Color(0xFFFFFFFF);
  static const darkBg = Color(0xFF1E293B);
  static const darkShadowDark = Color(0xFF0F172A);
  static const darkShadowLight = Color(0xFF334155);
  static const lightTextPrimary = Color(0xFF111827);
  static const darkTextPrimary = Color(0xFFF9FAFB);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const darkTextSecondary = Color(0xFF9CA3AF);

  // Convenience accessors that read the active palette from context. These let
  // widgets migrate incrementally: replace `AppColors.textPrimary` with
  // `AppColors.textPrimaryOf(context)`.
  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? AppPalette.light;
}

/// DEPRECATED. Use `Theme.of(context).extension<AppPalette>()!` instead.
@Deprecated('Use Theme.of(context).extension<AppPalette>()! instead.')
class MidnightColors {
  static const primary = AppColors.primary;
  static const primaryHover = AppColors.primaryDark;
  static const bgColor = AppColors.background;
  static const cardBg = AppColors.surface;
  static const cardBorder = AppColors.border;
  static const textMain = AppColors.textPrimary;
  static const textMuted = AppColors.textSecondary;
  static const shimmer1 = Color(0xFFF3F4F6);
  static const shimmer2 = Color(0xFFF9FAFB);
  static const emerald = Color(0xFF10B981);
  static const purple = Color(0xFF8B5CF6);
  static const orange = Color(0xFFF59E0B);
  static const error = AppColors.error;
  static const navBg = Color(0xFFFFFFFF);
}
