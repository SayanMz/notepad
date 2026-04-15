import 'dart:async';
import 'dart:convert';

import 'package:flutter_quill/flutter_quill.dart';

import 'package:notepad/data/note_repository.dart';
import 'package:notepad/services/note_recovery_service.dart';

/// Handles all non-UI logic for NotePage:
/// - Autosave (debounced)
/// - Crash recovery (shadow drafts)
/// - Persistent save (repository)
///
/// UI should NOT contain any of this logic.
class NoteController {
  final NoteRecoveryService recoveryService;
  final NoteRepository noteRepository;

  Timer? _autosaveDebounce;

  /// Prevents overlapping saves
  bool _isSaving = false;

  /// Current note ID (null for new note)
  String? noteId;

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
    required Future<void> Function() save,
  }) {
    // Crash recovery (lightweight)
    recoveryService.saveShadowDraft('new_note', [
      title,
      document.toPlainText(),
    ]);

    // Debounce persistent save
    _autosaveDebounce?.cancel();

    _autosaveDebounce = Timer(
      const Duration(seconds: 3),
      save,
    );
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

  try {
    final resolvedTitle = title.trim().isEmpty ? 'Untitled note' : title.trim();

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
  } finally {
    _isSaving = false;
  }
}

  void dispose() {
    _autosaveDebounce?.cancel();
  }
}