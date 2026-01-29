import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/dollar_repository.dart';
import '../../../data/datasources/http_dollar_data_source.dart';
import '../../../domain/models/bank.dart';
import '../../../domain/models/crypto_platform.dart';
import '../../../domain/models/dollar_rate.dart';
import '../../../domain/models/dollar_snapshot.dart';
import '../../../domain/models/dollar_type.dart';
import '../../settings/providers/settings_providers.dart';

final _defaultBackendUrl =
    'https://raw.githubusercontent.com/ramirogioia/dolar_argentina_back/main/data';

final dollarRepositoryProvider = Provider<DollarRepository>((ref) {
  final apiUrl = ref.watch(apiUrlProvider);
  final url = apiUrl.isNotEmpty ? apiUrl : _defaultBackendUrl;
  return DollarRepository(apiUrl: url);
});

final dollarSnapshotProvider =
    FutureProvider<DollarSnapshot>((ref) async {
  final repository = ref.watch(dollarRepositoryProvider);
  return repository.getDollarRates();
});

// Provider para obtener el JSON completo del backend
final fullJsonDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiUrl = ref.watch(apiUrlProvider);
  final url = apiUrl.isNotEmpty ? apiUrl : _defaultBackendUrl;
  final dataSource = HttpDollarDataSource(baseUrl: url);
  return await dataSource.getFullJsonData();
});

// Provider para la plataforma P2P seleccionada (por defecto Binance)
final selectedCryptoPlatformProvider =
    StateProvider<CryptoPlatform>((ref) => CryptoPlatform.binance);

// Tasas vacías cuando no hay datos del backend (muestra "-" en la UI)
Map<CryptoPlatform, DollarRate> get _emptyCryptoRates => {
  for (final p in CryptoPlatform.values)
    p: DollarRate(type: DollarType.crypto, buy: null, sell: null, changePercent: null),
};

// Valores para cada plataforma P2P (desde backend)
final cryptoPlatformRatesProvider = Provider<Map<CryptoPlatform, DollarRate>>((ref) {
  final jsonDataAsync = ref.watch(fullJsonDataProvider);

  return jsonDataAsync.when(
    data: (jsonData) {
      if (jsonData.isEmpty) return _emptyCryptoRates;
      
      final ultimaCorrida = jsonData['ultima_corrida'] as Map<String, dynamic>?;
      final dolarCripto = ultimaCorrida?['dolar_cripto'] as Map<String, dynamic>?;
      
      if (dolarCripto == null) return _emptyCryptoRates;
      
      // Obtener penúltima corrida para calcular variaciones
      final corridas = jsonData['corridas'] as List<dynamic>?;
      Map<String, dynamic>? penultimaCorrida;
      if (corridas != null && corridas.length >= 2) {
        final sortedCorridas = List<Map<String, dynamic>>.from(corridas)
          ..sort((a, b) {
            final tsA = _parseTimestamp(a['timestamp']);
            final tsB = _parseTimestamp(b['timestamp']);
            return tsB.compareTo(tsA);
          });
        penultimaCorrida = sortedCorridas[1];
      }
      
      final rates = Map<CryptoPlatform, DollarRate>.from(_emptyCryptoRates);
      
      // Mapear plataformas del JSON a enums
      final platformMapping = {
        'binance': CryptoPlatform.binance,
        'kucoin': CryptoPlatform.kucoin,
        'okx': CryptoPlatform.okx,
        'bitget': CryptoPlatform.bitget,
      };
      
      for (final entry in platformMapping.entries) {
        final platformData = dolarCripto[entry.key] as Map<String, dynamic>?;
        if (platformData != null) {
          final buy = _parseDouble(platformData['compra']);
          final sell = _parseDouble(platformData['venta']);
          
          // Calcular variación comparando con penúltima corrida
          double? changePercent;
          if (penultimaCorrida != null && buy != null) {
            final previousCripto = penultimaCorrida['dolar_cripto'] as Map<String, dynamic>?;
            final previousPlatformData = previousCripto?[entry.key] as Map<String, dynamic>?;
            if (previousPlatformData != null) {
              final previousBuy = _parseDouble(previousPlatformData['compra']);
              if (previousBuy != null && previousBuy > 0) {
                changePercent = ((buy - previousBuy) / previousBuy) * 100;
              }
            }
          }
          // Si no hay penúltima corrida o no se pudo calcular, usar 0.0 por defecto
          if (changePercent == null && buy != null) {
            changePercent = 0.0;
          }
          
          // Crear el rate incluso si buy o sell son null (mostrará "-" en la UI)
          rates[entry.value] = DollarRate(
            type: DollarType.crypto,
            buy: buy,
            sell: sell,
            changePercent: changePercent,
          );
        }
      }
      
      return rates;
    },
    loading: () => _emptyCryptoRates,
    error: (_, __) => _emptyCryptoRates,
  );
});

