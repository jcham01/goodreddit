/// Which Reddit listing the feed shows.
enum FeedSource {
  /// Personalised "Best" home feed (requires a signed-in session).
  home,

  /// Public "Popular" feed (works anonymously).
  popular;

  String get label => switch (this) {
    FeedSource.home => 'Accueil',
    FeedSource.popular => 'Populaire',
  };
}
