import 'package:equatable/equatable.dart';

/// Domain-level error type. Datasource [Exception]s are translated into these
/// by repositories, so the presentation layer never sees raw exceptions.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Server error occurred']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class RedditFailure extends Failure {
  const RedditFailure([super.message = 'Failed to access Reddit']);
}

class NotAuthenticatedFailure extends Failure {
  const NotAuthenticatedFailure([super.message = 'Please sign in to Reddit']);
}

class LlmFailure extends Failure {
  const LlmFailure([super.message = 'LLM API error occurred']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local storage error occurred']);
}

class ExportFailure extends Failure {
  const ExportFailure([super.message = 'Failed to export file']);
}

class ConfigFailure extends Failure {
  const ConfigFailure([super.message = 'Configuration error']);
}
