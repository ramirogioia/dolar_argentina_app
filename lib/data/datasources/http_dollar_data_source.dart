import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../app/constants/api_constants.dart';
import '../../domain/models/dollar_rate.dart';
import '../../domain/models/dollar_snapshot.dart';
import '../../domain/models/dollar_type.dart';
import 'dollar_data_source.dart';

/// Implementación para conectar con el repositorio GitHub que contiene los JSONs
class HttpDollarDataSource implements DollarDataSource {
  final String baseUrl;

  HttpDollarDataSource({String? baseUrl})
      : baseUrl =
            (baseUrl != null && baseUrl.isNotEmpty) ? baseUrl : apiBaseUrl;

  static const _timeoutSeconds = 30;
  static const _maxRetries = 2;

  @override
  Future<DollarSnapshot> getDollarRates() async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      // Agregar timestamp como query param para evitar caché
      final url = Uri.parse('$baseUrl/cotizaciones_$dateStr.json').replace(
        queryParameters: {
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      print('🔍 Intentando obtener datos de: ${url.toString()}');

      // Reintento en timeout (emulador y redes lentas)
      http.Response? response;
      Object? lastError;
      for (var attempt = 1; attempt <= _maxRetries; attempt++) {
        try {
          response = await http.get(
            url,
            headers: {
              'Accept': 'application/json',
              'User-Agent': 'DolarArgentinaApp/1.0',
              'Cache-Control': 'no-cache, no-store, must-revalidate',
              'Pragma': 'no-cache',
            },
          ).timeout(
            const Duration(seconds: _timeoutSeconds),
            onTimeout: () {
              throw Exception('Timeout al obtener datos del servidor');
            },
          );
          break;
        } catch (e) {
          lastError = e;
          if (attempt < _maxRetries) {
            print('⚠️ Intento $attempt falló ($e), reintentando en 2s...');
            await Future<void>.delayed(const Duration(seconds: 2));
          }
        }
      }
      if (response == null) {
        throw lastError ?? Exception('Error al obtener datos del servidor');
      }

      print(
          '📡 Respuesta recibida - Status: ${response.statusCode}, Content-Type: ${response.headers['content-type']}');

      // Manejar respuesta 404 - intentar con el día anterior
      if (response.statusCode == 404) {
        // Si no existe el JSON del día actual, intentar con el día anterior
        print(
            '⚠️ Archivo no encontrado para hoy ($dateStr), intentando con ayer...');
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayStr =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        final yesterdayUrl =
            Uri.parse('$baseUrl/cotizaciones_$yesterdayStr.json');
        print(
            '🔍 Intentando obtener datos de ayer: ${yesterdayUrl.toString()}');

        http.Response? yesterdayResponse;
        for (var attempt = 1; attempt <= _maxRetries; attempt++) {
          try {
            yesterdayResponse = await http.get(
              yesterdayUrl,
              headers: {
                'Accept': 'application/json',
                'User-Agent': 'DolarArgentinaApp/1.0',
                'Cache-Control': 'no-cache, no-store, must-revalidate',
                'Pragma': 'no-cache',
              },
            ).timeout(
              const Duration(seconds: _timeoutSeconds),
              onTimeout: () {
                throw Exception('Timeout al obtener datos del servidor');
              },
            );
            break;
          } catch (e) {
            if (attempt == _maxRetries) rethrow;
            print('⚠️ Intento ayer $attempt falló, reintentando...');
            await Future<void>.delayed(const Duration(seconds: 2));
          }
        }
        final respAyer = yesterdayResponse!;

        print('📡 Respuesta de ayer - Status: ${respAyer.statusCode}');

        if (respAyer.statusCode != 200) {
          final preview = respAyer.body.length > 200
              ? respAyer.body.substring(0, 200)
              : respAyer.body;
          throw Exception('No se encontraron datos para hoy ni para ayer.\n\n'
              'URLs intentadas:\n'
              '• Hoy: ${url.toString()}\n'
              '• Ayer: ${yesterdayUrl.toString()}\n\n'
              'Respuesta de ayer (${respAyer.statusCode}): ${preview}...');
        }

        final bodyPreview = respAyer.body.trim();
        if (bodyPreview.startsWith('<!') ||
            bodyPreview.startsWith('<html') ||
            bodyPreview.toLowerCase().contains('<!doctype')) {
          print('❌ Respuesta de ayer es HTML, no JSON');
          throw Exception('El servidor devolvió HTML en lugar de JSON.\n\n'
              'Posibles causas:\n'
              '• El repositorio GitHub es privado (debe ser público)\n'
              '• La URL es incorrecta\n\n'
              'URL intentada: ${yesterdayUrl.toString()}');
        }

        print('✅ JSON válido de ayer recibido, parseando...');
        return await _parseResponse(respAyer.body);
      }

      // Si llegamos aquí, el status code es 200
      // Validar que la respuesta sea JSON y no HTML
      final contentType = response.headers['content-type'] ?? '';
      final bodyPreview = response.body.trim();

      // Verificar si es HTML antes de validar content-type
      if (bodyPreview.startsWith('<!') ||
          bodyPreview.startsWith('<html') ||
          bodyPreview.toLowerCase().contains('<!doctype')) {
        print(
            '❌ Respuesta es HTML, no JSON. Primeros caracteres: ${bodyPreview.substring(0, bodyPreview.length > 100 ? 100 : bodyPreview.length)}');
        throw Exception('El servidor devolvió HTML en lugar de JSON.\n\n'
            'Posibles causas:\n'
            '• El repositorio GitHub es privado (debe ser público)\n'
            '• La URL es incorrecta\n'
            '• Problemas de conectividad\n\n'
            'URL intentada: ${url.toString()}\n\n'
            'Solución: Verifica que el repositorio sea público y accesible.');
      }

      if (!contentType.contains('application/json') &&
          !contentType.contains('text/plain') &&
          !contentType.contains('text/json')) {
        print('⚠️ Content-Type inesperado: $contentType');
      }

      // Si la primera corrida del día vino con null (scrape sin datos), usar última medición disponible
      final body = response.body;
      try {
        final parsed = jsonDecode(body) as Map<String, dynamic>;
        final uc = parsed['ultima_corrida'] as Map<String, dynamic>?;
        if (!_hasUsableDataInUltimaCorrida(uc)) {
          print(
              '⚠️ Primera corrida del día sin datos (scrape null), buscando ayer...');
          final yesterday = now.subtract(const Duration(days: 1));
          final dateStr =
              '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
          final prevBody = await _fetchRawJsonBodyForDate(dateStr);
          if (prevBody != null) {
            final prevMap = jsonDecode(prevBody) as Map<String, dynamic>;
            if (_hasUsableDataInUltimaCorrida(
                prevMap['ultima_corrida'] as Map<String, dynamic>?)) {
              print('✅ Usando última medición disponible: $dateStr');
              return await _parseResponse(prevBody);
            }
          }
          print('⚠️ Ayer tampoco tiene datos usables');
        }
      } catch (_) {
        // Si falla el check, seguir con el parse normal
      }

      print('✅ JSON válido recibido, parseando...');
      return await _parseResponse(body);
    } catch (e) {
      throw Exception('Error al obtener datos del backend: $e');
    }
  }

