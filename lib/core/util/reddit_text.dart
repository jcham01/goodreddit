/// Normalises a subreddit name to a stable lookup/join key.
///
/// Reddit — and LLMs echoing a prompt — refer to a subreddit in many shapes:
/// `flutterdev`, `r/flutterdev`, `/r/flutterdev`, `R/FlutterDev`. They all
/// denote the same community, so we strip an optional leading slash and an
/// optional `r/` prefix, then trim and lowercase. Idempotent for bare names.
///
/// This is the fix for the silent ranking join bug: the prompt listed
/// subreddits as `r/<name>`, the model echoed `"name": "r/<name>"`, and the
/// join looked up the bare `<name>` — so every semantic score fell back to 0.
String normalizeSubredditKey(String raw) {
  var s = raw.trim();
  if (s.startsWith('/')) s = s.substring(1);
  if (s.length >= 2 && s.substring(0, 2).toLowerCase() == 'r/') {
    s = s.substring(2);
  }
  return s.trim().toLowerCase();
}
