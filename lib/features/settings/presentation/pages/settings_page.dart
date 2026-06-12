import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:goodreddit/features/settings/domain/entities/agent_config.dart';
import 'package:goodreddit/features/settings/presentation/bloc/settings_cubit.dart';

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
  final _modelController = TextEditingController();
  LlmProvider _provider = LlmProvider.claude;
  bool _obscure = true;
  bool _initialised = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _hydrate(AgentConfig config) {
    if (_initialised) return;
    _initialised = true;
    _provider = config.provider;
    _apiKeyController.text = config.apiKey;
    _modelController.text = config.model ?? '';
  }

  void _save() {
    context.read<SettingsCubit>().save(AgentConfig(
          provider: _provider,
          apiKey: _apiKeyController.text.trim(),
          model: _modelController.text.trim().isEmpty
              ? null
              : _modelController.text.trim(),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LLM settings')),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state.status == SettingsStatus.loaded) _hydrate(state.config);
          if (state.status == SettingsStatus.saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Settings saved')),
            );
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Configure an LLM to refine subreddit search results with a '
                'semantic relevance score and to generate MEMORY/SKILL files. '
                'The API key is stored in the device secure storage.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              const Text('Provider'),
              const SizedBox(height: 8),
              SegmentedButton<LlmProvider>(
                segments: const [
                  ButtonSegment(value: LlmProvider.claude, label: Text('Claude')),
                  ButtonSegment(value: LlmProvider.openai, label: Text('OpenAI')),
                  ButtonSegment(value: LlmProvider.google, label: Text('Gemini')),
                ],
                selected: {_provider},
                onSelectionChanged: (s) => setState(() => _provider = s.first),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'API key',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _modelController,
                decoration: const InputDecoration(
                  labelText: 'Model (optional)',
                  helperText: 'Leave empty to use the provider default',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed:
                    state.status == SettingsStatus.saving ? null : _save,
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
