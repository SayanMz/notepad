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
