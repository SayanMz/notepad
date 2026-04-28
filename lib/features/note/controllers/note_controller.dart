import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter/foundation.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/features/note/controllers/groq_service.dart';
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

  NoteController({
    required this.recoveryService,
    required this.noteRepository,
    this.noteId,
  });

  Timer? _autosaveDebounce;
  bool _isDisposed = false;

  /// Prevents overlapping saves
  bool _isSaving = false;

  /// Current note ID (null for new note)
  String? noteId;
  final ValueNotifier<SaveState> saveState = ValueNotifier<SaveState>(
    SaveState.idle,
  );
  String? _lastEditorSignature;

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
    //Nothing has changed so skip saving - #Guard Clause or the "Bouncer Pattern"
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

    if (_isSaving) return; //avoids double saving
    _isSaving = true;

    saveState.value = SaveState.saving;
    await Future.delayed(Duration(milliseconds: 500));

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

      //Only update ID if a note was actually created/updated.
      // If 'saved' is null (no changes), KEEP existing noteId.
      if (saved != null) {
        noteId = saved
            .id; // This id would be passed to the save above, ensures proper update
      }

      _lastEditorSignature = _editorSignature(title, document);
    } finally {
      _isSaving = false;
      saveState.value = SaveState.saved;

      Future.delayed(UIConstants.saveIndicatorDuration, () {
        if (_isDisposed) return;

        if (saveState.value == SaveState.saved) {
          saveState.value = SaveState.idle;
        }
      });
    }
  }

  /// Called ONLY when the user presses the back button to leave the page.
  /// Cleans up the database if they left the note completely blank.
  void saveAndCleanupOnClose({
    required String title,
    required Document document,
  }) {
    final plainText = document.toPlainText().trim();
    final cleanTitle = title.trim();

    // Catch it if it's completely empty OR if it's an empty 'Untitled note'
    if ((cleanTitle.isEmpty || cleanTitle == 'Untitled note') &&
        plainText.isEmpty) {
      if (noteId != null) {
        noteRepository.deleteForever(noteId!);
      }
      return;
    }

    saveNote(title: title, document: document);
  }

  /// State for the voice processing spinner
  final ValueNotifier<bool> isProcessingVoice = ValueNotifier<bool>(false);

  Future<String?> processVoiceCommand({
    required String commandText,
    required QuillController controller,
  }) async {
    if (commandText.isEmpty) return null;
    isProcessingVoice.value = true;

    // 1. IME SAFETY LOCK
    FocusManager.instance.primaryFocus?.unfocus();
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final instructions = await GroqService.parseVoiceCommand(commandText);
      if (instructions == null || instructions.isEmpty)
        return 'No instructions found.';

      bool didApplyFormat = false;
      final pt = controller.document.toPlainText().toLowerCase();

      for (var inst in instructions) {
        final String k = inst['key']?.toString() ?? '';
        String target = inst['target']?.toString().toLowerCase().trim() ?? '';
        dynamic v = inst['value'];
        String occ =
            inst['occurrence']?.toString().toLowerCase().trim() ?? 'all';

        if (k.isEmpty) continue;
        if (target.isEmpty && k != 'unformat_all') continue;

        // --- SANITIZE BOOLEANS ---
        if (['bold', 'italic', 'underline', 'strike'].contains(k)) {
          v = (v.toString().toLowerCase() == 'true');
        }

        // --- 2. RUTHLESS CLEAR ---
        if (k == 'unformat_all') {
          final keys = [
            'bold',
            'italic',
            'underline',
            'strike',
            'color',
            'size',
            'list',
            'align',
          ];
          for (var key in keys) {
            controller.formatText(
              0,
              pt.length,
              Attribute.fromKeyValue(key, null),
            );
          }
          didApplyFormat = true;
          continue;
        }

        // --- 3. TARGET RESOLUTION ---
        List<Map<String, int>> ranges = [];
        bool isGlobal =
            target == 'all' || target == 'everything' || target == 'all text';

        if (isGlobal) {
          ranges.add({'start': 0, 'len': pt.length});
        } else if (target.startsWith('line:')) {
          String idxStr = target.split(':')[1].trim();
          List<String> lines = pt.split('\n');

          int targetIdx = -1;
          if (idxStr == 'last') {
            for (int i = lines.length - 1; i >= 0; i--) {
              if (lines[i].trim().isNotEmpty) {
                targetIdx = i;
                break;
              }
            }
            if (targetIdx == -1) targetIdx = lines.length - 1;
          } else {
            const ordinals = {
              'first': 0,
              'second': 1,
              'third': 2,
              'fourth': 3,
              'fifth': 4,
            };
            targetIdx = ordinals[idxStr] ?? (int.tryParse(idxStr) ?? -1);
          }

          if (targetIdx >= 0 && targetIdx < lines.length) {
            int startOffset = 0;
            for (int i = 0; i < targetIdx; i++) {
              startOffset += lines[i].length + 1;
            }
            int len = lines[targetIdx].length;
            if (len > 0) ranges.add({'start': startOffset, 'len': len});
          }
        } else {
          String pattern = target
              .split(RegExp(r'\s+'))
              .map(RegExp.escape)
              .join(r'\s+');
          var matches = RegExp(
            r'\b' + pattern + r'\b',
            caseSensitive: false,
          ).allMatches(pt).toList();

          if (matches.isEmpty) {
            matches = RegExp(
              pattern,
              caseSensitive: false,
            ).allMatches(pt).toList();
          }
          if (matches.isEmpty && target.contains(' ')) {
            String firstWord = target.split(' ')[0];
            matches = RegExp(
              r'\b' + RegExp.escape(firstWord) + r'\b',
              caseSensitive: false,
            ).allMatches(pt).toList();
          }

          if (occ != 'all' && matches.isNotEmpty) {
            const ords = {
              'first': 0,
              'second': 1,
              '2nd': 1,
              'third': 2,
              'last': -1,
            };
            int? i = (occ == 'last') ? matches.length - 1 : ords[occ];
            if (i != null && matches.length > i)
              matches = [matches[i]];
            else if (occ != 'all')
              matches = [];
          }
          for (var m in matches)
            ranges.add({'start': m.start, 'len': m.end - m.start});
        }

        // --- 4. EXECUTE UI FORMATTING ---
        for (var range in ranges.reversed) {
          int s = range['start']!;
          int l = range['len']!;

          // EXACT LOGIC REVERTED: The original cascading list block you requested
          if (k == 'list' && !isGlobal && !target.startsWith('line:')) {
            int listStart = pt.indexOf('\n', s);
            int listEnd = pt.indexOf('\n\n', s);
            if (listEnd == -1) listEnd = pt.length;

            dynamic val = (v == 'checkbox' || v == 'check') ? 'unchecked' : v;

            if (listStart != -1 && listStart < listEnd) {
              controller.formatText(
                listStart + 1,
                listEnd - (listStart + 1),
                Attribute.fromKeyValue(k, val),
              );
            } else {
              controller.formatText(
                s,
                listEnd - s,
                Attribute.fromKeyValue(k, val),
              );
            }
          }
          // ALIGNMENT LOGIC: The single-character anchor that fixed the merging lines
          else if (['align', 'list'].contains(k)) {
            dynamic val = (k == 'list' && (v == 'checkbox' || v == 'check'))
                ? 'unchecked'
                : v;

            if (isGlobal) {
              int pos = 0;
              while (pos < pt.length) {
                controller.formatText(pos, 1, Attribute.fromKeyValue(k, val));
                int nl = pt.indexOf('\n', pos);
                if (nl == -1) break;
                pos = nl + 1;
              }
            } else {
              controller.formatText(s, 1, Attribute.fromKeyValue(k, val));
            }
          }
          // INLINE STYLES: Bold, Size, Colors
          else {
            if (k == 'size_change') {
              final sAttr = controller.document
                  .collectStyle(s, 1)
                  .attributes['size'];
              double cur = (sAttr != null && sAttr.value is num)
                  ? (sAttr.value as num).toDouble()
                  : 16.0;
              controller.formatText(
                s,
                l,
                Attribute.fromKeyValue(
                  'size',
                  cur + (double.tryParse(v.toString()) ?? 10.0),
                ),
              );
            } else {
              if (k == 'size') v = double.tryParse(v.toString()) ?? 16.0;
              controller.formatText(s, l, Attribute.fromKeyValue(k, v));
            }
          }
          didApplyFormat = true;
        }
      }

      return didApplyFormat ? 'Formatting applied!' : 'No matches found.';
    } catch (e) {
      return 'Error: $e';
    } finally {
      isProcessingVoice.value = false;
    }
  }

  void dispose() {
    _isDisposed = true;
    _autosaveDebounce?.cancel();
    saveState.dispose();
  }
}

/*
Interview Note: "I designed the AI integration to be fully data-driven. 
Instead of writing brittle parsing logic with hardcoded switch cases in Dart, 
I prompt-engineered the LLM to output exact flutter_quill Delta JSON keys. 
This allows me to use Quill's native deserialization, reducing my processing 
logic to a single line of code and making the architecture instantly scalable for new formatting features."
*/
