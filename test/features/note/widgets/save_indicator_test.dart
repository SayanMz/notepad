import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notepad/features/note/widgets/save_indicator.dart';

void main() {
  testWidgets('SaveIndicator displays "Saving..." when state is saving', (
    WidgetTester tester,
  ) async {
    // 1. ARRANGE: Create a fake state locked in 'saving' mode
    final fakeState = ValueNotifier<SaveState>(SaveState.saving);

    // 2. ACT: Draw the widget on an invisible test screen
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(actions: [SaveIndicator(saveState: fakeState)]),
        ),
      ),
    );

    // 3. ASSERT: Ask Flutter to scan the screen for the exact text
    expect(find.text('Saving...'), findsOneWidget);

    // Ensure the "Saved" text is NOT on the screen yet
    expect(find.text('Saved'), findsNothing);
  });
}
