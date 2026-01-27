import '../../domain/models/dollar_snapshot.dart';

abstract class DollarDataSource {
  Future<DollarSnapshot> getDollarRates();
}

