/// Endpoints and tunables.
///
/// Reddit is accessed through a logged-in browser session (see
/// [RedditWebClient]), so paths here are *relative* to www.reddit.com and the
/// `.json` suffix is always used — the request is issued by the real browser
/// engine from the reddit.com origin, with the session cookie attached.
class ApiConstants {
  ApiConstants._();

  // Reddit (browser-session mode)
  static const String redditOrigin = 'https://www.reddit.com';
  static const String redditLoginUrl = '$redditOrigin/login';

  static const String subredditSearchPath = '/subreddits/search.json';
  static String subredditTopPath(String subreddit) =>
      '/r/$subreddit/top.json';
  static String postCommentsPath(String subreddit, String postId) =>
      '/r/$subreddit/comments/$postId.json';

  // Default query parameters
  static const int defaultSearchLimit = 25;
  static const int defaultPostLimit = 25;
  static const int defaultCommentLimit = 50;
  static const String defaultTimeFilter = 'week';

  // Claude API
  static const String claudeApiUrl = 'https://api.anthropic.com/v1/messages';
  static const String claudeDefaultModel = 'claude-opus-4-8';
  static const String claudeApiVersion = '2023-06-01';

  // OpenAI API
  static const String openaiApiUrl =
      'https://api.openai.com/v1/chat/completions';
  static const String openaiDefaultModel = 'gpt-4o-mini';

  // Google Gemini API
  static const String googleApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String googleDefaultModel = 'gemini-2.5-flash';

  // App updates — latest GitHub release (the repo must stay public for the
  // unauthenticated releases API to work)
  static const String githubRepo = 'jcham01/goodreddit';
  static const String latestReleaseUrl =
      'https://api.github.com/repos/$githubRepo/releases/latest';
}
