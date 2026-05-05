import 'package:flutter/material.dart';
import 'package:notepad/core/data/app_data.dart';
import 'package:notepad/features/search/controllers/search_controller.dart'
    as search_ctrl;
import 'package:notepad/features/search/models/search_filters.dart';
import 'package:notepad/features/search/widgets/search_result_card.dart';

class SearchResultsPanel extends StatelessWidget {
  const SearchResultsPanel({
    required this.controller,
    required this.onNoteTap,
    required this.showChips,
    required this.onClearFilter, // NEW: Callback added
    super.key,
  });

  final search_ctrl.SearchController controller;
  final Future<void> Function(NotesSection note) onNoteTap;
  final bool showChips;
  final VoidCallback onClearFilter; // NEW: Triggers parent header reveal

  void _applyQuickFilter(int daysBack) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: daysBack));

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

  bool _isQuickChipActive(SearchFilters currentFilters, int daysBack) {
    if (!currentFilters.isRangeSearch) return false;

    final now = DateTime.now();
    final start = now.subtract(Duration(days: daysBack));

    return currentFilters.startYear == start.year.toString() &&
        currentFilters.startMonth == start.month.toString().padLeft(2, '0') &&
        currentFilters.startDay == start.day.toString().padLeft(2, '0') &&
        currentFilters.endYear == now.year.toString() &&
        currentFilters.endMonth == now.month.toString().padLeft(2, '0') &&
        currentFilters.endDay == now.day.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final query = controller.query;
        final results = controller.results;
        final hasCriteria = controller.hasAnyCriteria;
        final hasFilters = controller.hasFilters;

        final is1DayActive = _isQuickChipActive(controller.filters, 1);
        final is7DaysActive = _isQuickChipActive(controller.filters, 7);
        final is30DaysActive = _isQuickChipActive(controller.filters, 30);
        final isAnyQuickChipActive =
            is1DayActive || is7DaysActive || is30DaysActive;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ---------------------------------------------------------------
            /// TOP ROW: ANIMATED QUICK CHIPS
            /// ---------------------------------------------------------------
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: showChips
                  ? SizedBox(
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10, left: 5),

                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 18,
                                color: isAnyQuickChipActive
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : Colors.grey[500],
                              ),
                              const SizedBox(width: 22.5),
                              _buildActionChip(
                                label: 'Yesterday',
                                isSelected: is1DayActive,
                                onPressed: () => _applyQuickFilter(1),
                                context: context,
                              ),
                              const SizedBox(width: 8),
                              _buildActionChip(
                                label: 'Past 7 days',
                                isSelected: is7DaysActive,
                                onPressed: () => _applyQuickFilter(7),
                                context: context,
                              ),
                              const SizedBox(width: 8),
                              _buildActionChip(
                                label: 'Past 30 days',
                                isSelected: is30DaysActive,
                                onPressed: () => _applyQuickFilter(30),
                                context: context,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity, height: 0),
            ),

            /// ---------------------------------------------------------------
            /// MIDDLE ROW: RESULT COUNT (Always Visible)
            /// ---------------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (hasCriteria && results.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: Text(
                      results.length == 1
                          ? '1 result'
                          : '${results.length} results',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Spacer(),
                if (hasFilters)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: TextButton.icon(
                      onPressed: () {
                        controller.clearFilter();
                        onClearFilter(); // FIX: Fire the callback to reveal headers
                      },
                      icon: const Icon(Icons.filter_alt_off, size: 18),
                      label: const Text('Clear Filter'),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark
                            ? Colors.grey[400]
                            : Colors.grey[700],
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
              ],
            ),

            /// ---------------------------------------------------------------
            /// BOTTOM SECTION: RESULTS / EMPTY STATES
            /// ---------------------------------------------------------------
            Expanded(
              child: Builder(
                builder: (context) {
                  if (!hasCriteria) {
                    return const SearchMessage(
                      title: 'Search your notes by title or content',
                      subtitle:
                          'Type a keyword or use the filter to find notes.',
                      icon: Icons.manage_search_rounded,
                    );
                  }

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

                  return ListView.builder(
                    padding: const EdgeInsets.only(left: 8, right: 15),
                    itemCount: results.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final note = results[index];
                      return SearchResultCard(
                        note: note,
                        query: query,
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

  Widget _buildActionChip({
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
    required BuildContext context,
  }) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color chipColor = isSelected
        ? Theme.of(context).colorScheme.primaryContainer.withAlpha(150)
        : (isDark ? Colors.grey[800]! : Colors.grey[200]!);

    return ActionChip(
      label: Text(label),
      onPressed: onPressed,
      backgroundColor: chipColor,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }
}
