import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notepad/services/note_text_utils.dart';

void main() {
  test('extractPreviewLines keeps the first meaningful lines only', () {
    final previewLines = extractPreviewLines(
      '\n\n  First line  \n\n- Second line\nThird line',
    );

    expect(previewLines, ['First line', '- Second line']);
  });

  test('list preview helpers detect and strip markers', () {
    expect(isListStyledPreviewLine('- Buy milk'), isTrue);
    expect(isListStyledPreviewLine('2. Call mom'), isTrue);
    expect(isListStyledPreviewLine('Plain text'), isFalse);
    expect(stripListMarker('- Buy milk'), 'Buy milk');
    expect(stripListMarker('2. Call mom'), 'Call mom');
  });

  test(
    'buildHighlightedTextSpans highlights query matches case-insensitively',
    () {
      const baseStyle = TextStyle(color: Colors.black);
      const highlightStyle = TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      );

      final spans = buildHighlightedTextSpans(
        text: 'Learn Flutter Widgets',
        query: 'flutter',
        baseStyle: baseStyle,
        highlightStyle: highlightStyle,
      ).cast<TextSpan>();

      expect(spans.map((span) => span.text).toList(), [
        'Learn ',
        'Flutter',
        ' Widgets',
      ]);
      expect(spans[1].style?.fontWeight, FontWeight.bold);
    },
  );
}
