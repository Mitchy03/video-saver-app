import 'dart:async';
import 'dart:ui';

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
  final _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  Timer? _completeTimer;
  bool _showComplete = false;
  bool _showError = false;
  String _errorMessage = '';
  Timer? _errorTimer;

  String _status = '';
  bool _isDownloading = false;
  double _progress = 0.0;
  int _selectedIndex = 0;

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
      _showErrorPopup('URLを入力してください');
      return;
    }

    if (!_videoExtractor.isValidUrl(url)) {
      _showErrorPopup('対応していないURLです');
      return;
    }

    setState(() {
      _isDownloading = true;
      _status = '準備中...';
      _progress = 0.0;
    });

    try {
      final filePath = await _downloadManager.startDownload(
        url: url,
        quality: quality,
      );

      _confettiController.play();

      setState(() {
        _showComplete = true;
        _isDownloading = false;
      });

      _completeTimer = Timer(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showComplete = false;
            _status = '';
          });
        }
      });
    } catch (e) {
      String message;
      if (e.toString().contains('inappropriate') || 
          e.toString().contains('unavailable')) {
        message = 'この投稿はダウンロードできません';
      } else if (e.toString().contains('format')) {
        message = '対応していない形式です';
      } else {
        message = 'ダウンロードに失敗しました';
      }

      setState(() {
        _isDownloading = false;
      });
      _showErrorPopup(message);
    }
  }

  void _showErrorPopup(String message) {
    setState(() {
      _showError = true;
      _errorMessage = message;
    });

    _errorTimer = Timer(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showError = false;
          _errorMessage = '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景とメインコンテンツ
          Container(
            decoration: BoxDecoration(
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
              child: _selectedIndex == 0 ? _buildHomeScreen() : _buildHistoryScreen(),
            ),
          ),

          // ブラー背景（ダウンロード中・Complete・エラー時）
          AnimatedOpacity(
            opacity: (_isDownloading || _showComplete || _showError) ? 1.0 : 0.0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // 紙吹雪（ブラーの上）
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.2,
              colors: [
                Color(0xFF833AB4),
                Color(0xFFFD1D1D),
                Color(0xFFFCAF45),
                Colors.white,
              ],
            ),
          ),

          // Complete ポップアップ
          AnimatedOpacity(
            opacity: _showComplete ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: AnimatedScale(
              scale: _showComplete ? 1.0 : 0.7,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: _showComplete
                  ? Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation(Colors.green),
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.green,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ).animate().scale(begin: Offset(0, 0), duration: 400.ms, curve: Curves.elasticOut),
                            SizedBox(height: 20),
                            Text(
                              'Complete',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3, end: 0),
                          ],
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ),

          // エラーポップアップ
          AnimatedOpacity(
            opacity: _showError ? 1.0 : 0.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: AnimatedScale(
              scale: _showError ? 1.0 : 0.7,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: _showError
                  ? Center(
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: 1.0,
                                    strokeWidth: 6,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation(Colors.red),
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red,
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ).animate().scale(begin: Offset(0, 0), duration: 400.ms, curve: Curves.elasticOut),
                            SizedBox(height: 20),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.3, end: 0),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.2), width: 0.5)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 0),
                _buildNavItem(Icons.history_rounded, 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 28,
        ),
      ),
    ).animate(target: isSelected ? 1 : 0).scale();
  }

  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(
                child: Text(
                  'Downloader Youtube X Instagram',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
              ),
              Icon(Icons.notifications_outlined, color: Colors.white, size: 28)
                  .animate().fadeIn(delay: 200.ms).scale(begin: Offset(0.5, 0.5)),
              SizedBox(width: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.workspace_premium, color: Colors.white, size: 24),
              ).animate().fadeIn(delay: 400.ms).scale(begin: Offset(0.5, 0.5)),
            ],
          ),
          
          SizedBox(height: 40),
          
          Text(
            'Youtube X Instagram Link',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ).animate().fadeIn(delay: 200.ms),
          
          SizedBox(height: 16),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(Icons.search, color: Colors.grey[600]),
                ),
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'URLを貼り付け',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Paste',
                    style: TextStyle(
                      color: Color(0xFF833AB4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          
          SizedBox(height: 24),
          
          Stack(
            children: [
              Column(
                children: [
                  _buildDownloadButton(
                    label: 'Download',
                    onTap: () => _startDownload(DownloadQuality.low),
                    delay: 600,
                  ),
                  SizedBox(height: 16),
                  _buildDownloadButton(
                    label: 'HD Download',
                    onTap: () => _startDownload(DownloadQuality.high),
                    delay: 800,
                  ),
                ],
              ),
              if (_isDownloading)
                Positioned.fill(
                  child: Container(
                    margin: EdgeInsets.only(top: 0),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF833AB4).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    height: 8,
                                    width: MediaQuery.of(context).size.width * _progress * 0.85,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF833AB4),
                                          Color(0xFFFD1D1D),
                                          Color(0xFFFCAF45),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFFFD1D1D).withOpacity(0.5),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ).animate(onPlay: (controller) => controller.repeat())
                                      .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.3)),
                                ],
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Downloading',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF833AB4),
                                    ),
                                  ),
                                  Text(
                                    '${(_progress * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFD1D1D),
                                    ),
                                  ).animate(onPlay: (controller) => controller.repeat())
                                      .fadeIn(duration: 500.ms)
                                      .then()
                                      .fadeOut(duration: 500.ms),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn().scale(begin: Offset(0.9, 0.9)),
                      ],
                    ),
                  ),
                ),
            ],
          ),

        ],
      ),
    );
  }

  Widget _buildDownloadButton({
    required String label,
    required VoidCallback onTap,
    required int delay,
  }) {
    return GestureDetector(
      onTap: _isDownloading ? null : onTap,
      child: AnimatedOpacity(
        opacity: _isDownloading ? 0.3 : 1.0,
        duration: Duration(milliseconds: 300),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF833AB4),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 600.ms)
        .slideY(begin: 0.2, end: 0)
        .then(delay: 1000.ms)
        .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5));
  }

  Widget _buildHistoryScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.white.withOpacity(0.5))
              .animate().scale(duration: 800.ms, curve: Curves.elasticOut),
          SizedBox(height: 16),
          Text(
            'ダウンロード履歴',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ).animate().fadeIn(delay: 200.ms),
          SizedBox(height: 8),
          Text(
            '履歴機能は今後実装予定',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _downloadManager.dispose();
    _confettiController.dispose();
    _completeTimer?.cancel();
    _errorTimer?.cancel();
    super.dispose();
  }
}
