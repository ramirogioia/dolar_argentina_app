import '../../domain/models/dollar_rate.dart';
import '../../domain/models/dollar_snapshot.dart';
import '../../domain/models/dollar_type.dart';
import 'dollar_data_source.dart';

class MockDollarDataSource implements DollarDataSource {
  @override
  Future<DollarSnapshot> getDollarRates() async {
    // Simular un pequeño delay de red
    await Future.delayed(const Duration(milliseconds: 500));

    final rates = [
      DollarRate(
        type: DollarType.blue,
        buy: 1485.0,
        sell: 1495.0,
        changePercent: 0.5,
      ),
      DollarRate(
        type: DollarType.official,
        buy: 850.0,
        sell: 870.0,
        changePercent: -0.2,
      ),
      DollarRate(
        type: DollarType.crypto,
        buy: 1470.0,
        sell: 1480.0,
        changePercent: 0.4,
      ),
      DollarRate(
        type: DollarType.tarjeta,
        buy: 1450.0,
        sell: 1460.0,
        changePercent: 0.3,
      ),
      DollarRate(
        type: DollarType.mep,
        buy: 1420.0,
        sell: 1430.0,
        changePercent: 0.1,
      ),
      DollarRate(
        type: DollarType.ccl,
        buy: 1410.0,
        sell: 1420.0,
        changePercent: 0.05,
      ),
    ];

    return DollarSnapshot(
      updatedAt: DateTime.now(),
      lastMeasurementAt: DateTime.now(),
      rates: rates,
    );
  }
}