// Tasas vacías para bancos cuando no hay datos del backend
Map<Bank, DollarRate> get _emptyBankRates => {
  for (final b in Bank.values)
    b: DollarRate(type: DollarType.official, buy: null, sell: null, changePercent: null),
};

// Provider para el banco seleccionado (por defecto Banco Nación)
final selectedBankProvider =
    StateProvider<Bank>((ref) => Bank.nacion);

// Valores para cada banco (desde backend)
final bankRatesProvider = Provider<Map<Bank, DollarRate>>((ref) {
  final jsonDataAsync = ref.watch(fullJsonDataProvider);

  return jsonDataAsync.when(
    data: (jsonData) {
      if (jsonData.isEmpty) return _emptyBankRates;
      
      final ultimaCorrida = jsonData['ultima_corrida'] as Map<String, dynamic>?;
      final dolarOficial = ultimaCorrida?['dolar_oficial'] as Map<String, dynamic>?;
      
      if (dolarOficial == null) return _emptyBankRates;
      
      // Obtener penúltima corrida para calcular variaciones
      final corridas = jsonData['corridas'] as List<dynamic>?;
      Map<String, dynamic>? penultimaCorrida;
      if (corridas != null && corridas.length >= 2) {
        final sortedCorridas = List<Map<String, dynamic>>.from(corridas)
          ..sort((a, b) {
            final tsA = _parseTimestamp(a['timestamp']);
            final tsB = _parseTimestamp(b['timestamp']);
            return tsB.compareTo(tsA);
          });
        penultimaCorrida = sortedCorridas[1];
      }
      
      final rates = Map<Bank, DollarRate>.from(_emptyBankRates);
      
      // Mapear bancos del JSON a enums
      // Mapeo de nombres del JSON a enums de la app
      final bankMapping = {
        'nacion': Bank.nacion,
        'bbva': Bank.bbva,
        'supervielle': Bank.supervielle,
        'patagonia': Bank.patagonia,
        'ciudad': Bank.ciudad,
        'hipotecario': Bank.hipotecario,
        'icbc': Bank.icbc,
        'provincia': Bank.provincia,
      };
      
      for (final entry in bankMapping.entries) {
        final bancoData = dolarOficial[entry.key] as Map<String, dynamic>?;
        if (bancoData != null) {
          final buy = _parseDouble(bancoData['compra']);
          final sell = _parseDouble(bancoData['venta']);
          
          // Calcular variación comparando con penúltima corrida
          double? changePercent;
          if (penultimaCorrida != null && buy != null) {
            final previousOficial = penultimaCorrida['dolar_oficial'] as Map<String, dynamic>?;
            final previousBancoData = previousOficial?[entry.key] as Map<String, dynamic>?;
            if (previousBancoData != null) {
              final previousBuy = _parseDouble(previousBancoData['compra']);
              if (previousBuy != null && previousBuy > 0) {
                changePercent = ((buy - previousBuy) / previousBuy) * 100;
              }
            }
          }
          // Si no hay penúltima corrida o no se pudo calcular, usar 0.0 por defecto
          if (changePercent == null && buy != null) {
            changePercent = 0.0;
          }
          
          // Crear el rate incluso si buy o sell son null (mostrará "-" en la UI)
          rates[entry.value] = DollarRate(
            type: DollarType.official,
            buy: buy,
            sell: sell,
            changePercent: changePercent,
          );
        }
      }
      
      return rates;
    },
    loading: () => _emptyBankRates,
    error: (_, __) => _emptyBankRates,
  );
});

// Función auxiliar para parsear doubles
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed;
  }
  return null;
}

// Función auxiliar para parsear timestamps
DateTime _parseTimestamp(dynamic timestamp) {
  if (timestamp == null) return DateTime.now();
  final tsStr = timestamp.toString();
  try {
    return DateTime.parse(tsStr);
  } catch (e) {
    return DateTime.now();
  }
}
