import 'package:flutter/material.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/features/note/data/note_repository.dart';
import 'package:notepad/features/note/note_page.dart';
import 'package:notepad/features/search/controllers/search_controller.dart'
    as search_ctrl;
import 'package:notepad/features/search/models/search_filters.dart';
import 'package:notepad/features/search/widgets/search_filter_dialog.dart';
import 'package:notepad/features/search/widgets/search_results_panel.dart';

/// ---------------------------------------------------------------------------
/// SEARCH PAGE
/// ---------------------------------------------------------------------------
///
/// UI entry point for searching notes.
///
/// Responsibilities:
/// - Capture user input (query)
/// - Trigger filter dialog
/// - Delegate all search logic to SearchController
/// - Render results via SearchResultsPanel
///
/// Note:
/// This widget intentionally contains no business logic.
/// Controller handles state, debounce, and search execution.
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  /// Controller responsible for:
  /// - Query state
  /// - Filter state
  /// - Search execution
  /// - Result caching
  late final search_ctrl.SearchController _searchController =
      search_ctrl.SearchController(repository: noteRepository);

  /// Focus node for controlling keyboard focus of search field
  final FocusNode _searchFocusNode = FocusNode();

  /// Helper getter for theme-based UI decisions
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();

    /// Ensures search field is focused after first frame render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    /// Clean up resources to prevent memory leaks
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    /// Current query derived from text field

    return Scaffold(
      /// ---------------------------------------------------------------------
      /// APP BAR
      /// ---------------------------------------------------------------------
      appBar: AppBar(
        title: const Text(
          'Search Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      /// ---------------------------------------------------------------------
      /// BODY
      /// ---------------------------------------------------------------------
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            /// ---------------------------------------------------------------
            /// SEARCH INPUT + FILTER BUTTON
            /// ---------------------------------------------------------------
            Row(
              children: [
                Expanded(
                  child: TextField(
                    //Delegates query handling (debounce + search trigger)
                    onChanged: _searchController.onQueryChanged,
                    //Controller owned by SearchController (single source of truth)
                    controller: _searchController.textController,
                    focusNode: _searchFocusNode,
                    textInputAction: TextInputAction.search,
                    // Text color adapts to theme
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Search title or content...',
                      // Hint styling based on theme
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      // Clear button appears only when query exists
                      suffixIcon: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _searchController.textController,
                        builder: (context, value, _) {
                          return value.text.isEmpty
                              ? const SizedBox.shrink()
                              : IconButton(
                                  icon: Icon(Icons.clear),
                                  // Clears query via controller
                                  onPressed: () {
                                    _searchController.clearQuery();
                                    _searchFocusNode.requestFocus();
                                  },
                                );
                        },
                      ),
                      filled: true,
                      //Background surface styling
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          UIConstants.radiusXL,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          UIConstants.radiusXL,
                        ),
                        //borderSide: BorderSide(color: Colors.blue),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.6),
                          width: UIConstants.searchFieldBorderWidth,
                        ),
                        borderRadius: BorderRadius.circular(
                          UIConstants.radiusXL,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 6),

                /// Filter icon button
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: _searchFilter(),
                ),
              ],
            ),

            /// ---------------------------------------------------------------
            /// SEARCH RESULTS PANEL
            /// ---------------------------------------------------------------
            Expanded(
              child: SearchResultsPanel(
                controller: _searchController,

                /// Handles navigation to note page
                onNoteTap: (note) async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotePage(noteId: note.id),
                    ),
                  );

                  if (mounted) _searchController.refresh();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// FILTER BUTTON WIDGET
  /// -------------------------------------------------------------------------
  ///
  /// Opens search filter dialog when tapped
  Widget _searchFilter() {
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(),
      onPressed: _openSearchFilterDialog, // Moves logic here
      icon: ImageIcon(
        const AssetImage('assets/images/filter_icon.png'),
        color: isDark ? const Color(0xFFFFFFFF) : Colors.black54,
        size: 24,
      ),
      // You can customize the splash radius if it feels too big
      splashRadius: 24,
    );
  }

  /// -------------------------------------------------------------------------
  /// FILTER DIALOG HANDLER - follows Delegation Pattern
  /// -------------------------------------------------------------------------
  ///
  /// Flow:
  /// - Open dialog with current filters
  /// - Receive updated filters
  /// - Apply via controller (triggers search)
  Future<void> _openSearchFilterDialog() async {
    final result = await showModalBottomSheet<SearchFilters>(
      context: context,
      // isScrollControlled: true, // Allows it to size correctly based on content
      // backgroundColor:
      //     Colors.transparent, // Lets us make custom rounded corners
      builder: (context) =>
          SearchFilterBottomSheet(initialFilters: _searchController.filters),
    );

    /// If user cancels dialog → no action
    if (result == null) {
      return;
    }

    /// Apply filters and trigger search
    _searchController.applyFilters(result);
  }
}
