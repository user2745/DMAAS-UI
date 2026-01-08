import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/auth_api_service.dart';

class AuthState extends Equatable {
  final String? token;
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.token,
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => token != null && token!.isNotEmpty;

  AuthState copyWith({
    String? token,
    Map<String, dynamic>? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [token, user, isLoading, error];
}

class AuthCubit extends Cubit<AuthState> {
  final AuthApiService _authApiService;

  AuthCubit(this._authApiService) : super(const AuthState());

  Future<void> login(String email, String password) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final (token, user) = await _authApiService.login(email, password);
      emit(AuthState(token: token, user: user, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      rethrow;
    }
  }

  Future<void> register(String email, String password, String? name) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final (token, user) = await _authApiService.register(email, password, name);
      emit(AuthState(token: token, user: user, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      rethrow;
    }
  }

  void logout() {
    emit(const AuthState());
  }
}
