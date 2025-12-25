import 'dart:io';

import 'package:flutter/material.dart';
import 'services/purchase_service.dart';
import 'services/download_manager.dart';
import 'services/video_extractor.dart';
import 'screens/download_screen.dart';
import 'services/ad_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid || Platform.isIOS) {
    await AdService.initialize();
  } else {
    // Skip ad initialization on unsupported platforms (e.g., Windows)
    debugPrint('Skipping ad initialization on this platform');
  }
  await PurchaseService.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Downloader Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ModernDownloadScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _urlController = TextEditingController();
  final _downloadManager = DownloadManager();
  final _videoExtractor = VideoExtractor();
  
  String _status = '待機中';
  bool _isDownloading = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _downloadManager.progressStream.listen((progress) {
      setState(() {
        _progress = progress.progress;
        _status = progress.message;
      });
    });
  }

  Future<void> _startDownload(DownloadQuality quality) async {
    final url = _urlController.text.trim();
    
    if (url.isEmpty) {
      setState(() => _status = 'URLを入力してください');
      return;
    }

    if (!_videoExtractor.isValidUrl(url)) {
      setState(() => _status = '対応していないURLです');
      return;
    }

    setState(() {
      _isDownloading = true;
      _status = '準備中...';
    });

    try {
      final result = await _downloadManager.startDownload(
        url: url,
        quality: quality,
      );
      
      setState(() {
        _status = '完了: ${result.filePath}';
        _isDownloading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'エラー: $e';
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('動画DLテスト')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: '動画URL',
                hintText: 'https://www.youtube.com/watch?v=...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDownloading ? null : () => _startDownload(DownloadQuality.low),
                    child: const Text('低画質DL（無料）'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isDownloading ? null : () => _startDownload(DownloadQuality.high),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('高画質DL（サブスク）'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isDownloading)
              LinearProgressIndicator(value: _progress),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _downloadManager.dispose();
    super.dispose();
  }
}
