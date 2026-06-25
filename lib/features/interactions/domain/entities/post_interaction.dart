import 'package:equatable/equatable.dart';
import 'package:goodreddit/core/util/vote_math.dart';
import 'package:goodreddit/features/scraper/domain/entities/post.dart';

/// Per-post interaction state, keyed (externally, in the store map) by the
/// post's `t3_` fullname.
///
/// Holds the SERVER baseline plus the user OVERLAY. The displayed score is
/// DERIVED from both, so re-seeding the baseline from a staler/fresher listing
/// can never double-count an applied or in-flight vote. On a confirmed write
/// the store folds the overlay into the baseline (so [diverges] returns false
/// and a later [reconcileBaseline] can pick up server score drift).
class PostInteraction extends Equatable {
  /// Server baseline.
  final int baseScore;
  final VoteDir baseDir;
  final bool baseSaved;

  /// User overlay (what the UI reflects right now).
  final VoteDir voteDir;
  final bool saved;

  final bool scoreHidden;
  final bool pending; // a write is in flight (gates reconcileBaseline)

  const PostInteraction({
    required this.baseScore,
    required this.baseDir,
    required this.baseSaved,
    required this.voteDir,
    required this.saved,
    this.scoreHidden = false,
    this.pending = false,
  });

  factory PostInteraction.seed(Post p) {
    final dir = VoteDir.fromLikes(p.likes);
    return PostInteraction(
      baseScore: p.score,
      baseDir: dir,
      baseSaved: p.saved,
      voteDir: dir,
      saved: p.saved,
      scoreHidden: p.scoreHidden,
    );
  }

  /// Displayed score = baseline minus the baseline's own vote contribution,
  /// plus the current overlay's contribution. Stable across re-seeds.
  int get displayScore => baseScore - baseDir.delta + voteDir.delta;

  /// True when the overlay differs from the server baseline (a real, not-yet
  /// reconciled user action). Guards [InteractionsCubit.reconcileBaseline].
  bool get diverges => voteDir != baseDir || saved != baseSaved;

  PostInteraction copyWith({
    int? baseScore,
    VoteDir? baseDir,
    bool? baseSaved,
    VoteDir? voteDir,
    bool? saved,
    bool? scoreHidden,
    bool? pending,
  }) {
    return PostInteraction(
      baseScore: baseScore ?? this.baseScore,
      baseDir: baseDir ?? this.baseDir,
      baseSaved: baseSaved ?? this.baseSaved,
      voteDir: voteDir ?? this.voteDir,
      saved: saved ?? this.saved,
      scoreHidden: scoreHidden ?? this.scoreHidden,
      pending: pending ?? this.pending,
    );
  }

  @override
  List<Object?> get props => [
    baseScore,
    baseDir,
    baseSaved,
    voteDir,
    saved,
    scoreHidden,
    pending,
  ];
}
