import 'package:goodreddit/core/constants/api_constants.dart';

/// All the reverse-engineered constants for the **experimental** "Sign in with
/// ChatGPT" Codex provider, isolated in one swappable place so the fragile bits
/// can change without touching logic.
///
/// Source of truth: the public `openai/codex` CLI (verified 2026-06). These are
/// OpenAI's *first-party* Codex client values; reusing them from a third-party
/// app is ToS-grey and may break at any time. This is a **feasibility PoC**: its
/// only job is to answer one question — does Cloudflare let an authenticated
/// Codex call through from a phone, or 403 it?
class CodexConstants {
  CodexConstants._();

  // ---- OAuth (PKCE, public/native client — no client_secret) ----
  static const String issuer = 'https://auth.openai.com';
  static const String authorizeUrl = '$issuer/oauth/authorize';
  static const String tokenUrl = '$issuer/oauth/token';
  static const String clientId = 'app_EMoamEEZ73f0CkXaXp7hrann';
  static const String scope =
      'openid profile email offline_access '
      'api.connectors.read api.connectors.invoke';

  // The CLI uses a loopback redirect. We don't run a local server: we load the
  // authorize page in a WebView and intercept the navigation to this URL.
  static const int loopbackPort = 1455;
  static const String redirectUri =
      'http://localhost:$loopbackPort/auth/callback';

  static const String originator = 'codex_cli_rs';

  /// id_token claim namespace that wraps `chatgpt_account_id` / `chatgpt_plan_type`.
  static const String authClaimNamespace = 'https://api.openai.com/auth';

  // ---- Model-call backend (ChatGPT-subscription mode, NOT api.openai.com) ----
  static const String chatgptOrigin = 'https://chatgpt.com';
  static const String codexResponsesUrl =
      '$chatgptOrigin/backend-api/codex/responses';

  /// Live model list — the ChatGPT model-picker endpoint (`{"models":[{slug…}]}`).
  /// Best-effort: codex-named slugs are merged with the curated
  /// [ApiConstants.openaiCodexFallbackModels]; failures fall back to the curated
  /// list. (The earlier `/backend-api/codex/models` guess returned 400.)
  static const String codexModelsUrl = '$chatgptOrigin/backend-api/models';

  /// Read-only usage/quota endpoint (5h + weekly windows). Polling it does NOT
  /// consume model quota. Same shape also arrives as `x-codex-*` headers on each
  /// /responses call.
  static const String codexUsageUrl = '$chatgptOrigin/backend-api/wham/usage';

  /// Default Codex model — single source of truth shared with [ApiConstants].
  static const String defaultModel = ApiConstants.openaiCodexDefaultModel;
}
