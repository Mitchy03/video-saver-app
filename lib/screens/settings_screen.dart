import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('settings'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: appState.isPremium,
            onChanged: (_) {},
            title: Text(strings.text('premium')),
            subtitle: Text(appState.isPremium
                ? 'Active subscription'
                : 'Tap purchase to upgrade'),
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: Text(strings.text('purchase')),
            onTap: () async => appState.purchasePremium(),
          ),
          ListTile(
            leading: const Icon(Icons.refresh_outlined),
            title: Text(strings.text('restore')),
            onTap: () async => appState.restorePurchases(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear history'),
            onTap: () async => appState.clearHistory(),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Export history (JSON)'),
            subtitle: Text(appState.exportHistoryJson(), maxLines: 3),
          ),
        ],
      ),
    );
  }
}
