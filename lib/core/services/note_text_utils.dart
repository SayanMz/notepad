import 'package:flutter/material.dart';

/// Converts note text into short preview lines for list cards and search.
List<String> extractPreviewLines(String content, {int maxLines = 2}) {
  final normalizedLines = content
      .replaceAll('\r\n', '\n')
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .toList();

  if (normalizedLines.isEmpty) {
    return const ['No additional text'];
  }

  return normalizedLines.take(maxLines).toList();
}

/// Returns search snippets centered around the matched query when possible.
List<String> extractSearchSnippets(
  String content,
  String query, {
  int maxLines = 2,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final lines = content.replaceAll('\r\n', '\n').split('\n');

  if (normalizedQuery.isEmpty) {
    return extractPreviewLines(content, maxLines: maxLines);
  }

  final matchingIndex = lines.indexWhere(
    (line) => line.toLowerCase().contains(normalizedQuery),
  );

  if (matchingIndex == -1) {
    return extractPreviewLines(content, maxLines: maxLines);
  }

  final start = matchingIndex.clamp(0, lines.length - 1);
  final end = (matchingIndex + maxLines).clamp(0, lines.length);
  final snippet = lines.sublist(start, end);

  return snippet
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .toList();
}

/// Splits text into highlighted and normal spans for search result rendering.
List<TextSpan> buildHighlightedTextSpans({
  required String text,
  required String query,
  required TextStyle baseStyle,
  required TextStyle highlightStyle,
}) {
  final normalizedQuery = query.trim();
  if (normalizedQuery.isEmpty) {
    return [TextSpan(text: text, style: baseStyle)];
  }

  final lowerText = text.toLowerCase();
  final lowerQuery = normalizedQuery.toLowerCase();
  final spans = <TextSpan>[];
  var start = 0;

  while (true) {
    final matchIndex = lowerText.indexOf(lowerQuery, start);
    if (matchIndex == -1) {
      if (start < text.length) {
        spans.add(TextSpan(text: text.substring(start), style: baseStyle));
      }
      break;
    }

    if (matchIndex > start) {
      spans.add(
        TextSpan(text: text.substring(start, matchIndex), style: baseStyle),
      );
    }

    spans.add(
      TextSpan(
        text: text.substring(matchIndex, matchIndex + normalizedQuery.length),
        style: highlightStyle,
      ),
    );

    start = matchIndex + normalizedQuery.length;
  }

  return spans;
}

/// Detects whether a preview line still includes a list marker.
bool isListStyledPreviewLine(String line) {
  return RegExp(r'^\s*([-•·]|\d+\.)\s+').hasMatch(line);
}

/// Removes list markers (bullets, numbers) from the start of a line for clean previews.
String stripListMarker(String line) {
  return line.replaceFirst(RegExp(r'^\s*([-•·]|\d+\.)\s+'), '');
}
