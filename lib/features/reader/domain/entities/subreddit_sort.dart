/// Sort orders for a subreddit listing.
enum SubredditSort {
  hot,
  top,
  rising,
  newest;

  /// Path segment for Reddit's listing endpoint (`/r/<sub>/<path>.json`).
  String get path => switch (this) {
    SubredditSort.hot => 'hot',
    SubredditSort.top => 'top',
    SubredditSort.rising => 'rising',
    SubredditSort.newest => 'new',
  };

  /// French label for the UI.
  String get label => switch (this) {
    SubredditSort.hot => 'À la une',
    SubredditSort.top => 'Top',
    SubredditSort.rising => 'En hausse',
    SubredditSort.newest => 'Récents',
  };

  /// Only `top` takes a time window (`t=` query parameter).
  bool get needsTimeFilter => this == SubredditSort.top;
}
