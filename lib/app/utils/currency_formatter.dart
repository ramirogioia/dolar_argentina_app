import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat.currency(
    symbol: '\$ ',
    decimalDigits: 0,
    locale: 'es_AR',
  );

  static String format(double value) {
    return _formatter.format(value);
  }
}

