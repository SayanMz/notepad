import 'package:flutter/material.dart';

import 'package:notepad/data/app_data.dart';
import 'package:notepad/data/note_repository.dart';
import 'package:notepad/services/note_text_utils.dart';
import 'package:notepad/views/note/note_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchQuery = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // UX OPTIMIZATION: Automatically trigger the keyboard after the page transition finishes.
    // Using a post-frame callback prevents keyboard-opening lag during the slide animation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    // Standard cleanup to prevent memory leaks in the background.
    _searchQuery.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final query = _searchQuery.text.trim();

    // ARCHITECTURE NOTE: The search algorithm is offloaded to the repository.
    // This allows for future optimizations (like indexed search) without changing this UI.
    final results = noteRepository.search(query);

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF09090B) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Search Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: BackButton(),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              textAlignVertical: TextAlignVertical.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              controller: _searchQuery,
              focusNode: _searchFocusNode,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _searchFocusNode.unfocus(),
              maxLines: 1,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                hintText: 'Search title or content...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery.clear());
                          _searchFocusNode.requestFocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                // FIX 1: Use a subtle shadow via BoxShadow rather than Material Elevation
                // This prevents the "clipped" look in Dark Mode.
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                // FIX 2: Give a small vertical padding (8-10) to help center the cursor
                // accurately on Android devices like your A55.
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Result counter: Only visible when there is active user input.
          if (query.isNotEmpty && results.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  results.length == 1
                      ? '1 result'
                      : '${results.length} results',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          Expanded(child: _buildSearchBody(query, results)),
        ],
      ),
    );
  }

  /// UI Logic: Conditional rendering for Empty states, Instructions, or the Results list.
  Widget _buildSearchBody(String query, List<NotesSection> results) {
    if (query.isEmpty) {
      return const _SearchMessage(
        title: 'Search your notes by title or content',
        subtitle: 'Type a keyword to find matching notes instantly.',
        icon: Icons.manage_search_rounded,
      );
    }

    if (results.isEmpty) {
      return _SearchMessage(
        title: 'No notes matched "$query"',
        subtitle: 'Try a shorter phrase or search for a different keyword.',
        icon: Icons.search_off_rounded,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final note = results[index];
        return _SearchResultCard(
          note: note,
          query: query,
          onTap: () async {
            // After returning from NotePage, the UI refreshes to reflect any content changes.
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotePage(noteId: note.id),
              ),
            );

            if (!mounted) return;
            setState(() {});
          },
        );
      },
    );
  }
}

/// UI COMPONENT: Displays a specific note with highlighted text matching the query.
class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.note,
    required this.query,
    required this.onTap,
  });

  final NotesSection note;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleStyle = const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    final previewStyle = TextStyle(color: Colors.grey[700], height: 1.25);

    // VISUAL: The highlight color for matches within the text.
    const highlightStyle = TextStyle(
      backgroundColor: Color(0xFFFFF176),
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );

    // TEXT PROCESSING: Logic to find and extract sentences containing the query word.
    // This provides "context" in the search results instead of just the start of the note.
    final previewLines = extractSearchSnippets(note.content, query);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        title: Text.rich(
          TextSpan(
            // Logic: Splits the title into parts to highlight matching segments.
            children: buildHighlightedTextSpans(
              text: note.title.isEmpty ? 'Untitled note' : note.title,
              query: query,
              baseStyle: titleStyle,
              highlightStyle: titleStyle.merge(highlightStyle),
            ),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: previewLines.map((line) {
              final isListLine = isListStyledPreviewLine(line);
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
        onTap: onTap,
      ),
    );
  }
}

/// UI COMPONENT: Generic center-aligned message for informational empty states.
class _SearchMessage extends StatelessWidget {
  const _SearchMessage({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey[500]),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
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
