import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import 'package:notepad/constants/ui_constants.dart';
import 'package:notepad/data/note_repository.dart';
import 'package:notepad/services/note_document_service.dart';
import 'package:notepad/services/note_recovery_service.dart';
import 'package:notepad/views/note/controllers/note_controller.dart';
import 'package:notepad/views/note/widgets/note_app_bar.dart';
import 'package:notepad/views/note/widgets/note_editor.dart';
import 'package:notepad/views/note/widgets/note_header.dart';
import 'package:notepad/views/note/widgets/note_toolbar.dart';

class NotePage extends StatefulWidget {
  final String title, content;
  final String? noteId;

  const NotePage({super.key, this.noteId, this.title = '', this.content = ''});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  late final AppLifecycleListener _lifecycleListener;
  late final NoteController _noteController;

  late final TextEditingController titleController;
  late final QuillController contentController;

  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();

  String lastSavedSignature = '';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();

    // 1. Initialize Controller Layer
    _noteController = NoteController(
      recoveryService: NoteRecoveryService(),
      noteRepository: noteRepository,
      noteId: widget.noteId,
    );

    // 2. Load Note Data
    final note = widget.noteId == null ? null : noteRepository.findById(widget.noteId!);
    titleController = TextEditingController(text: note?.title ?? widget.title);

    if (note != null) {
      contentController = QuillController(
        document: Document.fromJson(
          NoteDocumentService.decodeRichContent(note.richContent, note.content),
        ),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else if (widget.content.isNotEmpty) {
      final recoveredDoc = Document()..insert(0, widget.content);
      contentController = QuillController(
        document: recoveredDoc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      contentController = QuillController.basic();
    }

    // 3. Attach Listeners
    titleController.addListener(_handleEditorChanged);
    contentController.addListener(_handleEditorChanged);

    _lifecycleListener = AppLifecycleListener(
      onInactive: _saveCurrentNote,
      onPause: _saveCurrentNote,
    );

    lastSavedSignature = contentController.document.toPlainText();
  }

  void _handleEditorChanged() {
    if (lastSavedSignature == contentController.document.toPlainText()) return;

    // Delegate all saving/debouncing logic to our new Controller
    _noteController.handleEditorChanged(
      title: titleController.text,
      document: contentController.document,
      save: _saveCurrentNote,
    );
  }

  Future<void> _saveCurrentNote() async {
    await _noteController.saveNote(
      title: titleController.text,
      document: contentController.document,
    );

    lastSavedSignature = contentController.document.toPlainText();
  }

  void _toggleEditMode() {
    setState(() => _isEditing = !_isEditing);
  }

  @override
  void dispose() {
    titleController.removeListener(_handleEditorChanged);
    titleController.dispose();

    contentController.removeListener(_handleEditorChanged);
    contentController.dispose();

    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    _lifecycleListener.dispose();
    _noteController.dispose(); // Clean up controller timers

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _saveCurrentNote();
      },
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8F9FA),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ListenableBuilder(
            listenable: contentController,
            builder: (context, child) {
              return NoteAppBar(
                isEditing: _isEditing,
                onToggleEdit: _toggleEditMode,
                onUndo: () {
                  if (contentController.hasUndo) contentController.undo();
                },
                onRedo: () {
                  if (contentController.hasRedo) contentController.redo();
                },
                canUndo: contentController.hasUndo, 
                canRedo: contentController.hasRedo, 
              );
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // TOOLBAR
              AnimatedSwitcher(
                duration: UIConstants.animationMedium, // Using our UI Constant
                transitionBuilder: (child, animation) {
                  final offsetAnimation = Tween<Offset>(
                    begin: const Offset(0.0, -0.2),
                    end: Offset.zero,
                  ).animate(animation);

                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: offsetAnimation, child: child),
                  );
                },
                child: _isEditing
                    ? NoteToolbar(
                        key: const ValueKey('ToolbarVisible'),
                        controller: contentController,
                        focusNode: _editorFocusNode,
                        onConvertToLink: _convertToHyperlink,
                      )
                    : const SizedBox(key: ValueKey('ToolbarHidden')),
              ),
              
              const SizedBox(height: UIConstants.paddingSM),

              // HEADER (Title & Divider)
              NoteHeader(
                titleController: titleController,
                onToggleEdit: _toggleEditMode,
                isEditing: _isEditing,
              ),

              const SizedBox(height: UIConstants.paddingMD),

              // EDITOR
              Expanded(
                child: PlainPasteWrapper(
                  controller: contentController,
                  child: NoteEditor(
                    controller: contentController,
                    focusNode: _editorFocusNode,
                    scrollController: _editorScrollController,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Hyperlink Logic ---
  // Stays in NotePage because it needs BuildContext (Snackbars/Dialogs)

  Future<void> _convertToHyperlink() async {
    final selection = contentController.selection;
    int startIndex = selection.baseOffset;
    int textLength = selection.extentOffset - startIndex;
    String targetUrl = '';

    if (textLength > 0) {
      targetUrl = contentController.document.getPlainText(startIndex, textLength);
    } else {
      final textBefore = contentController.document.getPlainText(0, startIndex);
      final lastSpace = textBefore.lastIndexOf(RegExp(r'\s'));
      startIndex = lastSpace == -1 ? 0 : lastSpace + 1;
      textLength = selection.baseOffset - startIndex;
      if (textLength <= 0) return;
      targetUrl = contentController.document.getPlainText(startIndex, textLength);
    }

    if (!_isValidLink(targetUrl)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No valid link found')));
      }
      return;
    }

    final displayTitle = await _showLinkTitleDialog();
    if (displayTitle != null && displayTitle.isNotEmpty) {
      contentController.replaceText(startIndex, textLength, displayTitle, null);
      contentController.formatText(startIndex, displayTitle.length, Attribute.fromKeyValue('link', targetUrl));
      _editorFocusNode.requestFocus();
    }
  }

  bool _isValidLink(String text) => RegExp(r'^(https?://)?([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)?$').hasMatch(text.trim());

  Future<String?> _showLinkTitleDialog() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Hyperlink Title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'e.g., Google or My Website'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('OK')),
        ],
      ),
    );
  }
}

/// ---------- PLAIN PASTE INTENT ----------

class PlainPasteIntent extends Intent {
  const PlainPasteIntent();
}

class PlainPasteWrapper extends StatelessWidget {
  final Widget child;
  final QuillController controller;

  const PlainPasteWrapper({
    super.key,
    required this.child,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyV, control: true): PlainPasteIntent(),
      },
      child: Actions(
        actions: {
          PlainPasteIntent: CallbackAction<PlainPasteIntent>(
            onInvoke: (_) async {
              final data = await Clipboard.getData(Clipboard.kTextPlain);

              if (data?.text != null) {
                final index = controller.selection.baseOffset;
                final length = controller.selection.extentOffset - index;
                controller.replaceText(index, length, data!.text!, null);
              }
              return null;
            },
          ),
        },
        child: child,
      ),
    );
  }
}