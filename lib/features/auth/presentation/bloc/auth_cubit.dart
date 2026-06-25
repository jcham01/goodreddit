import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/usecases/usecase.dart';
import 'package:goodreddit/features/auth/domain/usecases/get_auth_status.dart';
import 'package:goodreddit/features/auth/domain/usecases/logout.dart';
import 'package:goodreddit/features/interactions/presentation/bloc/interactions_cubit.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final GetAuthStatus getAuthStatus;
  final Logout logout;

  /// The shared interaction store, wiped on sign-out so a different Reddit
  /// account never inherits the previous user's votes/saves/subscriptions.
  final InteractionsCubit interactions;

  AuthCubit({
    required this.getAuthStatus,
    required this.logout,
    required this.interactions,
  }) : super(const AuthState());

  Future<void> refresh() async {
    emit(state.copyWith(status: AuthStatus.checking));
    final result = await getAuthStatus(const NoParams());
    result.fold(
      (failure) => emit(
        state.copyWith(status: AuthStatus.error, errorMessage: failure.message),
      ),
      (session) => emit(
        AuthState(
          status: session.isAuthenticated
              ? AuthStatus.authenticated
              : AuthStatus.anonymous,
          username: session.username,
        ),
      ),
    );
  }

  Future<void> signOut() async {
    await logout(const NoParams());
    interactions.clear();
    await refresh();
  }
}
