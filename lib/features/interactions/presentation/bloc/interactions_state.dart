part of 'interactions_cubit.dart';

/// Interaction overlays for every post/sub currently known to the app, keyed by
/// `t3_` fullname (posts) and lowercased name (subs). Equatable compares the
/// maps by value, so an emit only propagates when a touched entry changed.
class InteractionsState extends Equatable {
  final Map<String, PostInteraction> posts;
  final Map<String, SubInteraction> subs;

  const InteractionsState({this.posts = const {}, this.subs = const {}});

  PostInteraction? postFor(String fullname) => posts[fullname];
  SubInteraction? subFor(String srName) => subs[srName.toLowerCase()];

  InteractionsState copyWith({
    Map<String, PostInteraction>? posts,
    Map<String, SubInteraction>? subs,
  }) {
    return InteractionsState(posts: posts ?? this.posts, subs: subs ?? this.subs);
  }

  @override
  List<Object?> get props => [posts, subs];
}
