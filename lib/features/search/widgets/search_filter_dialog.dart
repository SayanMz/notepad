import 'package:flutter/material.dart';
import 'package:notepad/features/search/models/search_filters.dart';

/// ---------------------------------------------------------------------------
/// SEARCH FILTER DIALOG
/// ---------------------------------------------------------------------------
///
/// Provides UI for configuring date/time filters for search.
///
/// Responsibilities:
/// - Display selectable date/time fields
/// - Support both single-date and range-based filtering
/// - Return updated filter state to caller
///
/// Design:
/// - Local mutable state (_state) used for dialog interaction
/// - Uses immutable SearchFilters model with copyWith updates
/// - UI rebuilds only when filter values change
class SearchFilterDialog extends StatefulWidget {
  const SearchFilterDialog({required this.initialFilters, super.key});

  /// Initial filter state passed from controller
  final SearchFilters initialFilters;

  @override
  State<SearchFilterDialog> createState() => _SearchFilterDialogState();
}

class _SearchFilterDialogState extends State<SearchFilterDialog> {
  /// Helper getter for theme-based UI decisions
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  /// Local working state of filters inside dialog
  /// Modified via setState and returned on submit
  late SearchFilters _state;

  /// Precomputed dropdown values for date/time selection
  final List<String> _days = List.generate(
    31,
    (i) => (i + 1).toString().padLeft(2, '0'),
  );

  final List<String> _months = List.generate(
    12,
    (i) => (i + 1).toString().padLeft(2, '0'),
  );

  final List<String> _years = List.generate(
    10,
    (i) => (DateTime.now().year - i).toString(),
  );

  final List<String> _hours = List.generate(
    24,
    (i) => i.toString().padLeft(2, '0'),
  );

  final List<String> _minutes = List.generate(
    60,
    (i) => i.toString().padLeft(2, '0'),
  );

  @override
  void initState() {
    super.initState();

    /// Initialize local state from incoming filters
    _state = widget.initialFilters;
  }

  /// Clears all filters and resets to default (non-range mode)
  void _clearFilters() {
    setState(() {
      _state = SearchFilters(isRangeSearch: false);
    });
  }

