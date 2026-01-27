import 'dollar_rate.dart';

class DollarSnapshot {
  final DateTime updatedAt;
  final List<DollarRate> rates;

  const DollarSnapshot({
    required this.updatedAt,
    required this.rates,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DollarSnapshot &&
          runtimeType == other.runtimeType &&
          updatedAt == other.updatedAt &&
          rates == other.rates;

  @override
  int get hashCode => updatedAt.hashCode ^ rates.hashCode;
}

