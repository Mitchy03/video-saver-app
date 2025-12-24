import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../services/ad_service.dart';
import '../services/download_manager.dart';
import '../services/preferences_service.dart';
import '../services/premium_service.dart';
import '../services/video_extractor.dart';

class DownloadHistoryItem {
  DownloadHistoryItem({
    required this.url,
    required this.platform,
    required this.quality,
    required this.savedAt,
  });

  final String url;
  final String platform;
  final String quality;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
        'url': url,
        'platform': platform,
        'quality': quality,
        'savedAt': savedAt.toIso8601String(),
      };

  factory DownloadHistoryItem.fromJson(Map<String, dynamic> json) {
    return DownloadHistoryItem(
      url: json['url'] as String? ?? '',
      platform: json['platform'] as String? ?? 'unknown',
      quality: json['quality'] as String? ?? 'low',
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class AppState extends ChangeNotifier {
  AppState()
      : premiumService = PremiumService(),
        extractor = VideoExtractor(),
        downloadManager = DownloadManager(),
        preferencesService = PreferencesService();

  final PremiumService premiumService;
  final VideoExtractor extractor;
  final DownloadManager downloadManager;
  final PreferencesService preferencesService;

  bool _initialized = false;
  bool _isPremium = false;
  List<DownloadHistoryItem> _history = [];
  String? _lastError;

  bool get isPremium => _isPremium;
  bool get initialized => _initialized;
  List<DownloadHistoryItem> get history => List.unmodifiable(_history);
  String? get lastError => _lastError;

  Future<void> bootstrap() async {
    try {
      await premiumService.initialize();
      await AdService.initialize();
      _isPremium = await premiumService.isPremiumUser();
      _history = await preferencesService.loadHistory();
      _initialized = true;
    } catch (error) {
      _lastError = error.toString();
      _initialized = true;
    }
    notifyListeners();
  }

  Future<void> setPremium(bool value) async {
    _isPremium = value;
    await premiumService.persistPremiumStatus(value);
    notifyListeners();
  }

  Future<void> purchasePremium() async {
    final success = await premiumService.purchaseMonthlySubscription();
    await setPremium(success);
  }

  Future<void> restorePurchases() async {
    final restored = await premiumService.restore();
    if (restored) {
      await setPremium(true);
    }
  }

  Future<void> addHistoryItem(DownloadHistoryItem item) async {
    _history = [item, ..._history].take(20).toList();
    await preferencesService.persistHistory(_history);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history = [];
    await preferencesService.persistHistory(_history);
    notifyListeners();
  }

  String exportHistoryJson() {
    final encoded = _history.map((e) => e.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(encoded);
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
