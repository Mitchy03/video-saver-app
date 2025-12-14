import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await MobileAds.instance.initialize();
    _initialized = true;
  }

  Future<void> showRewardedAd({required VoidCallback onEarned}) async {
    await initialize();
    await RewardedAd.load(
      adUnitId: RewardedAd.testAdUnitId,
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
}
