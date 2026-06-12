part of 'auth_cubit.dart';

enum AuthStatus { unknown, checking, authenticated, anonymous, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? username;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.username,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, username, errorMessage];
}
