import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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
final cryptoPlatformRatesProvider = FutureProvider<Map<CryptoPlatform, DollarRate>>((ref) async {
  final jsonDataAsync = ref.watch(fullJsonDataProvider);

  return jsonDataAsync.when(
    data: (jsonData) async {
      if (jsonData.isEmpty) return _emptyCryptoRates;
      
      final ultimaCorrida = jsonData['ultima_corrida'] as Map<String, dynamic>?;
      final dolarCripto = ultimaCorrida?['dolar_cripto'] as Map<String, dynamic>?;
      
      if (dolarCripto == null) return _emptyCryptoRates;
      
      // Cargar archivo de ayer para comparar variaciones
      Map<String, dynamic>? ultimaCorridaAyer;
      try {
        final apiUrl = ref.read(apiUrlProvider);
        final baseUrl = apiUrl.isNotEmpty ? apiUrl : _defaultBackendUrl;
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayStr =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        final yesterdayUrl = Uri.parse('$baseUrl/cotizaciones_$yesterdayStr.json');
        
        final yesterdayResponse = await http.get(
          yesterdayUrl,
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'DolarArgentinaApp/1.0',
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
        ).timeout(const Duration(seconds: 10));
        
        if (yesterdayResponse.statusCode == 200) {
          final body = yesterdayResponse.body.trim();
          if (!body.startsWith('<!') && !body.startsWith('<html')) {
            final jsonAyer = jsonDecode(body) as Map<String, dynamic>;
            ultimaCorridaAyer = jsonAyer['ultima_corrida'] as Map<String, dynamic>?;
          }
        }
      } catch (e) {
        print('⚠️ Error al cargar archivo de ayer para variaciones cripto: $e');
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
          
          // Calcular variación comparando último de HOY con último de AYER
          double? changePercent;
          if (ultimaCorridaAyer != null && buy != null) {
            final previousCripto = ultimaCorridaAyer['dolar_cripto'] as Map<String, dynamic>?;
            final previousPlatformData = previousCripto?[entry.key] as Map<String, dynamic>?;
            if (previousPlatformData != null) {
              final previousBuy = _parseDouble(previousPlatformData['compra']);
              if (previousBuy != null && previousBuy > 0) {
                changePercent = ((buy - previousBuy) / previousBuy) * 100;
                print('✅ Variación cripto provider ($entry.key): HOY($buy) vs AYER($previousBuy) = ${changePercent.toStringAsFixed(2)}%');
              }
            }
          }
          // Si no se pudo calcular, usar 0.0 por defecto
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
    loading: () async => _emptyCryptoRates,
    error: (_, __) async => _emptyCryptoRates,
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

/// Bancos que scrapea el backend (dolar_oficial). Solo estos se muestran en el dropdown.
const List<Bank> officialBanksFromBackend = [
  Bank.nacion,
  Bank.bbva,
  Bank.supervielle,
  Bank.patagonia,
  Bank.provincia,
  Bank.ciudad,
  Bank.hipotecario,
  Bank.icbc,
];

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
      
      // Obtener timestamp de la última corrida para búsqueda hacia atrás
      // ultima_corrida no tiene timestamp, siempre usar el de la última corrida del array
      DateTime? ultimaCorridaTimestamp;
      if (corridas != null && corridas.isNotEmpty) {
        // Ordenar corridas por timestamp descendente (más recientes primero)
        final sortedCorridas = List<Map<String, dynamic>>.from(corridas)
          ..sort((a, b) {
            final tsA = _parseTimestamp(a['timestamp']);
            final tsB = _parseTimestamp(b['timestamp']);
            return tsB.compareTo(tsA);
          });
        if (sortedCorridas.isNotEmpty) {
          ultimaCorridaTimestamp = _parseTimestamp(sortedCorridas.first['timestamp']);
          print('🔍 DEBUG - Timestamp de última corrida (del array): $ultimaCorridaTimestamp');
        }
      } else {
        print('⚠️ DEBUG - No hay corridas disponibles para obtener timestamp');
      }
      
      for (final entry in bankMapping.entries) {
        final bancoData = dolarOficial[entry.key] as Map<String, dynamic>?;
        double? buy;
        double? sell;
        
        if (bancoData != null) {
          buy = _parseDouble(bancoData['compra']);
          sell = _parseDouble(bancoData['venta']);
        }
        
        // Si algún valor es null, buscar hacia atrás en las últimas 2 horas
        if ((buy == null || sell == null) && corridas != null && ultimaCorridaTimestamp != null) {
          print('🔍 DEBUG - Buscando valores válidos para ${entry.key}. buy: $buy, sell: $sell');
          print('🔍 DEBUG - ultimaCorridaTimestamp: $ultimaCorridaTimestamp');
          final twoHoursAgo = ultimaCorridaTimestamp.subtract(const Duration(hours: 2));
          print('🔍 DEBUG - Buscando corridas desde: $twoHoursAgo hasta: $ultimaCorridaTimestamp');
          
          final sortedCorridas = List<Map<String, dynamic>>.from(corridas)
            ..sort((a, b) {
              final tsA = _parseTimestamp(a['timestamp']);
              final tsB = _parseTimestamp(b['timestamp']);
              return tsB.compareTo(tsA);
            });
          
          print('🔍 DEBUG - Total corridas a revisar: ${sortedCorridas.length}');
          
          for (int i = 0; i < sortedCorridas.length; i++) {
            final corrida = sortedCorridas[i];
            final timestamp = _parseTimestamp(corrida['timestamp']);
            final diff = ultimaCorridaTimestamp.difference(timestamp);
            print('🔍 DEBUG - Revisando corrida $i: $timestamp (diferencia: ${diff.inMinutes} min)');
            
            // Verificar que esté dentro de las últimas 2 horas
            if (timestamp.isBefore(twoHoursAgo)) {
              print('🔍 DEBUG - Corrida fuera del rango de 2 horas (${diff.inHours} horas atrás), deteniendo búsqueda');
              break;
            }
            
            final oficialData = corrida['dolar_oficial'] as Map<String, dynamic>?;
            if (oficialData == null) {
              print('🔍 DEBUG - Corrida sin dolar_oficial');
              continue;
            }
            
            final bancoDataAnterior = oficialData[entry.key] as Map<String, dynamic>?;
            if (bancoDataAnterior == null) {
              print('🔍 DEBUG - Corrida sin datos para ${entry.key}');
              continue;
            }
            
            final compraAnterior = _parseDouble(bancoDataAnterior['compra']);
            final ventaAnterior = _parseDouble(bancoDataAnterior['venta']);
            print('🔍 DEBUG - Encontrado datos para ${entry.key}: compra=$compraAnterior, venta=$ventaAnterior');
            
            // Solo usar valores que no sean null
            if (buy == null && compraAnterior != null) {
              buy = compraAnterior;
              print('✅ Valor de compra null para ${entry.key}, usando último valor válido de $timestamp: $buy');
            }
            if (sell == null && ventaAnterior != null) {
              sell = ventaAnterior;
              print('✅ Valor de venta null para ${entry.key}, usando último valor válido de $timestamp: $sell');
            }
            
            // Si ya tenemos ambos valores, no necesitamos seguir buscando
            if (buy != null && sell != null) {
              print('✅ Valores completos encontrados para ${entry.key}, deteniendo búsqueda');
              break;
            }
          }
          
          if (buy == null || sell == null) {
            print('⚠️ No se encontraron valores válidos para ${entry.key} en las últimas 2 horas');
          }
        }
        
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
