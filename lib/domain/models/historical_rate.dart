class HistoricalRate {
  final DateTime date;
  final double? blueVenta;
  final double? oficialVenta;
  /// USDT/ARS P2P (mismo criterio que el backend en ``dolar_cripto.binance``).
  final double? binanceCompra;
  final double? binanceVenta;

  const HistoricalRate({
    required this.date,
    this.blueVenta,
    this.oficialVenta,
    this.binanceCompra,
    this.binanceVenta,
  });

  factory HistoricalRate.fromJson(Map<String, dynamic> json) {
    return HistoricalRate(
      date: DateTime.parse(json['fecha'] as String),
      blueVenta: (json['blue_venta'] as num?)?.toDouble(),
      oficialVenta: (json['oficial_venta'] as num?)?.toDouble(),
      binanceCompra: (json['binance_compra'] as num?)?.toDouble(),
      binanceVenta: (json['binance_venta'] as num?)?.toDouble(),
    );
  }
}

class HistoricalSnapshot {
  final String desde;
  final String hasta;
  final int cantidadDias;
  final List<HistoricalRate> serie;

  const HistoricalSnapshot({
    required this.desde,
    required this.hasta,
    required this.cantidadDias,
    required this.serie,
  });

  factory HistoricalSnapshot.fromJson(Map<String, dynamic> json) {
    final meta = json['meta'] as Map<String, dynamic>;
    final serie = (json['serie_diaria'] as List<dynamic>)
        .map((e) => HistoricalRate.fromJson(e as Map<String, dynamic>))
        .toList();
    return HistoricalSnapshot(
      desde: meta['desde'] as String,
      hasta: meta['hasta'] as String,
      cantidadDias: meta['cantidad_dias'] as int,
      serie: serie,
    );
  }
}
