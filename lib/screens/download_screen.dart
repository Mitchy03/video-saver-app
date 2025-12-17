import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../services/download_manager.dart';
import '../services/video_extractor.dart';

class ModernDownloadScreen extends StatefulWidget {
  const ModernDownloadScreen({super.key});

  @override
  State<ModernDownloadScreen> createState() => _ModernDownloadScreenState();
}

class _ModernDownloadScreenState extends State<ModernDownloadScreen> {
  final _urlController = TextEditingController();
  final _downloadManager = DownloadManager();
  final _videoExtractor = VideoExtractor();
  final _confettiController =
      ConfettiController(duration: const Duration(seconds: 3));

  String _status = '';
  bool _isDownloading = false;
  double _progress = 0.0;
  VideoPlatform? _detectedPlatform;

  @override
  void initState() {
    super.initState();
    _downloadManager.progressStream.listen((progress) {
      setState(() {
        _progress = progress.progress;
        _status = progress.message;
      });
    });

    _urlController.addListener(() {
      final url = _urlController.text.trim();
      if (url.isNotEmpty) {
        setState(() {
          _detectedPlatform = _videoExtractor.detectPlatform(url);
        });
      } else {
        setState(() {
          _detectedPlatform = null;
        });
      }
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
      final filePath = await _downloadManager.startDownload(
        url: url,
        quality: quality,
      );

      _confettiController.play();

      setState(() {
        _status = '完了！\n$filePath';
        _isDownloading = false;
      });
    } catch (e) {
      String message;
      if (e.toString().contains('inappropriate') ||
          e.toString().contains('unavailable')) {
        message = 'この投稿はダウンロードできません\n（コラボ投稿または制限付きコンテンツ）';
      } else if (e.toString().contains('format')) {
        message = '対応していない形式です';
      } else {
        message = 'ダウンロードに失敗しました\nURLを確認してください';
      }

      setState(() {
        _status = message;
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF833AB4),
              Color(0xFFFD1D1D),
              Color(0xFFFCAF45),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),

                    // タイトル
                    const Text(
                      '動画ダウンロード',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms)
                        .slideY(begin: -0.2, end: 0),

                    const SizedBox(height: 40),

                    // URL入力
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'URLを貼り付け',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(20),
                          suffixIcon: _detectedPlatform != null
                              ? Padding(
                                  padding: const EdgeInsets.all(12),
                                  child:
                                      _buildPlatformIcon(_detectedPlatform!),
                                )
                              : null,
                        ),
                        style: const TextStyle(fontSize: 16),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: -0.2, end: 0),

                    const SizedBox(height: 32),

                    // ダウンロードボタン
                    _buildDownloadButton(
                      label: '低画質DL（無料）',
                      color: Colors.white,
                      textColor: const Color(0xFF833AB4),
                      onTap: () => _startDownload(DownloadQuality.low),
                      delay: 400,
                    ),

                    const SizedBox(height: 16),

                    _buildDownloadButton(
                      label: '高画質DL（プレミアム）',
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                      ),
                      textColor: Colors.white,
                      onTap: () => _startDownload(DownloadQuality.high),
                      delay: 600,
                    ),

                    const SizedBox(height: 32),

                    // 進捗表示
                    if (_isDownloading) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            LinearProgressIndicator(
                              value: _progress,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFFFD1D1D),
                              ),
                              minHeight: 8,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _status,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ).animate().fadeIn().scale(),
                    ] else if (_status.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _status,
                          style: TextStyle(
                            fontSize: 14,
                            color:
                                _status.contains('完了') ? Colors.green : Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ).animate().fadeIn().scale(),
                    ],
                  ],
                ),
              ),

              // 紙吹雪
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.05,
                  emissionFrequency: 0.05,
                  numberOfParticles: 50,
                  gravity: 0.2,
                  colors: const [
                    Color(0xFF833AB4),
                    Color(0xFFFD1D1D),
                    Color(0xFFFCAF45),
                    Colors.white,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDownloadButton({
    required String label,
    Color? color,
    Gradient? gradient,
    required Color textColor,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: _isDownloading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color,
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 600.ms)
        .slideY(begin: -0.2, end: 0)
        .then()
        .shimmer(delay: 1000.ms, duration: 2000.ms);
  }

  Widget _buildPlatformIcon(VideoPlatform platform) {
    IconData icon;
    Color color;

    switch (platform) {
      case VideoPlatform.youtube:
      case VideoPlatform.youtubeShorts:
        icon = Icons.play_circle_fill;
        color = Colors.red;
        break;
      case VideoPlatform.twitter:
        icon = Icons.tag;
        color = Colors.black;
        break;
      case VideoPlatform.instagram:
        icon = Icons.camera_alt;
        color = const Color(0xFFFD1D1D);
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 28)
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.2, 1.2),
          duration: 1000.ms,
        )
        .then()
        .scale(
          begin: const Offset(1.2, 1.2),
          end: const Offset(1, 1),
          duration: 1000.ms,
        );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _downloadManager.dispose();
    _confettiController.dispose();
    super.dispose();
  }
}
