import 'dart:async';
import 'package:flutter/material.dart';
import 'package:notepad/core/constants/ui_constants.dart';
import 'package:notepad/core/theme/app_colors.dart';
import 'package:notepad/core/data/app_data.dart';
import 'package:notepad/features/note/data/note_repository.dart';
import 'package:notepad/core/services/note_preview_text.dart';
import 'package:notepad/features/note/note_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // Toggle for showing the second range
  bool isSearchRange = false;

  // --- START RANGE VARIABLES ---
  String? _selectedDay;
  String? _selectedMonth;
  String? _selectedYear;
  String? _selectedHour;
  String? _selectedMinute;

  // --- END RANGE VARIABLES ---
  String? _endDay;
  String? _endMonth;
  String? _endYear;
  String? _endHour;
  String? _endMinute;

  // Check if ANY filter (start or end) is active
  bool get _hasActiveFilters =>
      _selectedDay != null ||
      _selectedMonth != null ||
      _selectedYear != null ||
      _selectedHour != null ||
      _selectedMinute != null ||
      _endDay != null ||
      _endMonth != null ||
      _endYear != null ||
      _endHour != null ||
      _endMinute != null;

  // Helper lists for the dropdowns
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

  final TextEditingController _searchQuery = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounce;
  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchQuery.dispose();
    _searchFocusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final query = _searchQuery.text.trim();

    // Pass the query AND the selected dropdown states into the updated method
    // NOTE: You will need to update your NoteRepository to accept the new _end variables!
    final results = noteRepository.search(
      query: query,
      isRangeSearch: isSearchRange,
      // Pass Start Variables
      startDay: _selectedDay,
      startMonth: _selectedMonth,
      startYear: _selectedYear,
      startHour: _selectedHour,
      startMinute: _selectedMinute,
      // Pass End Variables
      endDay: _endDay,
      endMonth: _endMonth,
      endYear: _endYear,
      endHour: _endHour,
      endMinute: _endMinute,
    );

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkScaffold
          : AppColors.lightScaffold,
      appBar: AppBar(
        title: const Text(
          'Search Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: const BackButton(),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(
                    UIConstants.searchFieldPadding - 15,
                  ),
                  child: TextField(
                    textAlignVertical: TextAlignVertical.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    controller: _searchQuery,
                    focusNode: _searchFocusNode,
                    autofocus: true,
                    onChanged: (value) {
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      _debounce = Timer(UIConstants.debounceStandard, () {
                        if (mounted) {
                          setState(() {});
                        }
                      });
                    },
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          UIConstants.radiusXL,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          UIConstants.radiusXL,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          UIConstants.radiusXL,
                        ),
                        borderSide: BorderSide(
                          color: colorScheme.primary.withValues(alpha: 0.6),
                          width: UIConstants.searchFieldBorderWidth,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: UIConstants.searchFieldContentPaddingH,
                        vertical: UIConstants.searchFieldContentPaddingV,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: _searchFilter(),
              ),
            ],
          ),

          // Result counter
          if ((query.isNotEmpty || _hasActiveFilters) && results.isNotEmpty)
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

  Widget _searchFilter() {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (BuildContext context) => _filterBox(context),
      ),
      child: ImageIcon(
        const AssetImage("assets/images/filter_icon.png"),
        color: isDark ? const Color(0xFFFFFFFF) : Colors.black54,
        size: 24,
      ),
    );
  }

  Widget _filterBox(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- START DATE SECTION ---
                Text(
                  isSearchRange ? "START DATE" : "DATE",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildRealDropdown(
                        hint: "DD",
                        value: _selectedDay,
                        items: _days,
                        onChanged: (val) =>
                            setDialogState(() => _selectedDay = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildRealDropdown(
                        hint: "MM",
                        value: _selectedMonth,
                        items: _months,
                        onChanged: (val) =>
                            setDialogState(() => _selectedMonth = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildRealDropdown(
                        hint: "YYYY",
                        value: _selectedYear,
                        items: _years,
                        onChanged: (val) =>
                            setDialogState(() => _selectedYear = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- START TIME SECTION ---
                Text(
                  isSearchRange ? "START TIME" : "TIME",
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
                        hint: "HH",
                        value: _selectedHour,
                        items: _hours,
                        onChanged: (val) =>
                            setDialogState(() => _selectedHour = val),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _buildRealDropdown(
                        hint: "MM",
                        value: _selectedMinute,
                        items: _minutes,
                        onChanged: (val) =>
                            setDialogState(() => _selectedMinute = val),
                      ),
                    ),
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
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () {
                            // FIX: Using setDialogState allows the box to expand!
                            setDialogState(() {
                              isSearchRange = !isSearchRange;
                            });
                          },
                          // Changes icon to a close button when expanded
                          icon: Icon(
                            isSearchRange ? Icons.close : Icons.date_range,
                            size: 18,
                          ),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              "Search range",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // --- END DATE / TIME (VISIBLE IF RANGE IS ACTIVE) ---
                // --- END DATE / TIME (ANIMATED EXPANSION) ---
                AnimatedSize(
                  duration: const Duration(
                    milliseconds: 300,
                  ), // Controls the speed
                  curve: Curves
                      .easeInOutCubic, // Gives it a smooth acceleration/deceleration
                  alignment: Alignment
                      .topCenter, // Ensures it grows downward naturally
                  child: !isSearchRange
                      ? const SizedBox.shrink() // Takes up 0 space when collapsed
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1, color: Colors.grey),
                            const SizedBox(height: 20),
                            const Text(
                              "END DATE",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildRealDropdown(
                                    hint: "DD",
                                    value: _endDay,
                                    items: _days,
                                    onChanged: (val) =>
                                        setDialogState(() => _endDay = val),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildRealDropdown(
                                    hint: "MM",
                                    value: _endMonth,
                                    items: _months,
                                    onChanged: (val) =>
                                        setDialogState(() => _endMonth = val),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _buildRealDropdown(
                                    hint: "YYYY",
                                    value: _endYear,
                                    items: _years,
                                    onChanged: (val) =>
                                        setDialogState(() => _endYear = val),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            const Text(
                              "END TIME",
                              style: TextStyle(
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
                                    hint: "HH",
                                    value: _endHour,
                                    items: _hours,
                                    onChanged: (val) =>
                                        setDialogState(() => _endHour = val),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _buildRealDropdown(
                                    hint: "MM",
                                    value: _endMinute,
                                    items: _minutes,
                                    onChanged: (val) =>
                                        setDialogState(() => _endMinute = val),
                                  ),
                                ),
                                const Spacer(flex: 5),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                ),

                // --- SUBMIT BUTTON ---
                // --- ACTION BUTTONS ---
                Row(
                  children: [
                    // 1. THE CLEAR BUTTON
                    Expanded(
                      flex: 1, // Takes up 1/3 of the space
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // Matches your app's theme color to the outline
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          onPressed: () {
                            // 1. Reset all variables to null inside the dialog
                            setDialogState(() {
                              _selectedDay = null;
                              _selectedMonth = null;
                              _selectedYear = null;
                              _selectedHour = null;
                              _selectedMinute = null;

                              _endDay = null;
                              _endMonth = null;
                              _endYear = null;
                              _endHour = null;
                              _endMinute = null;

                              isSearchRange = false; // Collapses the range view
                            });

                            // 2. Refresh the main page immediately to remove filters from the list
                            setState(() {});
                          },
                          child: Text(
                            "Clear",
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12), // Spacing between buttons
                    // 2. THE SUBMIT BUTTON
                    Expanded(
                      flex: 2, // Takes up 2/3 of the space
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onPrimary,
                          ),
                          onPressed: () {
                            Navigator.pop(context); // Close the dialog
                            setState(() {}); // Trigger the search
                          },
                          child: const Text(
                            "Get Search Results",
                            style: TextStyle(fontSize: 16),
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
      },
    );
  }

  Widget _buildRealDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          menuMaxHeight: 250,
          hint: Text(
            hint,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: Colors.grey,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSearchBody(String query, List<NotesSection> results) {
    if (query.isEmpty && !_hasActiveFilters) {
      return const _SearchMessage(
        title: 'Search your notes by title or content',
        subtitle: 'Type a keyword or use the filter to find notes.',
        icon: Icons.manage_search_rounded,
      );
    }

    if (results.isEmpty) {
      return _SearchMessage(
        title: query.isNotEmpty
            ? 'No notes matched "$query"'
            : 'No notes matched your filters',
        subtitle: 'Try a shorter phrase or adjust your date/time selection.',
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

    const highlightStyle = TextStyle(
      backgroundColor: Color(0xFFFFF176),
      fontWeight: FontWeight.w600,
      color: Colors.black,
    );

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
