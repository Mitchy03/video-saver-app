import 'dart:async';

import 'video_extractor.dart';

class DownloadProgress {
  DownloadProgress({required this.progress, required this.message});

  final double progress;
  final String message;
}

class DownloadManager {
  Stream<DownloadProgress> startDownload(
    VideoExtractionResult result, {
    required bool highQuality,
  }) async* {
    final qualityLabel = highQuality
        ? result.qualityLabels.highQuality
        : result.qualityLabels.lowQuality;
    for (var i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 250));
      yield DownloadProgress(
        progress: i / 100,
        message: 'Downloading $qualityLabel',
      );
    }
  }
}
