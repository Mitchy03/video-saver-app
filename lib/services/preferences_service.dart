import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../state/app_state.dart';

class PreferencesService {
  static const _historyKey = 'download_history';

  Future<List<DownloadHistoryItem>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey) ?? [];
    return historyJson
        .map((item) => DownloadHistoryItem.fromJson(
            jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> persistHistory(List<DownloadHistoryItem> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = history.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_historyKey, encoded);
  }
}
