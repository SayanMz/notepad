// import 'package:flutter_test/flutter_test.dart';
// import 'package:notepad/data/app_data.dart';
// import 'package:notepad/data/note_repository.dart';

// void main() {
//   group('NoteRepository lifecycle', () {
//     test('creates a new note for non-empty content', () {
//       //final repository = NoteRepository(initialNotes: []);

//       final savedNote = repository.saveNote(
//         noteId: null,
//         title: '  Grocery list  ',
//         content: 'Milk\nBread',
//         //useUntitledTitleFallback: true,
//       );

//       expect(savedNote, isNotNull);
//       expect(repository.allNotes, hasLength(1));
//       expect(savedNote!.title, 'Grocery list');
//       expect(savedNote.content, 'Milk\nBread');
//       expect(savedNote.id, isNotEmpty);
//     });

//     test('updates an existing note by stable id', () {
//       final existing = NotesSection(
//         id: 'note_1',
//         title: 'Old title',
//         content: 'Old content',
//       );
//       final repository = NoteRepository(initialNotes: [existing]);

//       final savedNote = repository.saveNote(
//         noteId: existing.id,
//         title: 'New title',
//         content: 'Updated content',
//         //useUntitledTitleFallback: true,
//       );

//       expect(savedNote, same(existing));
//       expect(repository.allNotes, hasLength(1));
//       expect(existing.title, 'New title');
//       expect(existing.content, 'Updated content');
//     });

//     test('removes an existing note when title and content are cleared', () {
//       final existing = NotesSection(
//         id: 'note_1',
//         title: 'Old title',
//         content: 'Old content',
//       );
//       final repository = NoteRepository(initialNotes: [existing]);

//       final savedNote = repository.saveNote(
//         noteId: existing.id,
//         title: '   ',
//         content: '\n\n',
//         //useUntitledTitleFallback: true,
//       );

//       expect(savedNote, isNull);
//       expect(repository.allNotes, isEmpty);
//     });

//     test('restores and permanently deletes notes by id', () {
//       final deletedNote = NotesSection(
//         id: 'note_deleted',
//         title: 'Archived',
//         isDeleted: true,
//       );
//       final repository = NoteRepository(initialNotes: [deletedNote]);

//       expect(repository.restoreNote(deletedNote.id), isTrue);
//       expect(deletedNote.isDeleted, isFalse);

//       expect(repository.deleteForever(deletedNote.id), isTrue);
//       expect(repository.allNotes, isEmpty);
//     });
//   });

//   group('NoteRepository queries and selection', () {
//     test('search matches active notes and ignores deleted ones', () {
//       final repository = NoteRepository(
//         initialNotes: [
//           NotesSection(id: '1', title: 'Flutter ideas', content: 'State'),
//           NotesSection(
//             id: '2',
//             title: 'Deleted flutter note',
//             content: 'Hidden',
//             isDeleted: true,
//           ),
//           NotesSection(id: '3', title: 'Groceries', content: 'Milk and eggs'),
//         ],
//       );

//       final results = repository.search('flutter');

//       expect(results.map((note) => note.id), ['1']);
//     });

//     test(
//       'select all only affects active notes and bulk delete clears selection',
//       () {
//         final activeOne = NotesSection(id: '1', title: 'One');
//         final activeTwo = NotesSection(id: '2', title: 'Two');
//         final deleted = NotesSection(id: '3', title: 'Three', isDeleted: true);
//         final repository = NoteRepository(
//           initialNotes: [activeOne, activeTwo, deleted],
//         );

//         repository.setSelectAllForAllActiveNotes(true);

//         expect(repository.areAllActiveNotesSelected, isTrue);
//         expect(activeOne.isSelected, isTrue);
//         expect(activeTwo.isSelected, isTrue);
//         expect(deleted.isSelected, isFalse);

//         final movedCount = repository.moveSelectedNotesToRecycleBin();

//         expect(movedCount, 2);
//         expect(activeOne.isDeleted, isTrue);
//         expect(activeTwo.isDeleted, isTrue);
//         expect(activeOne.isSelected, isFalse);
//         expect(activeTwo.isSelected, isFalse);
//       },
//     );

//     test('pinning keeps pinned notes at the top', () {
//       final first = NotesSection(id: '1', title: 'First');
//       final second = NotesSection(id: '2', title: 'Second');
//       final repository = NoteRepository(initialNotes: [first, second]);

//       repository.togglePin(second.id);

//       expect(repository.allNotes.first.id, second.id);
//       expect(second.isPinned, isTrue);
//     });
//   });
// }
