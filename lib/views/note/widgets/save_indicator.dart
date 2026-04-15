import 'package:flutter/material.dart';

/// ---------------------------------------------------------------------------
/// SAVE STATE ENUM
/// ---------------------------------------------------------------------------
enum SaveState {
  idle,
  saving,
  saved,
}

/// ---------------------------------------------------------------------------
/// SAVE INDICATOR WIDGET
/// ---------------------------------------------------------------------------
///
/// RESPONSIBILITY:
/// - Shows save status (Saving... → Saved ✓)
/// - Fully isolated → prevents unnecessary AppBar rebuilds
///
/// DESIGN:
/// - Uses ValueListenableBuilder for reactive updates
/// - AnimatedSwitcher for smooth transitions
class SaveIndicator extends StatelessWidget {
  const SaveIndicator({
    super.key,
    required this.saveState,
  });

  final ValueNotifier<SaveState> saveState;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SaveState>(
      valueListenable: saveState,
      builder: (context, state, _) {
        if (state == SaveState.idle) {
          return const SizedBox();
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),

          /// Smooth fade transition
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },

          child: state == SaveState.saving
              ? Row(
                  key: const ValueKey('saving'),
                  children: const [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 6),
                    Text(
                      "Saving...",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                )
              : Row(
                  key: const ValueKey('saved'),
                  children: const [
                    Icon(Icons.check, size: 16, color: Colors.green),
                    SizedBox(width: 4),
                    Text(
                      "Saved",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

              /*
              Improvement: Icons.sync → Icons.check
              Positioned(
  top: 10,
  right: 16,
  child: ...
)
              */