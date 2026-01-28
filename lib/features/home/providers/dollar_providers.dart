import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/dollar_repository.dart';
import '../../../data/datasources/http_dollar_data_source.dart';
import '../../../domain/models/bank.dart';
import '../../../domain/models/crypto_platform.dart';
import '../../../domain/models/dollar_rate.dart';
import '../../../domain/models/dollar_snapshot.dart';
import '../../../domain/models/dollar_type.dart';
import '../../settings/providers/settings_providers.dart';

final dollarRepositoryProvider = Provider<DollarRepository>((ref) {
  final useMockData = ref.watch(useMockDataProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  
  // Debug: imprimir la URL que se está usando
  if (!useMockData) {
    print('🔧 Usando URL del backend: $apiUrl');
  }
  
  return DollarRepository(useMockData: useMockData, apiUrl: apiUrl);
});

final dollarSnapshotProvider =
    FutureProvider<DollarSnapshot>((ref) async {
  final repository = ref.watch(dollarRepositoryProvider);
  return repository.getDollarRates();
});

// Provider para obtener el JSON completo cuando no se usa mock
final fullJsonDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final useMockData = ref.watch(useMockDataProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  
  if (useMockData) {
    return {};
  }
  
  final dataSource = HttpDollarDataSource(baseUrl: apiUrl);
  return await dataSource.getFullJsonData();
});

// Provider para la plataforma P2P seleccionada (por defecto Binance)
final selectedCryptoPlatformProvider =
    StateProvider<CryptoPlatform>((ref) => CryptoPlatform.binance);

// Valores para cada plataforma P2P (desde JSON o mock)
final cryptoPlatformRatesProvider = Provider<Map<CryptoPlatform, DollarRate>>((ref) {
  final jsonDataAsync = ref.watch(fullJsonDataProvider);
  
  // Datos mock por defecto
  final mockRates = {
    CryptoPlatform.binance: DollarRate(
      type: DollarType.crypto,
      buy: 1470.0,
      sell: 1480.0,
      changePercent: 0.4,
    ),
    CryptoPlatform.kucoin: DollarRate(
      type: DollarType.crypto,
      buy: 1475.0,
      sell: 1485.0,
      changePercent: 0.38,
    ),
    CryptoPlatform.okx: DollarRate(
      type: DollarType.crypto,
      buy: 1473.0,
      sell: 1483.0,
      changePercent: 0.36,
    ),
    CryptoPlatform.bitget: DollarRate(
      type: DollarType.crypto,
      buy: 1474.0,
      sell: 1484.0,
      changePercent: 0.37,
    ),
  };

  return jsonDataAsync.when(
    data: (jsonData) {
      if (jsonData.isEmpty) return mockRates;
      
      final ultimaCorrida = jsonData['ultima_corrida'] as Map<String, dynamic>?;
      final dolarCripto = ultimaCorrida?['dolar_cripto'] as Map<String, dynamic>?;
      
      if (dolarCripto == null) return mockRates;
      
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
      
      final rates = Map<CryptoPlatform, DollarRate>.from(mockRates);
      
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
    loading: () => mockRates,
    error: (_, __) => mockRates,
  );
});

// Provider para el banco seleccionado (por defecto Banco Nación)
final selectedBankProvider =
    StateProvider<Bank>((ref) => Bank.nacion);

// Valores para cada banco (desde JSON o mock)
final bankRatesProvider = Provider<Map<Bank, DollarRate>>((ref) {
  final jsonDataAsync = ref.watch(fullJsonDataProvider);
  
  // Datos mock por defecto
  final mockRates = {
    Bank.nacion: DollarRate(
      type: DollarType.official,
      buy: 850.0,
      sell: 870.0,
      changePercent: -0.2,
    ),
    Bank.santander: DollarRate(
      type: DollarType.official,
      buy: 851.0,
      sell: 871.0,
      changePercent: -0.15,
    ),
    Bank.galicia: DollarRate(
      type: DollarType.official,
      buy: 849.5,
      sell: 869.5,
      changePercent: -0.25,
    ),
    Bank.bbva: DollarRate(
      type: DollarType.official,
      buy: 850.5,
      sell: 870.5,
      changePercent: -0.18,
    ),
    Bank.patagonia: DollarRate(
      type: DollarType.official,
      buy: 851.5,
      sell: 871.5,
      changePercent: -0.12,
    ),
    Bank.supervielle: DollarRate(
      type: DollarType.official,
      buy: 850.2,
      sell: 870.2,
      changePercent: -0.22,
    ),
    Bank.icbc: DollarRate(
      type: DollarType.official,
      buy: 849.8,
      sell: 869.8,
      changePercent: -0.28,
    ),
    Bank.ciudad: DollarRate(
      type: DollarType.official,
      buy: 850.8,
      sell: 870.8,
      changePercent: -0.16,
    ),
    Bank.comafi: DollarRate(
      type: DollarType.official,
      buy: 849.9,
      sell: 869.9,
      changePercent: -0.26,
    ),
    Bank.credicoop: DollarRate(
      type: DollarType.official,
      buy: 850.6,
      sell: 870.6,
      changePercent: -0.17,
    ),
    Bank.hipotecario: DollarRate(
      type: DollarType.official,
      buy: 851.1,
      sell: 871.1,
      changePercent: -0.13,
    ),
    Bank.provincia: DollarRate(
      type: DollarType.official,
      buy: 850.5,
      sell: 870.5,
      changePercent: -0.19,
    ),
  };

  return jsonDataAsync.when(
    data: (jsonData) {
      if (jsonData.isEmpty) return mockRates;
      
      final ultimaCorrida = jsonData['ultima_corrida'] as Map<String, dynamic>?;
      final dolarOficial = ultimaCorrida?['dolar_oficial'] as Map<String, dynamic>?;
      
      if (dolarOficial == null) return mockRates;
      
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
      
      final rates = Map<Bank, DollarRate>.from(mockRates);
      
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
    loading: () => mockRates,
    error: (_, __) => mockRates,
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
