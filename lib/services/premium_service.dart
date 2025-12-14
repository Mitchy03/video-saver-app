import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService {
  static const _prefKey = 'is_premium';
  static const _apiKey = 'REVENUECAT_API_KEY_PLACEHOLDER';
  bool _configured = false;

  Future<void> initialize() async {
    if (_configured) return;
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(_apiKey));
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
    try {
      final offerings = await Purchases.getOfferings();
      final monthly = offerings.current?.monthly;
      if (monthly == null) {
        return false;
      }
      final customerInfo = await Purchases.purchasePackage(monthly);
      return customerInfo.entitlements.active.isNotEmpty;
    } on Exception {
      return false;
    }
  }

  Future<bool> restore() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.active.isNotEmpty;
    } on Exception {
      return false;
    }
  }
}
