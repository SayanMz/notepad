import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notepad/views/pages/home_page.dart';
import 'package:notepad/data/note_repository.dart'; 
import 'package:notepad/main.dart'; // Needed for rootScaffoldMessengerKey

void main() {
  setUp(() {
    // 1. Clear out any old test data
    //noteRepository.resetForTesting();
    
    // 2. THE GETTER FIX: Use the official save method to inject the fake note!
    noteRepository.saveNote(
      noteId: 'test-123',
      title: 'Unit Test Note',
      content: 'This is a test.',
      richContent: '[]', // Dummy JSON
      //useUntitledTitleFallback: true,
    );
  });

  testWidgets('Swiping a note triggers the Dismissible and shows Undo SnackBar', (WidgetTester tester) async {
    // 1. ARRANGE: Build the UI
    await tester.pumpWidget(
      MaterialApp(
        scaffoldMessengerKey: rootScaffoldMessengerKey, 
        home: const HomePage(),
      ),
    );

    // Initial render
    await tester.pumpAndSettle();

    // Verify our injected note rendered successfully
    final noteFinder = find.byKey(const ValueKey('dismiss_test-123'));
    expect(noteFinder, findsOneWidget, reason: 'The note should be visible on screen');

    // 2. ACT: Simulate the left-to-right swipe
    await tester.drag(noteFinder, const Offset(500.0, 0.0));
    
    // THE TIMER FIX: Fast-forward the clock just enough for the swipe animation to finish (500ms)
    await tester.pump(const Duration(milliseconds: 500));

    // 3. ASSERT: Verify the UI reacted correctly
    expect(noteFinder, findsNothing, reason: 'Note should be removed from the list');
    expect(find.text('1 Note moved to recycle bin'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // Clean up: Fast-forward the clock 4 seconds so the SnackBar timer finishes safely
    await tester.pump(const Duration(seconds: 4));
  });
}