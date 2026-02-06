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

/// Fecha del último día de mercado anterior a [referenceDate].
/// Oficial/MEP/CCL/Tarjeta no operan sábado/domingo.
/// Lunes → viernes. Sábado/domingo (datos del viernes) → jueves. Martes a viernes → día anterior.
DateTime _getPreviousMarketDate(DateTime referenceDate) {
  final w = referenceDate.weekday; // 1=Mon, 7=Sun
  if (w == DateTime.monday)
    return referenceDate.subtract(const Duration(days: 3)); // Viernes
  if (w == DateTime.saturday)
    return referenceDate.subtract(const Duration(days: 2)); // Jueves
  if (w == DateTime.sunday)
    return referenceDate.subtract(const Duration(days: 3)); // Jueves
  return referenceDate.subtract(const Duration(days: 1));
}

final dollarRepositoryProvider = Provider<DollarRepository>((ref) {
  final apiUrl = ref.watch(apiUrlProvider);
  final url = apiUrl.isNotEmpty ? apiUrl : _defaultBackendUrl;
  return DollarRepository(apiUrl: url);
});

final dollarSnapshotProvider = FutureProvider<DollarSnapshot>((ref) async {
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
        p: DollarRate(
            type: DollarType.crypto,
            buy: null,
            sell: null,
            changePercent: null),
    };

// Valores para cada plataforma P2P (desde backend)
final cryptoPlatformRatesProvider =
    FutureProvider<Map<CryptoPlatform, DollarRate>>((ref) async {
  final jsonDataAsync = ref.watch(fullJsonDataProvider);

  return jsonDataAsync.when(
    data: (jsonData) async {
      if (jsonData.isEmpty) return _emptyCryptoRates;

      final ultimaCorrida = jsonData['ultima_corrida'] as Map<String, dynamic>?;
      final dolarCripto =
          ultimaCorrida?['dolar_cripto'] as Map<String, dynamic>?;

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
        final yesterdayUrl =
            Uri.parse('$baseUrl/cotizaciones_$yesterdayStr.json');

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
            ultimaCorridaAyer =
                jsonAyer['ultima_corrida'] as Map<String, dynamic>?;
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
        'bybit': CryptoPlatform.bybit,
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
            final previousCripto =
                ultimaCorridaAyer['dolar_cripto'] as Map<String, dynamic>?;
            final previousPlatformData =
                previousCripto?[entry.key] as Map<String, dynamic>?;
            if (previousPlatformData != null) {
              final previousBuy = _parseDouble(previousPlatformData['compra']);
              if (previousBuy != null && previousBuy > 0) {
                changePercent = ((buy - previousBuy) / previousBuy) * 100;
                print(
                    '✅ Variación cripto provider ($entry.key): HOY($buy) vs AYER($previousBuy) = ${changePercent.toStringAsFixed(2)}%');
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
        b: DollarRate(
            type: DollarType.official,
            buy: null,
            sell: null,
            changePercent: null),
    };

/// Última corrida dolar_oficial del último día hábil (para variación en front).
/// Así la comparación de valores para variación se hace acá, sin tocar el backend.
final previousMarketDayOficialProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  try {
    final baseUrl = ref.read(apiUrlProvider);
    final url = baseUrl.isNotEmpty ? baseUrl : _defaultBackendUrl;
    final refDate = DateTime.now();
    final prevDate = _getPreviousMarketDate(refDate);
    final prevStr =
        '${prevDate.year}-${prevDate.month.toString().padLeft(2, '0')}-${prevDate.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse('$url/cotizaciones_$prevStr.json');
    final response = await http.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'DolarArgentinaApp/1.0',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      },
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return null;
    final body = response.body.trim();
    if (body.startsWith('<!') || body.startsWith('<html')) return null;
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['ultima_corrida']?['dolar_oficial'] as Map<String, dynamic>?;
  } catch (e) {
    return null;
  }
});

// Provider para el banco seleccionado (por defecto Banco Nación)
final selectedBankProvider = StateProvider<Bank>((ref) => Bank.nacion);

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

/// Construye el mapa de tasas por banco. La variación se calcula acá en el front:
/// si [dolarOficialPrevMarket] está disponible (día hábil anterior), se usa para comparar;
/// si no, se usa la penúltima corrida del mismo día.
Map<Bank, DollarRate> _buildBankRates(
  Map<String, dynamic> jsonData,
  Map<String, dynamic>? dolarOficialPrevMarket,
) {
  final ultimaCorrida = jsonData['ultima_corrida'] as Map<String, dynamic>?;
  final dolarOficial = ultimaCorrida?['dolar_oficial'] as Map<String, dynamic>?;
  if (dolarOficial == null) return _emptyBankRates;

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

  DateTime? ultimaCorridaTimestamp;
  if (corridas != null && corridas.isNotEmpty) {
    final sortedCorridas = List<Map<String, dynamic>>.from(corridas)
      ..sort((a, b) {
        final tsA = _parseTimestamp(a['timestamp']);
        final tsB = _parseTimestamp(b['timestamp']);
        return tsB.compareTo(tsA);
      });
    if (sortedCorridas.isNotEmpty) {
      ultimaCorridaTimestamp =
          _parseTimestamp(sortedCorridas.first['timestamp']);
    }
  }

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

  final rates = Map<Bank, DollarRate>.from(_emptyBankRates);

  for (final entry in bankMapping.entries) {
    final bancoData = dolarOficial[entry.key] as Map<String, dynamic>?;
    double? buy;
    double? sell;

    if (bancoData != null) {
      buy = _parseDouble(bancoData['compra']);
      sell = _parseDouble(bancoData['venta']);
    }

    if ((buy == null || sell == null) &&
        corridas != null &&
        ultimaCorridaTimestamp != null) {
      final twoHoursAgo =
          ultimaCorridaTimestamp.subtract(const Duration(hours: 2));
      final sortedCorridas = List<Map<String, dynamic>>.from(corridas)
        ..sort((a, b) {
          final tsA = _parseTimestamp(a['timestamp']);
          final tsB = _parseTimestamp(b['timestamp']);
          return tsB.compareTo(tsA);
        });
      for (final corrida in sortedCorridas) {
        final timestamp = _parseTimestamp(corrida['timestamp']);
        if (timestamp.isBefore(twoHoursAgo)) break;
        final oficialData = corrida['dolar_oficial'] as Map<String, dynamic>?;
        if (oficialData == null) continue;
        final bancoDataAnterior =
            oficialData[entry.key] as Map<String, dynamic>?;
        if (bancoDataAnterior == null) continue;
        final compraAnterior = _parseDouble(bancoDataAnterior['compra']);
        final ventaAnterior = _parseDouble(bancoDataAnterior['venta']);
        if (buy == null && compraAnterior != null) buy = compraAnterior;
        if (sell == null && ventaAnterior != null) sell = ventaAnterior;
        if (buy != null && sell != null) break;
      }
    }

    // Variación: acá en el front. Preferir día hábil anterior (fin de semana correcto)
    double? changePercent;
    if (buy != null && buy > 0) {
      final previousBancoData =
          dolarOficialPrevMarket?[entry.key] as Map<String, dynamic>?;
      final previousBuy = previousBancoData != null
          ? _parseDouble(previousBancoData['compra'])
          : null;
      if (previousBuy != null && previousBuy > 0) {
        changePercent = ((buy - previousBuy) / previousBuy) * 100;
      } else if (penultimaCorrida != null) {
        final previousOficial =
            penultimaCorrida['dolar_oficial'] as Map<String, dynamic>?;
        final prevBanco = previousOficial?[entry.key] as Map<String, dynamic>?;
        final prevBuy =
            prevBanco != null ? _parseDouble(prevBanco['compra']) : null;
        if (prevBuy != null && prevBuy > 0) {
          changePercent = ((buy - prevBuy) / prevBuy) * 100;
        }
      }
      if (changePercent == null) changePercent = 0.0;
    }

    rates[entry.value] = DollarRate(
      type: DollarType.official,
      buy: buy,
      sell: sell,
      changePercent: changePercent,
    );
  }
  return rates;
}

// Valores para cada banco (desde backend). Variación calculada acá en el front.
final bankRatesProvider = Provider<Map<Bank, DollarRate>>((ref) {
  final jsonDataAsync = ref.watch(fullJsonDataProvider);
  final prevMarketAsync = ref.watch(previousMarketDayOficialProvider);

  return jsonDataAsync.when(
    data: (jsonData) {
      if (jsonData.isEmpty) return _emptyBankRates;
      return prevMarketAsync.when(
        data: (dolarOficialPrev) => _buildBankRates(jsonData, dolarOficialPrev),
        loading: () => _buildBankRates(jsonData, null),
        error: (_, __) => _buildBankRates(jsonData, null),
      );
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
