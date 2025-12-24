import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/ad_service.dart';
import '../services/video_extractor.dart';
import 'download_progress_screen.dart';

class AdScreenArguments {
  const AdScreenArguments({required this.result});
  final VideoExtractionResult result;
}

class AdScreen extends StatefulWidget {
  const AdScreen({super.key});
  static const routeName = '/ad';

  @override
  State<AdScreen> createState() => _AdScreenState();
}

class _AdScreenState extends State<AdScreen> {
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _completed = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer(VideoExtractionResult result) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        await _finishAd(result);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  Future<void> _finishAd(VideoExtractionResult result) async {
    if (_completed) return;
    _completed = true;
    await AdService.showRewardedAdWithCallback(onUserEarnedReward: () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        DownloadProgressScreen.routeName,
        arguments: DownloadProgressArguments(
          result: result,
          highQuality: false,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as AdScreenArguments?;
    final result = args?.result;
    final strings = AppLocalizations.of(context);
    if (result == null) {
      return const Scaffold(body: Center(child: Text('No video found')));
    }
    return Scaffold(
      appBar: AppBar(title: Text(strings.text('watchAd'))),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_filter_outlined, size: 80),
            const SizedBox(height: 16),
            Text(strings.text('premiumOnly'), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text('30s required | Remaining: $_secondsRemaining s'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _timer == null ? () => _startTimer(result) : null,
              child: const Text('Start Rewarded Ad'),
            ),
          ],
        ),
      ),
    );
  }
}
