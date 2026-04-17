import 'package:flutter/material.dart';
import 'package:notepad/core/constants/ui_constants.dart';

class NoteHeader extends StatelessWidget {
  const NoteHeader({
    super.key,
    required this.titleController,
    required this.onToggleEdit,
    required this.isEditing,
  });

  final TextEditingController titleController;
  final VoidCallback onToggleEdit;
  final bool isEditing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: UIConstants.noteHeaderTitleSpacing),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UIConstants.headerTitlePaddingHorizontal,
                ),
                child: TextField(
                  controller: titleController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: UIConstants.headerTitleFontSize,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: UIConstants.noteHeaderTitleSpacing,
              child: IconButton(
                onPressed: onToggleEdit,
                icon: Icon(
                  Icons.auto_fix_high, // Restored original magic wand icon
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
          ],
        ),

        // Restored original centered half-divider
        Center(
          child: SizedBox(
            width:
                MediaQuery.of(context).size.width *
                UIConstants.headerWidthRatio,
            child: Divider(
              thickness: UIConstants.headerUnderlineThickness,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}
