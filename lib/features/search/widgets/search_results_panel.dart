import 'package:flutter/material.dart';
import 'package:notepad/core/data/app_data.dart';
import 'package:notepad/features/search/controllers/search_controller.dart'
    as search_ctrl;
import 'package:notepad/features/search/models/search_filters.dart';
import 'package:notepad/features/search/widgets/search_result_card.dart';

/// ---------------------------------------------------------------------------
/// SEARCH RESULTS PANEL
/// ---------------------------------------------------------------------------
///
/// UI layer component responsible for:
/// - Rendering search results
/// - Displaying quick filters (chips)
/// - Showing result count or empty states
///
/// Architectural Role:
/// - Pure presentation layer
/// - Delegates all logic/state to SearchController
///
/// Design:
/// - Uses ListenableBuilder to react to controller changes
/// - Keeps UI declarative and state minimal
class SearchResultsPanel extends StatelessWidget {
  const SearchResultsPanel({
    required this.controller,
    required this.onNoteTap,
    super.key,
  });

  /// Controller providing query, filters, and results
  final search_ctrl.SearchController controller;

  /// Callback when a note is tapped
  final Future<void> Function(NotesSection note) onNoteTap;

  /// -------------------------------------------------------------------------
  /// QUICK FILTER APPLICATION
  /// -------------------------------------------------------------------------
  ///
  /// Applies predefined date-range filters (e.g., last 7 days)
  ///
  /// Design:
  /// - Converts relative time (daysBack) into absolute date filters
  /// - Delegates actual filtering to controller
  void _applyQuickFilter(int daysBack) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: daysBack));

    final filter = SearchFilters(
      isRangeSearch: true,
      startYear: start.year.toString(),
      startMonth: start.month.toString().padLeft(2, '0'),
      startDay: start.day.toString().padLeft(2, '0'),
      endYear: now.year.toString(),
      endMonth: now.month.toString().padLeft(2, '0'),
      endDay: now.day.toString().padLeft(2, '0'),
    );

    controller.applyFilters(filter);
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    /// -----------------------------------------------------------------------
    /// ROOT REACTIVE BUILDER
    /// -----------------------------------------------------------------------
    ///
    /// Listens to controller and rebuilds entire UI when state changes
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final query = controller.query;
        final results = controller.results;
        final hasCriteria = controller.hasAnyCriteria;

        return Column(
          children: [
            /// ---------------------------------------------------------------
            /// TOP SECTION: RESULT COUNT / QUICK FILTER CHIPS
            /// ---------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// LEFT SIDE (dynamic content)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      /// STATE 1: Active search with results → show count
                      if (hasCriteria && results.isNotEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
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
                        );
                      }

                      /// STATE 2: No search → show quick filter chips
                      if (!hasCriteria) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: SizedBox(
                            width: double.infinity,

                            /// Horizontal scroll for filter chips
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  /// Icon indicating quick actions
                                  Icon(
                                    Icons.bolt_rounded,
                                    size: 18,
                                    color: Colors.grey[500],
                                  ),
                                  const SizedBox(width: 8),

                                  /// Quick filter: Last 7 days
                                  ActionChip(
                                    label: const Text('Last 7 Days'),
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide.none,
                                    backgroundColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    onPressed: () => _applyQuickFilter(7),
                                  ),

                                  const SizedBox(width: 8),

                                  /// Quick filter: Past Month
                                  ActionChip(
                                    label: const Text('Past Month'),
                                    visualDensity: VisualDensity.compact,
                                    side: BorderSide.none,
                                    backgroundColor: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    onPressed: () => _applyQuickFilter(30),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      /// Default empty state (no UI)
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                /// -----------------------------------------------------------
                /// CLEAR FILTER BUTTON
                /// -----------------------------------------------------------
                ///
                /// Visible only when search/filter is active
                if (results.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      /// Delegates reset to controller
                      controller.resetSearch();
                    },

                    icon: const Icon(Icons.filter_alt_off, size: 18),
                    label: const Text('Clear Filter'),

                    /// Subtle styling to avoid visual dominance
                    style: TextButton.styleFrom(
                      foregroundColor: isDark
                          ? Colors.grey[400]
                          : Colors.grey[700],
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),

            /// ---------------------------------------------------------------
            /// BOTTOM SECTION: RESULTS / EMPTY STATES
            /// ---------------------------------------------------------------
            Expanded(
              child: Builder(
                builder: (context) {
                  /// STATE A: Initial (no query / no filters)
                  if (!hasCriteria) {
                    return const SearchMessage(
                      title: 'Search your notes by title or content',
                      subtitle:
                          'Type a keyword or use the filter to find notes.',
                      icon: Icons.manage_search_rounded,
                    );
                  }

                  /// STATE B: No results found
                  if (results.isEmpty) {
                    return SearchMessage(
                      title: query.isNotEmpty
                          ? 'No notes matched "$query"'
                          : 'No notes matched your filters',
                      subtitle:
                          'Try a shorter phrase or adjust your date/time selection.',
                      icon: Icons.search_off_rounded,
                    );
                  }

                  /// STATE C: Results available
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: results.length,

                    /// Builds each result item
                    itemBuilder: (context, index) {
                      final note = results[index];

                      return SearchResultCard(
                        note: note,
                        query: query,

                        /// Delegate navigation handling
                        onTap: () => onNoteTap(note),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
