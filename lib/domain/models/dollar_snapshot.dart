import 'dollar_rate.dart';

class DollarSnapshot {
  /// Momento en que terminó la consulta en el cliente (header, refresh manual).
  final DateTime updatedAt;
  /// Momento de la medición en el backend (solo lógica interna, ej. variación stale en cards).
  final DateTime? lastMeasurementAt;
  final List<DollarRate> rates;

  const DollarSnapshot({
    required this.updatedAt,
    this.lastMeasurementAt,
    required this.rates,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DollarSnapshot &&
          runtimeType == other.runtimeType &&
          updatedAt == other.updatedAt &&
          lastMeasurementAt == other.lastMeasurementAt &&
          rates == other.rates;

  @override
  int get hashCode =>
      Object.hash(updatedAt, lastMeasurementAt, rates.hashCode);
}

