import 'package:flutter/material.dart';

/// Extracts a few lines of text to show as a "teaser" in the note list card.
List<String> extractPreviewLines(String content, {int maxLines = 2}) {
  //1. Line Ending Normalization
  //Data Sanitization—taking raw, unpredictable user input and turning it into predictable, structured output
  final normalizedLines = content
      .replaceAll('\r\n', '\n')
      //2. Splitting into a List
      .split('\n')
      //3. Whitespace & Tab "Collapsing"
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      //4. Empty Line Removal
      .where((line) => line.isNotEmpty)
      .toList();
  //5. The "No Text" Safety Net
  if (normalizedLines.isEmpty) {
    return const ['No additional text'];
  }
  //6. Final Truncation
  // Only take the first few lines as defined by maxLines (default is 2).
  return normalizedLines.take(maxLines).toList();
}

/// Creates a "Google-style" search snippet. 
/// If the query is found deep in the text, it centers the snippet around the match.
List<String> extractSearchSnippets(
  String content,
  String query, {
  int maxLines = 2,
  int contextCharacters = 54, // How much text to show around the keyword
}) {
  //1. The Normalization Phase
  final normalizedQuery = query.trim().toLowerCase();

  // If no search query, just show the standard preview.
  if (normalizedQuery.isEmpty) {
    return extractPreviewLines(content, maxLines: maxLines);
  }

  final normalizedLines = content
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .toList();

  final snippets = <String>[];
  for (final line in normalizedLines) {
    final lowerLine = line.toLowerCase();
    //2. The Matching Loop
    final matchIndex = lowerLine.indexOf(normalizedQuery);

    // Skip lines that don't contain the search term.
    if (matchIndex < 0) {
      continue;
    }

    //3. Calculating the "Window" (The Math)
    // Calculate a "window" around the matching word.
    final start = (matchIndex - contextCharacters ~/ 2).clamp(0, line.length);
    final end = (matchIndex + normalizedQuery.length + contextCharacters ~/ 2)
        .clamp(0, line.length);
    final hasLeadingOverflow = start > 0;
    final hasTrailingOverflow = end < line.length;
    final snippet = line.substring(start, end).trim();

    //4. Adding Ellipses (...)
    // Add ellipses (...) if the text was cut off on either side.
    snippets.add(
      '${hasLeadingOverflow ? '...' : ''}$snippet${hasTrailingOverflow ? '...' : ''}',
    );
    //5. Output and Fallback
    if (snippets.length == maxLines) {
      break;
    }
  }
  // Return the highlighted snippets, or standard preview if no matches found in lines.
  if (snippets.isNotEmpty) {
    return snippets;
  }
  // If no snippets were found during the loop, this line runs:
  return extractPreviewLines(content, maxLines: maxLines);
}

/// Checks if a line starts with a list marker like "1.", "-", or "•".
bool isListStyledPreviewLine(String line) {
  return RegExp(r'^([-*•]\s+|\d+[.)]\s+)').hasMatch(line);
}

/// Removes list markers so the preview starts with pure text content.
String stripListMarker(String line) {
  return line.replaceFirst(RegExp(r'^([-*•]\s+|\d+[.)]\s+)'), '').trim();
}

/// A complex builder that breaks a string into "spans."
/// It finds the search query and applies the [highlightStyle] only to those parts.
List<InlineSpan> buildHighlightedTextSpans({
  required String text,
  required String query,
  required TextStyle baseStyle,
  required TextStyle highlightStyle,
}) {
  final normalizedQuery = query.trim();
  //1. The Early Exit (The Safety Check)
  if (normalizedQuery.isEmpty || text.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final lowerText = text.toLowerCase();
  //2. Case-Insensitive Preparation
  final lowerQuery = normalizedQuery.toLowerCase();
  final spans = <InlineSpan>[];
  var start = 0;

  //3. The Search Loop
  // Loop through the text to find every occurrence of the query.
  while (true) {
    final matchIndex = lowerText.indexOf(lowerQuery, start); //Finding the Match
    //4. The Final Piece
    // If no more matches, add the remaining plain text and stop.
    if (matchIndex < 0) {
      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
      }
      break;
    }

    // Add the plain text appearing BEFORE the match.
    if (matchIndex > start) {
      spans.add(
        TextSpan(text: text.substring(start, matchIndex), style: baseStyle),
      );
    }

    // Add the MATCHING text with the highlight style.
    spans.add(
      TextSpan(
        text: text.substring(matchIndex, matchIndex + normalizedQuery.length),
        style: highlightStyle,
      ),
    );

    // Move the pointer forward to search for the next match.
    start = matchIndex + normalizedQuery.length;
  }

  return spans;
}
