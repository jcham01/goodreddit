import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:goodreddit/core/constants/api_constants.dart';
import 'package:goodreddit/features/settings/data/datasources/codex_auth_datasource.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';
import 'package:goodreddit/features/settings/presentation/bloc/settings_cubit.dart';
import 'package:goodreddit/features/settings/presentation/pages/codex_login_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<SettingsCubit>()..load(),
      child: const _SettingsForm(),
    );
  }
}

class _SettingsForm extends StatefulWidget {
  const _SettingsForm();

  @override
  State<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<_SettingsForm> {
  final _apiKeyController = TextEditingController();
  LlmProvider _provider = LlmProvider.claude;
  String? _model;
  bool _obscure = true;
  bool _initialised = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _hydrate(AgentConfig config) {
    if (_initialised) return;
    _initialised = true;
    _provider = config.provider;
    _apiKeyController.text = config.apiKey;
    _model = (config.model?.isEmpty ?? true) ? null : config.model;
  }

  void _reloadModels() {
    context.read<SettingsCubit>().loadModels(
      _provider,
      _provider == LlmProvider.openaiCodex ? '' : _apiKeyController.text,
    );
  }

  void _save() {
    context.read<SettingsCubit>().save(
      AgentConfig(
        provider: _provider,
        apiKey: _provider == LlmProvider.openaiCodex
            ? ''
            : _apiKeyController.text.trim(),
        model: _model,
      ),
    );
  }

  static String _defaultModelFor(LlmProvider provider) {
    switch (provider) {
      case LlmProvider.claude:
        return ApiConstants.claudeDefaultModel;
      case LlmProvider.openai:
        return ApiConstants.openaiDefaultModel;
      case LlmProvider.google:
        return ApiConstants.googleDefaultModel;
      case LlmProvider.openaiCodex:
        return ApiConstants.openaiCodexDefaultModel;
    }
  }

  bool get _usesApiKey => _provider != LlmProvider.openaiCodex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LLM settings')),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state.status == SettingsStatus.loaded) _hydrate(state.config);
          if (state.status == SettingsStatus.saved) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Settings saved')));
          }
          if (state.status == SettingsStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Error')),
            );
          }
        },
        builder: (context, state) {
          if (state.status == SettingsStatus.loading ||
              state.status == SettingsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          // The dropdown must always contain its current value, even when the
          // saved model is missing from the fetched catalog.
          final modelItems = [
            ...state.models,
            if (_model != null && !state.models.contains(_model)) _model!,
          ];
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Configure an LLM to refine subreddit search results with a '
                'semantic relevance score and to generate MEMORY/SKILL files.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              const Text('Provider'),
              const SizedBox(height: 8),
              SegmentedButton<LlmProvider>(
                segments: const [
                  ButtonSegment(
                    value: LlmProvider.claude,
                    label: Text('Claude'),
                  ),
                  ButtonSegment(
                    value: LlmProvider.openai,
                    label: Text('OpenAI'),
                  ),
                  ButtonSegment(
                    value: LlmProvider.google,
                    label: Text('Gemini'),
                  ),
                  ButtonSegment(
                    value: LlmProvider.openaiCodex,
                    label: Text('Codex'),
                  ),
                ],
                selected: {_provider},
                onSelectionChanged: (s) {
                  setState(() {
                    _provider = s.first;
                    _model = null;
                    if (!_usesApiKey) _apiKeyController.clear();
                  });
                  _reloadModels();
                },
              ),
              const SizedBox(height: 20),
              if (_usesApiKey)
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'API key',
                    helperText: 'Stored in the device secure storage',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  onSubmitted: (_) => _reloadModels(),
                )
              else
                const _CodexAccountPanel(),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                key: ValueKey('$_provider-${modelItems.length}'),
                initialValue: _model,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Model',
                  helperText: _provider == LlmProvider.openaiCodex
                      ? 'Versions GPT-5.x du compte ChatGPT (repli hors-ligne)'
                      : state.modelsLoading
                      ? 'Refreshing model list…'
                      : _apiKeyController.text.trim().isEmpty
                      ? 'Static catalog — set an API key and refresh for '
                            'the live list'
                      : 'Live list from the provider',
                  border: const OutlineInputBorder(),
                  suffixIcon: _usesApiKey
                      ? IconButton(
                          tooltip: 'Refresh model list',
                          icon: state.modelsLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          onPressed: state.modelsLoading
                              ? null
                              : _reloadModels,
                        )
                      : null,
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Default (${_defaultModelFor(_provider)})'),
                  ),
                  for (final m in modelItems)
                    DropdownMenuItem<String?>(value: m, child: Text(m)),
                ],
                onChanged: (value) => setState(() => _model = value),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: state.status == SettingsStatus.saving ? null : _save,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// "Sign in with ChatGPT" account panel for the Codex provider: sign in / out,
