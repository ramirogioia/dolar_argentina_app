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
      final url = Uri.parse('$baseUrl/cotizaciones_$dateStr.json');

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

      print('✅ JSON válido recibido, parseando...');
      return await _parseResponse(response.body);
    } catch (e) {
      throw Exception('Error al obtener datos del backend: $e');
    }
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
      final ultimaCorrida = json['ultima_corrida'] as Map<String, dynamic>?;
      if (ultimaCorrida == null) {
        throw Exception('El JSON no contiene "ultima_corrida"');
      }
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

      // Obtener las corridas para calcular variaciones
      // Buscar el valor de hace 24 horas: primero en el archivo de hoy, luego en el de ayer
      final corridas = json['corridas'] as List<dynamic>?;
      Map<String, dynamic>? corridaComparacion;

      // Intentar cargar el archivo de ayer para comparar con hace 24 horas
      Map<String, dynamic>? jsonAyer;
      try {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final yesterdayStr =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        final yesterdayUrl =
            Uri.parse('$baseUrl/cotizaciones_$yesterdayStr.json');

        print(
            '🔍 Intentando cargar archivo de ayer para comparación: ${yesterdayUrl.toString()}');
        final yesterdayResponse = await http.get(
          yesterdayUrl,
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'DolarArgentinaApp/1.0',
          },
        ).timeout(const Duration(seconds: 10));

        if (yesterdayResponse.statusCode == 200) {
          final body = yesterdayResponse.body.trim();
          if (!body.startsWith('<!') && !body.startsWith('<html')) {
            jsonAyer = jsonDecode(body) as Map<String, dynamic>;
            print('✅ Archivo de ayer cargado exitosamente para comparación');
          }
        }
      } catch (e) {
        print('⚠️ No se pudo cargar archivo de ayer para comparación: $e');
      }

      // Combinar corridas de hoy y ayer para buscar la más cercana a hace 24 horas
      final todasLasCorridas = <Map<String, dynamic>>[];
      if (corridas != null) {
        todasLasCorridas.addAll(corridas.map((c) => c as Map<String, dynamic>));
      }

      // Agregar corridas del archivo de ayer si está disponible
      if (jsonAyer != null) {
        final corridasAyer = jsonAyer['corridas'] as List<dynamic>?;
        if (corridasAyer != null) {
          todasLasCorridas
              .addAll(corridasAyer.map((c) => c as Map<String, dynamic>));
          print(
              '📊 Combinadas ${corridas?.length ?? 0} corridas de hoy con ${corridasAyer.length} de ayer');
        }
      }

      if (todasLasCorridas.isNotEmpty) {
        final now = DateTime.now();
        final hace24Horas = now.subtract(const Duration(hours: 24));
        final inicioDelDia = DateTime(now.year, now.month, now.day, 0, 0, 0);

        // Ordenar por timestamp (más antiguo primero para buscar el más cercano a hace 24h)
        todasLasCorridas.sort((a, b) {
          final tsA = _parseTimestamp(a['timestamp']);
          final tsB = _parseTimestamp(b['timestamp']);
          return tsA.compareTo(tsB);
        });

        // Buscar la corrida más cercana a hace 24 horas en todas las corridas (hoy + ayer)
        Map<String, dynamic>? corridaMasCercana24h;
        Duration? diferenciaMinima;

        for (final corrida in todasLasCorridas) {
          final timestamp = _parseTimestamp(corrida['timestamp']);
          final diferencia = timestamp.difference(hace24Horas).abs();

          if (diferenciaMinima == null || diferencia < diferenciaMinima) {
            diferenciaMinima = diferencia;
            corridaMasCercana24h = corrida;
          }
        }

        // Si encontramos una corrida de hace menos de 30 horas, usarla
        // Si no, usar la primera corrida del día (apertura)
        if (corridaMasCercana24h != null &&
            diferenciaMinima != null &&
            diferenciaMinima < const Duration(hours: 30)) {
          corridaComparacion = corridaMasCercana24h;
          print(
              '✅ Usando corrida de hace 24h: ${_parseTimestamp(corridaMasCercana24h['timestamp'])} (diferencia: ${diferenciaMinima.inHours}h ${diferenciaMinima.inMinutes % 60}m)');
        } else {
          // Buscar la primera corrida del día (apertura)
          for (final corrida in todasLasCorridas) {
            final timestamp = _parseTimestamp(corrida['timestamp']);
            if (timestamp.isAfter(inicioDelDia) ||
                timestamp.isAtSameMomentAs(inicioDelDia)) {
              corridaComparacion = corrida;
              print(
                  '✅ Usando primera corrida del día (apertura): ${timestamp}');
              break;
            }
          }
          // Si no hay corrida del día actual, usar la primera disponible
          if (corridaComparacion == null && todasLasCorridas.isNotEmpty) {
            corridaComparacion = todasLasCorridas.first;
            print(
                '✅ Usando primera corrida disponible: ${_parseTimestamp(todasLasCorridas.first['timestamp'])}');
          }
        }
      }

      // Construir la lista de DollarRate
      final rates = <DollarRate>[];

      // Mapear cada tipo de dólar
      for (final dollarType in DollarType.values) {
        final rate = _extractDollarRate(
          ultimaCorrida,
          corridaComparacion,
          dollarType,
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

  /// Extrae un DollarRate para un tipo específico de dólar
  /// [corridaComparacion] puede ser la corrida de hace 24h o la primera del día (apertura)
  DollarRate? _extractDollarRate(
    Map<String, dynamic> ultimaCorrida,
    Map<String, dynamic>? corridaComparacion,
    DollarType dollarType,
  ) {
    final typeKey = _getDollarTypeKey(dollarType);

    // Buscar el valor en la última corrida
    final latestData = ultimaCorrida[typeKey] as Map<String, dynamic>?;
    if (latestData == null) return null;

    double? buy;
    double? sell;
    double? changePercent;

    if (dollarType == DollarType.official) {
      // Para dólar oficial, necesitamos seleccionar un banco
      // Por defecto usamos "nacion", pero podríamos hacer un promedio
      final bancoData = latestData['nacion'] as Map<String, dynamic>?;
      if (bancoData == null) {
        // Si no hay nacion, buscar el primer banco disponible
        final bancos = latestData.keys.toList();
        if (bancos.isEmpty) return null;
        final primerBanco = bancos.first;
        final primerBancoData =
            latestData[primerBanco] as Map<String, dynamic>?;
        if (primerBancoData == null) return null;
        buy = _parseDouble(primerBancoData['compra']);
        sell = _parseDouble(primerBancoData['venta']);
      } else {
        buy = _parseDouble(bancoData['compra']);
        sell = _parseDouble(bancoData['venta']);
      }

      // Calcular variación comparando con la corrida de referencia (hace 24h o apertura)
      if (corridaComparacion != null && buy != null) {
        final previousData =
            corridaComparacion[typeKey] as Map<String, dynamic>?;
        if (previousData != null) {
          final previousBancoData =
              previousData['nacion'] as Map<String, dynamic>?;
          if (previousBancoData == null) {
            final bancos = previousData.keys.toList();
            if (bancos.isNotEmpty) {
              final primerBanco = bancos.first;
              final primerBancoData =
                  previousData[primerBanco] as Map<String, dynamic>?;
              if (primerBancoData != null) {
                final previousBuy = _parseDouble(primerBancoData['compra']);
                if (previousBuy != null && previousBuy > 0) {
                  changePercent = ((buy - previousBuy) / previousBuy) * 100;
                }
              }
            }
          } else {
            final previousBuy = _parseDouble(previousBancoData['compra']);
            if (previousBuy != null && previousBuy > 0) {
              changePercent = ((buy - previousBuy) / previousBuy) * 100;
            }
          }
        }
      }
      // Si no hay corrida de comparación o no se pudo calcular, usar 0.0 por defecto
      if (changePercent == null && buy != null) {
        changePercent = 0.0;
      }
    } else if (dollarType == DollarType.crypto) {
      // Para dólar crypto, necesitamos seleccionar una plataforma
      // Por defecto usamos "binance"
      final plataformaData = latestData['binance'] as Map<String, dynamic>?;
      if (plataformaData == null) {
        // Si no hay binance, buscar la primera plataforma disponible
        final plataformas = latestData.keys.toList();
        if (plataformas.isEmpty) return null;
        final primeraPlataforma = plataformas.first;
        final primeraPlataformaData =
            latestData[primeraPlataforma] as Map<String, dynamic>?;
        if (primeraPlataformaData == null) return null;
        buy = _parseDouble(primeraPlataformaData['compra']);
        sell = _parseDouble(primeraPlataformaData['venta']);
      } else {
        buy = _parseDouble(plataformaData['compra']);
        sell = _parseDouble(plataformaData['venta']);
      }

      // Calcular variación comparando con la corrida de referencia (hace 24h o apertura)
      if (corridaComparacion != null && buy != null) {
        final previousData =
            corridaComparacion[typeKey] as Map<String, dynamic>?;
        if (previousData != null) {
          final previousPlataformaData =
              previousData['binance'] as Map<String, dynamic>?;
          if (previousPlataformaData == null) {
            final plataformas = previousData.keys.toList();
            if (plataformas.isNotEmpty) {
              final primeraPlataforma = plataformas.first;
              final primeraPlataformaData =
                  previousData[primeraPlataforma] as Map<String, dynamic>?;
              if (primeraPlataformaData != null) {
                final previousBuy =
                    _parseDouble(primeraPlataformaData['compra']);
                if (previousBuy != null && previousBuy > 0) {
                  changePercent = ((buy - previousBuy) / previousBuy) * 100;
                }
              }
            }
          } else {
            final previousBuy = _parseDouble(previousPlataformaData['compra']);
            if (previousBuy != null && previousBuy > 0) {
              changePercent = ((buy - previousBuy) / previousBuy) * 100;
            }
          }
        }
      }
      // Si no hay corrida de comparación o no se pudo calcular, usar 0.0 por defecto
      if (changePercent == null && buy != null) {
        changePercent = 0.0;
      }
    } else {
      // Para los demás tipos (blue, tarjeta, mep, ccl), la estructura es directa
      buy = _parseDouble(latestData['compra']);
      sell = _parseDouble(latestData['venta']);

      // Calcular variación comparando con la corrida de referencia (hace 24h o apertura)
      // Para tarjeta, usar 'sell' si 'buy' es null
      if (corridaComparacion != null) {
        final previousData =
            corridaComparacion[typeKey] as Map<String, dynamic>?;
        if (previousData != null) {
          if (dollarType == DollarType.tarjeta && buy == null && sell != null) {
            // Para tarjeta, calcular variación usando 'venta' si 'compra' es null
            final previousSell = _parseDouble(previousData['venta']);
            if (previousSell != null && previousSell > 0) {
              changePercent = ((sell - previousSell) / previousSell) * 100;
            }
          } else if (buy != null) {
            // Para otros tipos, usar 'compra' como siempre
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
      final url = Uri.parse('$baseUrl/cotizaciones_$dateStr.json');

      final response = await http.get(url).timeout(
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
        final yesterdayResponse = await http.get(yesterdayUrl).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            return http.Response('', 408); // Timeout
          },
        );

        if (yesterdayResponse.statusCode != 200) {
          return {};
        }

        // Validar que no sea HTML
        final body = yesterdayResponse.body.trim();
        if (body.startsWith('<!') || body.startsWith('<html')) {
          return {};
        }

        return jsonDecode(yesterdayResponse.body) as Map<String, dynamic>;
      }

      if (response.statusCode != 200) {
        return {};
      }

      // Validar que no sea HTML
      final body = response.body.trim();
      if (body.startsWith('<!') || body.startsWith('<html')) {
        return {};
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}