  /// Fecha del último día de mercado anterior a [referenceDate].
  /// Lunes → viernes. Sábado/domingo (datos del viernes) → jueves. Martes a viernes → día anterior.
  static DateTime _getPreviousMarketDate(DateTime referenceDate) {
    final w = referenceDate.weekday; // 1=Mon, 7=Sun
    if (w == DateTime.monday)
      return referenceDate.subtract(const Duration(days: 3)); // Viernes
    if (w == DateTime.saturday)
      return referenceDate.subtract(const Duration(days: 2)); // Jueves
    if (w == DateTime.sunday)
      return referenceDate.subtract(const Duration(days: 3)); // Jueves
    return referenceDate.subtract(const Duration(days: 1));
  }

  /// Indica si [ultimaCorrida] tiene al menos un valor usable (compra o venta numérico).
  /// Útil cuando la primera corrida del día vino con null (scrape falló).
  static bool _hasUsableDataInUltimaCorrida(
      Map<String, dynamic>? ultimaCorrida) {
    if (ultimaCorrida == null) return false;
    for (final entry in ultimaCorrida.entries) {
      final v = entry.value;
      if (v is! Map<String, dynamic>) continue;
      final compra = v['compra'];
      final venta = v['venta'];
      if (compra != null &&
          (compra is num ||
              (compra is String && double.tryParse(compra) != null)))
        return true;
      if (venta != null &&
          (venta is num || (venta is String && double.tryParse(venta) != null)))
        return true;
      // Nested (dolar_oficial: { nacion: {...} }, dolar_cripto: { binance: {...} })
      for (final inner in (v as Map<String, dynamic>).entries) {
        final innerV = inner.value;
        if (innerV is! Map<String, dynamic>) continue;
        final c = innerV['compra'];
        final s = innerV['venta'];
        if (c != null &&
            (c is num || (c is String && double.tryParse(c) != null)))
          return true;
        if (s != null &&
            (s is num || (s is String && double.tryParse(s) != null)))
          return true;
      }
    }
    return false;
  }

