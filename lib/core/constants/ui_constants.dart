
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

  static const Duration animationExtraSlow =
      Duration(milliseconds: 500);

  static const Duration debounceStandard =
      Duration(milliseconds: 300);

  static const Duration saveIndicatorDuration =
      Duration(seconds: 3);

  static const Duration snackbarShort =
      Duration(seconds: 2);

  // ======================
  // Spacing
  // ======================

  static const double paddingXS = 4.0;
  static const double paddingXXS = 2.0;
  static const double paddingS = 6.0;
  static const double paddingM = 10.0;
  static const double paddingXL = 24.0;
  static const double paddingSM = 8.0;
  static const double paddingXLarge = 20.0;
  static const double paddingMD = 12.0;
  static const double paddingLG = 16.0;
  static const double paddingXXL = 32.0;

  // ======================
  // Border Radius
  // ======================

  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusXL = 30.0;
  static const double radiusTiny = 4.0;

  // ======================
  // Elevation
  // ======================

  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 6.0;

  // ======================
  // Icon Sizes
  // ======================

  static const double iconXS = 14.0;
  static const double iconSM = 20.0;
  static const double iconSmall = 16.0;
  static const double iconMD = 24.0;
  static const double iconLG = 28.0;
  static const double iconXL = 48.0;

  // ======================
  // Layout
  // ======================

  static const double listPadding = 12.0;
  static const double cardVerticalMargin = 8.0;
  static const double progressBarHeight = 2.0;
  static const double toolbarMarginHorizontal = 15.0;
  static const double toolbarMarginTop = 8.0;
  static const double toolbarVerticalPadding = 4.0;
  static const double toolbarBlurSigma = 12.0;
  static const double toolbarShadowBlur = 10.0;
  static const double toolbarShadowOffsetY = 4.0;
  static const double toolbarBorderWidth = 1.0;
  static const double toolbarSizeMenuOffsetX = 35.0;
  static const double toolbarColorMenuOffsetX = 60.0;
  static const double toolbarMenuWidth = 150.0;
  static const double toolbarSizeMenuHorizontalPadding = 7.0;
  static const double toolbarColorCircleSize = 30.0;
  static const double toolbarColorCircleMargin = 6.0;
  static const double toolbarColorCircleBorderWidth = 2.0;
  static const double toolbarDividerWidth = 20.0;
  static const double toolbarDividerHeight = 24.0;
  static const double toolbarDividerThickness = 1.0;
  static const double headerSideSpacer = 60.0;
  static const double headerTitlePaddingHorizontal = 15.0;
  static const double headerTitleFontSize = 22.0;
  static const double headerUnderlineThickness = 2.0;
  static const double headerWidthRatio = 0.5;
  static const double saveIndicatorSpinnerSize = 14.0;
  static const double saveIndicatorIconSize = 16.0;
  static const double saveIndicatorTextFontSize = 12.0;
  static const double saveIndicatorSpacingTiny = 4.0;
  static const double saveIndicatorSpacingSmall = 6.0;
  static const double saveIndicatorTop = 10.0;
  static const double saveIndicatorRight = 16.0;
  static const double searchFieldPadding = 20.0;
  static const double searchFieldContentPaddingV = 12.0;
  static const double searchFieldContentPaddingH = 20.0;
  static const double searchFieldBorderWidth = 1.5;
  static const double searchResultCardMargin = 12.0;
  static const double searchResultListPadding = 16.0;
  static const double searchResultSnippetFontSize = 16.0;
  static const double searchResultSnippetHeight = 1.25;
  static const double searchEmptyHorizontalPadding = 32.0;
  static const double searchEmptyIconSize = 48.0;
  static const double searchEmptyTitleFontSize = 18.0;
  static const double searchEmptyTitleGap = 12.0;
  static const double searchEmptySubtitleGap = 6.0;
  static const double recycleSheetRadius = 20.0;
  static const double recycleEmptyLottieHeight = 200.0;
  static const double recycleListPadding = 12.0;
  static const double recycleCardMargin = 4.0;
  static const double recycleCardRadius = 12.0;
  static const double recycleCardPadding = 16.0;
  static const double recycleIconSize = 28.0;
  static const double recycleEmptyTextFontSize = 18.0;
  static const double noteCardPreviewHeight = 250.0;
  static const double noteCardPreviewTitleFontSize = 20.0;
  static const double noteCardTitleFontSize = 16.0;
  static const double noteCardEditedFontSize = 12.0;
  static const double noteCardBulletSize = 5.0;
  static const double noteCardBulletRightPadding = 10.0;
  static const double noteCardBulletTopPadding = 7.0;
  static const double noteCardPreviewMaxWidthBreakpoint = 600.0;
  static const double noteCardPreviewDesktopBreakpoint = 1200.0;
  static const double noteCardPreviewTabletBreakpoint = 900.0;
  static const int noteCardPreviewLargeDesktopLines = 12;
  static const int noteCardPreviewTabletLines = 8;
  static const int noteCardPreviewSmallTabletLines = 5;
  static const int noteCardPreviewPhoneLines = 2;
  static const double editorHorizontalPadding = 12.0;
  static const double editorFontSize = 18.0;
  static const double noteHeaderTitleSpacing = 60.0;
  static const double selectionBorderWidth = 2.0;
  static const double noteCardPreviewFontSize = 13.0;
  static const double noteCardPreviewLineHeightCompact = 1.2;
  static const double noteCardPreviewLineHeightExpanded = 1.5;
  static const double routeSlideInBeginX = 1.0;
  static const double routeSlideOutEndX = -0.2;
  static const double pinnedScale = 1.2;
}
