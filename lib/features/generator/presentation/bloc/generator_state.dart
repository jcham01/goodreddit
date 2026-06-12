part of 'generator_cubit.dart';

enum GenerationKind { memory, skill }

enum GeneratorStatus { idle, generating, done, error }

class GeneratorState extends Equatable {
  final GeneratorStatus status;
  final GenerationKind? kind;
  final String? memoryContent;
  final String? skillContent;
  final String? errorMessage;

  const GeneratorState({
    this.status = GeneratorStatus.idle,
    this.kind,
    this.memoryContent,
    this.skillContent,
    this.errorMessage,
  });

  GeneratorState copyWith({
    GeneratorStatus? status,
    GenerationKind? kind,
    String? memoryContent,
    String? skillContent,
    String? errorMessage,
  }) {
    return GeneratorState(
      status: status ?? this.status,
      kind: kind ?? this.kind,
      memoryContent: memoryContent ?? this.memoryContent,
      skillContent: skillContent ?? this.skillContent,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    kind,
    memoryContent,
    skillContent,
    errorMessage,
  ];
}
