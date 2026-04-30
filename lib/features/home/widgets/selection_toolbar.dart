import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:notepad/core/constants/ui_constants.dart';

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
class SelectionToolbar extends StatefulWidget {
  const SelectionToolbar({
    super.key,
    required this.isDark,
    required this.allSelected,
    required this.onSelectAll,
    required this.onShare,
    required this.onDelete,
    required this.onColorChanged,
  });

  final bool isDark;
  final bool allSelected;

  /// Callback: toggle select all
  final ValueChanged<bool> onSelectAll;

  /// Callback: share selected notes
  final VoidCallback onShare;

  /// Callback: delete selected notes
  final VoidCallback onDelete;
  final Function(Color) onColorChanged;

  @override
  State<SelectionToolbar> createState() => _SelectionToolbarState();
}

class _SelectionToolbarState extends State<SelectionToolbar>
    with SingleTickerProviderStateMixin {
  ColorScheme get colorScheme => Theme.of(context).colorScheme;
  bool get isDark => Theme.of(context).brightness == Brightness.dark;
  // Track the custom color locally
  Color _currentSelectionColor = Colors.red;

  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // Initialize the controller to spin continuously over 4 seconds
    _rotationController = AnimationController(
      duration: const Duration(
        seconds: 10,
      ), // Increase for slower spin, decrease for faster
      vsync: this,
    )..repeat(); // .repeat() makes it loop infinitely while the toolbar is open
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white : colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.all(UIConstants.paddingSM),
      child: Row(
        children: [
          /// Select All Checkbox
          Checkbox(
            side: BorderSide(
              color: iconColor,
              width: UIConstants.selectionBorderWidth,
            ),
            value: widget.allSelected,
            onChanged: (value) => widget.onSelectAll(value ?? false),
          ),

          const Text('Select All'),

          const Spacer(),

          _buildColorCircle(),

          /// Share button
          IconButton(
            icon: Icon(Icons.share, size: UIConstants.iconMD, color: iconColor),
            onPressed: widget.onShare,
          ),

          /// Delete button
          IconButton(
            icon: Icon(
              Icons.delete,
              size: UIConstants.iconMD,
              color: iconColor,
            ),
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildColorCircle() {
    return GestureDetector(
      onTap: () {
        _openCustomColorPicker();
      },
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(
              horizontal: UIConstants.toolbarColorCircleMargin,
            ),
            width: UIConstants.iconMD,
            height: UIConstants.iconMD,
            decoration: BoxDecoration(
              // Use gradient for rainbow, solid color for others
              color: null,
              gradient: SweepGradient(
                transform: GradientRotation(
                  _rotationController.value * 2 * math.pi,
                ),
                colors: [
                  Color(0xFFBF616A), // Dusty Red
                  Color(0xFFD08770), // Soft Orange
                  Color(0xFFEBCB8B), // Warm Sand
                  Color(0xFFA3BE8C), // Sage Green
                  Color(0xFF81A1C1), // Frost Blue
                  Color(0xFFB48EAD), // Muted Lavender
                  Color(0xFFBF616A), // Dusty Red (closes the loop)
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    );
  }

  void _openCustomColorPicker() {
    Color temporaryColor = _currentSelectionColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batch change Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temporaryColor,
            onColorChanged: (color) => temporaryColor = color,
            pickerAreaHeightPercent: 0.7, // Balances height like your reference
            enableAlpha: false, // Standard hex only for Quill
            displayThumbColor: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _currentSelectionColor = temporaryColor);
              widget.onColorChanged(temporaryColor); // NOTIFY PARENT
              Navigator.pop(context);
            },
            child: const Text('Apply to selected'),
          ),
        ],
      ),
    );
  }
}
