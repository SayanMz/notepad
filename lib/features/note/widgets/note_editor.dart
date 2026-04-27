import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:url_launcher/url_launcher.dart';

class NoteEditor extends StatefulWidget {
  const NoteEditor({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
  });

  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;

  @override
  State<NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<NoteEditor> {
  Future<LinkMenuAction> _handleLinkActionPicker(
    BuildContext context,
    String link,
    Node node,
  ) async {
    final normalizedLink = link.trim();
    final uri = Uri.tryParse(normalizedLink);

    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return LinkMenuAction.none;
    }

    return LinkMenuAction.launch;
  }

  @override
  Widget build(BuildContext context) {
    return QuillEditor(
      controller: widget.controller,
      focusNode: widget.focusNode,
      scrollController: widget.scrollController,
      config: QuillEditorConfig(
        onLaunchUrl: (String url) async {
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        linkActionPickerDelegate: _handleLinkActionPicker,
        expands: true,
        padding: EdgeInsets.symmetric(
          horizontal: UIConstants.editorHorizontalPadding,
        ),
        placeholder: 'Start typing your note...',
        customStyles: DefaultStyles(
          placeHolder: DefaultTextBlockStyle(
            TextStyle(
              fontSize: UIConstants.editorFontSize,
              color: Color(0xFF515151),
            ),
            HorizontalSpacing(0, 0),
            VerticalSpacing(0, 0),
            VerticalSpacing(0, 0),
            null,
          ),
        ),
      ),
    );
  }
}
