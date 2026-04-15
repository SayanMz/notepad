import 'package:flutter/material.dart';
import 'package:notepad/constants/ui_constants.dart';

/// ---------------------------------------------------------------------------
/// SELECTION TOOLBAR
/// ---------------------------------------------------------------------------
///
/// RESPONSIBILITIES:
/// - Displays bulk selection controls
/// - Select All checkbox
/// - Bulk actions (share, delete)
///
/// DESIGN:
/// - Stateless and reusable
/// - Fully controlled via parameters (no internal state)
class SelectionToolbar extends StatelessWidget {
  const SelectionToolbar({
    super.key,
    required this.isDark,
    required this.allSelected,
    required this.onSelectAll,
    required this.onShare,
    required this.onDelete,
  });

  final bool isDark;
  final bool allSelected;

  /// Callback: toggle select all
  final ValueChanged<bool> onSelectAll;

  /// Callback: share selected notes
  final VoidCallback onShare;

  /// Callback: delete selected notes
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
        final iconColor = isDark
    ? Colors.white
    : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.all(UIConstants.paddingSM),
      child: Row(
        children: [
          /// Select All Checkbox
          Checkbox(
            side: BorderSide(
              color: iconColor,
              width: 2,
            ),
            value: allSelected,
            onChanged: (value) => onSelectAll(value ?? false),
          ),

          const Text('Select All'),

          const Spacer(),

          /// Share button
          IconButton(
            icon: Icon(
              Icons.share,
              size: UIConstants.iconMD,
              color: iconColor,
            ),
            onPressed: onShare,
          ),

          /// Delete button
          IconButton(
            icon: Icon(
              Icons.delete,
              size: UIConstants.iconMD,
              color: iconColor,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}