/// connection status, and live usage (5h + weekly windows).
class _CodexAccountPanel extends StatefulWidget {
  const _CodexAccountPanel();

  @override
  State<_CodexAccountPanel> createState() => _CodexAccountPanelState();
}

class _CodexAccountPanelState extends State<_CodexAccountPanel> {
  final CodexAuthDataSource _auth = GetIt.I<CodexAuthDataSource>();
  CodexTokens? _tokens;
  CodexProbeResult? _result;
  CodexRateLimits? _usage;
  bool _usageLoading = false;
  bool _busy = false;
  String? _phase;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final tokens = await _auth.loadTokens();
    if (!mounted) return;
    setState(() => _tokens = tokens);
    if (tokens != null) {
      // Instant display from the last snapshot, then refresh (no quota cost).
      final cached = await _auth.loadUsage();
      if (mounted && cached != null) setState(() => _usage = cached);
      await _refreshUsage();
    }
  }

  Future<void> _refreshUsage() async {
    if (_tokens == null) return;
    setState(() => _usageLoading = true);
    try {
      final usage = await _auth.fetchUsage();
      if (mounted && usage != null) setState(() => _usage = usage);
    } finally {
      // Always clear the spinner, even if the fetch hung/failed.
      if (mounted) setState(() => _usageLoading = false);
    }
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _phase = 'Connexion à ChatGPT…';
      _result = null;
    });
    try {
      final request = _auth.beginSignIn();
      final tokenJson = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (_) => CodexLoginPage(
            authorizeUrl: request.authorizeUrl,
            state: request.state,
            codeVerifier: request.codeVerifier,
          ),
        ),
      );
      if (tokenJson == null) {
        if (mounted) {
          setState(() {
            _busy = false;
            _phase = null;
          });
        }
        return;
      }
      final tokens = await _auth.completeSignIn(tokenJson);
      if (!mounted) return;
      // Refresh the model dropdown (live list, if available).
      context.read<SettingsCubit>().loadModels(LlmProvider.openaiCodex, '');
      setState(() {
        _tokens = tokens;
        _busy = false;
        _phase = null;
      });
      await _refreshUsage(); // free — does not consume quota
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _phase = null;
          _result = CodexProbeResult(status: -1, ok: false, verdict: '❌ $e');
        });
      }
    }
  }

  Future<void> _test() async {
    final tokens = _tokens;
    if (tokens == null) return;
    setState(() {
      _busy = true;
      _phase = 'Test de la connexion…';
      _result = null;
    });
    final result = await _auth.probe(tokens);
    final usage = await _auth.loadUsage();
    if (mounted) {
      setState(() {
        _result = result;
        if (usage != null) _usage = usage;
        _busy = false;
        _phase = null;
      });
    }
  }

  Future<void> _signOut() async {
    await _auth.clear();
    if (mounted) {
      setState(() {
        _tokens = null;
        _result = null;
        _usage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = _tokens;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.chat_bubble_outline,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Codex — Connexion ChatGPT',
                    style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Connecte-toi avec ton compte ChatGPT pour utiliser Codex (quota de '
            'ton abonnement, pas de clé API). Sélectionne « Codex » puis « Save » '
            'pour l\'activer comme fournisseur.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (tokens != null) ...[
            _InfoRow(
              icon: Icons.check_circle_outline,
              color: Colors.green,
              text: 'Connecté'
                  '${tokens.planType != null ? ' · plan ${tokens.planType}' : ''}'
                  '${tokens.accountId != null ? ' · acct ${_shortId(tokens.accountId!)}' : ''}',
            ),
            const SizedBox(height: 12),
            _CodexUsageView(
              usage: _usage,
              loading: _usageLoading,
              onRefresh: _refreshUsage,
            ),
            const SizedBox(height: 8),
          ],
          if (_busy)
            Row(
              children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Expanded(child: Text(_phase ?? 'En cours…')),
              ],
            )
          else if (tokens == null)
            FilledButton.tonalIcon(
              onPressed: _signIn,
              icon: const Icon(Icons.login),
              label: const Text('Se connecter avec ChatGPT'),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _test,
                  icon: const Icon(Icons.wifi_tethering),
                  label: const Text('Tester la connexion'),
                ),
                TextButton.icon(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                  label: const Text('Déconnexion'),
                ),
              ],
            ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            _CodexTestResult(result: _result!),
          ],
        ],
      ),
    );
  }

  String _shortId(String id) => id.length > 10 ? '${id.substring(0, 10)}…' : id;
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoRow({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
      ],
    );
  }
}

