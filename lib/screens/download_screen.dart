import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/download_manager.dart';
import '../services/video_extractor.dart';

class ModernDownloadScreen extends StatefulWidget {
  const ModernDownloadScreen({super.key});

  @override
  State<ModernDownloadScreen> createState() => _ModernDownloadScreenState();
}

class _ModernDownloadScreenState extends State<ModernDownloadScreen>
    with SingleTickerProviderStateMixin {
  final _urlController = TextEditingController();
  final _downloadManager = DownloadManager();
  final _videoExtractor = VideoExtractor();
  final _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  late AnimationController _completeAnimController;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;
  late PageController _pageController;
  List<Map<String, dynamic>> _downloadHistory = [];
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
    _pageController = PageController(initialPage: 0);
    _downloadManager.progressStream.listen((progress) {
      setState(() {
        _progress = progress.progress;
        _status = progress.message;
      });
    });

    _completeAnimController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _circleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _completeAnimController,
        curve: Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _checkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _completeAnimController,
        curve: Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );
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
      // 履歴に追加
      _downloadHistory.insert(0, {
        'url': url,
        'quality': quality == DownloadQuality.high ? 'HD' : 'SD',
        'date': DateTime.now(),
        'platform': _videoExtractor.detectPlatform(url).toString().split('.').last,
      });
      _completeAnimController.forward(from: 0.0);

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
          // 背景グラデーション（_buildMainScreen から色をコピー）
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF833AB4),
                  Color(0xFFE1306C),
                  Color(0xFFF77737),
                  Color(0xFFFCAF45),
                ],
                stops: [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
          // PageView
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _selectedIndex = index);
            },
            children: [
              _buildMainScreen(),
              _buildHistoryPageScreen(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF833AB4).withOpacity(0.45),
              Color(0xFFC13584).withOpacity(0.4),
            ],
          ),
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
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isSelected ? 0.25 : 0.0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white70,
          size: 28,
        ),
      ),
    ).animate(target: isSelected ? 1 : 0).scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1.0, 1.0),
        );
  }

  Widget _buildMainScreen() {
    return Stack(
      children: [
        // 背景とメインコンテンツ
        Container(
          color: Colors.transparent,
          child: SafeArea(
            child: _buildHomeScreen(),
          ),
        ),

        // ブラー背景
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: (_isDownloading || _showComplete || _showError) ? 1.0 : 0.0,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ),

        // DL進捗表示（ブラーの上）
        if (_isDownloading)
          Positioned(
            top: 350,
            left: 48,
            right: 48,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF833AB4).withOpacity(0.35),
                    Color(0xFFC13584).withOpacity(0.30),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            height: 8,
                            width: constraints.maxWidth * _progress,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Color(0xFFF77737),
                                  Color(0xFFE1306C),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFFF6416C).withOpacity(0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ).animate(onPlay: (controller) => controller.repeat())
                              .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.4)),
                        ],
                      );
                    },
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
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
          ),

        // 紙吹雪
        IgnorePointer(
          child: Align(
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
        ),

        // Complete ポップアップ（if文なし）
        IgnorePointer(
          ignoring: !_showComplete,
          child: AnimatedOpacity(
            opacity: _showComplete ? 1.0 : 0.0,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: AnimatedScale(
              scale: _showComplete ? 1.0 : 0.7,
              duration: Duration(milliseconds: 400),
              curve: _showComplete ? Curves.elasticOut : Curves.easeInOut,
              child: Center(
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
                  child: AnimatedBuilder(
                    animation: _completeAnimController,
                    builder: (context, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // グラデーション進捗円
                              SizedBox(
                                width: 80,
                                height: 80,
                                child: CustomPaint(
                                  painter: GradientCirclePainter(
                                    progress: _circleAnimation.value,
                                    gradientColors: [
                                      Color(0xFF833AB4),
                                      Color(0xFFFD1D1D),
                                      Color(0xFFFCAF45),
                                    ],
                                  ),
                                ),
                              ),
                              // チェックマーク
                              Transform.scale(
                                scale: _checkAnimation.value,
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        Color(0xFF833AB4),
                                        Color(0xFFFD1D1D),
                                        Color(0xFFFCAF45),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Complete',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        // エラーポップアップ（if文なし）
        IgnorePointer(
          ignoring: !_showError,
          child: AnimatedOpacity(
            opacity: _showError ? 1.0 : 0.0,
            duration: Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            child: AnimatedScale(
              scale: _showError ? 1.0 : 0.7,
              duration: Duration(milliseconds: 400),
              curve: _showError ? Curves.elasticOut : Curves.easeInOut,
              child: Center(
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
                      ),
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
                  style: GoogleFonts.pacifico(
                    fontSize: 24,
                    color: Colors.white,
                  ),
                ).animate().fadeIn(duration: 600.ms).slideX(begin: -0.2, end: 0),
              ),
              Icon(Icons.notifications_outlined, color: Colors.white, size: 28)
                  .animate().fadeIn(delay: 200.ms).scale(begin: Offset(0.5, 0.5)),
              SizedBox(width: 16),
              GestureDetector(
                onTap: () => _showSubscriptionSheet(),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.workspace_premium, color: Colors.white, size: 24),
                ),
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
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF833AB4),
                        Color(0xFFC13584),
                        Color(0xFFF77737),
                      ],
                    ).createShader(bounds),
                    child: TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        hintText: 'URLを貼り付け',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
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

  Widget _buildHistoryPageScreen() {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Download History',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${_downloadHistory.length} downloads',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _downloadHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No downloads yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _downloadHistory.length,
                      itemBuilder: (context, index) {
                        final item = _downloadHistory[index];
                        final date = item['date'] as DateTime;
                        final timeAgo = _getTimeAgo(date);

                        return Container(
                          margin: EdgeInsets.only(bottom: 12),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFF833AB4).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getPlatformIcon(item['platform']),
                                  color: Color(0xFF833AB4),
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['platform'].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      timeAgo,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: item['quality'] == 'HD'
                                      ? LinearGradient(
                                          colors: [
                                            Color(0xFF833AB4),
                                            Color(0xFFFD1D1D),
                                          ],
                                        )
                                      : null,
                                  color: item['quality'] == 'SD' ? Colors.grey[300] : null,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item['quality'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: item['quality'] == 'HD' ? Colors.white : Colors.black54,
                                  ),
                                ),
                              ),
                            ],
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

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'youtube':
      case 'youtubeshorts':
        return Icons.play_circle_fill;
      case 'twitter':
        return Icons.tag;
      case 'instagram':
        return Icons.camera_alt;
      default:
        return Icons.video_library;
    }
  }

  void _showSubscriptionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
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
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 40),
            Icon(
              Icons.workspace_premium,
              size: 80,
              color: Colors.white,
            ),
            SizedBox(height: 24),
            Text(
              'Premium',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Unlock unlimited downloads',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            SizedBox(height: 48),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  _buildFeatureItem('HD Quality Downloads'),
                  _buildFeatureItem('No Ads'),
                  _buildFeatureItem('Unlimited Downloads'),
                  _buildFeatureItem('Priority Support'),
                ],
              ),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '¥980 / month',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF833AB4),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Cancel anytime',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Maybe later',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Text(
            text,
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _downloadManager.dispose();
    _confettiController.dispose();
    _pageController.dispose();
    _completeAnimController.dispose();
    _completeTimer?.cancel();
    _errorTimer?.cancel();
    super.dispose();
  }
}

class GradientCirclePainter extends CustomPainter {
  final double progress;
  final List<Color> gradientColors;

  GradientCirclePainter({
    required this.progress,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 背景円
    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // グラデーション円
    if (progress > 0) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      final gradient = SweepGradient(
        colors: gradientColors,
        startAngle: -3.14 / 2,
        endAngle: 3.14 * 2 - 3.14 / 2,
      );

      final gradientPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * 3.14159 * progress;
      canvas.drawArc(
        rect,
        -3.14159 / 2,
        sweepAngle,
        false,
        gradientPaint,
      );
    }
  }

  @override
  bool shouldRepaint(GradientCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
