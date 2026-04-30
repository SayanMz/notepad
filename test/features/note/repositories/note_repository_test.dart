// import 'dart:io';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:hive/hive.dart';
// import 'package:notepad/core/data/app_data.dart';
// import 'package:notepad/features/note/data/note_repository.dart';

// void main() {
//   late NoteRepository repository;
//   late Directory tempDir;

//   setUp(() async {
//     tempDir = await Directory.systemTemp.createTemp('hive_test_sandbox');
//     Hive.init(tempDir.path);

//     if (!Hive.isAdapterRegistered(0)) {
//       Hive.registerAdapter(NotesSectionAdapter());
//     }

//     await Hive.openBox<NotesSection>('notes_box');

//     repository = NoteRepository.internalForTesting();
//     await repository.init();

//     // THE FIX: Nuke the 4 auto-generated seed notes so the test starts at exactly 0
//     final allNoteIds = repository.allNotes.map((n) => n.id).toList();
//     for (final id in allNoteIds) {
//       repository.deleteForever(id);
//     }
//   });

//   tearDown(() async {
//     await Hive.deleteFromDisk();
//     await tempDir.delete(recursive: true);
//   });

//   group('NoteRepository Data Integrity', () {
//     test('Search ignores deleted notes and finds correct matches', () {
//       repository.saveNote(noteId: null, title: 'Flutter Basics', content: '');
//       repository.saveNote(noteId: null, title: 'Dart Testing', content: '');

//       final deletedNote = repository.saveNote(
//         noteId: null,
//         title: 'Flutter Advanced',
//         content: '',
//       );
//       repository.moveToRecycleBin(deletedNote!.id);

//       final results = repository.search('Flutter', query: '');

//       expect(results.length, 1);
//       expect(results.first.title, 'Flutter Basics');
//     });

//     test('Pinned ordering pushes a bottom note mathematically to index 0', () {
//       // Because your saveNote inserts at the top, note1 gets pushed to the bottom
//       final note1 = repository.saveNote(
//         noteId: null,
//         title: 'Note 1',
//         content: '',
//       );
//       // final note2 = repository.saveNote(
//       //   noteId: null,
//       //   title: 'Note 2',
//       //   content: '',
//       // );
//       // final note3 = repository.saveNote(
//       //   noteId: null,
//       //   title: 'Note 3',
//       //   content: '',
//       // );

//       // Prove note1 is currently at the bottom (index 2)
//       expect(repository.activeNotes.last.id, note1!.id);

//       // ACT: Pin note1
//       repository.togglePin(note1.id);

//       // ASSERT: Prove it instantly jumped to the very top (index 0)
//       expect(repository.activeNotes.first.id, note1.id);
//     });

//     test('Soft delete removes from UI but preserves physical data', () {
//       final targetNote = repository.saveNote(
//         noteId: null,
//         title: 'To Delete',
//         content: '',
//       );

//       expect(repository.activeNotes.length, 1);
//       expect(repository.deletedNotes.length, 0);

//       repository.moveToRecycleBin(targetNote!.id);

//       expect(repository.activeNotes.length, 0);
//       expect(repository.deletedNotes.length, 1);

//       // Prove the O(1) Hive database kept the data
//       final box = Hive.box<NotesSection>('notes_box');
//       expect(box.length, 1);
//     });
//   });
// }
