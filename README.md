# 4SNS動画クリップセーバー

プレミアム/無料プランを備えた動画クリップ保存アプリです。X(Twitter)、YouTube、YouTubeショート、Instagramの公開投稿に対応し、無料版は30秒のリワード広告視聴後に720pダウンロード、プレミアム版は広告なしで1080p以上を優先取得します。

## 主な機能
- URL自動判定付きのホーム画面＋ダウンロード履歴表示
- スプラッシュ → ホーム → 広告視聴（無料）/即DL（プレミアム） → 進捗表示 → 完了
- プレミアム紹介・設定画面から月額500円のRevenueCatサブスク購入/復元
- Google Mobile AdsによるRewarded Video（30秒視聴必須）
- shared_preferencesでプレミアム状態と履歴を永続化
- 多言語対応（日本語/英語）、ダークモード対応
- 審査向け「自分の投稿のみ」ダウンロードガード（Graph API風のエラーを全SNSで返却）

## ストア説明文（汎用動画保存ツール）
「4SNS動画クリップセーバー」は自分の公開投稿を端末に保存できる汎用動画保存ツールです。無料版は広告視聴で720p保存、プレミアムは広告なしで1080p以上に対応します。

## 開発メモ
- 依存: google_mobile_ads, purchases_flutter, youtube_explode_dart, twitter_api_v2, shared_preferences ほか
- pubspec固定: Flutter SDKに合わせた`intl 0.20.2`を採用し、`http 0.13.6`のまま`twitter_api_v2`との互換性を維持するため`youtube_explode_dart 1.12.4`を固定しています。
- テスト: `flutter test`（本環境ではFlutter SDK未導入のため未実行）
- スクリーンショット/アセットは `assets/` 配下に配置してください（サンプル .gitkeep のみ同梱）。

## 利用上の注意
各SNSの利用規約に従い、**自分が権利を持つ投稿のみ**をダウンロードしてください。権限が確認できない場合はGraph API風のエラーを返し、処理を中断します。
