import 'package:flutter/material.dart';
import 'package:notepad/core/data/app_data.dart';
import 'package:notepad/core/services/note_preview_text.dart';

/// ---------------------------------------------------------------------------
/// SEARCH RESULT CARD
/// ---------------------------------------------------------------------------
///
/// Displays a single search result (note).
///
/// Responsibilities:
/// - Show note title with highlighted matches
/// - Show preview snippets from content
/// - Highlight query matches in both title and preview
/// - Handle tap navigation via callback
///
/// Design:
/// - Stateless → fully driven by input data
/// - Uses helper functions for text highlighting and snippet extraction
class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    required this.note,
    required this.query,
    required this.onTap,
    super.key,
  });

  /// Note data to display
  final NotesSection note;

  /// Current search query (used for highlighting)
  final String query;

  /// Tap handler (usually navigates to NotePage)
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    /// Base style for title text
    final titleStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );

    /// Base style for preview text
    final previewStyle = TextStyle(color: Colors.grey[700], height: 1.25);

    /// Highlight style applied to matched query segments
    const highlightStyle = TextStyle(
      backgroundColor: Color(0xFFFFF176),
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );

    /// Extracts relevant preview lines from note content
    /// based on the search query
    final previewLines = extractSearchSnippets(note.content, query);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.hardEdge,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),

        /// ---------------------------------------------------------------
        /// TITLE WITH HIGHLIGHTED MATCHES
        /// ---------------------------------------------------------------
        title: Text.rich(
          TextSpan(
            children: buildHighlightedTextSpans(
              text: note.title.isEmpty ? 'Untitled note' : note.title,
              query: query,
              baseStyle: titleStyle,
              // Merge base + highlight styles
              highlightStyle: titleStyle.merge(highlightStyle),
            ),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        /// ---------------------------------------------------------------
        /// PREVIEW SNIPPETS
        /// ---------------------------------------------------------------
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            /// Each line represents a snippet containing query matches
            children: previewLines.map((line) {
              /// Detects if snippet comes from a list-style content
              final isListLine = isListStyledPreviewLine(line);

              /// Removes list markers for cleaner display
              final previewText = isListLine ? stripListMarker(line) : line;

              return Padding(
                padding: const EdgeInsets.only(bottom: 2),

                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: buildHighlightedTextSpans(
                            text: previewText,
                            query: query,
                            baseStyle: previewStyle,
                            // Highlight styling merged with preview style
                            highlightStyle: previewStyle.merge(highlightStyle),
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),

        /// Tap interaction (navigation handled externally)
        onTap: onTap,
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// SEARCH EMPTY / MESSAGE STATE
/// ---------------------------------------------------------------------------
///
/// Displays feedback when:
/// - No query entered
/// - No results found
///
/// Responsibilities:
/// - Show icon, title, and subtitle message
/// - Provide guidance to user
class SearchMessage extends StatelessWidget {
  const SearchMessage({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  /// Main message text
  final String title;

  /// Secondary explanatory text
  final String subtitle;

  /// Icon representing state (empty / no results / search)
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// State icon
            Icon(icon, size: 48, color: Colors.grey[500]),

            const SizedBox(height: 12),

            /// Title message
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),

            const SizedBox(height: 6),

            /// Subtitle message
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
