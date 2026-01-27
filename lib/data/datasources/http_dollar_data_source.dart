import '../../app/constants/api_constants.dart';
import '../../domain/models/dollar_rate.dart';
import '../../domain/models/dollar_snapshot.dart';
import '../../domain/models/dollar_type.dart';
import 'dollar_data_source.dart';

/// Implementación futura para conectar con Google Apps Script Web App
/// TODO: Implementar cuando se tenga el backend listo
class HttpDollarDataSource implements DollarDataSource {
  final String baseUrl;

  HttpDollarDataSource({String? baseUrl})
      : baseUrl = baseUrl ?? apiBaseUrl;

  @override
  Future<DollarSnapshot> getDollarRates() async {
    // TODO: Implementar llamada HTTP real
    // Ejemplo de estructura esperada:
    // final response = await http.get(Uri.parse('$baseUrl/rates'));
    // final data = jsonDecode(response.body);
    // return DollarSnapshot.fromJson(data);

    throw UnimplementedError(
      'HttpDollarDataSource no está implementado aún. '
      'Usa MockDollarDataSource por ahora.',
    );
  }

  /// Convierte un JSON del backend a DollarSnapshot
  /// Formato esperado del backend:
  /// {
  ///   "updatedAt": "2024-01-23T12:00:00Z",
  ///   "rates": [
  ///     {"type": "blue", "buy": 1485.0, "sell": 1495.0, "changePercent": 0.5},
  ///     ...
  ///   ]
  /// }
  // ignore: unused_element
  DollarSnapshot _parseResponse(Map<String, dynamic> json) {
    final rates = (json['rates'] as List)
        .map((rateJson) => DollarRate(
              type: DollarType.values.firstWhere(
                (type) => type.name == rateJson['type'],
              ),
              buy: (rateJson['buy'] as num).toDouble(),
              sell: (rateJson['sell'] as num).toDouble(),
              changePercent: rateJson['changePercent'] != null
                  ? (rateJson['changePercent'] as num).toDouble()
                  : null,
            ))
        .toList();

    return DollarSnapshot(
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      rates: rates,
    );
  }
}

