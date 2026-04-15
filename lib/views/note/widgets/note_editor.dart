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
      ),
    );
  }
}