  /// Returns selected filters back to caller
  void _submit() => Navigator.pop(context, _state);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      /// Rounded dialog shape
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),

      child: Padding(
        padding: const EdgeInsets.all(20.0),

        /// Main layout container
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// -----------------------------------------------------------
            /// START DATE (OR SINGLE DATE)
            /// -----------------------------------------------------------
            Text(
              _state.isRangeSearch ? 'START DATE' : 'DATE',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            /// Date selection row (Day / Month / Year)
            Row(
              children: [
                Expanded(
                  child: _buildRealDropdown(
                    hint: 'DD',
                    value: _state.startDay,
                    items: _days,

                    /// Updates day in state
                    onChanged: (val) => setState(() {
                      _state = _state.copyWith(startDay: val);
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildRealDropdown(
                    hint: 'MM',
                    value: _state.startMonth,
                    items: _months,

                    /// Updates month in state
                    onChanged: (val) => setState(() {
                      _state = _state.copyWith(startMonth: val);
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildRealDropdown(
                    hint: 'YYYY',
                    value: _state.startYear,
                    items: _years,

                    /// Updates year in state
                    onChanged: (val) => setState(() {
                      _state = _state.copyWith(startYear: val);
                    }),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// -----------------------------------------------------------
            /// START TIME (OR SINGLE TIME)
            /// -----------------------------------------------------------
            Text(
              _state.isRangeSearch ? 'START TIME' : 'TIME',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildRealDropdown(
                    hint: 'HH',
                    value: _state.startHour,
                    items: _hours,

                    /// Updates hour
                    onChanged: (val) => setState(() {
                      _state = _state.copyWith(startHour: val);
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: _buildRealDropdown(
                    hint: 'MM',
                    value: _state.startMinute,
                    items: _minutes,

                    /// Updates minute
                    onChanged: (val) => setState(() {
                      _state = _state.copyWith(startMinute: val);
                    }),
                  ),
                ),

                /// Toggle between single search and range search
                const Spacer(flex: 1),

                Expanded(
                  flex: 4,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: isDark
                            ? Theme.of(context).colorScheme.primary
                            : Color(0xFFF1F5F9),
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),

                      /// Toggles range search mode
                      onPressed: () {
                        setState(() {
                          _state = _state.copyWith(
                            isRangeSearch: !_state.isRangeSearch,
                          );
                        });
                      },

                      icon: Icon(
                        _state.isRangeSearch ? Icons.close : Icons.date_range,
                        size: 18,
                        color: isDark ? Colors.black : Color(0xFF475569),
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Search range',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.black
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            /// -----------------------------------------------------------
            /// END RANGE (VISIBLE ONLY IF RANGE SEARCH ENABLED)
            /// -----------------------------------------------------------
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              alignment: Alignment.topCenter,

              /// Hidden when not in range mode
              child: !_state.isRangeSearch
                  ? const SizedBox.shrink()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Divider between start and end sections
                        const Divider(height: 1, color: Colors.grey),

                        const SizedBox(height: 20),

                        const Text(
                          'END DATE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        /// End date selection
                        Row(
                          children: [
                            Expanded(
                              child: _buildRealDropdown(
                                hint: 'DD',
                                value: _state.endDay,
                                items: _days,
                                onChanged: (val) => setState(() {
                                  _state = _state.copyWith(endDay: val);
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRealDropdown(
                                hint: 'MM',
                                value: _state.endMonth,
                                items: _months,
                                onChanged: (val) => setState(() {
                                  _state = _state.copyWith(endMonth: val);
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildRealDropdown(
                                hint: 'YYYY',
                                value: _state.endYear,
                                items: _years,
                                onChanged: (val) => setState(() {
                                  _state = _state.copyWith(endYear: val);
                                }),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        const Text(
                          'END TIME',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),

                        const SizedBox(height: 8),

                        /// End time selection
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildRealDropdown(
                                hint: 'HH',
                                value: _state.endHour,
                                items: _hours,
                                onChanged: (val) => setState(() {
                                  _state = _state.copyWith(endHour: val);
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: _buildRealDropdown(
                                hint: 'MM',
                                value: _state.endMinute,
                                items: _minutes,
                                onChanged: (val) => setState(() {
                                  _state = _state.copyWith(endMinute: val);
                                }),
                              ),
                            ),
                            const Spacer(flex: 5),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
            ),

            /// -----------------------------------------------------------
            /// ACTION BUTTONS (CLEAR / APPLY)
            /// -----------------------------------------------------------
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark
                            ? Theme.of(context).colorScheme.primary
                            : Color(0xFFF1F5F9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(
                          color: isDark
                              ? Theme.of(context).colorScheme.primary
                              : Color(0xFF475569),
                        ),
                      ),

                      /// Clears filters and closes dialog
                      onPressed: () {
                        _clearFilters();
                        _submit();
                      },

                      child: Text(
                        'Clear',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.black : Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        backgroundColor: isDark
                            ? Theme.of(context).colorScheme.primary
                            : Color(0xFF334155),
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                      ),

                      /// Applies filters and closes dialog
                      onPressed: _submit,

                      child: Text(
                        'Get Search Results',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark
                              ? Colors.black
                              : const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// -------------------------------------------------------------------------
  /// REUSABLE DROPDOWN BUILDER - Encapsulation used
  /// -------------------------------------------------------------------------
  ///
  /// Used for all date/time fields to ensure consistent styling
  Widget _buildRealDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),

      /// Dropdown container styling
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),

      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          menuMaxHeight: 250,

          /// Placeholder text when no value selected
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),

          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Colors.grey,
          ),

          /// Converts list of values into dropdown items
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),

          /// Updates parent state on selection
          onChanged: onChanged,
        ),
      ),
    );
  }
}
