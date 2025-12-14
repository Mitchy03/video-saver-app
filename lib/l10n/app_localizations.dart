import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('ja')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static List<LocalizationsDelegate<dynamic>> get globalDelegates => const [
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': '4SNS Video Saver',
      'enterUrl': 'Enter video URL',
      'ownership': 'This is my own post',
      'download': 'Download',
      'history': 'History',
      'premium': 'Premium',
      'settings': 'Settings',
      'watchAd': 'Watch Ad to Continue',
      'premiumOnly': 'Premium users can skip ads and get 1080p downloads.',
      'progress': 'Download Progress',
      'complete': 'Completed',
      'share': 'Share',
      'retry': 'Retry',
      'premiumPitch':
          'Remove ads and unlock high-quality downloads for ¥500 / month.',
      'purchase': 'Purchase',
      'restore': 'Restore',
      'ownPostError': 'Only your own posts are eligible for download.',
    },
    'ja': {
      'appTitle': '4SNS動画クリップセーバー',
      'enterUrl': '動画URLを入力',
      'ownership': '自分の投稿である',
      'download': 'ダウンロード',
      'history': '履歴',
      'premium': 'プレミアム',
      'settings': '設定',
      'watchAd': '広告を視聴して続行',
      'premiumOnly': 'プレミアムは広告なしで1080p以上を取得できます。',
      'progress': 'ダウンロード進捗',
      'complete': '完了',
      'share': 'シェア',
      'retry': '再試行',
      'premiumPitch': '月額500円で広告なし＆高画質を解除。',
      'purchase': '購入',
      'restore': '復元',
      'ownPostError': '自分の投稿のみダウンロードできます。',
    },
  };

  String text(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.contains(locale);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
