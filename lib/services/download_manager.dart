import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class DownloadProgress {
  DownloadProgress({required this.progress, required this.message});

  final double progress;
  final String message;
}

class DownloadResult {
  DownloadResult({
    required this.filePath,
    required this.isImage,
    this.title,
  });

  final String filePath;
  final bool isImage;
  final String? title;
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

  Future<DownloadResult> startDownload({
    required String url,
    required DownloadQuality quality,
  }) async {
    await initialize();

    final downloadsDir = await getDownloadsDirectory();
    if (downloadsDir == null) {
      throw Exception('ダウンロードフォルダが見つかりません');
    }

    final isInstagram = _isInstagramUrl(url);
    _MediaInfo? mediaInfo;
    if (isInstagram) {
      mediaInfo = await _fetchMediaInfo(url);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputTemplate =
        '${downloadsDir.path}${Platform.pathSeparator}media_$timestamp.%(ext)s';
    final expectedExtension = mediaInfo?.extension ??
        (mediaInfo?.isImage == true ? 'jpg' : 'mp4');

    final qualityFlag = isInstagram
        ? (quality == DownloadQuality.high ? 'best' : 'worst')
        : quality == DownloadQuality.high
            ? 'bestvideo+bestaudio/best' // 元動画と同じ最高画質
            : 'worst[height<=480]/worst'; // 480p以下（全プラットフォーム対応）

    _progressController.add(DownloadProgress(
      progress: 0.0,
      message: 'ダウンロード開始...',
    ));

    try {
      final process = await Process.start(
        _ytdlpPath!,
        [
          '--newline',
          '--ffmpeg-location',
          _ffmpegPath!,
          '-f',
          qualityFlag,
          '-o',
          outputTemplate,
          url,
        ],
      );

      final stdoutSubscription = process.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        final match = RegExp(r'(\d+\.?\d*)%').firstMatch(line);
        if (match != null) {
          final percent = double.tryParse(match.group(1)!);
          if (percent != null) {
            _progressController.add(
              DownloadProgress(
                progress: percent / 100,
                message: line.trim(),
              ),
            );
          }
        }
      });

      final stderrSubscription = process.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
        // エラーメッセージがあれば進捗に流す
        _progressController.add(
          DownloadProgress(progress: 0.0, message: line.trim()),
        );
      });

      final exitCode = await process.exitCode;

      await stdoutSubscription.cancel();
      await stderrSubscription.cancel();

      if (exitCode != 0) {
        throw Exception('yt-dlp exited with code $exitCode');
      }

      _progressController.add(DownloadProgress(
        progress: 1.0,
        message: 'ダウンロード完了',
      ));

      final outputPath =
          '${downloadsDir.path}${Platform.pathSeparator}media_$timestamp.$expectedExtension';
      return DownloadResult(
        filePath: outputPath,
        isImage: mediaInfo?.isImage ?? false,
        title: mediaInfo?.title,
      );
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

  bool _isInstagramUrl(String url) {
    return url.contains('instagram.com/');
  }

  Future<_MediaInfo> _fetchMediaInfo(String url) async {
    try {
      final processResult = await Process.run(
        _ytdlpPath!,
        [
          '-J',
          url,
        ],
      );

      if (processResult.exitCode != 0) {
        throw Exception(processResult.stderr.toString());
      }

      final decoded = jsonDecode(processResult.stdout.toString());
      Map<String, dynamic>? info;
      if (decoded is Map<String, dynamic>) {
        if (decoded['entries'] is List && (decoded['entries'] as List).isNotEmpty) {
          final firstEntry = (decoded['entries'] as List).first;
          if (firstEntry is Map<String, dynamic>) {
            info = firstEntry;
          }
        } else {
          info = decoded;
        }
      }

      if (info == null) {
        throw Exception('メタデータの取得に失敗しました');
      }

      final extension = (info['ext'] as String?)?.toLowerCase();
      final title = info['title']?.toString();
      final isImage = extension != null && _imageExtensions.contains(extension);

      return _MediaInfo(
        extension: extension,
        title: title,
        isImage: isImage,
      );
    } catch (e) {
      throw Exception('メタデータの取得に失敗しました: $e');
    }
  }
}

class _MediaInfo {
  _MediaInfo({
    required this.extension,
    required this.title,
    required this.isImage,
  });

  final String? extension;
  final String? title;
  final bool isImage;
}

const _imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'};
