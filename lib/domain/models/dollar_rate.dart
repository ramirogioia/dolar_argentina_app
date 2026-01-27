import 'dollar_type.dart';

class DollarRate {
  final DollarType type;
  final double buy;
  final double sell;
  final double? changePercent;

  const DollarRate({
    required this.type,
    required this.buy,
    required this.sell,
    this.changePercent,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DollarRate &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          buy == other.buy &&
          sell == other.sell &&
          changePercent == other.changePercent;

  @override
  int get hashCode =>
      type.hashCode ^ buy.hashCode ^ sell.hashCode ^ changePercent.hashCode;
}

