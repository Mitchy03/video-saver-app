import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  bool _initialized = false;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isWindows => defaultTargetPlatform == TargetPlatform.windows;
  bool get _isMobile => _isAndroid || _isIOS;

  Future<void> initialize() async {
    if (_initialized) return;
    if (_isMobile) {
      await MobileAds.instance.initialize();
    }
    _initialized = true;
  }

  Future<void> showRewardedAd({required VoidCallback onEarned}) async {
    await initialize();
    if (_isWindows) {
      onEarned();
      return;
    }

    final adUnitId = _rewardedAdUnitId;
    if (adUnitId == null) {
      onEarned();
      return;
    }

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          ad.show(onUserEarnedReward: (_, __) => onEarned());
        },
        onAdFailedToLoad: (_) {
          onEarned();
        },
      ),
    );
  }

  String? get _rewardedAdUnitId {
    if (_isAndroid) {
      return 'ca-app-pub-3940256099942544/5224354917';
    }

    if (_isIOS) {
      return 'ca-app-pub-3940256099942544/1712485313';
    }

    return null;
  }
}
