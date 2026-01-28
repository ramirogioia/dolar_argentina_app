import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/dollar_type.dart';

class SettingsService {
  static const String _keyUseMockData = 'use_mock_data';
  static const String _keyApiUrl = 'api_url';
  static const String _keyDollarTypeVisibility = 'dollar_type_visibility_';
  static const String _keyThemeMode = 'theme_mode'; // 'light' o 'dark'
  static const String _keyDollarTypeOrder = 'dollar_type_order';
  static const bool _defaultUseMockData = true;
  static const String _defaultApiUrl =
      'https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec';
  static const bool _defaultDollarTypeVisible =
      true; // Por defecto todos visibles
  static const String _defaultThemeMode = 'light'; // Por defecto light mode

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

  Future<bool> getDollarTypeVisibility(DollarType type) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_keyDollarTypeVisibility${type.name}') ??
        _defaultDollarTypeVisible;
  }

  Future<void> setDollarTypeVisibility(DollarType type, bool visible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyDollarTypeVisibility${type.name}', visible);
  }

  Future<Map<DollarType, bool>> getAllDollarTypeVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<DollarType, bool> visibility = {};

    for (final type in DollarType.values) {
      visibility[type] =
          prefs.getBool('$_keyDollarTypeVisibility${type.name}') ??
              _defaultDollarTypeVisible;
    }

    return visibility;
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? _defaultThemeMode;
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<List<String>> getDollarTypeOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderList = prefs.getStringList(_keyDollarTypeOrder);

    if (orderList != null && orderList.isNotEmpty) {
      return orderList;
    }

    // Por defecto, retornar el orden que coincide con el home: blue, official, crypto, tarjeta, mep, ccl
    return [
      DollarType.blue.name,
      DollarType.official.name,
      DollarType.crypto.name,
      DollarType.tarjeta.name,
      DollarType.mep.name,
      DollarType.ccl.name,
    ];
  }

  Future<void> setDollarTypeOrder(List<String> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyDollarTypeOrder, order);
  }
}
