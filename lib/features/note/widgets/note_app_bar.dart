import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/features/note/widgets/save_indicator.dart';

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
    required this.canUndo,
    required this.canRedo,
    required this.saveState,
    required this.contentController,
  });

  final bool isEditing;
  final VoidCallback onToggleEdit;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final bool canUndo;
  final bool canRedo;
  final ValueNotifier<SaveState> saveState;
  final QuillController contentController;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return AppBar(
      title: const Text('Note'),
      centerTitle: true,
      actions: [
        /// SAVE INDICATOR (isolated, efficient)
        Padding(
          padding: const EdgeInsets.only(right: UIConstants.paddingSM),
          child: SaveIndicator(saveState: saveState),
        ),
        IconButton(
          icon: const Icon(Icons.undo),
          onPressed: contentController.hasUndo
              ? () => contentController.undo()
              : null,
          color: canUndo ? iconColor : Colors.grey, // Reactive color
        ),
        IconButton(
          icon: const Icon(Icons.redo),
          onPressed: contentController.hasRedo
              ? () => contentController.redo()
              : null,
          color: canRedo ? iconColor : Colors.grey, // Reactive color
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
