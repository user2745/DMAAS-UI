import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchState extends Equatable {
  const SearchState({this.query = ''});

  final String query;

  bool get isSearching => query.isNotEmpty;

  SearchState copyWith({String? query}) =>
      SearchState(query: query ?? this.query);

  @override
  List<Object?> get props => [query];
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(const SearchState());

  void updateQuery(String query) {
    emit(state.copyWith(query: query.toLowerCase().trim()));
  }

  void clearSearch() {
    emit(const SearchState());
  }

  bool matchesSearch(String text) {
    if (!state.isSearching) return true;
    return text.toLowerCase().contains(state.query);
  }
}
