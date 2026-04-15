import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

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
  @override
  Widget build(BuildContext context) {
    return QuillEditor(
      controller: widget.controller,
      focusNode: widget.focusNode,
      scrollController: widget.scrollController,
      config: const QuillEditorConfig(
        expands: true,
        padding: EdgeInsets.symmetric(horizontal: 12),
        placeholder: 'Start typing your note...',
        customStyles: DefaultStyles(
          placeHolder: DefaultTextBlockStyle(
            TextStyle(
              fontSize: 18,
              color: Color(0xFF515151),
            ),
        HorizontalSpacing(0, 0),
        VerticalSpacing(0, 0),
        VerticalSpacing(0, 0),
                null)
        )
      ),
    );
  }
}