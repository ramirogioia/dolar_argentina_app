import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyUseMockData = 'use_mock_data';
  static const String _keyApiUrl = 'api_url';
  static const bool _defaultUseMockData = true;
  static const String _defaultApiUrl =
      'https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec';

  Future<bool> getUseMockData() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseMockData) ?? _defaultUseMockData;
  }

  Future<void> setUseMockData(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseMockData, value);
  }

  Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyApiUrl) ?? _defaultApiUrl;
  }

  Future<void> setApiUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyApiUrl, value);
  }
}

