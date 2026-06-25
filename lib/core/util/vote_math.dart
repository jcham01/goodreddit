/// Vote vocabulary + toggle arithmetic, with zero Flutter dependencies.
///
/// This is the single home of the vote logic so the toggle table is tested once
/// and shared by production and tests. Score is NOT mutated here — it is derived
/// in `PostInteraction.displayScore` from the baseline + overlay, which is what
/// prevents a re-seed from double-counting.
enum VoteDir {
  up,
  none,
  down;

  /// Contribution of this direction to the displayed score.
  int get delta => switch (this) {
    VoteDir.up => 1,
    VoteDir.down => -1,
    VoteDir.none => 0,
  };

  /// Value Reddit's `/api/vote` expects for the `dir` field.
  String get apiDir => switch (this) {
    VoteDir.up => '1',
    VoteDir.down => '-1',
    VoteDir.none => '0',
  };

  /// Maps Reddit's tri-state `likes` (true/false/null) to a direction.
  static VoteDir fromLikes(bool? likes) => likes == true
      ? VoteDir.up
      : likes == false
      ? VoteDir.down
      : VoteDir.none;
}

/// Reddit toggle semantics: tapping the currently-active arrow clears the vote,
/// tapping the other arrow switches to it. [tapped] is always [VoteDir.up] or
/// [VoteDir.down] (the two buttons); the active one toggling to itself yields
/// [VoteDir.none].
VoteDir nextVote(VoteDir current, VoteDir tapped) =>
    current == tapped ? VoteDir.none : tapped;
