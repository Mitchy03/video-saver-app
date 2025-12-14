import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../state/app_state.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});
  static const routeName = '/premium';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('premium'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.text('premiumPitch'),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.hd),
              title: const Text('1080p+ high quality streams'),
            ),
            const ListTile(
              leading: Icon(Icons.timer_off_outlined),
              title: Text('Skip 30-second rewarded ads'),
            ),
            const ListTile(
              leading: Icon(Icons.lock_open_outlined),
              title: Text('Priority parsing for 4 SNS sources'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: appState.isPremium
                  ? null
                  : () async {
                      await appState.purchasePremium();
                      if (context.mounted && appState.isPremium) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Premium activated.')),
                        );
                      }
                    },
              child: Text(appState.isPremium
                  ? strings.text('premium')
                  : strings.text('purchase')),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await appState.restorePurchases();
              },
              child: Text(strings.text('restore')),
            ),
          ],
        ),
      ),
    );
  }
}
