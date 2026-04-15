import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class NoteToolbar extends StatelessWidget {
  const NoteToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onConvertToLink,
  });

  final QuillController controller;
  final FocusNode focusNode;
  final Future<void> Function() onConvertToLink;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Restored: Returning a Column containing TWO separate glass toolbars
    return Column(
      children: [
        _buildRawGlassToolbar(context, [
          _buildRawToggle(context, Icons.format_bold, Attribute.bold),
          _buildRawToggle(context, Icons.format_italic, Attribute.italic),
          _buildRawToggle(
            context,
            Icons.format_underlined,
            Attribute.underline,
          ),
          _buildRawAlignmentMenu(context),
        ]),
        _buildRawGlassToolbar(context, [
          _buildRawSizeMenu(context),
          _buildRawColorMenu(context),
          _buildRawListMenu(context),
          IconButton(
            icon: Icon(
              Icons.link,
              color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
            ),
            onPressed: onConvertToLink,
          ),
        ]),
        const SizedBox(height: 10),
      ],
    );
  }

  // --- UI Helpers for Styling Bar ---

  Widget _buildRawGlassToolbar(BuildContext context, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(15, 8, 15, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.7),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRawToggle(BuildContext context, IconData icon, Attribute attr) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final isSelected = controller
            .getSelectionStyle()
            .attributes
            .containsKey(attr.key);
        return IconButton(
          icon: Icon(
            icon,
            color: isSelected
                ? Colors.blueAccent
                : (isDark
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          onPressed: () {
            focusNode.requestFocus();
            controller.formatSelection(
              isSelected ? Attribute.clone(attr, null) : attr,
            );
          },
        );
      },
    );
  }

  Widget _buildRawAlignmentMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      builder: (context, menuController, child) => IconButton(
        icon: Icon(
          Icons.format_align_justify,
          color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
        ),
        onPressed: () => menuController.isOpen
            ? menuController.close()
            : menuController.open(),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: Icon(
            Icons.format_align_left,
            color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
          ),
          onPressed: () => controller.formatSelection(Attribute.leftAlignment),
          child: const Text('Left'),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.format_align_center,
            color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
          ),
          onPressed: () =>
              controller.formatSelection(Attribute.centerAlignment),
          child: const Text('Center'),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.format_align_right,
            color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
          ),
          onPressed: () => controller.formatSelection(Attribute.rightAlignment),
          child: const Text('Right'),
        ),
      ],
    );
  }

  Widget _buildRawSizeMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      alignmentOffset: const Offset(-35, 0),
      builder: (context, menuController, child) => IconButton(
        icon: Icon(
          Icons.text_fields,
          color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
        ),
        onPressed: () => menuController.isOpen
            ? menuController.close()
            : menuController.open(),
      ),
      menuChildren: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.text_increase,
                  color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _changeTextSize(increase: true),
              ),
              SizedBox(
                height: 24,
                child: VerticalDivider(
                  width: 20,
                  thickness: 1,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.text_decrease,
                  color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _changeTextSize(increase: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRawColorMenu(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(-60, 0),
      builder: (context, menuController, child) => IconButton(
        icon: const Icon(Icons.palette, color: Colors.redAccent),
        onPressed: () => menuController.isOpen
            ? menuController.close()
            : menuController.open(),
      ),
      menuChildren: [
        SizedBox(
          width: 150,
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              Colors.black,
              Colors.red,
              Colors.blue,
              Colors.green,
              Colors.orange,
              Colors.purple,
            ].map((color) => _buildColorCircle(color)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorCircle(Color color) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final hexString = '#${color.toARGB32().toRadixString(16).substring(2)}';
        final bool isSelected =
            controller.getSelectionStyle().attributes['color']?.value ==
            hexString;
        return GestureDetector(
          onTap: () {
            final colorAttr = ColorAttribute(hexString);
            if (controller.selection.isCollapsed) {
              controller.formatSelection(colorAttr);
            } else {
              controller.formatText(
                controller.selection.start,
                controller.selection.end - controller.selection.start,
                colorAttr,
              );
            }
            focusNode.requestFocus();
          },
          child: Container(
            margin: const EdgeInsets.all(6),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.lightGreenAccent : Colors.white,
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRawListMenu(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return MenuAnchor(
      builder: (context, menuController, child) => IconButton(
        icon: Icon(
          Icons.format_list_bulleted,
          color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
        ),
        onPressed: () => menuController.isOpen
            ? menuController.close()
            : menuController.open(),
      ),
      menuChildren: [
        MenuItemButton(
          leadingIcon: Icon(
            Icons.format_list_bulleted,
            color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
          ),
          onPressed: () => _toggleListAttribute(Attribute.ul),
          child: const Text('Bullets'),
        ),
        MenuItemButton(
          leadingIcon: Icon(
            Icons.format_list_numbered,
            color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
          ),
          onPressed: () => _toggleListAttribute(Attribute.ol),
          child: const Text('Numbers'),
        ),
      ],
    );
  }

  void _changeTextSize({required bool increase}) {
    final attrs = controller.getSelectionStyle().attributes;
    var currentSize = 16.0;
    if (attrs.containsKey('size')) {
      currentSize = double.tryParse(attrs['size']!.value.toString()) ?? 16.0;
    }
    final newSize = (increase ? currentSize + 15 : currentSize - 15).clamp(
      15.0,
      100.0,
    );
    final sizeAttr = Attribute.fromKeyValue('size', newSize);
    if (controller.selection.isCollapsed) {
      controller.formatSelection(sizeAttr);
    } else {
      controller.formatText(
        controller.selection.start,
        controller.selection.end - controller.selection.start,
        sizeAttr,
      );
    }
    focusNode.requestFocus();
  }


void _toggleListAttribute(Attribute attribute) {
  focusNode.requestFocus();

  final selection = controller.selection;
  final style = controller.getSelectionStyle();
  final currentList = style.attributes['list'];

  // 1. STANDARD BEHAVIOR: If the user manually highlighted multiple lines, 
  // respect their exact selection.
  if (!selection.isCollapsed) {
    if (currentList?.value == attribute.value) {
      controller.formatSelection(Attribute.clone(Attribute.list, null));
    } else {
      controller.formatSelection(attribute);
    }
    return;
  }

  // 2. THE LEGENDARY FIX: Target the entire connected block
  final offset = selection.baseOffset;
  
  // Grab the current line node based on the cursor position
  final line = controller.document.queryChild(offset).node;

  // In flutter_quill, list items are wrapped in a parent 'Block' container
  if (line != null && line.parent != null) {
    final parent = line.parent!;

    // Check if the parent is a list block. If it is, we found our boundaries!
    if (parent.style.attributes.containsKey('list')) {
      final blockStart = parent.documentOffset;
      final blockLength = parent.length ; //parent.length - 1;

      if (currentList?.value == attribute.value) {
        // Toggle OFF: Remove the list formatting from the entire block
        controller.formatText(
          blockStart, 
          blockLength, 
          Attribute.clone(Attribute.list, null)
        );
      } else {
        // Toggle ON / SWITCH: Apply the new list type (e.g. bullets to numbers) 
        // to the entire block at once
        controller.formatText(blockStart, blockLength, attribute);
      }

      // Re-apply the cursor position so it doesn't jump around
      controller.updateSelection(selection, ChangeSource.local);
      return;
    }
  }

  // 3. FALLBACK: If we are creating a brand new list (not currently in a block)
  if (currentList?.value == attribute.value) {
    controller.formatSelection(Attribute.clone(Attribute.list, null));
  } else {
    controller.formatSelection(attribute);
  }
}
}