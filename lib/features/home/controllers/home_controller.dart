import 'package:flutter/material.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/core/data/app_data.dart';
import 'package:notepad/features/note/data/note_repository.dart';
import 'package:notepad/main.dart';
import 'package:notepad/features/note/services/note_document_service.dart';
import 'package:notepad/features/note/services/note_recovery_service.dart';
import 'package:notepad/features/home/services/app_router.dart';
import 'package:notepad/features/note/note_page.dart';

/// ---------------------------------------------------------------------------
/// HOME CONTROLLER (BUSINESS LOGIC LAYER)
/// ---------------------------------------------------------------------------
///
/// ROLE IN ARCHITECTURE:
/// - Acts as the intermediary between UI (HomePage) and data/services
/// - Encapsulates business logic to keep UI clean and declarative
///
/// RESPONSIBILITIES:
/// - Expose derived state from repository
/// - Handle note actions (open, pin, delete, share)
/// - Manage side effects (navigation, SnackBars, persistence)
///
/// DESIGN PRINCIPLES:
/// - Thin controller (not bloated with UI logic)
/// - Repository remains the single source of truth
/// - UI delegates actions → controller executes
///

class HomeController {
  /// Handles crash recovery and draft restoration
  final NoteRecoveryService recoveryService;

  HomeController(this.recoveryService);

  // -------------------------------------------------------------------------
  // STATE HELPERS (DERIVED STATE)
  // -------------------------------------------------------------------------

  /// Whether selection mode is active.
  ///
  /// NOTE:
  /// - Derived from repository (not stored locally)
  /// - Prevents duplication of state in UI
  bool get isSelectionMode => noteRepository.selectedNotes.isNotEmpty;

  /// Active notes currently visible to user.
  ///
  /// SOURCE:
  /// - Directly from repository
  /// - Always up-to-date via ListenableBuilder
  List<NotesSection> get activeNotes => noteRepository.activeNotes;

  /// Whether all active notes are selected.
  ///
  /// Used for:
  /// - "Select All" checkbox state
  bool get allSelected => noteRepository.areAllActiveNotesSelected;

  // -------------------------------------------------------------------------
  // ACTIONS (USER INTENTS)
  // -------------------------------------------------------------------------

  /// Opens a note page.
  ///
  /// SIDE EFFECTS:
  /// - Clears existing SnackBars for clean UX
  /// - Navigates using centralized AppRouter
  Future<void> openNote(BuildContext context, {String? noteId}) async {
    rootScaffoldMessengerKey.currentState?.clearSnackBars();

    await Navigator.push(context, AppRouter.slide(NotePage(noteId: noteId)));
  }

  /// Toggles pin state of a note.
  ///
  /// DESIGN:
  /// - Immediate mutation + persistence
  /// - Keeps UI responsive and consistent
  Future<void> togglePin(String noteId) async {
    noteRepository.togglePin(noteId);
  }

  /// Shares selected notes as HTML.
  ///
  /// UX:
  /// - Gracefully handles empty selection
  /// - Shows error feedback via SnackBar
  Future<void> shareSelectedNotes(BuildContext context) async {
    final selectedNotes = noteRepository.selectedNotes;

    if (selectedNotes.isEmpty) return;

    try {
      await NoteDocumentService.shareNotesAsHTML(
        selectedNotes,
        text: 'Sharing ${selectedNotes.length} Notes',
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not share selected notes: $e')),
      );
    }
  }

  /// Deletes selected notes (moves to recycle bin).
  ///
  /// UX PATTERN:
  /// - Performs soft delete (recoverable)
  /// - Shows Snackbar with restore option
  Future<void> deleteSelected(List<NotesSection> notes) async {
    final selectedNotes = notes;
    final selectedCount = selectedNotes.length;

    if (selectedCount == 0) return;

    /// Store IDs for undo functionality
    final movedNoteIds = selectedNotes.map((n) => n.id).toList();

    /// Perform deletion
    noteRepository.moveSelectedNotesToRecycleBin(selectedNotes);

    /// Undo Snackbar
    showRootSnackBar(
      SnackBar(
        key: UniqueKey(),
        duration: UIConstants.saveIndicatorDuration,
        content: Text(
          '$selectedCount ${selectedCount == 1 ? 'note' : 'notes'} moved to recycle bin',
        ),
        action: SnackBarAction(
          label: 'Restore',
          onPressed: () async {
            rootScaffoldMessengerKey.currentState?.hideCurrentSnackBar();

            for (final id in movedNoteIds) {
              noteRepository.restoreNote(id);
            }
          },
        ),
      ),
      autoHideAfter: UIConstants.saveIndicatorDuration,
    );
  }

  /// Toggles selection mode.
  ///
  /// BEHAVIOR:
  /// - Disabling selection clears all selected notes
  /// - Keeps repository as single source of truth
  void toggleSelectionMode(bool enabled) {
    if (!enabled) {
      noteRepository.clearSelection();
    }
  }
}

/// INTERVIEW NOTE:
/// This reflects a “Controller pattern” similar to MVVM/MVC-lite in Flutter
