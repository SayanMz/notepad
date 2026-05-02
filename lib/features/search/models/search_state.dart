import 'package:notepad/features/search/models/search_filters.dart';

/// ---------------------------------------------------------------------------
/// SEARCH STATE MODEL
/// ---------------------------------------------------------------------------
///
/// Represents the complete search state:
/// - query text (user input)
/// - filter configuration (date/time)
///
/// Responsibilities:
/// - Act as a single source of truth for search inputs
/// - Provide derived properties for search logic
/// - Support immutable updates via copyWith
///
/// Design:
/// - Immutable data model
/// - Separates raw input (query) from derived values (normalizedQuery)
/// - Used by controller to drive search execution and UI state
class SearchState {
  const SearchState({required this.query, required this.filters});

  /// Raw query text entered by the user
  final String query;

  /// Filter configuration (date/time)
  final SearchFilters filters;

  /// Normalized version of query:
  /// - trimmed
  /// - lowercased
  ///
  /// Used for consistent search matching
  String get normalizedQuery => query.trim().toLowerCase();

  /// Indicates whether a non-empty query exists
  bool get hasQuery => normalizedQuery.isNotEmpty;

  /// Indicates whether any filters are active
  bool get hasFilters => filters.hasFilters;

  /// Indicates whether search should be performed
  ///
  /// True if:
  /// - query is present OR
  /// - filters are applied
  bool get hasAnyCriteria => hasQuery || hasFilters;

  /// Creates a modified copy of the current state
  ///
  /// Pattern: Atomicity
  /// - Only provided values override existing ones
  /// - Maintains immutability for safe state transitions
  SearchState copyWith({String? query, SearchFilters? filters}) {
    return SearchState(
      query: query ?? this.query,
      filters: filters ?? this.filters,
    );
  }
}
