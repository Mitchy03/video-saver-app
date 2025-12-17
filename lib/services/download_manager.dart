import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';

class DownloadProgress {
  DownloadProgress({required this.progress, required this.message});

  final double progress;
  final String message;
}

enum DownloadQuality {
  low, // 無料・広告あり
  high, // サブスク・チケット
}

class DownloadManager {
  static const String ytdlpAsset = 'assets/yt-dlp.exe';
  static const String ffmpegAsset = 'assets/ffmpeg.exe';
  String? _ytdlpPath;
  String? _ffmpegPath;
  final _progressController = StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  Future<void> initialize() async {
    if (_ytdlpPath != null) return;

    final tempDir = await getTemporaryDirectory();
    _ytdlpPath = '${tempDir.path}\\yt-dlp.exe';

    final file = File(_ytdlpPath!);
    if (!await file.exists()) {
      try {
        final data = await rootBundle.load(ytdlpAsset);
        await file.writeAsBytes(data.buffer.asUint8List());
      } catch (e) {
        throw Exception('yt-dlp.exe の読み込みに失敗: $e');
      }
    }

    // ffmpeg展開
    _ffmpegPath = '${tempDir.path}\\ffmpeg.exe';
    final ffmpegFile = File(_ffmpegPath!);
    if (!await ffmpegFile.exists()) {
      final ffmpegData = await rootBundle.load(ffmpegAsset);
      await ffmpegFile.writeAsBytes(ffmpegData.buffer.asUint8List());
    }
  }

  Future<String> startDownload({
    required String url,
    required DownloadQuality quality,
  }) async {
    await initialize();

    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) {
      throw Exception('ダウンロードフォルダが見つかりません');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = '${downloadsDir.path}\\video_$timestamp.mp4';

    final qualityFlag = quality == DownloadQuality.high
        ? 'bestvideo+bestaudio/best' // 元動画と同じ最高画質
        : 'worst[height<=480]/worst'; // 480p以下（全プラットフォーム対応）

    _progressController.add(DownloadProgress(
      progress: 0.0,
      message: 'ダウンロード開始...',
    ));

    try {
      final shell = Shell();

      await shell.run('''
        "$_ytdlpPath" --ffmpeg-location "$_ffmpegPath" -f "$qualityFlag" -o "$outputPath" "$url"
      ''');

      _progressController.add(DownloadProgress(
        progress: 1.0,
        message: 'ダウンロード完了',
      ));

      return outputPath;
    } catch (e) {
      _progressController.add(DownloadProgress(
        progress: 0.0,
        message: 'エラー: $e',
      ));
      throw Exception('ダウンロード失敗: $e');
    }
  }

  void dispose() {
    _progressController.close();
  }
}
