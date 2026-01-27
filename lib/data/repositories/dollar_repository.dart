import '../../domain/models/dollar_snapshot.dart';
import '../datasources/dollar_data_source.dart';
import '../datasources/http_dollar_data_source.dart';
import '../datasources/mock_dollar_data_source.dart';

class DollarRepository {
  final DollarDataSource _dataSource;

  DollarRepository({required bool useMockData, String? apiUrl})
      : _dataSource = useMockData
            ? MockDollarDataSource()
            : HttpDollarDataSource(baseUrl: apiUrl);

  Future<DollarSnapshot> getDollarRates() {
    return _dataSource.getDollarRates();
  }
}

