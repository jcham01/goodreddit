import 'package:equatable/equatable.dart';

/// The current Reddit authentication state, derived from the browser session.
class RedditSession extends Equatable {
  final bool isAuthenticated;

  /// Username, when it can be resolved from the logged-in session.
  final String? username;

  const RedditSession({required this.isAuthenticated, this.username});

  const RedditSession.anonymous() : isAuthenticated = false, username = null;

  @override
  List<Object?> get props => [isAuthenticated, username];
}
