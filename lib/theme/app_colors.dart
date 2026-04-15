import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// CENTRALIZED COLOR SYSTEM
/// ---------------------------------------------------------------------------
///
/// PURPOSE:
/// - Avoid hardcoded color duplication across the app
/// - Ensure consistency in branding and theming
/// - Simplify future design updates
///
/// USAGE:
/// - Refer to these constants instead of raw Color(...) values

class AppColors {
  // Primary brand colors
  static const teal = Color(0xFF14B8A6);
  static const tealDark = Color(0xFF0D9488);

  // Light theme backgrounds
  static const lightScaffold = Color(0xFFF0FDF4);

  // Dark theme backgrounds (AMOLED optimized)
  static const darkScaffold = Color(0xFF09090B);
  static const darkSurface = Color(0xFF18181B);
  static const darkCard = Color(0xFF1C1C1E);
  static const darkElevated = Color(0xFF27272A);

  // Borders
  static const lightBorder = Color(0xFFE4E4E7);

  // Accent colors
  static const amber = Colors.amberAccent;
  static const amberSecondary = Color(0xFFFFD54F);

  // Text
  static const lightText = Colors.black;
  static const darkText = Color(0xFFF4F4F5);

///For Dismissible widget - 
///Light and dark theme
// Background
static const deleteLightBg = Color(0xFFFEE2E2); // soft red (Tailwind-like)
static const deleteDarkBg = Color(0xFF3F1D1D); // muted deep red
// Icon / Accent

static const deleteLightIcon = Color(0xFFDC2626); // strong red
static const deleteDarkIcon = Color(0xFFFF6B6B); // bright contrast red
}