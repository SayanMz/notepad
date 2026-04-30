import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:notepad/core/data/app_data.dart';

/// ------------------------------------------------------------
/// NOTE REPOSITORY
/// ------------------------------------------------------------
/// Centralized in-memory data manager for notes.
///
/// Responsibilities:
/// - Single source of truth for all notes
/// - CRUD operations (create, read, update, delete)
/// - UI state handling (selection, deletion flags)
/// - Persistence coordination (StorageService)
/// - Notifies UI via ChangeNotifier (Observer pattern)
///
/// Design Patterns:
/// - Repository Pattern
/// - Singleton Pattern
/// - Observer Pattern (ChangeNotifier)
///
/// Trade-offs:
/// - Combines UI state + data (simple but tightly coupled)
/// - Uses O(n) operations for search/filter (acceptable for small datasets)
/// ------------------------------------------------------------
class NoteRepository extends ChangeNotifier {
  /// The physical database
  late final Box<NotesSection> _box = Hive.box<NotesSection>('notes_box');

  /// Internal mutable list containing all notes.
  /// Includes active, deleted, and selected notes.
  final List<NotesSection> _notes =
      []; //The List provides the Order: Necessary for the ListView and sorting logic (Pinned first).

  //The Map provides the Speed: Ensures that toggling a pin, selecting a note,
  //or saving an edit happens in constant time ($O(1)$), regardless of how many notes the user has.
  final Map<String, NotesSection> _noteMap = {};

  /// Singleton setup to ensure one shared instance across app.
  NoteRepository._internal();
  static final NoteRepository _instance = NoteRepository._internal();

  /// Public constructor strictly for injecting Fakes during testing.
  @visibleForTesting
  NoteRepository.internalForTesting();

  factory NoteRepository() => _instance;

  /// ------------------------------------------------------------
  /// INITIALIZATION
  /// ------------------------------------------------------------
  /// Loads notes from storage or seeds default data.
  Future<void> init() async {
    _notes.clear();
    _noteMap.clear();

    if (_box.isEmpty) {
      _addSeedNotes();
      // To persist seed notes in Hive:
      for (var note in _notes) {
        _noteMap[note.id] = note;
        await _box.put(note.id, note);
      }
    } else {
      for (var note in _box.values) {
        _notes.add(note);
        _noteMap[note.id] = note; // Build index from storage
      }
    }
    _sortPinnedFirst();
    notifyListeners();
    //stressTestHive();
  }

  ///Stress Test
  void stressTestHive() async {
    for (int i = 0; i < 100; i++) {
      saveNote(
        noteId: null, // Forces a new ID generation
        title: 'Stress Test Note #$i',
        content:
            'This is a test note to check if the O(1) Map lookup remains fast.',
      );
    }
  }

  // ------------------------------------------------------------
  // READ OPERATIONS (O(1) Efficiency)
  // ------------------------------------------------------------

  /// Finds a note by ID using linear search.
  NotesSection? findById(String id) => _noteMap[id];

  /// Adds initial demo notes for onboarding UX.
  void _addSeedNotes() {
    _notes.addAll([
      // --- 1. THE BASICS ---
      NotesSection(
        title: 'Welcome to Notepad 🚀',
        content:
            'Your new favorite workspace.\n\n'
            '• Use the toolbar below to manually apply styles like bold, italic, or new colors.\n'
            '• Highlight text to add links or change font sizes.\n'
            '• Long-press a note on the home screen to delete it.\n\n'
            'Dive in and start typing, or check out the next note to see something cool!',
        isPinned: true,
        cardColorValue: 0xFF81A1C1, // Material Blue
      ),

      // --- 2. AI INTRODUCTION ---
      NotesSection(
        title: 'Meet your AI Assistant 🎙️',
        content:
            'Why tap when you can talk?\n\n'
            'Tap the floating circle icon to activate your Voice AI. Just speak naturally to format your text.\n\n'
            'Quick commands to try right now:\n'
            '- Highlight this line and say: "Make this green"\n'
            '- Say: "Make everything bold"\n'
            '- Made a mess? Just say: "Clear all formatting" or "Nuke styles"',
        isPinned: false,
        cardColorValue: 0xFFB48EAD, // Material Purple
      ),

      // --- 3. THE SANDBOX ---
      NotesSection(
        title: 'AI Playground 🧪',
        content:
            // Paragraph 1 (Ends with \n\n)
            'Test out the engine\'s precision right here.\n\n'
            // Paragraph 2 (Contains two sentences ending in . and one \n\n block)
            'The golden retriever is a very intelligent dog. Because it is loyal, the dog makes a great pet.\n\n'
            // Paragraph 3 (List block ending with \n\n)
            'Menu items:\n'
            'Pizza\n'
            'Burger\n\n'
            // Paragraph 4 (The last paragraph)
            'Try saying these exact commands:\n'
            '- "Make the first sentence italic"\n'
            '- "Make golden retriever huge"\n'
            '- "Underline the second instance of dog"\n'
            '- "Make menu items a checklist"\n'
            '- "Center the last paragraph"',
        isPinned: false,
        cardColorValue: 0xFFEBCB8B, // Material Amber
      ),
    ]);
  }

