import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:goodreddit/core/widgets/active_llm_badge.dart';
import 'package:goodreddit/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:goodreddit/features/history/presentation/bloc/history_cubit.dart';
import 'package:goodreddit/features/library/presentation/pages/library_tab.dart';
import 'package:goodreddit/features/reader/presentation/pages/feed_tab.dart';
import 'package:goodreddit/features/search/presentation/pages/search_tab.dart';
import 'package:goodreddit/features/settings/presentation/pages/settings_page.dart';

/// Root navigation shell: a single Scaffold hosting the three persistent tabs
/// (Feed / Search / Library) via an [IndexedStack], with Settings reachable
/// from the AppBar. Replaces the old SearchPage-as-home model.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  // Bumped on returning from Settings so the active-LLM badge re-fetches.
  int _settingsEpoch = 0;

  static const _titles = ['GoodReddit', 'Recherche', 'Bibliothèque'];

  @override
  void initState() {
    super.initState();
    // One-shot session check for the whole app.
    context.read<AuthCubit>().refresh();
  }

  void _onTab(int i) {
    setState(() => _index = i);
    // Refresh the library so freshly generated files appear.
    if (i == 2) context.read<HistoryCubit>().load();
  }

  Future<void> _openSettings() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
    if (mounted) setState(() => _settingsEpoch++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Réglages',
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _openSettings,
                child: ActiveLlmBadge(key: ValueKey(_settingsEpoch)),
              ),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _index,
        children: const [FeedTab(), SearchTab(), LibraryTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Recherche'),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Bibliothèque',
          ),
        ],
      ),
    );
  }
}
