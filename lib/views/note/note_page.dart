// (imports unchanged)

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
import 'package:notepad/views/note/widgets/save_indicator.dart';


/// ---------------------------------------------------------------------------
/// NOTE PAGE (EDITOR SCREEN)
/// ---------------------------------------------------------------------------
///
/// ROLE IN ARCHITECTURE:
/// - Core feature screen for creating & editing notes
/// - Integrates:
///     • Rich text editor (flutter_quill)
///     • Persistence layer (NoteRepository)
///     • Recovery system
///     • Controller abstraction (NoteController)
///
/// RESPONSIBILITIES:
/// - Initialize editor state (new / existing / recovered note)
/// - Handle user input (title + content)
/// - Delegate saving & debouncing to controller
/// - Manage editor lifecycle and focus
///
/// DESIGN PRINCIPLES:
/// - UI delegates logic → NoteController
/// - Editor state is reactive via controllers
/// - Lifecycle-aware saving (AppLifecycleListener)
///
/// INTERVIEW NOTE:
/// This is the most complex screen — demonstrates state handling,
/// editor integration, and lifecycle awareness.
class NotePage extends StatefulWidget {
  final String title, content;
  final String? noteId;

  /// Supports:
  /// - Creating new notes
  /// - Editing existing notes (via noteId)
  /// - Restoring unsaved drafts (title/content)
  const NotePage({
    super.key,
    this.noteId,
    this.title = '',
    this.content = '',
  });

  

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  /// Listens to app lifecycle (background, pause, etc.)
  late final AppLifecycleListener _lifecycleListener;

  /// Controller layer handling business logic
  late final NoteController _noteController;

  /// Title input controller
  late final TextEditingController titleController;

  /// Rich text editor controller (flutter_quill)
  late final QuillController contentController;

  /// Focus control for editor
  final FocusNode _editorFocusNode = FocusNode();

  /// Scroll control for editor
  final ScrollController _editorScrollController = ScrollController();

  /// Used to detect changes for autosave optimization
  int lastSavedHash = 0;

  /// UI-only state → toggles toolbar visibility
  bool _isEditing = false;



