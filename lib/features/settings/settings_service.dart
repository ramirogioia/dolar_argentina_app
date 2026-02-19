import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/dollar_type.dart';

class SettingsService {
  static const String _keyApiUrl = 'api_url';
  static const String _keyDollarTypeVisibility = 'dollar_type_visibility_';
  static const String _keyThemeMode = 'theme_mode'; // 'light' o 'dark'
  static const String _keyDollarTypeOrder = 'dollar_type_order';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyLocale = 'locale'; // 'es', 'en' o '' (sistema)
  static const String _defaultApiUrl =
      'https://raw.githubusercontent.com/ramirogioia/dolar_argentina_back/main/data';
  static const bool _defaultDollarTypeVisible =
      true; // Por defecto todos visibles
  static const String _defaultThemeMode = 'light'; // Por defecto light mode
  static const bool _defaultNotificationsEnabled = true; // Por defecto activadas

  Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_keyApiUrl);
    
    // Si no hay URL guardada o es la URL antigua de Google Apps Script, actualizar y usar la nueva por defecto
    if (savedUrl == null || 
        savedUrl.isEmpty || 
        savedUrl.contains('script.google.com') ||
        savedUrl.contains('YOUR_SCRIPT_ID')) {
      // Actualizar automáticamente el valor guardado para futuras ejecuciones
      await prefs.setString(_keyApiUrl, _defaultApiUrl);
      return _defaultApiUrl;
    }
    
    return savedUrl;
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

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? _defaultNotificationsEnabled;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  /// Locale: 'es', 'en' o '' (vacío = usar idioma del dispositivo).
  Future<String> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLocale) ?? '';
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, languageCode);
  }
}
