import 'package:flutter/material.dart';

class StorageProgressBar extends StatelessWidget {
  /// A value between 0.0 and 1.0 representing the fill percentage.
  final double progress;

  /// The color of both the border and the inner fill.
  final Color color;

  /// The total height of the progress bar.
  final double height;

  const StorageProgressBar({
    super.key,
    required this.progress,
    this.color = const Color(0xFF64B5F6), // A standard Material light blue
    this.height = 32.0, // Matches the chunky look of your image
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    // 1. The Outer Track (Border)
    return Container(
      height: height,
      width: double.infinity, // Fills available horizontal space
      padding: const EdgeInsets.all(
        4.0,
      ), // Creates the gap between border and fill
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: isDark ? colorScheme.primary : color,
          width: 3.0, // Thickness of the outer ring
        ),
        borderRadius: BorderRadius.circular(height / 2), // Perfect pill shape
      ),

      // 2. The Inner Fill
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          // Clamps the value to ensure it never breaks out of the bar
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Color(0xFFFFFFFF) : colorScheme.primary,
              // The inner radius needs to be slightly smaller than the outer radius
              borderRadius: BorderRadius.circular((height - 8) / 2),
            ),
          ),
        ),
      ),
    );
  }
}
