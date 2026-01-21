import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Represents a single field filter with field key and selected values
class FieldFilter extends Equatable {
  const FieldFilter({
    required this.fieldId,
    required this.fieldName,
    required this.selectedValues,
  });

  final String fieldId;
  final String fieldName;
  final List<String> selectedValues;

  FieldFilter copyWith({
    String? fieldId,
    String? fieldName,
    List<String>? selectedValues,
  }) =>
      FieldFilter(
        fieldId: fieldId ?? this.fieldId,
        fieldName: fieldName ?? this.fieldName,
        selectedValues: selectedValues ?? this.selectedValues,
      );

  @override
  List<Object?> get props => [fieldId, fieldName, selectedValues];
}

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.fieldFilters = const [],
  });

  final String query;
  final List<FieldFilter> fieldFilters;

  bool get isSearching => query.isNotEmpty;

  bool get hasFieldFilters => fieldFilters.isNotEmpty;

  bool get isFiltering => isSearching || hasFieldFilters;

  SearchState copyWith({
    String? query,
    List<FieldFilter>? fieldFilters,
  }) =>
      SearchState(
        query: query ?? this.query,
        fieldFilters: fieldFilters ?? this.fieldFilters,
      );

  @override
  List<Object?> get props => [query, fieldFilters];
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(const SearchState());

  void updateQuery(String query) {
    emit(state.copyWith(query: query.toLowerCase().trim()));
  }

  void clearSearch() {
    emit(state.copyWith(query: ''));
  }

  void addFieldFilter(FieldFilter filter) {
    final filters = [...state.fieldFilters];
    // Remove existing filter for same field if present
    filters.removeWhere((f) => f.fieldId == filter.fieldId);
    // Add new filter only if it has selected values
    if (filter.selectedValues.isNotEmpty) {
      filters.add(filter);
    }
    emit(state.copyWith(fieldFilters: filters));
  }

  void removeFieldFilter(String fieldId) {
    final filters = state.fieldFilters
        .where((f) => f.fieldId != fieldId)
        .toList();
    emit(state.copyWith(fieldFilters: filters));
  }

  void clearFieldFilters() {
    emit(state.copyWith(fieldFilters: []));
  }

  void clearAll() {
    emit(const SearchState());
  }

  bool matchesSearch(String text) {
    if (!state.isSearching) return true;
    return text.toLowerCase().contains(state.query);
  }

  /// Check if a task's field value matches the selected filters
  bool matchesFieldFilters(Map<String, dynamic>? fieldValues) {
    if (!state.hasFieldFilters || fieldValues == null) {
      return true;
    }

    // All field filters must match (AND logic)
    return state.fieldFilters.every((filter) {
      final value = fieldValues[filter.fieldId];
      if (value == null) return false;

      // Support both single values and lists
      final valueList = value is List ? value : [value];
      final valueStrings =
          valueList.map((v) => v.toString().toLowerCase()).toList();

      // At least one selected value must be in the task's field value
      return filter.selectedValues.any((selected) =>
          valueStrings.contains(selected.toLowerCase()));
    });
  }

  /// Combined matching for both text and field filters
  bool matches(String searchText, Map<String, dynamic>? fieldValues) {
    return matchesSearch(searchText) && matchesFieldFilters(fieldValues);
  }
}
