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
  static String subredditTopPath(String subreddit) => '/r/$subreddit/top.json';
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

  // OpenAI Codex provider (device-code auth is handled by Codex surfaces).
  static const String openaiCodexDefaultModel = 'gpt-5.5';

  // Model catalogs — live list endpoints, queried with the user's API key
  static const String anthropicModelsUrl =
      'https://api.anthropic.com/v1/models';
  static const String openaiModelsUrl = 'https://api.openai.com/v1/models';
  // Google reuses [googleApiUrl] (it already is the models collection).

  // Static fallbacks shown when no API key is set or the live fetch fails
  // (snapshot 2026-06).
  static const List<String> claudeFallbackModels = [
    'claude-opus-4-8',
    'claude-fable-5',
    'claude-opus-4-7',
    'claude-opus-4-6',
    'claude-sonnet-4-6',
    'claude-haiku-4-5',
  ];
  static const List<String> openaiFallbackModels = [
    'gpt-5.1',
    'gpt-5',
    'gpt-5-mini',
    'gpt-5-nano',
    'gpt-4.1',
    'gpt-4o',
    'gpt-4o-mini',
  ];
  static const List<String> googleFallbackModels = [
    'gemini-3-pro-preview',
    'gemini-2.5-pro',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];
  // Offline baseline for Codex (real GPT-5.x versions, dot format). The live
  // list is derived from the account's ChatGPT model picker; see
  // [CodexAuthDataSource.listModels].
  static const List<String> openaiCodexFallbackModels = [
    'gpt-5.5',
    'gpt-5.4',
    'gpt-5.3',
  ];

  // App updates — latest GitHub release (the repo must stay public for the
  // unauthenticated releases API to work)
  static const String githubRepo = 'jcham01/goodreddit';
  static const String latestReleaseUrl =
      'https://api.github.com/repos/$githubRepo/releases/latest';
}