  /// Descarga el JSON completo de una fecha. Devuelve null si 404, HTML o error.
  Future<Map<String, dynamic>?> _fetchFullJsonForDate(String dateStr) async {
    try {
      final url = Uri.parse('$baseUrl/cotizaciones_$dateStr.json');
      final response = await http.get(
        url,
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
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Descarga el body crudo del JSON de una fecha (para reutilizar _parseResponse).
  Future<String?> _fetchRawJsonBodyForDate(String dateStr) async {
    try {
      final url = Uri.parse('$baseUrl/cotizaciones_$dateStr.json');
      final response = await http.get(
        url,
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
      return body;
    } catch (e) {
      return null;
    }
  }

  /// Descarga el JSON de una fecha y devuelve ultima_corrida (o null).
  Future<Map<String, dynamic>?> _fetchUltimaCorridaForDate(
    String baseUrl,
    String dateStr,
    String label,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/cotizaciones_$dateStr.json');
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DolarArgentinaApp/1.0',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (!body.startsWith('<!') && !body.startsWith('<html')) {
          final data = jsonDecode(body) as Map<String, dynamic>;
          final ultima = data['ultima_corrida'] as Map<String, dynamic>?;
          if (ultima != null)
            print('✅ Ultima corrida ($label) cargada para variación');
          return ultima;
        }
      }
    } catch (e) {
      print('⚠️ Error al cargar $label para variación: $e');
    }
    return null;
  }

  /// Convierte un JSON del backend a DollarSnapshot
  /// Formato esperado:
  /// {
  ///   "fecha": "2026-01-28",
  ///   "ultima_actualizacion": "2026-01-28T16:53:32.423939-03:00",
  ///   "corridas": [...],
  ///   "ultima_corrida": {...}
  /// }
  Future<DollarSnapshot> _parseResponse(String jsonString) async {
    try {
      // Validar que no sea HTML antes de parsear
      final trimmed = jsonString.trim();
      if (trimmed.startsWith('<!') || trimmed.startsWith('<html')) {
        throw FormatException('La respuesta es HTML, no JSON. '
            'Primeros caracteres: ${trimmed.substring(0, trimmed.length > 100 ? 100 : trimmed.length)}');
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      // Usar la fecha/hora actual (cuándo se hizo el fetch desde el frontend)
      // en lugar de la fecha del backend, para que el usuario sepa cuándo actualizó él los datos
      final updatedAt = DateTime.now();

      // Obtener la última corrida (valores más recientes)
      final fechaArchivo = json['fecha'] as String?;
      print('📅 DEBUG - Fecha del archivo cargado: $fechaArchivo');
      final ultimaCorrida = json['ultima_corrida'] as Map<String, dynamic>?;
      if (ultimaCorrida == null) {
        throw Exception('El JSON no contiene "ultima_corrida"');
      }
      print(
          '📅 DEBUG - ultima_corrida timestamp: ${ultimaCorrida['timestamp']}');
      // "Última actualización: ..." debe mostrar el dato del backend (ultima_actualizacion).
      // Si no existe, usar el timestamp de la última corrida del array.
      DateTime? lastMeasurementAt;
      final ultimaActualizacion = json['ultima_actualizacion'];
      if (ultimaActualizacion != null) {
        lastMeasurementAt = _parseTimestamp(ultimaActualizacion);
      }
      if (lastMeasurementAt == null) {
        final corridas = json['corridas'] as List<dynamic>?;
        if (corridas != null && corridas.isNotEmpty) {
          final ultima = corridas.last as Map<String, dynamic>;
          lastMeasurementAt = _parseTimestamp(ultima['timestamp']);
        }
      }
      if (lastMeasurementAt == null) {
        lastMeasurementAt = _parseTimestamp(ultimaCorrida['timestamp']);
      }

      // Fecha de referencia: la del JSON que estamos mostrando (para lógica fin de semana)
      DateTime referenceDate = DateTime.now();
      if (fechaArchivo != null) {
        try {
          referenceDate = DateTime.parse(fechaArchivo);
        } catch (_) {}
      }
      final previousMarketDate = _getPreviousMarketDate(referenceDate);

      // Última corrida de AYER (calendario): para blue y cripto (operan todos los días)
      Map<String, dynamic>? ultimaCorridaAyer;
      final yesterday = referenceDate.subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      ultimaCorridaAyer =
          await _fetchUltimaCorridaForDate(baseUrl, yesterdayStr, 'ayer');

      // Última corrida del ÚLTIMO DÍA DE MERCADO (para oficial, MEP, CCL, tarjeta: no operan sábado/domingo)
      // Sábado/domingo: comparar con jueves (variación = cierre viernes vs jueves). Lunes: comparar con viernes.
      Map<String, dynamic>? ultimaCorridaPrevMarket;
      final prevMarketStr =
          '${previousMarketDate.year}-${previousMarketDate.month.toString().padLeft(2, '0')}-${previousMarketDate.day.toString().padLeft(2, '0')}';
      if (prevMarketStr != yesterdayStr) {
        ultimaCorridaPrevMarket = await _fetchUltimaCorridaForDate(
            baseUrl, prevMarketStr, 'día hábil anterior');
      } else {
        ultimaCorridaPrevMarket = ultimaCorridaAyer;
      }

      // Obtener el array de corridas para búsqueda hacia atrás cuando hay valores null
      final corridas = json['corridas'] as List<dynamic>?;
      final ultimaCorridaTimestamp =
          _parseTimestamp(ultimaCorrida['timestamp']);

      // Construir la lista de DollarRate
      final rates = <DollarRate>[];

      // Mapear cada tipo de dólar
      // Oficial, MEP, CCL, tarjeta: comparar con último día hábil (fin de semana no operan)
      // Blue, cripto: comparar con ayer calendario
      for (final dollarType in DollarType.values) {
        final rate = _extractDollarRate(
          ultimaCorrida,
          ultimaCorridaAyer,
          dollarType,
          corridas: corridas,
          ultimaCorridaTimestamp: ultimaCorridaTimestamp,
          ultimaCorridaPrevMarket: ultimaCorridaPrevMarket,
        );
        if (rate != null) {
          rates.add(rate);
        }
      }

      final snapshot = DollarSnapshot(
        updatedAt: updatedAt,
        lastMeasurementAt: lastMeasurementAt,
        rates: rates,
      );

      print(
          '✅ Parsing completado exitosamente. ${rates.length} tipos de dólar encontrados. Actualizado: ${updatedAt.toString()}');

      return snapshot;
    } catch (e) {
      print('❌ Error al parsear respuesta del backend: $e');
      throw Exception('Error al parsear respuesta del backend: $e');
    }
  }

  /// Busca el último valor válido (no null) en las corridas de las últimas 2 horas
  /// para un banco o plataforma específica
  Map<String, dynamic>? _findLastValidValueInCorridas(
    List<dynamic>? corridas,
    DateTime? ultimaCorridaTimestamp,
    String typeKey,
    String entityKey, // 'nacion', 'binance', etc.
  ) {
    if (corridas == null ||
        corridas.isEmpty ||
        ultimaCorridaTimestamp == null) {
      return null;
    }

    final twoHoursAgo =
        ultimaCorridaTimestamp.subtract(const Duration(hours: 2));

    // Ordenar corridas por timestamp descendente (más recientes primero)
    final sortedCorridas = List<Map<String, dynamic>>.from(corridas)
      ..sort((a, b) {
        final tsA = _parseTimestamp(a['timestamp']);
        final tsB = _parseTimestamp(b['timestamp']);
        return tsB.compareTo(tsA);
      });

    // Buscar el último valor válido en las últimas 2 horas
    for (final corrida in sortedCorridas) {
      final timestamp = _parseTimestamp(corrida['timestamp']);
      if (timestamp.isBefore(twoHoursAgo)) {
        continue; // Fuera del rango de 2 horas
      }

      final typeData = corrida[typeKey] as Map<String, dynamic>?;
      if (typeData == null) continue;

      final entityData = typeData[entityKey] as Map<String, dynamic>?;
      if (entityData == null) continue;

      final compra = _parseDouble(entityData['compra']);
      final venta = _parseDouble(entityData['venta']);

      // Si tiene al menos un valor válido, retornarlo
      if (compra != null || venta != null) {
        return entityData;
      }
    }

    return null; // No se encontró ningún valor válido en las últimas 2 horas
  }

  /// Extrae un DollarRate para un tipo específico de dólar
  /// [ultimaCorridaAyer] comparación para blue y cripto (ayer calendario)
  /// [ultimaCorridaPrevMarket] comparación para oficial, MEP, CCL, tarjeta (último día hábil)
  DollarRate? _extractDollarRate(
    Map<String, dynamic> ultimaCorrida,
    Map<String, dynamic>? ultimaCorridaAyer,
    DollarType dollarType, {
    List<dynamic>? corridas,
    DateTime? ultimaCorridaTimestamp,
    Map<String, dynamic>? ultimaCorridaPrevMarket,
  }) {
    final typeKey = _getDollarTypeKey(dollarType);

    // Buscar el valor en la última corrida
    final latestData = ultimaCorrida[typeKey] as Map<String, dynamic>?;
    if (latestData == null) return null;

    double? buy;
    double? sell;
    double? changePercent;

    if (dollarType == DollarType.official) {
      // Para dólar oficial, necesitamos seleccionar un banco
      // Por defecto usamos "nacion", pero intentamos mantener consistencia
      String? bancoSeleccionado;
      final bancoData = latestData['nacion'] as Map<String, dynamic>?;
      if (bancoData == null) {
        // Si no hay nacion, buscar el primer banco disponible
        final bancos = latestData.keys.toList();
        if (bancos.isEmpty) return null;
        bancoSeleccionado = bancos.first;
        final primerBancoData =
            latestData[bancoSeleccionado] as Map<String, dynamic>?;
        if (primerBancoData == null) return null;
        buy = _parseDouble(primerBancoData['compra']);
        sell = _parseDouble(primerBancoData['venta']);
      } else {
        bancoSeleccionado = 'nacion';
        buy = _parseDouble(bancoData['compra']);
        sell = _parseDouble(bancoData['venta']);
      }

      // Si algún valor es null, buscar hacia atrás en las últimas 2 horas
      if ((buy == null || sell == null) &&
          corridas != null &&
          ultimaCorridaTimestamp != null) {
        final validData = _findLastValidValueInCorridas(
          corridas,
          ultimaCorridaTimestamp,
          typeKey,
          bancoSeleccionado,
        );
        if (validData != null) {
          if (buy == null) {
            buy = _parseDouble(validData['compra']);
            print(
                '🔍 Valor de compra null para $bancoSeleccionado, usando último valor válido: $buy');
          }
          if (sell == null) {
            sell = _parseDouble(validData['venta']);
            print(
                '🔍 Valor de venta null para $bancoSeleccionado, usando último valor válido: $sell');
          }
        }
      }

      // Variación: comparar con último día hábil (oficial no opera fin de semana)
      final comparisonOficial = ultimaCorridaPrevMarket ?? ultimaCorridaAyer;
      if (comparisonOficial != null && buy != null) {
        final previousData =
            comparisonOficial[typeKey] as Map<String, dynamic>?;
        if (previousData != null) {
          // Buscar el mismo banco en los datos anteriores
          final previousBancoData =
              previousData[bancoSeleccionado] as Map<String, dynamic>?;
          if (previousBancoData != null) {
            final previousBuy = _parseDouble(previousBancoData['compra']);
            if (previousBuy != null && previousBuy > 0) {
              changePercent = ((buy - previousBuy) / previousBuy) * 100;
              print(
                  '✅ Variación oficial ($bancoSeleccionado): ${buy} vs ${previousBuy} = ${changePercent.toStringAsFixed(2)}%');
            } else {
              print(
                  '⚠️ No se pudo parsear previousBuy para $bancoSeleccionado');
            }
          } else {
            // Si no existe el mismo banco, intentar con el primer banco disponible
            final bancos = previousData.keys.toList();
            if (bancos.isNotEmpty) {
              final primerBanco = bancos.first;
              final primerBancoData =
                  previousData[primerBanco] as Map<String, dynamic>?;
              if (primerBancoData != null) {
                final previousBuy = _parseDouble(primerBancoData['compra']);
                if (previousBuy != null && previousBuy > 0) {
                  changePercent = ((buy - previousBuy) / previousBuy) * 100;
                  print(
                      '⚠️ Usando banco diferente para comparación: $bancoSeleccionado vs $primerBanco');
                }
              }
            } else {
              print(
                  '⚠️ No hay bancos disponibles en datos anteriores para comparar');
            }
          }
        } else {
          print(
              '⚠️ No hay datos del día hábil anterior para variación oficial');
        }
      }
      if (changePercent == null && buy != null) {
        changePercent = 0.0;
      }
    } else if (dollarType == DollarType.crypto) {
      // Para dólar crypto, necesitamos seleccionar una plataforma
      // API usa perspectiva exchange: compra=ellos compran, venta=ellos venden.
      // Para el usuario: Comprar=venta (lo que pagás), Vender=compra (lo que recibís)
      String? plataformaSeleccionada;
      final plataformaData = latestData['binance'] as Map<String, dynamic>?;
      if (plataformaData == null) {
        // Si no hay binance, buscar la primera plataforma disponible
        final plataformas = latestData.keys.toList();
        if (plataformas.isEmpty) return null;
        plataformaSeleccionada = plataformas.first;
        final primeraPlataformaData =
            latestData[plataformaSeleccionada] as Map<String, dynamic>?;
        if (primeraPlataformaData == null) return null;
        buy = _parseDouble(primeraPlataformaData['venta']);
        sell = _parseDouble(primeraPlataformaData['compra']);
      } else {
        plataformaSeleccionada = 'binance';
        buy = _parseDouble(plataformaData['venta']);
        sell = _parseDouble(plataformaData['compra']);
      }

      // Si algún valor es null, buscar hacia atrás en las últimas 2 horas
      if ((buy == null || sell == null) &&
          corridas != null &&
          ultimaCorridaTimestamp != null) {
        final validData = _findLastValidValueInCorridas(
          corridas,
          ultimaCorridaTimestamp,
          typeKey,
          plataformaSeleccionada,
        );
        if (validData != null) {
          if (buy == null) {
            buy = _parseDouble(validData['venta']);
            print(
                '🔍 Valor de compra null para $plataformaSeleccionada, usando último valor válido: $buy');
          }
          if (sell == null) {
            sell = _parseDouble(validData['compra']);
            print(
                '🔍 Valor de venta null para $plataformaSeleccionada, usando último valor válido: $sell');
          }
        }
      }

      // Calcular variación comparando último de HOY con último de AYER
      // IMPORTANTE: Comparar la misma plataforma en ambos momentos
      print(
          '🔍 DEBUG Cripto - buy (HOY): $buy, plataformaSeleccionada: $plataformaSeleccionada, ultimaCorridaAyer: ${ultimaCorridaAyer != null}');
      print(
          '🔍 DEBUG - latestData (HOY) content: ${latestData[plataformaSeleccionada]}');
      if (ultimaCorridaAyer != null && buy != null) {
        print(
            '🔍 DEBUG - typeKey: $typeKey, ultimaCorridaAyer keys: ${ultimaCorridaAyer.keys.toList()}');
        final previousData =
            ultimaCorridaAyer[typeKey] as Map<String, dynamic>?;
        print(
            '🔍 DEBUG - previousData (dolar_cripto): ${previousData != null}, keys: ${previousData?.keys.toList()}');
        if (previousData != null) {
          // Buscar la misma plataforma en los datos anteriores
          final previousPlataformaData =
              previousData[plataformaSeleccionada] as Map<String, dynamic>?;
          print(
              '🔍 DEBUG - previousPlataformaData ($plataformaSeleccionada): ${previousPlataformaData != null}');
          if (previousPlataformaData != null) {
            print(
                '🔍 DEBUG - previousPlataformaData content (AYER): $previousPlataformaData');
            final previousBuy = _parseDouble(previousPlataformaData['venta']);
            print('🔍 DEBUG - previousBuy parsed (AYER): $previousBuy');
            if (previousBuy != null && previousBuy > 0) {
              changePercent = ((buy - previousBuy) / previousBuy) * 100;
              print(
                  '✅ Variación cripto ($plataformaSeleccionada): HOY($buy) vs AYER($previousBuy) = ${changePercent.toStringAsFixed(2)}%');
            } else {
              print(
                  '⚠️ No se pudo parsear previousBuy para $plataformaSeleccionada (previousBuy: $previousBuy)');
            }
          } else {
            // Si no existe la misma plataforma, intentar con la primera disponible
            final plataformas = previousData.keys.toList();
            print(
                '⚠️ No se encontró $plataformaSeleccionada en datos anteriores. Plataformas disponibles: $plataformas');
            if (plataformas.isNotEmpty) {
              final primeraPlataforma = plataformas.first;
              final primeraPlataformaData =
                  previousData[primeraPlataforma] as Map<String, dynamic>?;
              if (primeraPlataformaData != null) {
                final previousBuy =
                    _parseDouble(primeraPlataformaData['venta']);
                if (previousBuy != null && previousBuy > 0) {
                  changePercent = ((buy - previousBuy) / previousBuy) * 100;
                  print(
                      '⚠️ Usando plataforma diferente para comparación: $plataformaSeleccionada vs $primeraPlataforma');
                }
              }
            } else {
              print(
                  '⚠️ No hay plataformas disponibles en datos anteriores para comparar');
            }
          }
        } else {
          print(
              '⚠️ No hay datos anteriores (ultimaCorridaAyer[$typeKey]) para calcular variación cripto');
        }
      } else {
        if (ultimaCorridaAyer == null) {
          print(
              '⚠️ ultimaCorridaAyer es null - no se cargó el archivo de ayer');
        }
        if (buy == null) {
          print('⚠️ buy es null - no hay valor de compra actual');
        }
      }
      // Si no hay corrida de comparación o no se pudo calcular, usar 0.0 por defecto
      if (changePercent == null && buy != null) {
        changePercent = 0.0;
        print('⚠️ No se pudo calcular variación para cripto, usando 0.0%');
      }
    } else {
      // Para los demás tipos (blue, tarjeta, mep, ccl), la estructura es directa
      buy = _parseDouble(latestData['compra']);
      sell = _parseDouble(latestData['venta']);

      // Si algún valor es null, buscar hacia atrás en las últimas 2 horas
      if ((buy == null || sell == null) &&
          corridas != null &&
          ultimaCorridaTimestamp != null) {
        // Para estos tipos, la estructura es directa (no hay bancos/plataformas)
        // Buscar en las corridas de las últimas 2 horas
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

          final typeData = corrida[typeKey] as Map<String, dynamic>?;
          if (typeData == null) continue;

          if (buy == null) {
            final compra = _parseDouble(typeData['compra']);
            if (compra != null) {
              buy = compra;
              print(
                  '🔍 Valor de compra null para $typeKey, usando último valor válido: $buy');
            }
          }
          if (sell == null) {
            final venta = _parseDouble(typeData['venta']);
            if (venta != null) {
              sell = venta;
              print(
                  '🔍 Valor de venta null para $typeKey, usando último valor válido: $sell');
            }
          }

          // Si ya tenemos ambos valores, no necesitamos seguir buscando
          if (buy != null && sell != null) break;
        }
      }

      // Variación: blue con ayer; tarjeta, MEP, CCL con último día hábil (no operan fin de semana)
      final comparisonRest = (dollarType == DollarType.blue)
          ? ultimaCorridaAyer
          : (ultimaCorridaPrevMarket ?? ultimaCorridaAyer);
      if (comparisonRest != null) {
        final previousData = comparisonRest[typeKey] as Map<String, dynamic>?;
        if (previousData != null) {
          if (dollarType == DollarType.tarjeta && buy == null && sell != null) {
            final previousSell = _parseDouble(previousData['venta']);
            if (previousSell != null && previousSell > 0) {
              changePercent = ((sell - previousSell) / previousSell) * 100;
            }
          } else if (buy != null) {
            final previousBuy = _parseDouble(previousData['compra']);
            if (previousBuy != null && previousBuy > 0) {
              changePercent = ((buy - previousBuy) / previousBuy) * 100;
            }
          }
        }
      }
      // Si no hay penúltima corrida o no se pudo calcular, usar 0.0 por defecto
      if (changePercent == null) {
        if (dollarType == DollarType.tarjeta && sell != null) {
          changePercent = 0.0;
        } else if (buy != null) {
          changePercent = 0.0;
        }
      }
    }

    // Crear el rate incluso si buy o sell son null (mostrará "-" en la UI)
    return DollarRate(
      type: dollarType,
      buy: buy,
      sell: sell,
      changePercent: changePercent,
    );
  }

  /// Convierte un valor a double, manejando null
  double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed;
    }
    return null;
  }

  /// Convierte un timestamp string a DateTime
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return DateTime.now();

    final tsStr = timestamp.toString();

    try {
      // Intentar parsear como ISO 8601
      return DateTime.parse(tsStr);
    } catch (e) {
      // Si falla, usar la fecha actual
      return DateTime.now();
    }
  }

  /// Obtiene la key del JSON para un tipo de dólar
  String _getDollarTypeKey(DollarType type) {
    switch (type) {
      case DollarType.blue:
        return 'dolar_blue';
      case DollarType.official:
        return 'dolar_oficial';
      case DollarType.tarjeta:
        return 'dolar_tarjeta';
      case DollarType.mep:
        return 'dolar_mep';
      case DollarType.ccl:
        return 'dolar_ccl';
      case DollarType.crypto:
        return 'dolar_cripto';
    }
  }

  /// Obtiene el JSON completo para uso en providers de bancos y plataformas
  Future<Map<String, dynamic>> getFullJsonData() async {
    try {
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      // Agregar timestamp como query param para evitar caché
      final url = Uri.parse('$baseUrl/cotizaciones_$dateStr.json').replace(
        queryParameters: {
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'DolarArgentinaApp/1.0',
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          return http.Response('', 408); // Timeout
        },
      );

      if (response.statusCode == 404) {
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
        ).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            return http.Response('', 408); // Timeout
          },
        );

        if (yesterdayResponse.statusCode != 200) {
          return {};
        }

        final bodyAyer = yesterdayResponse.body.trim();
        if (bodyAyer.startsWith('<!') || bodyAyer.startsWith('<html')) {
          return {};
        }

        final parsedAyer = jsonDecode(bodyAyer) as Map<String, dynamic>;
        return parsedAyer;
      }

      if (response.statusCode != 200) {
        return {};
      }

      // Validar que no sea HTML
      final body = response.body.trim();
      if (body.startsWith('<!') || body.startsWith('<html')) {
        return {};
      }

      final parsed = jsonDecode(body) as Map<String, dynamic>;
      final uc = parsed['ultima_corrida'] as Map<String, dynamic>?;
      if (!_hasUsableDataInUltimaCorrida(uc)) {
        final yesterday = now.subtract(const Duration(days: 1));
        final dateStr =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        final prevJson = await _fetchFullJsonForDate(dateStr);
        if (prevJson != null &&
            _hasUsableDataInUltimaCorrida(
                prevJson['ultima_corrida'] as Map<String, dynamic>?)) {
          return prevJson;
        }
      }
      return parsed;
    } catch (e) {
      return {};
    }
  }
}