/// Codex usage panel: 5-hour (primary) and weekly (secondary) windows.
class _CodexUsageView extends StatelessWidget {
  final CodexRateLimits? usage;
  final bool loading;
  final VoidCallback onRefresh;

  const _CodexUsageView({
    required this.usage,
    required this.loading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = usage;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.data_usage,
                  size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 6),
              Text('Utilisation Codex', style: theme.textTheme.labelLarge),
              const Spacer(),
              if (loading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  tooltip: 'Rafraîchir l\'usage',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.refresh, size: 18),
                  onPressed: onRefresh,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (u == null)
            Text(
              loading
                  ? 'Récupération de l\'usage…'
                  : 'Usage indisponible — rafraîchis ou lance une recherche.',
              style: theme.textTheme.bodySmall,
            )
          else ...[
            _UsageBar(label: 'Limite 5h', window: u.primary),
            const SizedBox(height: 10),
            _UsageBar(label: 'Limite hebdomadaire', window: u.secondary),
          ],
        ],
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  final String label;
  final CodexRateWindow? window;

  const _UsageBar({required this.label, required this.window});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = window;
    if (w == null) {
      return Text('$label : indisponible', style: theme.textTheme.bodySmall);
    }
    final remaining = w.remainingPercent;
    final color = remaining <= 0
        ? theme.colorScheme.error
        : (remaining < 15 ? Colors.orange : Colors.green);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: theme.textTheme.labelMedium),
            const Spacer(),
            Text('${remaining.toStringAsFixed(0)} % restant',
                style: theme.textTheme.labelMedium?.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (remaining / 100).clamp(0, 1),
            minHeight: 7,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          w.resetsAt != null
              ? 'Réutilisable ${_formatReset(w.resetsAt!)}'
              : 'Reset inconnu',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Formats an absolute reset time as "aujourd'hui HH:MM" / "demain HH:MM" /
/// "dd/MM HH:MM" (no intl dependency).
String _formatReset(DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  if (sameDay(local, now)) return 'aujourd\'hui à $hh:$mm';
  if (sameDay(local, now.add(const Duration(days: 1)))) {
    return 'demain à $hh:$mm';
  }
  final dd = local.day.toString().padLeft(2, '0');
  final mo = local.month.toString().padLeft(2, '0');
  return 'le $dd/$mo à $hh:$mm';
}

/// Concise connection-test result (full HTTP/headers/body go to the logs).
class _CodexTestResult extends StatelessWidget {
  final CodexProbeResult result;
  const _CodexTestResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = result.ok
        ? Colors.green
        : (result.status == 429 ? Colors.orange : theme.colorScheme.error);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            result.ok ? Icons.check_circle : Icons.info_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.verdict, style: theme.textTheme.bodyMedium),
                if (result.text != null && result.text!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Réponse : ${result.text}',
                      style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
