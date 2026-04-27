import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/core/theme/app_colors.dart';
import 'package:notepad/features/note/data/note_repository.dart';
import 'package:notepad/features/note/services/note_document_service.dart';
import 'package:notepad/features/note/services/note_recovery_service.dart';
import 'package:notepad/features/note/controllers/note_controller.dart';
import 'package:notepad/features/note/widgets/note_app_bar.dart';
import 'package:notepad/features/note/widgets/note_editor.dart';
import 'package:notepad/features/note/widgets/note_header.dart';
import 'package:notepad/features/note/widgets/note_toolbar.dart';
import 'package:notepad/main.dart';

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
  const NotePage({super.key, this.noteId, this.title = '', this.content = ''});

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

  /// UI-only state → toggles toolbar visibility
  bool _isEditing = false;
  bool _hasNudgedToolbar = false; //Track the Nudge

  /// --- VOICE AI TESTING STATE ---

  /// Dialog to type out the voice command manually
  Future<void> _showVoiceSimulatorDialog() async {
    final simulatorController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simulate Voice Command'),
        content: TextField(
          controller: simulatorController,
          decoration: const InputDecoration(
            hintText: 'e.g., Make the dogs red',
          ),
          autofocus: true,
          onSubmitted: (val) => Navigator.pop(context, val),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, simulatorController.text),
            child: const Text('Execute'),
          ),
        ],
      ),
    );

    // DELEGATE TO CONTROLLER
    if (result != null && result.isNotEmpty) {
      final feedback = await _noteController.processVoiceCommand(
        commandText: result,
        controller: contentController,
      );

      if (feedback != null && mounted) {
        showRootSnackBar(SnackBar(content: Text(feedback)));
      }
    }
  }

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
    titleController = TextEditingController(text: note?.title ?? widget.title);

    /// Initialize content controller
    if (note != null) {
      /// Existing note → decode rich content
      contentController = QuillController(
        document: Document.fromJson(
          NoteDocumentService.decodeRichContent(note.richContent, note.content),
        ),
        selection: const TextSelection.collapsed(offset: 0),
        keepStyleOnNewLine: false,
      );
    } else if (widget.content.isNotEmpty) {
      /// Recovered draft
      final recoveredDoc = Document()..insert(0, widget.content);

      contentController = QuillController(
        document: recoveredDoc,
        selection: const TextSelection.collapsed(offset: 0),
        keepStyleOnNewLine: false,
      );
    } else {
      /// New note
      contentController = QuillController(
        document: Document(),
        selection: const TextSelection.collapsed(offset: 0),
        keepStyleOnNewLine: false,
      );
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
    _noteController.handleEditorChanged(
      title: titleController.text,
      document: contentController.document,
    );
  }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      /// Save note when navigating back
      onPopInvokedWithResult: (didPop, result) {
        _noteController.saveAndCleanupOnClose(
          title: titleController.text,
          document: contentController.document,
        );
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkScaffold
            : AppColors.lightScaffold,

        // -------------------------------------------------------------------
        // APP BAR (UNDO / REDO / EDIT TOGGLE)
        // -------------------------------------------------------------------
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: NoteAppBar(
            saveState: _noteController.saveState,
            contentController: contentController,
            title: titleController,
            isDark: isDark,
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
                duration: UIConstants.animationMedium,
                curve: Curves.easeInOutCubic,
                child: _isEditing
                    ? Container(
                        padding: const EdgeInsets.only(
                          bottom: UIConstants.paddingSM,
                        ),
                        child: NoteToolbar(
                          controller: contentController,
                          focusNode: _editorFocusNode,
                          shouldNudge: !_hasNudgedToolbar,
                          onNudgeComplete: () {
                            if (mounted) {
                              setState(() => _hasNudgedToolbar = true);
                            }
                          },
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
                    scrollController: _editorScrollController,
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: ValueListenableBuilder<bool>(
          valueListenable: _noteController.isProcessingVoice,
          builder: (context, isProcessing, _) {
            return FloatingActionButton(
              onPressed: isProcessing ? null : _showVoiceSimulatorDialog,
              backgroundColor: AppColors.amber,
              child: isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.mic),
            );
          },
        ),
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
        SingleActivator(LogicalKeyboardKey.keyV, control: true):
            PlainPasteIntent(),
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

/*
🧠 INTERVIEW GOLD ANSWER

“I centralized all persistence triggers inside the controller to ensure consistent behavior and 
make the UI fully declarative.”
*/
