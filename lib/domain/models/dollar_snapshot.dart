import 'dollar_rate.dart';

class DollarSnapshot {
  /// Cuándo se refrescaron los datos en la app (pull to refresh / fetch).
  final DateTime updatedAt;
  /// Timestamp de la última medición del backend (para mostrar "Última actualización: ...").
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

