import 'package:flutter/material.dart';

class AppColors {
  // Primary (Emerald Green)
  static const primary = Color(0xFF10B981);
  static const primaryDark = Color(0xFF059669);
  static const primaryLight = Color(0xFFECFDF5);

  // Background & Surface — Minimal White
  static const background = Color(0xFFF9FAFB); // gray-50, neutral off-white
  static const surface = Color(0xFFFFFFFF);    // pure white cards

  // Text
  static const textPrimary   = Color(0xFF111827); // gray-900
  static const textSecondary = Color(0xFF6B7280); // gray-500
  static const textMuted     = Color(0xFF9CA3AF); // gray-400

  // Border
  static const border = Color(0xFFE5E7EB); // gray-200, visible but subtle

  // Semantic
  static const error   = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);

  // Legacy neumorphic (kept for backward-compat, not actively used)
  static const lightBg          = Color(0xFFF9FAFB);
  static const lightShadowDark  = Color(0xFFD1D5DB);
  static const lightShadowLight = Color(0xFFFFFFFF);
  static const darkBg           = Color(0xFF1E293B);
  static const darkShadowDark   = Color(0xFF0F172A);
  static const darkShadowLight  = Color(0xFF334155);
  static const lightTextPrimary   = Color(0xFF111827);
  static const darkTextPrimary    = Color(0xFFF9FAFB);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const darkTextSecondary  = Color(0xFF9CA3AF);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.primary,

      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge:  TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static ThemeData get dark => light;
}

/// Alias class — tüm ekranlarda MidnightColors referansları bu
/// yeni minimal-white paletine otomatik olarak yönlendirilir.
class MidnightColors {
  static const primary      = AppColors.primary;
  static const primaryHover = AppColors.primaryDark;
  static const bgColor      = AppColors.background;
  static const cardBg       = AppColors.surface;
  static const cardBorder   = AppColors.border;
  static const textMain     = AppColors.textPrimary;
  static const textMuted    = AppColors.textSecondary;
  static const shimmer1     = Color(0xFFF3F4F6); // gray-100
  static const shimmer2     = Color(0xFFF9FAFB); // gray-50
  static const emerald      = Color(0xFF10B981);
  static const purple       = Color(0xFF8B5CF6);
  static const orange       = Color(0xFFF59E0B);
  static const error        = AppColors.error;
  static const navBg        = Color(0xFFFFFFFF);
}
