import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ---------------------------------------------------------------------------
/// LIGHT THEME DEFINITION
/// ---------------------------------------------------------------------------
///
/// DESIGN GOALS:
/// - Clean, minimal, soft UI
/// - Teal-based branding
/// - Subtle elevation and borders for structure

class LightTheme {
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    /// Global shadow styling
    shadowColor: AppColors.tealDark.withValues(alpha: 0.4),

    /// Text selection (cursor + highlight)
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.teal,
      selectionColor: AppColors.teal.withValues(alpha: 0.3),
      selectionHandleColor: AppColors.teal,
    ),

    /// Input field styling
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
      ),
    ),

    /// Background
    scaffoldBackgroundColor: AppColors.lightScaffold,

    /// AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightScaffold,
    ),

    /// Material 3 Color System
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.light,
      primary: AppColors.teal,
      surface: Colors.white,
    ),

    /// Cards
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.lightBorder, width: 1.5),
      ),
    ),

    /// Floating Action Button
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.tealDark,
      foregroundColor: Colors.white,
      elevation: 2,
      highlightElevation: 4,
    ),
  );
}
