import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../settings_service.dart';

final settingsServiceProvider =
    Provider<SettingsService>((ref) => SettingsService());

final useMockDataProvider = StateNotifierProvider<UseMockDataNotifier, bool>(
  (ref) {
    final service = ref.watch(settingsServiceProvider);
    return UseMockDataNotifier(service);
  },
);

final apiUrlProvider = StateNotifierProvider<ApiUrlNotifier, String>(
  (ref) {
    final service = ref.watch(settingsServiceProvider);
    return ApiUrlNotifier(service);
  },
);

class UseMockDataNotifier extends StateNotifier<bool> {
  final SettingsService _service;
  bool _initialized = false;

  UseMockDataNotifier(this._service) : super(true) {
    _load();
  }

  Future<void> _load() async {
    if (_initialized) return;
    state = await _service.getUseMockData();
    _initialized = true;
  }

  Future<void> setValue(bool value) async {
    await _service.setUseMockData(value);
    state = value;
  }
}

class ApiUrlNotifier extends StateNotifier<String> {
  final SettingsService _service;
  bool _initialized = false;

  ApiUrlNotifier(this._service) : super('') {
    _load();
  }

  Future<void> _load() async {
    if (_initialized) return;
    state = await _service.getApiUrl();
    _initialized = true;
  }

  Future<void> setValue(String value) async {
    await _service.setApiUrl(value);
    state = value;
  }
}

