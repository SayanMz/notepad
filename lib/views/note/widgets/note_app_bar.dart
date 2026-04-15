import 'package:flutter/material.dart';

/// AppBar for NotePage
///
/// RESPONSIBILITIES:
/// - Display title
/// - Provide edit mode toggle
/// - Expose undo/redo actions
///
/// DESIGN:
/// - Stateless (no internal state)
/// - Does NOT depend on editor/controller directly
/// - Uses callbacks → keeps separation clean
class NoteAppBar extends StatelessWidget implements PreferredSizeWidget {
  const NoteAppBar({
    super.key,
    required this.isEditing,
    required this.onToggleEdit,
    required this.onUndo,
    required this.onRedo,
    required this.canUndo, // ADD THIS
    required this.canRedo, // ADD THIS
  });

  final bool isEditing;
  final VoidCallback onToggleEdit;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo; // ADD THIS
  final bool canRedo; // ADD THIS

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white : Theme.of(context).colorScheme.onSurfaceVariant;

    return AppBar(
      //title: const Text('Note'),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: canUndo ? onUndo : null,
          color: canUndo ? iconColor : Colors.grey, // Reactive color
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          onPressed: canRedo ? onRedo : null,
          color: canRedo ? iconColor : Colors.grey, // Reactive color
        ),
      ],
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);
}