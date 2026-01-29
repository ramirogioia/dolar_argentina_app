import '../../domain/models/dollar_snapshot.dart';
import '../datasources/http_dollar_data_source.dart';

class DollarRepository {
  final HttpDollarDataSource _dataSource;

  DollarRepository({required String apiUrl})
      : _dataSource = HttpDollarDataSource(baseUrl: apiUrl);

  Future<DollarSnapshot> getDollarRates() {
    return _dataSource.getDollarRates();
  }
}

