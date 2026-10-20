import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';

import '../../../data/services/auth_service.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  StreamSubscription<User?>? _authStateSubscription;

  AuthCubit({AuthService? authService})
      : _authService = authService ?? AuthService(),
        super(AuthInitial()) {
    _monitorAuthState();
  }
  
  User? get user => switch (state) {
    Authenticated(user: final user) => user,
    _ => null,
  };



  void _monitorAuthState() {
    _authStateSubscription = _authService.authStateChanges.listen((user) {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    });
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      await _authService.login(
        email: email,
        password: password,
      );
    } catch (e) {
      emit(Unauthenticated());
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      emit(AuthLoading());
      await _authService.register(
        name: name,
        email: email,
        password: password,
      );
    } catch (e) {
      emit(Unauthenticated());
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
