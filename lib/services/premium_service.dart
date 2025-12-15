import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static const _prefKey = 'is_premium';
  static const _apiKey = 'REVENUECAT_API_KEY_PLACEHOLDER';
  bool _configured = false;

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  bool get _isMobile => _isAndroid || _isIOS;
  bool get _isWindows => defaultTargetPlatform == TargetPlatform.windows;

  Future<void> initialize() async {
    if (_configured) return;
    if (_isMobile) {
      await Purchases.setLogLevel(LogLevel.debug);
      await Purchases.configure(PurchasesConfiguration(_apiKey));
    }
    _configured = true;
  }

  Future<bool> isPremiumUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<void> persistPremiumStatus(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }

  Future<bool> purchaseMonthlySubscription() async {
    if (_isWindows) {
      await persistPremiumStatus(true);
      return true;
    }

    try {
      final offerings = await Purchases.getOfferings();
      final monthly = offerings.current?.monthly;
      if (monthly == null) {
        return false;
      }
      final customerInfo = await Purchases.purchasePackage(monthly);
      final hasAccess = customerInfo.entitlements.active.isNotEmpty;
      await persistPremiumStatus(hasAccess);
      return hasAccess;
    } on Exception {
      return false;
    }
  }

  Future<bool> restore() async {
    if (_isWindows) {
      return isPremiumUser();
    }

    try {
      final info = await Purchases.restorePurchases();
      final hasAccess = info.entitlements.active.isNotEmpty;
      await persistPremiumStatus(hasAccess);
      return hasAccess;
    } on Exception {
      return false;
    }
  }
}
