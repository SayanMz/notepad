import 'package:flutter/material.dart';

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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: TextField(
                  controller: titleController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Title',
                    hintStyle: TextStyle(color: Color(0xFF515151)),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
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
            width: MediaQuery.of(context).size.width * 0.5,
            child: Divider(
              thickness: 2,
              color: colorScheme.primary.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }
}