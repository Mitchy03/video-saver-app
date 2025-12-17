import 'package:flutter/material.dart';
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
      
      setState(() {
        _status = 'ダウンロード完了！\n$filePath';
        _isDownloading = false;
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
        _status = message;
        _isDownloading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF833AB4),  // 紫
              Color(0xFFFD1D1D),  // ピンク
              Color(0xFFFCAF45),  // オレンジ
            ],
          ),
        ),
        child: SafeArea(
          child: _selectedIndex == 0 ? _buildHomeScreen() : _buildHistoryScreen(),
        ),
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
    );
  }

  Widget _buildHomeScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          
          // タイトル
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
                ),
              ),
              Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
              SizedBox(width: 16),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.workspace_premium, color: Colors.white, size: 24),
              ),
            ],
          ),
          
          SizedBox(height: 40),
          
          // サブタイトル
          Text(
            'Youtube X Instagram Link',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          
          SizedBox(height: 16),
          
          // URL入力欄
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
                  onPressed: () {
                    // Paste機能（後で実装）
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
          ),
          
          SizedBox(height: 24),
          
          // Downloadボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isDownloading ? null : () => _startDownload(DownloadQuality.low),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'Download',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF833AB4),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // HD Downloadボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isDownloading ? null : () => _startDownload(DownloadQuality.high),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'HD Download',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF833AB4),
                ),
              ),
            ),
          ),
          
          SizedBox(height: 32),
          
          // 進捗・ステータス表示
          if (_isDownloading) ...[
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                      Container(
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
                      ),
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (_status.isNotEmpty && _status.contains('完了')) ...[
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF833AB4),
                          Color(0xFFFD1D1D),
                          Color(0xFFFCAF45),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFD1D1D).withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Complete',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF833AB4),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Video saved successfully',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_status.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3), width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _status,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.white.withOpacity(0.5)),
          SizedBox(height: 16),
          Text(
            'ダウンロード履歴',
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '履歴機能は今後実装予定',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
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
    super.dispose();
  }
}