  // ------------------------------------------------------------
  // READ-ONLY VIEWS (GETTERS)
  // ------------------------------------------------------------

  /// Returns all notes (immutable view to prevent external mutation).
  List<NotesSection> get allNotes => List<NotesSection>.unmodifiable(_notes);

  /// Returns only active (non-deleted) notes.
  /// NOTE: Each call performs O(n) filtering.
  List<NotesSection> get activeNotes =>
      List<NotesSection>.unmodifiable(_notes.where((note) => !note.isDeleted));

  /// Returns notes currently in recycle bin.
  List<NotesSection> get deletedNotes =>
      List<NotesSection>.unmodifiable(_notes.where((note) => note.isDeleted));

  /// Returns notes currently selected in UI.
  List<NotesSection> get selectedNotes =>
      List<NotesSection>.unmodifiable(_notes.where((note) => note.isSelected));

  Future<String> exportNotesToBackupString() async {
    final allNotes = _notes.map((note) => note.toJson()).toList();
    return jsonEncode(allNotes);
  }

  Future<void> importNotesFromBackupString(String jsonString) async {
    final List<dynamic> decoded = jsonDecode(jsonString);
    final importedNotes = decoded
        .map((item) => NotesSection.fromJson(item))
        .toList();

    await _box.clear();
    await _box.addAll(importedNotes);
    _notes.clear();
    _notes.addAll(importedNotes);
    notifyListeners();
  }

  /// Determines if all visible notes are selected.
  /// Used for "Select All" checkbox logic.
  bool get areAllActiveNotesSelected {
    final visibleNotes = activeNotes;
    return visibleNotes.isNotEmpty &&
        visibleNotes.every((note) => note.isSelected);
  }

  /// Moves a note just below pinned notes.
  /// Maintains pinned-first ordering invariant.
  void moveOnTop(NotesSection note) {
    if (note.isPinned) return;

    _notes.remove(note);

    final pinnedCount = _notes.where((n) => n.isPinned).length;

    _notes.insert(pinnedCount, note);

    notifyListeners();
  }

