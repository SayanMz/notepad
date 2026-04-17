import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:notepad/core/data/app_data.dart';
import 'package:notepad/core/services/storage_service.dart';

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
  final Box<NotesSection> _box = Hive.box<NotesSection>('notes_box');

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
    for (int i = 0; i < 5100; i++) {
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

  /// Persists current in-memory notes to storage.
  /// NOTE: Explicit persistence allows batching writes.
  Future<void> persist() async {
    await StorageService.exportAllNotesToJSON(_notes);
    // notifyListeners();
  }

  /// Adds initial demo notes for onboarding UX.
  void _addSeedNotes() {
    _notes.addAll([
      NotesSection(
        title: 'Welcome to Notepad! 👋',
        content:
            'Here are a few tips to get you started:\n• Tap a note to edit it.\n• Long-press to select and delete.\n• Use the search bar to find keywords instantly.',
      ),
      NotesSection(
        title: 'Grocery List 🛒',
        content:
            '- Milk and Eggs\n- Fresh Vegetables\n- Whole Grain Bread\n- Coffee Beans',
      ),
      NotesSection(
        title: 'Favorite Quote 🖋️',
        content:
            '"The secret of getting ahead is getting started." — Mark Twain',
      ),
      NotesSection(
        title: 'App Features 💡',
        content:
            'This app supports pinning important notes to the top and a Recycle Bin to recover anything you accidentally deleted!',
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
  List<NotesSection> search(String query) {
    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return const [];
    }

    return List<NotesSection>.unmodifiable(
      _notes.where((note) {
        if (note.isDeleted) return false;

        final title = note.title.toLowerCase();
        final content = note.content.toLowerCase();

        return title.contains(normalizedQuery) ||
            content.contains(normalizedQuery);
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
    final normalizedContent = content.trimRight();
    final existingNote = noteId == null ? null : findById(noteId);

    // Skip if nothing changed
    if (existingNote != null &&
        existingNote.title == rawTitle &&
        existingNote.content == normalizedContent &&
        existingNote.richContent == richContent) {
      return existingNote;
    }

    final now = DateTime.now();

    // Update existing
    if (existingNote != null) {
      existingNote
        ..title = rawTitle
        ..content = normalizedContent
        ..richContent = richContent
        ..updatedAt = now;

      StorageService.saveNote(existingNote);
      notifyListeners();
      return existingNote;
    }

    // Creates a new note
    final newNote = NotesSection(
      title: rawTitle,
      content: normalizedContent,
      richContent: richContent,
      createdAt: now,
      updatedAt: now,
    );

    // Maintain pinned ordering
    final pinnedCount = _notes.where((n) => n.isPinned).length;
    _notes.insert(pinnedCount, newNote);
    _noteMap[newNote.id] = newNote;
    StorageService.saveNote(newNote);

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
    if (note == null) return;

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

  /// Soft delete: moves notes to recycle bin.
  int moveSelectedNotesToRecycleBin() {
    final selected = selectedNotes.where((note) => !note.isDeleted).toList();

    for (final note in selected) {
      note
        ..isDeleted = true
        ..isSelected = false;
      _box.put(note.id, note);
    }

    notifyListeners();
    return selected.length;
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
    StorageService.deleteNote(noteId);

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
