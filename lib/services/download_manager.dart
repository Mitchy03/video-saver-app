import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

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
  static const String _apiUrl = 'https://video-saver-api.onrender.com/get-video-url';
  final _progressController = StreamController<DownloadProgress>.broadcast();

  Stream<DownloadProgress> get progressStream => _progressController.stream;

  Future<String> startDownload({
    required String url,
    required DownloadQuality quality,
  }) async {
    try {
      _progressController.add(DownloadProgress(
        progress: 0.0,
        message: 'ダウンロード準備中...',
      ));

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'url': url,
          'quality': quality == DownloadQuality.high ? 'high' : 'low',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('API error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception('不正なレスポンス形式です');
      }

      if (data['error'] != null) {
        throw Exception(data['error']);
      }

      final videoUrl = data['video_url'] as String?;
      final title = data['title'] as String? ?? 'video';
      final ext = data['ext'] as String? ?? 'mp4';

      if (videoUrl == null || videoUrl.isEmpty) {
        throw Exception('動画URLの取得に失敗しました');
      }

      _progressController.add(DownloadProgress(
        progress: 0.3,
        message: 'ダウンロード中...',
      ));

      final videoResponse = await http.get(Uri.parse(videoUrl));

      if (videoResponse.statusCode != 200) {
        throw Exception('動画の取得に失敗しました (${videoResponse.statusCode})');
      }

      _progressController.add(DownloadProgress(
        progress: 0.8,
        message: '保存中...',
      ));

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$title.$ext';
      final file = File(filePath);
      await file.writeAsBytes(videoResponse.bodyBytes);

      _progressController.add(DownloadProgress(
        progress: 1.0,
        message: 'ダウンロード完了',
      ));

      return filePath;
    } catch (e) {
      _progressController.add(DownloadProgress(
        progress: 0.0,
        message: 'エラー: $e',
      ));
      rethrow;
    }
  }

  void dispose() {
    _progressController.close();
  }
}