  /// Searches notes by keyword in title/content.
  /// Ignores deleted notes.
  /// Searches notes by keyword in title/content AND optional date/time filters.
  /// Ignores deleted notes.
  /// Searches notes by keyword AND/OR a specific date-time range.
  /// Searches notes by keyword AND/OR a specific date-time range.
  List<NotesSection> search({
    required String query,
    required bool
    isRangeSearch, // <-- NEW: Tells the backend which mode we are in
    // Start/Single constraints
    String? startDay,
    String? startMonth,
    String? startYear,
    String? startHour,
    String? startMinute,

    // End constraints
    String? endDay,
    String? endMonth,
    String? endYear,
    String? endHour,
    String? endMinute,
  }) {
    final normalizedQuery = query.toLowerCase();

    // Bail out if absolutely nothing is being searched/filtered
    if (normalizedQuery.isEmpty &&
        startDay == null &&
        startMonth == null &&
        startYear == null &&
        startHour == null &&
        startMinute == null &&
        endDay == null &&
        endMonth == null &&
        endYear == null &&
        endHour == null &&
        endMinute == null) {
      return const [];
    }

    return List<NotesSection>.unmodifiable(
      _notes.where((note) {
        if (note.isDeleted) return false;

        // --- 1. TEXT FILTER ---
        if (normalizedQuery.isNotEmpty) {
          final title = note.title.toLowerCase();
          final content = note.content.toLowerCase();
          if (!title.contains(normalizedQuery) &&
              !content.contains(normalizedQuery)) {
            return false;
          }
        }

        // --- 2. DATE FILTER ---
        final date = note.updatedAt;

        if (!isRangeSearch) {
          // ==========================================
          // MODE A: EXACT MATCH (Single Date/Time)
          // ==========================================
          // If the user selects '2026', ONLY return 2026.
          if (startYear != null && date.year.toString() != startYear)
            return false;
          if (startMonth != null &&
              date.month.toString().padLeft(2, '0') != startMonth)
            return false;
          if (startDay != null &&
              date.day.toString().padLeft(2, '0') != startDay)
            return false;
          if (startHour != null &&
              date.hour.toString().padLeft(2, '0') != startHour)
            return false;
          if (startMinute != null &&
              date.minute.toString().padLeft(2, '0') != startMinute)
            return false;
        } else {
          // ==========================================
          // MODE B: RANGE MATCH (Between Date A and B)
          // ==========================================
          DateTime? createBoundary({
            String? y,
            String? m,
            String? d,
            String? h,
            String? min,
            required bool isEndOfRange,
          }) {
            if (y == null && m == null && d == null && h == null && min == null)
              return null;

            final now = DateTime.now();
            int year = int.tryParse(y ?? '') ?? now.year;
            int month = int.tryParse(m ?? '') ?? (isEndOfRange ? 12 : 1);
            int day =
                int.tryParse(d ?? '') ??
                (isEndOfRange ? DateTime(year, month + 1, 0).day : 1);
            int hour = int.tryParse(h ?? '') ?? (isEndOfRange ? 23 : 0);
            int minute = int.tryParse(min ?? '') ?? (isEndOfRange ? 59 : 0);

            return DateTime(year, month, day, hour, minute);
          }

          final startDate = createBoundary(
            y: startYear,
            m: startMonth,
            d: startDay,
            h: startHour,
            min: startMinute,
            isEndOfRange: false,
          );
          final endDate = createBoundary(
            y: endYear,
            m: endMonth,
            d: endDay,
            h: endHour,
            min: endMinute,
            isEndOfRange: true,
          );

          if (startDate != null && date.isBefore(startDate)) return false;
          if (endDate != null && date.isAfter(endDate)) return false;
        }

        // If it survived the checks, include it!
        return true;
      }),
    );
  }

  // ------------------------------------------------------------
  // SMART SAVE (CREATE / UPDATE)
  // ------------------------------------------------------------

  /// Handles:
  /// - Create (new note)
  /// - Update (existing note)
  /// - No-op (if nothing changed)
  ///
  /// Optimization:
  /// Prevents unnecessary updates if content unchanged.
  NotesSection? saveNote({
    required String? noteId,
    required String title,
    required String content,
    String richContent = '',
  }) {
    final rawTitle = title.trim();
    final existingNote = noteId == null ? null : findById(noteId);

    final now = DateTime.now();

    // Update existing
    if (existingNote != null) {
      existingNote
        ..title = rawTitle
        ..content = content
        ..richContent = richContent
        ..updatedAt = now;

      _box.put(existingNote.id, existingNote);
      notifyListeners();
      return existingNote;
    }

    // Creates a new note
    final newNote = NotesSection(
      title: rawTitle,
      content: content,
      //normalizedContent,
      richContent: richContent,
      createdAt: now,
      updatedAt: now,
    );

    // Maintain pinned ordering
    final pinnedCount = _notes.where((n) => n.isPinned).length;
    _notes.insert(pinnedCount, newNote);
    _noteMap[newNote.id] = newNote;
    _box.put(newNote.id, newNote);

    notifyListeners();
    return newNote;
  }

  // ------------------------------------------------------------
  // UI STATE MANAGEMENT
  // ------------------------------------------------------------

