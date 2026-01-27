import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/dollar_repository.dart';
import '../../../domain/models/dollar_snapshot.dart';
import '../../settings/providers/settings_providers.dart';

final dollarRepositoryProvider = Provider<DollarRepository>((ref) {
  final useMockData = ref.watch(useMockDataProvider);
  final apiUrl = ref.watch(apiUrlProvider);
  return DollarRepository(useMockData: useMockData, apiUrl: apiUrl);
});

final dollarSnapshotProvider =
    FutureProvider<DollarSnapshot>((ref) async {
  final repository = ref.watch(dollarRepositoryProvider);
  return repository.getDollarRates();
});

