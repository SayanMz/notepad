import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter/foundation.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/features/note/data/note_repository.dart';
import 'package:notepad/features/note/services/note_recovery_service.dart';
import 'package:notepad/features/note/widgets/save_indicator.dart';

/// Handles all non-UI logic for NotePage:
/// - Autosave (debounced)
/// - Crash recovery (shadow drafts)
/// - Persistent save (repository)
class NoteController {
  final NoteRecoveryService recoveryService;
  final NoteRepository noteRepository;

  Timer? _autosaveDebounce;

  /// Prevents overlapping saves
  bool _isSaving = false;

  /// Current note ID (null for new note)
  String? noteId;
  final ValueNotifier<SaveState> saveState = ValueNotifier<SaveState>(
    SaveState.idle,
  );
  String? _lastEditorSignature;

  NoteController({
    required this.recoveryService,
    required this.noteRepository,
    this.noteId,
  });

  /// Called whenever editor content changes
  ///
  /// FLOW:
  /// 1. Immediate shadow save (fast, crash-safe)
  /// 2. Debounced persistent save (slow, disk-heavy)
  void handleEditorChanged({
    required String title,
    required Document document,
  }) {
    final currentSignature = _editorSignature(title, document);

    if (_lastEditorSignature == currentSignature) {
      return;
    }

    _lastEditorSignature = currentSignature;

    // Crash recovery (lightweight)
    recoveryService.saveShadowDraft(NoteRecoveryService.draftKey, [
      title,
      document.toPlainText(),
    ]);

    // Debounce persistent save
    _autosaveDebounce?.cancel();

    _autosaveDebounce = Timer(
      UIConstants.saveIndicatorDuration,
      () => saveNote(title: title, document: document),
    );
  }

  String _editorSignature(String title, Document document) {
    return '${title.trim()}\n${jsonEncode(document.toDelta().toJson())}';
  }

  /// Saves note to repository
  ///
  /// Uses "latest-wins" strategy to avoid race conditions

  Future<void> saveNote({
    required String title,
    required Document document,
  }) async {
    _autosaveDebounce?.cancel();

    final plainText = document.toPlainText().trim();
    // Don't save if it's completely empty
    if ((title.trim() + plainText).isEmpty) return;

    if (_isSaving) return;
    _isSaving = true;

    saveState.value = SaveState.saving;

    try {
      final resolvedTitle = title.trim().isEmpty
          ? 'Untitled note'
          : title.trim();

      final saved = noteRepository.saveNote(
        noteId: noteId, // Passes current ID (null if new)
        title: resolvedTitle,
        content: plainText,
        richContent: jsonEncode(document.toDelta().toJson()),
      );

      // THE FIX: Only update our ID if a note was actually created/updated.
      // If 'saved' is null (no changes), we KEEP our existing noteId.
      if (saved != null) {
        noteId = saved.id;
      }

      await noteRepository.persist();
      _lastEditorSignature = _editorSignature(title, document);
    } finally {
      _isSaving = false;
      saveState.value = SaveState.saved;

      Future.delayed(UIConstants.saveIndicatorDuration, () {
        if (saveState.value == SaveState.saved) {
          saveState.value = SaveState.idle;
        }
      });
    }
  }

  void dispose() {
    _autosaveDebounce?.cancel();
    saveState.dispose();
  }
}
