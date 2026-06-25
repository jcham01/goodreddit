import 'package:equatable/equatable.dart';

/// One row in a flattened, depth-aware comment thread.
///
/// A thread is rendered as a flat list (not a nested widget tree) so it
/// virtualizes cleanly in a `SliverList`; nesting is conveyed by [depth].
sealed class ThreadItem extends Equatable {
  final int depth;
  const ThreadItem({required this.depth});
}

/// A real comment (`kind: 't1'`).
class CommentNode extends ThreadItem {
  final String id;
  final String author;
  final String body;
  final int score;
  final bool scoreHidden;
  final DateTime createdAt;
  final bool isSubmitter; // posted by the OP
  final bool isStickied;
  final String? distinguished; // 'moderator' | 'admin' | null
  final bool edited;

  const CommentNode({
    required this.id,
    required this.author,
    required this.body,
    required this.score,
    required this.createdAt,
    required super.depth,
    this.scoreHidden = false,
    this.isSubmitter = false,
    this.isStickied = false,
    this.distinguished,
    this.edited = false,
  });

  bool get isModerator => distinguished == 'moderator';
  bool get isAdmin => distinguished == 'admin';
  bool get isDeleted =>
      body == '[deleted]' || body == '[removed]' || author == '[deleted]';

  @override
  List<Object?> get props => [
    id,
    author,
    body,
    score,
    depth,
    isSubmitter,
    isStickied,
    distinguished,
  ];
}

/// A "load more comments" continuation (`kind: 'more'`). In Phase 3A it is a
/// non-expanding marker — tapping it opens the full thread on reddit.com.
class MoreNode extends ThreadItem {
  final int count; // number of hidden replies

  const MoreNode({required this.count, required super.depth});

  @override
  List<Object?> get props => [count, depth];
}
