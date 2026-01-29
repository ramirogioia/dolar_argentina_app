import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/dollar_type.dart';
import '../settings_service.dart';

final settingsServiceProvider =
    Provider<SettingsService>((ref) => SettingsService());

final apiUrlProvider = StateNotifierProvider<ApiUrlNotifier, String>(
  (ref) {
    final service = ref.watch(settingsServiceProvider);
    return ApiUrlNotifier(service);
  },
);

class ApiUrlNotifier extends StateNotifier<String> {
  final SettingsService _service;
  bool _initialized = false;

  ApiUrlNotifier(this._service) : super('') {
    _load();
  }

  Future<void> _load() async {
    if (_initialized) return;
    final url = await _service.getApiUrl();
    state = url;
    _initialized = true;
  }

  Future<void> setValue(String value) async {
    await _service.setApiUrl(value);
    state = value;
  }
  
  // Método para forzar recarga (útil después de cambios en el servicio)
  Future<void> reload() async {
    _initialized = false;
    await _load();
  }
}

// Provider para la visibilidad de cada tipo de dólar
final dollarTypeVisibilityProvider =
    StateNotifierProvider<DollarTypeVisibilityNotifier, Map<DollarType, bool>>(
  (ref) {
    final service = ref.watch(settingsServiceProvider);
    return DollarTypeVisibilityNotifier(service);
  },
);

class DollarTypeVisibilityNotifier
    extends StateNotifier<Map<DollarType, bool>> {
  final SettingsService _service;
  bool _initialized = false;

  DollarTypeVisibilityNotifier(this._service) : super({}) {
    _load();
  }

  Future<void> _load() async {
    if (_initialized) return;
    state = await _service.getAllDollarTypeVisibility();
    _initialized = true;
  }

  Future<void> setVisibility(DollarType type, bool visible) async {
    await _service.setDollarTypeVisibility(type, visible);
    state = {...state, type: visible};
  }

  bool isVisible(DollarType type) {
    return state[type] ?? true; // Por defecto visible si no está definido
  }
}

// Provider para el modo de tema (light/dark)
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, String>(
  (ref) {
    final service = ref.watch(settingsServiceProvider);
    return ThemeModeNotifier(service);
  },
);

class ThemeModeNotifier extends StateNotifier<String> {
  final SettingsService _service;
  bool _initialized = false;

  ThemeModeNotifier(this._service) : super('light') {
    _load();
  }

  Future<void> _load() async {
    if (_initialized) return;
    state = await _service.getThemeMode();
    _initialized = true;
  }

  Future<void> setThemeMode(String mode) async {
    await _service.setThemeMode(mode);
    state = mode;
  }

  bool get isDarkMode => state == 'dark';
}

// Provider para el orden de los tipos de dólar
final dollarTypeOrderProvider =
    StateNotifierProvider<DollarTypeOrderNotifier, List<DollarType>>(
  (ref) {
    final service = ref.watch(settingsServiceProvider);
    return DollarTypeOrderNotifier(service);
  },
);

class DollarTypeOrderNotifier extends StateNotifier<List<DollarType>> {
  final SettingsService _service;
  bool _initialized = false;

  // Orden por defecto que coincide con el orden del home
  static const List<DollarType> _defaultOrder = [
    DollarType.blue,
    DollarType.official,
    DollarType.crypto,
    DollarType.tarjeta,
    DollarType.mep,
    DollarType.ccl,
  ];

  DollarTypeOrderNotifier(this._service) : super(_defaultOrder) {
    _load();
  }

  Future<void> _load() async {
    if (_initialized) return;
    final orderList = await _service.getDollarTypeOrder();

    // Convertir la lista de strings a lista de DollarType
    final orderedTypes = <DollarType>[];
    final allTypes = DollarType.values.toList();

    // Primero agregar los tipos en el orden guardado
    for (final typeName in orderList) {
      final type = allTypes.firstWhere(
        (t) => t.name == typeName,
        orElse: () => DollarType.blue,
      );
      if (!orderedTypes.contains(type)) {
        orderedTypes.add(type);
      }
    }

    // Agregar cualquier tipo que falte (por si se agregaron nuevos tipos)
    for (final type in allTypes) {
      if (!orderedTypes.contains(type)) {
        orderedTypes.add(type);
      }
    }

    state = orderedTypes;
    _initialized = true;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final newOrder = List<DollarType>.from(state);
    final item = newOrder.removeAt(oldIndex);
    newOrder.insert(newIndex, item);

    // Guardar el nuevo orden
    final orderList = newOrder.map((type) => type.name).toList();
    await _service.setDollarTypeOrder(orderList);

    state = newOrder;
  }
}

// Provider para notificaciones push
final notificationsEnabledProvider =
    StateNotifierProvider<NotificationsEnabledNotifier, bool>(
  (ref) {
    final service = ref.watch(settingsServiceProvider);
    return NotificationsEnabledNotifier(service);
  },
);

class NotificationsEnabledNotifier extends StateNotifier<bool> {
  final SettingsService _service;
  bool _initialized = false;

  NotificationsEnabledNotifier(this._service) : super(true) {
    _load();
  }

  Future<void> _load() async {
    if (_initialized) return;
    state = await _service.getNotificationsEnabled();
    _initialized = true;
  }

  Future<void> setEnabled(bool enabled) async {
    await _service.setNotificationsEnabled(enabled);
    state = enabled;
  }
}
