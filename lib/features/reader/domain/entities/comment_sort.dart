/// Comment sort orders supported by Reddit's listing endpoint.
enum CommentSort {
  best,
  top,
  newest,
  controversial;

  /// Value expected by Reddit's `sort` query parameter.
  String get apiValue => switch (this) {
    CommentSort.best => 'confidence',
    CommentSort.top => 'top',
    CommentSort.newest => 'new',
    CommentSort.controversial => 'controversial',
  };

  /// French label for the UI.
  String get label => switch (this) {
    CommentSort.best => 'Meilleurs',
    CommentSort.top => 'Plus votés',
    CommentSort.newest => 'Récents',
    CommentSort.controversial => 'Controversés',
  };
}
