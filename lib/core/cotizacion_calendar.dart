// Calendario de archivos `cotizaciones_YYYY-MM-DD.json` (sin zona horaria).
// Evita que DateTime.parse en ISO date-only desalinee el día respecto al `fecha` del backend.

DateTime parseCotizacionFechaString(String? fecha) {
  if (fecha != null && fecha.length >= 10) {
    final y = int.tryParse(fecha.substring(0, 4));
    final m = int.tryParse(fecha.substring(5, 7));
    final d = int.tryParse(fecha.substring(8, 10));
    if (y != null && m != null && d != null) {
      return DateTime.utc(y, m, d);
    }
  }
  final n = DateTime.now();
  return DateTime.utc(n.year, n.month, n.day);
}

DateTime parseCotizacionReferenceDate(Map<String, dynamic> json) {
  return parseCotizacionFechaString(json['fecha'] as String?);
}

String formatCotizacionDate(DateTime d) {
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Último día hábil anterior a [referenceDate] (oficial / blue / MEP / CCL / tarjeta).
/// Lunes → viernes. Sábado/domingo → viernes. Martes–viernes → día anterior.
DateTime getPreviousMarketDate(DateTime referenceDate) {
  final w = referenceDate.weekday;
  if (w == DateTime.monday) {
    return referenceDate.subtract(const Duration(days: 3));
  }
  if (w == DateTime.saturday) {
    return referenceDate.subtract(const Duration(days: 1));
  }
  if (w == DateTime.sunday) {
    return referenceDate.subtract(const Duration(days: 2));
  }
  return referenceDate.subtract(const Duration(days: 1));
}
