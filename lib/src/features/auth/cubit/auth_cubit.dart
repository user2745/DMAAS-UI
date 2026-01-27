import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<User?>? _userSubscription;

  AuthCubit({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    _userSubscription = _authRepository.user.listen(_onUserChanged);
  }

  void _onUserChanged(User? user) {
    if (user != null) {
      emit(AuthState.authenticated(user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _authRepository.signIn(email: email, password: password);
    } catch (e) {
      emit(AuthState.unauthenticated(error: e.toString()));
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _authRepository.signUp(email: email, password: password);
    } catch (e) {
      emit(AuthState.unauthenticated(error: e.toString()));
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await _authRepository.resetPassword(email: email);
    } catch (e) {
      emit(AuthState.unauthenticated(error: e.toString()));
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  Future<String?> getIdToken() async {
    return await _authRepository.getIdToken();
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