  @override
  void initState() {
    super.initState();

    // -----------------------------------------------------------------------
    // 1. CONTROLLER INITIALIZATION
    // -----------------------------------------------------------------------
_noteController = NoteController(
  recoveryService: NoteRecoveryService(),
  noteRepository: noteRepository,
  noteId: widget.noteId,
);
    // -----------------------------------------------------------------------
    // 2. LOAD NOTE DATA
    // -----------------------------------------------------------------------

    final note = widget.noteId == null
        ? null
        : noteRepository.findById(widget.noteId!);

    /// Initialize title
    titleController =
        TextEditingController(text: note?.title ?? widget.title);

    /// Initialize content controller
    if (note != null) {
      /// Existing note → decode rich content
      contentController = QuillController(
        document: Document.fromJson(
          NoteDocumentService.decodeRichContent(
            note.richContent,
            note.content,
          ),
        ),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else if (widget.content.isNotEmpty) {
      /// Recovered draft
      final recoveredDoc = Document()..insert(0, widget.content);

      contentController = QuillController(
        document: recoveredDoc,
        selection: const TextSelection.collapsed(offset: 0),
      );
    } else {
      /// New note
      contentController = QuillController.basic();
    }

    // -----------------------------------------------------------------------
    // 3. LISTENERS
    // -----------------------------------------------------------------------

    /// Detect changes in title/content
    titleController.addListener(_handleEditorChanged);
    contentController.addListener(_handleEditorChanged);

    /// Lifecycle-based auto-save
   _lifecycleListener = AppLifecycleListener(
  onInactive: () => _noteController.saveNote(
    title: titleController.text,
    document: contentController.document,
  ),
  onPause: () => _noteController.saveNote(
    title: titleController.text,
    document: contentController.document,
  ),
  onDetach: () => _noteController.saveNote(
    title: titleController.text,
    document: contentController.document,
  ),
);

    /// Initial snapshot for change detection
    lastSavedHash = contentController.document.hashCode;
  }

  /// -------------------------------------------------------------------------
  /// CHANGE HANDLER (AUTO-SAVE TRIGGER)
  /// -------------------------------------------------------------------------
  ///
  /// Delegates:
  /// - Debouncing
  /// - Save timing
  /// to NoteController
  void _handleEditorChanged() {
      final currentHash = contentController.document.hashCode;

    if (lastSavedHash ==
        currentHash) {
      return;
    }

          lastSavedHash = currentHash;
          saveState: _noteController.saveState;

_noteController.handleEditorChanged(
  title: titleController.text,
  document: contentController.document,
);
  }

  /// Saves note immediately.
  ///
  /// Updates signature after successful save.
//   Future<void> _saveCurrentNote() async {
//     _saveState.value = SaveState.saving;

//     await _noteController.saveNote(
//       title: titleController.text,
//       document: contentController.document,
//     );

//     _saveState.value = SaveState.saved;

//     /// Auto-hide after delay
// Future.delayed(const Duration(seconds: 1), () {
//   if (_saveState.value == SaveState.saved) {
//     _saveState.value = SaveState.idle;
//   }
// });

//     lastSavedLength =
//         contentController.document.length;
//   }

  /// Toggles editing mode (shows/hides toolbar)
  void _toggleEditMode() {
    setState(() => _isEditing = !_isEditing);
  }

  @override
  void dispose() {
    /// Remove listeners to prevent memory leaks
    titleController.removeListener(_handleEditorChanged);
    titleController.dispose();

    contentController.removeListener(_handleEditorChanged);
    contentController.dispose();

    _editorFocusNode.dispose();
    _editorScrollController.dispose();

    /// Clean lifecycle + controller
    _lifecycleListener.dispose();
    _noteController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      /// Save note when navigating back
    onPopInvokedWithResult: (didPop, result) async {
  await _noteController.saveNote(
    title: titleController.text,
    document: contentController.document,
  );
},
      child: Scaffold(
        backgroundColor:
            isDark ? Colors.black : const Color(0xFFF8F9FA),

        // -------------------------------------------------------------------
        // APP BAR (UNDO / REDO / EDIT TOGGLE)
        // -------------------------------------------------------------------
        appBar: PreferredSize(
          preferredSize:
              const Size.fromHeight(kToolbarHeight),
          child: ListenableBuilder(
            listenable: contentController,

            /// Rebuild only when editor state changes
            builder: (context, child) {
              return NoteAppBar(
                isEditing: _isEditing,
                onToggleEdit: _toggleEditMode,

                /// Undo / Redo actions
                onUndo: () {
                  if (contentController.hasUndo) {
                    contentController.undo();
                  }
                },
                onRedo: () {
                  if (contentController.hasRedo) {
                    contentController.redo();
                  }
                },

                canUndo: contentController.hasUndo,
                canRedo: contentController.hasRedo,
                 saveState: _noteController.saveState,
                 contentController: contentController,
              );
            },
          ),
        ),

        // -------------------------------------------------------------------
        // BODY
        // -------------------------------------------------------------------
        body: SafeArea(
          child: Column(
            children: [
              // -------------------------------------------------------------
              // TOOLBAR (FORMATTING)
              // -------------------------------------------------------------
              AnimatedSize(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOutCubic,
  child: _isEditing
      ? Container(
          padding: const EdgeInsets.only(bottom: 8),
          child: NoteToolbar(
            controller: contentController,
            focusNode: _editorFocusNode,
            onConvertToLink: _convertToHyperlink,
          ),
        )
      : const SizedBox.shrink(),
),

              const SizedBox(height: UIConstants.paddingSM),

              // -------------------------------------------------------------
              // HEADER (TITLE)
              // -------------------------------------------------------------
              NoteHeader(
                titleController: titleController,
                onToggleEdit: _toggleEditMode,
                isEditing: _isEditing,
              ),

              const SizedBox(height: UIConstants.paddingMD),

              // -------------------------------------------------------------
              // EDITOR
              // -------------------------------------------------------------
              Expanded(
                child: PlainPasteWrapper(
                  controller: contentController,

                  /// Custom editor widget
                  child: NoteEditor(
                    controller: contentController,
                    focusNode: _editorFocusNode,
                    scrollController:
                        _editorScrollController,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // HYPERLINK FEATURE
  // -------------------------------------------------------------------------
  ///
  /// Converts selected text into a clickable hyperlink.
  ///
  /// NOTE:
  /// - Kept inside UI because it requires dialogs + SnackBars
  Future<void> _convertToHyperlink() async {
    final selection = contentController.selection;

    int startIndex = selection.baseOffset;
    int textLength =
        selection.extentOffset - startIndex;

    String targetUrl = '';

    /// Extract selected or nearby text
    if (textLength > 0) {
      targetUrl = contentController.document
          .getPlainText(startIndex, textLength);
    } else {
      final textBefore = contentController.document
          .getPlainText(0, startIndex);

      final lastSpace =
          textBefore.lastIndexOf(RegExp(r'\s'));

      startIndex = lastSpace == -1 ? 0 : lastSpace + 1;
      textLength = selection.baseOffset - startIndex;

      if (textLength <= 0) return;

      targetUrl = contentController.document
          .getPlainText(startIndex, textLength);
    }

    /// Validate URL
    if (!_isValidLink(targetUrl)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No valid link found'),
          ),
        );
      }
      return;
    }

    /// Ask user for display title
    final displayTitle = await _showLinkTitleDialog();

    if (displayTitle != null &&
        displayTitle.isNotEmpty) {
      contentController.replaceText(
        startIndex,
        textLength,
        displayTitle,
        null,
      );

      contentController.formatText(
        startIndex,
        displayTitle.length,
        Attribute.fromKeyValue('link', targetUrl),
      );

      _editorFocusNode.requestFocus();
    }
  }

  /// Simple URL validation
  bool _isValidLink(String text) {
    return RegExp(
      r'^(https?://)?([\w-]+\.)+[\w-]+(/[\w- ./?%&=]*)?$',
    ).hasMatch(text.trim());
  }

  /// Dialog to enter hyperlink title
  Future<String?> _showLinkTitleDialog() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Hyperlink Title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g., Google or My Website',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// PLAIN PASTE WRAPPER
/// ---------------------------------------------------------------------------
///
/// PURPOSE:
/// - Overrides default paste behavior
/// - Ensures only plain text is pasted (no formatting - from websites)
///
/// BENEFIT:
/// - Prevents unwanted styles from external sources
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
        SingleActivator(
          LogicalKeyboardKey.keyV,
          control: true,
        ): PlainPasteIntent(),
      },
      child: Actions(
        actions: {
          PlainPasteIntent:
              CallbackAction<PlainPasteIntent>(
            onInvoke: (_) async {
              final data = await Clipboard.getData(
                Clipboard.kTextPlain,
              );

              if (data?.text != null) {
                final index =
                    controller.selection.baseOffset;

                final length =
                    controller.selection.extentOffset -
                        index;

                controller.replaceText(
                  index,
                  length,
                  data!.text!,
                  null,
                );
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


/*
🧠 INTERVIEW GOLD ANSWER

“I centralized all persistence triggers inside the controller to ensure consistent behavior and 
make the UI fully declarative.”
*/