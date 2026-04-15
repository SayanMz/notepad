
/// Centralized UI constants to eliminate magic numbers and
/// enforce consistency across the app.
///
/// RULE:
/// - Values here should represent design decisions, not arbitrary numbers.
class UIConstants {
  UIConstants._(); // prevent instantiation

  // ======================
  // Animation Durations
  // ======================

  static const Duration animationFast =
      Duration(milliseconds: 200);

  static const Duration animationMedium =
      Duration(milliseconds: 300);

  static const Duration animationSlow =
      Duration(milliseconds: 400);

  // ======================
  // Spacing
  // ======================

  static const double paddingXS = 4.0;
  static const double paddingXL = 24.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 12.0;
  static const double paddingLG = 16.0;

  // ======================
  // Border Radius
  // ======================

  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 30.0;

  // ======================
  // Elevation
  // ======================

  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;

  // ======================
  // Icon Sizes
  // ======================

  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 28.0;

  // ======================
  // Layout
  // ======================

  static const double listPadding = 12.0;
  static const double cardVerticalMargin = 8.0;
}