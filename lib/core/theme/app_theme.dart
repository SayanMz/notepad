import 'light_theme.dart';
import 'dark_theme.dart';

/// ---------------------------------------------------------------------------
/// APP THEME ENTRY POINT
/// ---------------------------------------------------------------------------
///
/// PURPOSE:
/// - Provides a single import point for all theme configurations
/// - Simplifies usage in main.dart
///
/// USAGE:
/// theme: AppTheme.light
/// darkTheme: AppTheme.dark

class AppTheme {
  static final light = LightTheme.theme;
  static final dark = DarkTheme.theme;
}