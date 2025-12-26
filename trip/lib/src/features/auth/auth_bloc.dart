import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'auth_repository.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  AuthLoginRequested(this.username, this.password);
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String accessToken;
  Authenticated(this.accessToken);
  @override
  List<Object?> get props => [accessToken];
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;
  AuthBloc(this._repo) : super(AuthInitial()) {
    on<AuthStarted>((event, emit) async {
      emit(AuthInitial());
    });
    on<AuthLoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final tokens = await _repo.login(event.username, event.password);
        emit(Authenticated(tokens['access'] as String));
      } catch (e) {
        emit(AuthFailure('Login failed'));
      }
    });
  }
}
