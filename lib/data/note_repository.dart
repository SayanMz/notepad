import 'package:flutter/material.dart';
import 'package:notepad/data/app_data.dart';
import 'package:notepad/services/storage_service.dart';

/// Manages the collection of notes, providing methods for CRUD operations,
/// searching, selection management, and persistence.
class NoteRepository extends ChangeNotifier {

  
  final List<NotesSection> _notes = [];   /// The master list of all notes (including deleted ones).
  NoteRepository._internal();
  static final NoteRepository _instance = NoteRepository._internal();
  factory NoteRepository() => _instance;

  Future<void> init() async {
    final savedData = await StorageService.loadNotes();
    _notes.clear();

    if (savedData.isNotEmpty) {
      _notes.addAll(savedData);
    } else {
      _addSeedNotes();
    }

    _sortPinnedFirst();
    notifyListeners();

  }

  void _addSeedNotes() { //"Seed" Data" = a helper function that generates initial "dummy" data.
    _notes.addAll([ 
      //"Fat Arrow": A shorthand function that returns a single expression.
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

  // ----- Getters (Views of the Data) -----

  /// Returns a read-only list of every note in the repository.
  List<NotesSection> get allNotes => List<NotesSection>.unmodifiable(_notes);

  /// Returns only notes that have NOT been moved to the recycle bin.
  List<NotesSection> get activeNotes =>
      List<NotesSection>.unmodifiable(_notes.where((note) => !note.isDeleted));

  /// Returns only notes currently in the trash.
  List<NotesSection> get deletedNotes =>
      List<NotesSection>.unmodifiable(_notes.where((note) => note.isDeleted));

  /// Returns notes currently marked for multi-select actions.
  List<NotesSection> get selectedNotes =>
      List<NotesSection>.unmodifiable(_notes.where((note) => note.isSelected));
  
 // int get pinnedNotesLength => _cachedPinnedCount;

  /// Logic for the "Select All" checkbox state.
  bool get areAllActiveNotesSelected {
    final visibleNotes = activeNotes;
    return visibleNotes.isNotEmpty &&
        visibleNotes.every((note) => note.isSelected);
  }
  // ----- Storage Operations -----

  /// Pulls notes from permanent storage into memory.
  Future<void> load() async {
    replaceAll(await StorageService.loadNotes());
    debugPrint("Notes are now loaded");
  }

  /// Commits current in-memory notes to permanent storage.
  Future<void> persist() async {
    StorageService.saveNotes(_notes);
    notifyListeners();
  }

  /// Wipes current list and replaces it with new data (useful after a sync or load).
  void replaceAll(Iterable<NotesSection> notes) {
    _notes
      ..clear() // 1. Clears the list, then returns _notes
      ..addAll(notes); // 2. Adds the new items to _notes
    _sortPinnedFirst();
  }

  // ----- Note Management -----

  /// Helper to find a specific note by its unique ID.
  NotesSection? findById(String id) {
    for (final note in _notes) {
      if (note.id == id) {
        return note;
      }
    }
    return null;
  }
  void moveOnTop(NotesSection note) {
    if (note.isPinned) return;
    _notes.remove(note);
    
    final pinnedCount = _notes.where((n) => n.isPinned).length;
    _notes.insert(pinnedCount, note);

    notifyListeners();
  }
 

  /// Basic search engine that checks titles and content (ignoring deleted notes).
  List<NotesSection> search(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return const [];
    }

    return List<NotesSection>.unmodifiable(
      _notes.where((note) {
        if (note.isDeleted) {
          return false;
        }

        final title = note.title.toLowerCase();
        final content = note.content.toLowerCase();
        return title.contains(normalizedQuery) ||
            content.contains(normalizedQuery);
      }),
    );
  }

  /// The "Smart Save" method: handles creating new notes, updating existing ones,
  /// or deleting notes that were saved with empty content.
NotesSection? saveNote({
  required String? noteId,
  required String title,
  required String content,
  String richContent = '',
}) {
  final rawTitle = title.trim();
  final normalizedContent = content.trimRight();
  
  // 1. Check if note already exists
  final existingNote = noteId == null ? null : findById(noteId);

  // 2. SDE Tip: If we have an existing note, compare incoming data with current data.
  // This prevents creating a "new" version of a file that hasn't actually changed.
  if (existingNote != null &&
      existingNote.title == rawTitle &&
      existingNote.content == normalizedContent &&
      existingNote.richContent == richContent) {
    return existingNote; // Return the existing note instead of null to keep the ID alive
  }

  final now = DateTime.now();

  // 3. Update Path: If noteId was provided and found
  if (existingNote != null) {
    existingNote
      ..title = rawTitle
      ..content = normalizedContent
      ..richContent = richContent
      ..updatedAt = now;
    return existingNote;
  }

  // 4. Create Path: If noteId is null
  final newNote = NotesSection(
    title: rawTitle,
    content: normalizedContent,
    richContent: richContent,
    createdAt: now,
    updatedAt: now,
  );
  
  // Insert at the top (after pinned notes)
  final pinnedCount = _notes.where((n) => n.isPinned).length;
  _notes.insert(pinnedCount, newNote);
  notifyListeners();

  return newNote;
}

  // ----- UI State Helpers -----

  void togglePin(String noteId) {
    final note = findById(noteId);
    if (note == null) {
      return;
    }

    note.isPinned = !note.isPinned;
    _sortPinnedFirst(); // Ensure pinning moves the note to the top.
    notifyListeners();
  }

  void setSelected(String noteId, bool isSelected) {
    final note = findById(noteId);
    if (note == null) {
      return;
    }

    note.isSelected = isSelected;
    print("Listener fired from note_repository setSelected");
    notifyListeners();
  }

  void toggleSelected(String noteId) {
    final note = findById(noteId);
    if (note == null) {
      return;
    }

    note.isSelected = !note.isSelected;
    print("Listener fired from note_repository toggleselected");
    notifyListeners();
  }

  /// Selects or deselects all active (non-trash) notes.
  void setSelectAllForAllActiveNotes(bool isSelected) {
    for (final note in _notes) {
      if (!note.isDeleted) {
        note.isSelected = isSelected;
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    for (final note in _notes) {
      note.isSelected = false;
    }
    notifyListeners();
  }

  // ----- Deletion Logic -----

  /// Soft-delete: Moves selected notes to the Recycle Bin.
  int moveSelectedNotesToRecycleBin() {
    final selected = selectedNotes.where((note) => !note.isDeleted).toList();
    for (final note in selected) {
      note
        ..isDeleted = true
        ..isSelected = false;
    }
    return selected.length;
  }

  /// Restores a note from the Recycle Bin back to the active list.
  bool restoreNote(String noteId) {
    final note = findById(noteId);
    if (note == null) {
      return false;
    }

    note
      ..isDeleted = false
      ..isSelected = false;

    notifyListeners();
    return true;
  }

  /// Hard-delete: Permanently removes a note from the list and memory.
  bool deleteForever(String noteId) {
    final previousLength = _notes.length;
    _notes.removeWhere((note) => note.id == noteId);
    print("Listener fired from note_repository deleteForever");
    notifyListeners();
    return _notes.length != previousLength;
  }

  // ----- Sorting Logic -----

  /// Maintains the visual order: Pinned notes at the top, others below.
  void _sortPinnedFirst() {
    final pinnedNotes = _notes.where((note) => note.isPinned).toList();
    final unpinnedNotes = _notes.where((note) => !note.isPinned).toList();

    _notes
      ..clear()
      ..addAll(pinnedNotes)
      ..addAll(unpinnedNotes);
  }
}

/// Singleton instance for easy access across the BCA project.
final NoteRepository noteRepository = NoteRepository();
