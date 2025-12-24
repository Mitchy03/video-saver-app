import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/download_manager.dart';
import '../services/purchase_service.dart';
import '../services/video_extractor.dart';

class ModernDownloadScreen extends StatefulWidget {
  const ModernDownloadScreen({super.key});

  @override
  State<ModernDownloadScreen> createState() => _ModernDownloadScreenState();
}

class _ModernDownloadScreenState extends State<ModernDownloadScreen>
    with TickerProviderStateMixin {
  final _urlController = TextEditingController();
  final _downloadManager = DownloadManager();
  final _videoExtractor = VideoExtractor();
  final _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  late AnimationController _completeAnimController;
  late Animation<double> _circleAnimation;
  late Animation<double> _checkAnimation;
  late AnimationController _completionAnimController;
  late Animation<double> _circleProgressAnimation;
  late Animation<double> _iconScaleAnimation;
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

    _completionAnimController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _circleProgressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _completionAnimController,
        curve: Interval(0.0, 0.7, curve: Curves.easeInOut),
      ),
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _completionAnimController,
        curve: Interval(0.7, 1.0, curve: Curves.elasticOut),
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
      final platform = _videoExtractor.detectPlatform(url);
      final platformLabel = platform.toString().split('.').last;
      final thumbnailUrl = _getThumbnailUrl(url, platform);
      // 履歴に追加
      _downloadHistory.insert(0, {
        'url': url,
        'quality': quality == DownloadQuality.high ? 'HD' : 'SD',
        'date': DateTime.now(),
        'platform': platformLabel,
        'thumbnailUrl': thumbnailUrl,
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

          if (!_isDownloading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildNavBar(),
            ),

          if (_isDownloading) ...[
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.1),
                ),
              ),
            ),
            Center(child: _buildProgressCard()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Opacity(
                opacity: 0.3,
                child: _buildNavBar(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    return SafeArea(
      child: Container(
        margin: EdgeInsets.only(left: 24, right: 24, bottom: 24),
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Color(0xFF833AB4).withOpacity(0.3),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          children: [
            _buildNavItem(Icons.home_rounded, 0),
            _buildNavItem(Icons.history_rounded, 1),
          ],
        ),
      ),
    );
  }

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  Widget _buildNavItem(IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onNavTap(index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(35),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Icon(
              icon,
              color: isSelected ? Color(0xFF833AB4) : Colors.white70,
              size: 28,
            ),
          ),
        ),
      ).animate(target: isSelected ? 1 : 0).scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
          ),
    );
  }

  Widget _buildProgressCard() {
    final double progressValue = _progress.clamp(0.0, 1.0).toDouble();
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 48),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // 背景バー
                    Container(
                      width: constraints.maxWidth,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // 進捗バー
                    AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      width: constraints.maxWidth * progressValue,
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFF77737), Color(0xFFE1306C)],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                );
              },
            ),
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
                '${(progressValue * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: Offset(0.9, 0.9));
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
            opacity: (_showComplete || _showError) ? 1.0 : 0.0,
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
                  style: const TextStyle(
                    fontFamily: 'Lucida Handwriting',
                    fontFamilyFallback: [
                      'Segoe Script',
                      'Brush Script MT',
                      'Comic Sans MS',
                    ],
                    fontSize: 26,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    Icons.search,
                    color: Color(0xFFC13584),
                  ),
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
                        hintText: 'URL',
                        hintStyle: TextStyle(
                          color: Colors.grey.withOpacity(0.5),
                          fontSize: 16,
                        ),
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
                  onPressed: () async {
                    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
                    if (clipboardData != null && clipboardData.text != null) {
                      _urlController.text = clipboardData.text!;
                    }
                  },
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
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
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
                      padding: EdgeInsets.symmetric(vertical: 8),
                      physics: BouncingScrollPhysics(),
                      itemCount: _downloadHistory.length,
                      itemBuilder: (context, index) {
                        final item = _downloadHistory[index];
                        final date = item['date'] as DateTime;
                        final timeAgo = _getTimeAgo(date);
                        final thumbnailUrl = item['thumbnailUrl'] as String?;
                        final title = (item['url'] as String?) ?? 'Video';

                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                                    ? Image.network(
                                        thumbnailUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            _buildThumbnailPlaceholder(),
                                      )
                                    : _buildThumbnailPlaceholder(),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          _getPlatformIcon(item['platform']),
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          timeAgo,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: item['quality'] == 'HD'
                                      ? LinearGradient(
                                          colors: [
                                            Color(0xFF833AB4),
                                            Color(0xFFFD1D1D),
                                          ],
                                        )
                                      : null,
                                  color: item['quality'] == 'SD' ? Colors.grey[200] : null,
                                  borderRadius: BorderRadius.circular(10),
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
                              SizedBox(width: 12),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.grey[400],
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

  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey.withOpacity(0.3),
      child: Icon(
        Icons.video_library,
        color: Colors.white54,
      ),
    );
  }

  String? _getThumbnailUrl(String url, VideoPlatform platform) {
    switch (platform) {
      case VideoPlatform.youtube:
      case VideoPlatform.youtubeShorts:
        final videoId = _extractYouTubeVideoId(url);
        if (videoId != null && videoId.isNotEmpty) {
          return 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
        }
        return null;
      case VideoPlatform.twitter:
      case VideoPlatform.instagram:
      case VideoPlatform.unknown:
        return null;
    }
  }

  String? _extractYouTubeVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    final watchId = uri.queryParameters['v'];
    if (watchId != null && watchId.isNotEmpty) {
      return watchId;
    }

    if (uri.pathSegments.contains('shorts')) {
      final shortsIndex = uri.pathSegments.indexOf('shorts');
      if (shortsIndex >= 0 && uri.pathSegments.length > shortsIndex + 1) {
        return uri.pathSegments[shortsIndex + 1];
      }
    }

    return null;
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
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 400),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return SlideTransition(
          position: Tween<Offset>(begin: Offset(0, 0.1), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(curved),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        return _buildPremiumContent();
      },
    );
  }

  Widget _buildPremiumContent() {
    final isJapanese = Platform.localeName.startsWith('ja');

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 24, vertical: 80),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF833AB4),
                Color(0xFFC13584),
                Color(0xFFF77737),
              ],
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                spreadRadius: 0,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.workspace_premium, color: Colors.white, size: 24),
                        SizedBox(width: 8),
                        Text(
                          'Premium',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                        duration: Duration(seconds: 2),
                        color: Colors.white.withOpacity(0.3),
                      ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                isJapanese ? '無制限ダウンロードを解除' : 'Unlock unlimited downloads',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 32),
              Column(
                children: [
                  _buildFeatureItem(isJapanese ? '広告なし' : 'No Ads'),
                  _buildFeatureItem(
                    isJapanese ? '無制限ダウンロード' : 'Unlimited Downloads',
                  ),
                ],
              ),
              SizedBox(height: 32),
              GestureDetector(
                onTap: () async {
                  final success = await PurchaseService.purchasePremium();
                  if (success) {
                    Navigator.of(context).pop();
                    _confettiController.play();
                    _showPurchaseCompleteDialog();
                  }
                },
                child: Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  padding: EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        spreadRadius: 0,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        isJapanese ? '¥500 / 月' : '\$5 / month',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF833AB4),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        isJapanese ? 'いつでもキャンセル可能' : 'Cancel anytime',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                    duration: Duration(seconds: 2),
                    color: Colors.white.withOpacity(0.3),
                  ),
              SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  child: Text(
                    isJapanese ? '後で' : 'Maybe later',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  void _showPurchaseCompleteDialog() {
    _completionAnimController.forward(from: 0.0);
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: Duration(milliseconds: 500),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.elasticOut),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      pageBuilder: (context, animation, secondaryAnimation) {
        final isJapanese = Platform.localeName.startsWith('ja');
        return Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.95,
            margin: EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF833AB4),
                  Color(0xFFC13584),
                  Color(0xFFF77737),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFC13584).withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _completionAnimController,
                  builder: (context, child) {
                    return Container(
                      width: 100,
                      height: 100,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size(100, 100),
                            painter: CircleProgressPainter(
                              progress: _circleProgressAnimation.value,
                              color: Colors.white,
                              strokeWidth: 4,
                            ),
                          ),
                          Transform.scale(
                            scale: _iconScaleAnimation.value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.workspace_premium,
                                size: 48,
                                color: Color(0xFFC13584),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                Text(
                  isJapanese ? 'ようこそ！' : 'Welcome!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  isJapanese ? 'プレミアムメンバー' : 'Premium Member',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 20,
                  ),
                ),
                SizedBox(height: 16),
                _buildCompleteBenefit(Icons.block, isJapanese ? '広告なし' : 'No Ads'),
                SizedBox(height: 12),
                _buildCompleteBenefit(
                  Icons.all_inclusive,
                  isJapanese ? '無制限ダウンロード' : 'Unlimited Downloads',
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Text(
                      isJapanese ? '始める' : 'Get Started',
                      style: TextStyle(
                        color: Color(0xFFC13584),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompleteBenefit(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _downloadManager.dispose();
    _confettiController.dispose();
    _pageController.dispose();
    _completeAnimController.dispose();
    _completionAnimController.dispose();
    _completeTimer?.cancel();
    _errorTimer?.cancel();
    super.dispose();
  }
}

class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  CircleProgressPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(CircleProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
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
