import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notepad/core/constants/ui_constants.dart';

class NoteToolbar extends StatelessWidget {
  const NoteToolbar({
    super.key,
    required this.controller,
    required this.focusNode,
    //required this.onConvertToLink,
  });

  final QuillController controller;
  final FocusNode focusNode;
  //final Future<void> Function() onConvertToLink;

  @override
  Widget build(BuildContext context) {
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
          _buildRawToggle(
            context,
            Icons.format_strikethrough,
            Attribute.strikeThrough,
          ),
        ]),
        _buildRawGlassToolbar(context, [
          _buildRawSizeMenu(context),
          _buildRawColorMenu(context),
          _buildRawListMenu(context),
          _buildRawAlignmentMenu(context, controller),
          // IconButton(
          //   icon: Icon(
          //     Icons.link,
          //     color: isDark ? Colors.white : colorScheme.onSurfaceVariant,
          //   ),
          //   onPressed: onConvertToLink,
          // ),
        ]),
        const SizedBox(height: UIConstants.paddingM),
      ],
    );
  }

  // --- UI Helpers for Styling Bar ---

  Widget _buildRawGlassToolbar(BuildContext context, List<Widget> children) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        UIConstants.toolbarMarginHorizontal,
        UIConstants.toolbarMarginTop,
        UIConstants.toolbarMarginHorizontal,
        0,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(UIConstants.radiusMD),
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.7),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: UIConstants.toolbarBorderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: UIConstants.toolbarShadowBlur,
            offset: const Offset(0, UIConstants.toolbarShadowOffsetY),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(UIConstants.radiusMD),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: UIConstants.toolbarBlurSigma,
            sigmaY: UIConstants.toolbarBlurSigma,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: UIConstants.toolbarVerticalPadding,
            ),
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

  Widget _buildRawSizeMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    return MenuAnchor(
      alignmentOffset: const Offset(-UIConstants.toolbarSizeMenuOffsetX, 0),
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
          padding: const EdgeInsets.symmetric(
            horizontal: UIConstants.toolbarSizeMenuHorizontalPadding,
          ),
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
                height: UIConstants.toolbarDividerHeight,
                child: VerticalDivider(
                  width: UIConstants.toolbarDividerWidth,
                  thickness: UIConstants.toolbarDividerThickness,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MenuAnchor(
      alignmentOffset: const Offset(-UIConstants.toolbarColorMenuOffsetX, 0),
      builder: (context, menuController, child) => IconButton(
        icon: const Icon(Icons.palette, color: Colors.redAccent),
        onPressed: () => menuController.isOpen
            ? menuController.close()
            : menuController.open(),
      ),
      menuChildren: [
        SizedBox(
          width: UIConstants.toolbarMenuWidth,
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [
              _buildColorCircle(
                isDark ? Colors.white : Colors.black,
                isDefault: true,
              ),
              _buildColorCircle(Colors.red),
              _buildColorCircle(Colors.blue),
              _buildColorCircle(Colors.green),
              _buildColorCircle(Colors.orange),
              _buildColorCircle(Colors.purple),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildColorCircle(Color color, {bool isDefault = false}) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final hexString = '#${color.toARGB32().toRadixString(16).substring(2)}';
        final bool isSelected = isDefault
            ? controller.getSelectionStyle().attributes['color'] == null
            : controller.getSelectionStyle().attributes['color']?.value ==
                  hexString;
        return GestureDetector(
          onTap: () {
            final colorAttr = isDefault
                ? Attribute.fromKeyValue('color', null)
                : ColorAttribute(hexString);
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
            margin: const EdgeInsets.all(UIConstants.toolbarColorCircleMargin),
            width: UIConstants.toolbarColorCircleSize,
            height: UIConstants.toolbarColorCircleSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.lightGreenAccent : Colors.white,
                width: UIConstants.toolbarColorCircleBorderWidth,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRawListMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        // Get the current list attribute value (e.g., 'ul' or 'ol')
        final currentList = controller
            .getSelectionStyle()
            .attributes['list']
            ?.value;

        final bool isListActive = currentList != null;

        return MenuAnchor(
          builder: (context, menuController, child) => IconButton(
            icon: Icon(
              Icons.format_list_bulleted,
              color: (menuController.isOpen || isListActive)
                  ? Colors.blueAccent
                  : (isDark ? Colors.white : colorScheme.onSurfaceVariant),
            ),
            onPressed: () => menuController.isOpen
                ? menuController.close()
                : menuController.open(),
          ),
          menuChildren: [
            _buildListItem(
              context,
              Icons.format_list_bulleted,
              'Bullets',
              isDark,
              currentList,
              Attribute.ul,
              colorScheme,
            ),
            _buildListItem(
              context,
              Icons.format_list_numbered,
              'Numbers',
              isDark,
              currentList,
              Attribute.ol,
              colorScheme,
            ),
          ],
        );
      },
    );
  }

  Widget _buildListItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isDark,
    dynamic currentList,
    Attribute attr,
    ColorScheme colorScheme,
  ) {
    // Check if this specific list type is active
    final isSelected = currentList == attr.value;
    // Highlighting: Amber for Dark mode, Teal for Light mode

    final defaultColor = isDark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return MenuItemButton(
      style: ButtonStyle(
        iconColor: WidgetStateProperty.resolveWith((states) {
          if (isSelected) {
            return colorScheme.primary;
          }
          if (states.contains(WidgetState.pressed)) {
            return colorScheme.primary;
          }
          return defaultColor;
        }),
      ),
      leadingIcon: Icon(icon),
      onPressed: () => _toggleListAttribute(attr), // Uses your existing logic
      child: Text(label),
    );
  }

  void _changeTextSize({required bool increase}) {
    final attrs = controller.getSelectionStyle().attributes;
    var currentSize = 16.0;
    if (attrs.containsKey('size')) {
      currentSize = double.tryParse(attrs['size']!.value.toString()) ?? 16.0;
    }
    final newSize = (increase ? currentSize + 5 : currentSize - 5).clamp(
      15.0,
      80.0,
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

    //  STANDARD BEHAVIOR
    if (!selection.isCollapsed) {
      if (currentList?.value == attribute.value) {
        controller.formatSelection(Attribute.clone(Attribute.list, null));
      } else {
        controller.formatSelection(attribute);
      }
      return;
    }

    final offset = selection.baseOffset;
    final line = controller.document.queryChild(offset).node;

    if (line != null && line.parent != null) {
      final parent = line.parent!;

      if (parent.style.attributes.containsKey('list')) {
        final blockStart = parent.documentOffset;
        final blockLength = parent.length;

        if (currentList?.value == attribute.value) {
          // Toggle OFF: Remove formatting from the document row
          controller.formatText(
            line.documentOffset,
            line.length,
            Attribute.clone(Attribute.list, null),
          );

          controller.formatSelection(Attribute.clone(Attribute.list, null));
        } else {
          // Toggle ON / SWITCH: Apply new list type to the entire document block
          controller.formatText(blockStart, blockLength, attribute);

          controller.formatSelection(attribute);
        }

        return; // updateSelection is no longer needed, formatSelection handles it
      }
    }

    // 3. FALLBACK
    if (currentList?.value == attribute.value) {
      controller.formatSelection(Attribute.clone(Attribute.list, null));
    } else {
      controller.formatSelection(attribute);
    }
  }

  Widget _buildRawAlignmentMenu(
    BuildContext context,
    QuillController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final currentAlign = controller
            .getSelectionStyle()
            .attributes[Attribute.align.key]
            ?.value;

        return MenuAnchor(
          builder: (context, menuController, child) => IconButton(
            icon: const Icon(
              Icons.format_align_justify,
              color: Colors.blueAccent,
            ),
            onPressed: () => menuController.isOpen
                ? menuController.close()
                : menuController.open(),
          ),
          menuChildren: [
            _buildAlignmentItem(
              context,
              Icons.format_align_left,
              'left',
              'Left',
              isDark,
              currentAlign,
            ),
            _buildAlignmentItem(
              context,
              Icons.format_align_center,
              'center',
              'Center',
              isDark,
              currentAlign,
            ),
            _buildAlignmentItem(
              context,
              Icons.format_align_right,
              'right',
              'Right',
              isDark,
              currentAlign,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlignmentItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    bool isDark,
    dynamic currentAlign,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final bool isSelected =
        (currentAlign == value) || (currentAlign == null && value == 'left');

    final activeColor = colorScheme.primary;
    final defaultColor = isDark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return MenuItemButton(
      leadingIcon: Icon(icon, color: isSelected ? activeColor : defaultColor),
      onPressed: () => controller.formatSelection(
        value == 'left'
            ? Attribute.leftAlignment
            : value == 'center'
            ? Attribute.centerAlignment
            : Attribute.rightAlignment,
      ),
      child: Text(label),
    );
  }
}
