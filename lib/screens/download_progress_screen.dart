import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/download_manager.dart';
import '../services/video_extractor.dart';
import '../state/app_state.dart';

class DownloadProgressArguments {
  const DownloadProgressArguments({
    required this.result,
    required this.highQuality,
  });

  final VideoExtractionResult result;
  final bool highQuality;
}

class DownloadProgressScreen extends StatelessWidget {
  const DownloadProgressScreen({super.key});
  static const routeName = '/progress';

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments
        as DownloadProgressArguments?;
    final result = args?.result;
    final highQuality = args?.highQuality ?? false;
    final appState = context.watch<AppState>();
    final strings = AppLocalizations.of(context);
    if (result == null) {
      return const Scaffold(body: Center(child: Text('No download')));
    }
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('progress'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<DownloadProgress>(
          stream: appState.downloadManager
              .startDownload(result, highQuality: highQuality),
          builder: (context, snapshot) {
            final progress = snapshot.data?.progress ?? 0;
            final message = snapshot.data?.message ?? 'Preparing download...';
            final completed = progress >= 1.0;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(result.title, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text('${(progress * 100).round()}% - $message'),
                const SizedBox(height: 16),
                if (completed) ...[
                  Text(strings.text('complete'),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved to gallery (placeholder).'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save_alt),
                        label: const Text('Save'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Shared link (placeholder).'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.share_outlined),
                        label: Text(strings.text('share')),
                      ),
                    ],
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
