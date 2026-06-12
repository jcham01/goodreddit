/// Low-level exceptions thrown by the data layer (datasources).
///
/// Repositories catch these and translate them into [Failure]s
/// (see core/error/failures.dart) before they reach the domain layer.
library;

class ServerException implements Exception {
  final String message;
  const ServerException([this.message = 'Server error']);

  @override
  String toString() => 'ServerException: $message';
}

class NetworkException implements Exception {
  final String message;
  const NetworkException([this.message = 'Network error']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Raised when Reddit access fails (HTTP error, parse error, blocked request).
class RedditException implements Exception {
  final String message;
  const RedditException([this.message = 'Reddit access error']);

  @override
  String toString() => 'RedditException: $message';
}

/// Raised when the user is not authenticated against Reddit but the
/// requested operation needs a logged-in browser session.
class NotAuthenticatedException implements Exception {
  final String message;
  const NotAuthenticatedException([this.message = 'Not signed in to Reddit']);

  @override
  String toString() => 'NotAuthenticatedException: $message';
}

class LlmException implements Exception {
  final String message;
  const LlmException([this.message = 'LLM error']);

  @override
  String toString() => 'LlmException: $message';
}

class CacheException implements Exception {
  final String message;
  const CacheException([this.message = 'Cache error']);

  @override
  String toString() => 'CacheException: $message';
}

class ExportException implements Exception {
  final String message;
  const ExportException([this.message = 'Export error']);

  @override
  String toString() => 'ExportException: $message';
}