  /// Toggles pinned state and reorders list.
  void togglePin(String noteId) {
    final note = findById(noteId);
    if (note == null) return;

    note.isPinned = !note.isPinned;
    _box.put(note.id, note);

    _sortPinnedFirst();
    notifyListeners();
  }

  /// Explicitly sets selection state.
  /// Used for deterministic actions (e.g., bulk select).
  void setSelected(String noteId, bool isSelected) {
    final note = findById(noteId);
    if (note == null) return; // #Defensive Programming approach is used here

    note.isSelected = isSelected;
    notifyListeners();
  }

  /// Toggles selection state.
  /// Used for user interactions.
  void toggleSelected(String noteId) {
    final note = findById(noteId);
    if (note == null) return;

    note.isSelected = !note.isSelected;
    notifyListeners();
  }

  /// Select/Deselect all active notes.
  void setSelectAllForAllActiveNotes(bool isSelected) {
    for (final note in _notes) {
      if (!note.isDeleted) {
        note.isSelected = isSelected;
      }
    }
    notifyListeners();
  }

  /// Clears all selections.
  void clearSelection() {
    for (final note in _notes) {
      note.isSelected = false;
    }
    notifyListeners();
  }

  // ------------------------------------------------------------
  // DELETION LOGIC
  // ------------------------------------------------------------

  /// Soft delete: moves bulk notes to recycle bin.(selection mode)
  void moveSelectedNotesToRecycleBin(List<NotesSection> notes) {
    for (final note in notes) {
      note
        ..isDeleted = true
        ..isSelected = false;
      _box.put(note.id, note);
    }

    notifyListeners();
  }

  ///Soft delete: moves one note to recycle bin.(Dismissible)
  void moveToRecycleBin(String noteId) {
    final note = findById(noteId);
    if (note == null) return;

    note
      ..isDeleted = true
      ..isSelected = false; // Unselect it just in case

    _box.put(note.id, note);
    notifyListeners();
  }

  /// Restores a note from recycle bin.
  bool restoreNote(String noteId) {
    final note = findById(noteId);
    if (note == null) return false;

    note
      ..isDeleted = false
      ..isSelected = false;
    _box.put(note.id, note);

    notifyListeners();
    return true;
  }

  /// Permanently deletes a note.
  bool deleteForever(String noteId) {
    debugPrint("Listener fired from note_repository deleteForever");
    final previousLength = _notes.length;
    //Layer 1 (UI List)
    _notes.removeWhere((note) => note.id == noteId);
    //Layer 2 (The Index):
    _noteMap.remove(noteId);
    //Layer 3 (The Storage):
    _box.delete(noteId);
    notifyListeners();

    return _notes.length != previousLength;
  }

  // ------------------------------------------------------------
  // SORTING LOGIC
  // ------------------------------------------------------------

  /// Ensures pinned notes appear first.
  /// Maintains UI ordering invariant.
  void _sortPinnedFirst() {
    final pinnedNotes = _notes.where((note) => note.isPinned).toList();
    final unpinnedNotes = _notes.where((note) => !note.isPinned).toList();

    _notes
      ..clear()
      ..addAll(pinnedNotes)
      ..addAll(unpinnedNotes);
  }

  void updateColorForSelectedNotes(Color color) {
    // 1. Identify selected notes
    final selected = _notes.where((n) => n.isSelected).toList();

    if (selected.isEmpty) return;

    // 2. Perform bulk update
    for (var note in selected) {
      note.cardColorValue = color.value; // Update the persistent int value
      _box.put(note.id, note);
    }
    notifyListeners();
  }

  // 3. Persist to Hive (Layer 3)
}

/// Global singleton access.
/// NOTE: Replace with dependency injection for scalability.
final NoteRepository noteRepository = NoteRepository();

/*
Repository Design: 

“I used a repository pattern to manage notes in memory and synchronize with persistent storage. 
It supports CRUD operations, search, selection, and soft deletion. 
I also implemented optimizations like avoiding unnecessary updates and ensuring pinned notes are always prioritized. 
For scalability, I’m aware that I should separate UI state, introduce indexing for faster lookup, 
and use dependency injection instead of a singleton.”

Separation of Concerns: The Map handles data access, the List handles UI presentation, 
and the Box handles physical storage.
*/
