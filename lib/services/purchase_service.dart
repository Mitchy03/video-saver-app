import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class PurchaseService {
  static const String _premiumKey = 'is_premium';

  // RevenueCat API Keys（ストア登録後に設定）
  static const String _appleApiKey = 'YOUR_APPLE_API_KEY';
  static const String _googleApiKey = 'YOUR_GOOGLE_API_KEY';

  static Future<void> initialize() async {
    // ストア登録後に有効化
    // await Purchases.setDebugLogsEnabled(true);
    //
    // PurchasesConfiguration configuration;
    // if (Platform.isIOS) {
    //   configuration = PurchasesConfiguration(_appleApiKey);
    // } else if (Platform.isAndroid) {
    //   configuration = PurchasesConfiguration(_googleApiKey);
    // }
    // await Purchases.configure(configuration);
  }

  static Future<bool> purchasePremium() async {
    try {
      // ストア登録後に実際の課金処理を実装
      // final offerings = await Purchases.getOfferings();
      // if (offerings.current != null) {
      //   final package = offerings.current!.monthly;
      //   if (package != null) {
      //     await Purchases.purchasePackage(package);
      //     await _setPremiumStatus(true);
      //     return true;
      //   }
      // }

      // 今は仮実装: 常に成功とする（テスト用）
      await _setPremiumStatus(true);
      return true;
    } catch (e) {
      print('Purchase error: $e');
      return false;
    }
  }

  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_premiumKey) ?? false;
  }

  static Future<void> _setPremiumStatus(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, status);
  }

  static Future<void> restorePurchases() async {
    try {
      // ストア登録後に実装
      // final customerInfo = await Purchases.restorePurchases();
      // final isPremium = customerInfo.entitlements.active.containsKey('premium');
      // await _setPremiumStatus(isPremium);
    } catch (e) {
      print('Restore error: $e');
    }
  }
}
