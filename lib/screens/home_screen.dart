import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/video_extractor.dart';
import '../state/app_state.dart';
import 'ad_screen.dart';
import 'download_progress_screen.dart';
import 'premium_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  static const routeName = '/home';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = TextEditingController();
  bool _ownContent = false;
  VideoPlatform _platform = VideoPlatform.unknown;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDownload(AppState appState, AppLocalizations strings) async {
    FocusScope.of(context).unfocus();
    final url = _controller.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.text('enterUrl'))));
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await appState.extractor.extract(
        url,
        isPremium: appState.isPremium,
        ownContent: _ownContent,
      );
      if (!mounted) return;
      final historyItem = DownloadHistoryItem(
        url: url,
        platform: appState.extractor.iconLabel(result.platform),
        quality: appState.isPremium
            ? result.qualityLabels.highQuality
            : result.qualityLabels.lowQuality,
        savedAt: DateTime.now(),
      );
      await appState.addHistoryItem(historyItem);
      if (appState.isPremium) {
        Navigator.pushNamed(
          context,
          DownloadProgressScreen.routeName,
          arguments: DownloadProgressArguments(
            result: result,
            highQuality: true,
          ),
        );
      } else {
        Navigator.pushNamed(
          context,
          AdScreen.routeName,
          arguments: AdScreenArguments(
            result: result,
          ),
        );
      }
    } on OwnershipException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } on FormatException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final appState = context.watch<AppState>();
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.text('appTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.workspace_premium_outlined),
            onPressed: () => Navigator.pushNamed(context, PremiumScreen.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, SettingsScreen.routeName),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              onChanged: (value) => setState(
                () => _platform = appState.extractor.detectPlatform(value),
              ),
              decoration: InputDecoration(
                labelText: strings.text('enterUrl'),
                prefixIcon: Icon(_platformIcon(_platform)),
                border: const OutlineInputBorder(),
              ),
            ),
            SwitchListTile(
              value: _ownContent,
              onChanged: (value) => setState(() => _ownContent = value),
              title: Text(strings.text('ownership')),
              subtitle: Text(strings.text('ownPostError')),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _loading ? null : () => _onDownload(appState, strings),
              icon: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(strings.text('download')),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Chip(
                  avatar: Icon(appState.isPremium
                      ? Icons.star
                      : Icons.timelapse_outlined),
                  label: Text(appState.isPremium
                      ? strings.text('premium')
                      : strings.text('watchAd')),
                ),
                const SizedBox(width: 8),
                Text(strings.text('premiumOnly')),
              ],
            ),
            const SizedBox(height: 16),
            Text(strings.text('history'), style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Expanded(
              child: appState.history.isEmpty
                  ? const Center(child: Text('No downloads yet'))
                  : ListView.builder(
                      itemCount: appState.history.length,
                      itemBuilder: (context, index) {
                        final item = appState.history[index];
                        return ListTile(
                          leading: Icon(_platformIcon(
                              appState.extractor.detectPlatform(item.url))),
                          title: Text(item.url),
                          subtitle: Text('${item.platform} • ${item.quality}'),
                          trailing: Text(
                            '${item.savedAt.month}/${item.savedAt.day}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _platformIcon(VideoPlatform platform) {
    switch (platform) {
      case VideoPlatform.twitter:
        return Icons.alternate_email;
      case VideoPlatform.youtube:
        return Icons.ondemand_video;
      case VideoPlatform.youtubeShorts:
        return Icons.video_call;
      case VideoPlatform.instagram:
        return Icons.camera_alt_outlined;
      case VideoPlatform.unknown:
        return Icons.link;
    }
  }
}
