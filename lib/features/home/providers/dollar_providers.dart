import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/dollar_repository.dart';
import '../../../domain/models/bank.dart';
import '../../../domain/models/crypto_platform.dart';
import '../../../domain/models/dollar_rate.dart';
import '../../../domain/models/dollar_snapshot.dart';
import '../../../domain/models/dollar_type.dart';
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

// Provider para la plataforma P2P seleccionada (por defecto Binance)
final selectedCryptoPlatformProvider =
    StateProvider<CryptoPlatform>((ref) => CryptoPlatform.binance);

// Valores mockeados para cada plataforma P2P
final cryptoPlatformRatesProvider = Provider<Map<CryptoPlatform, DollarRate>>((ref) {
  return {
    CryptoPlatform.binance: DollarRate(
      type: DollarType.crypto,
      buy: 1470.0,
      sell: 1480.0,
      changePercent: 0.4,
    ),
    CryptoPlatform.prex: DollarRate(
      type: DollarType.crypto,
      buy: 1465.0,
      sell: 1475.0,
      changePercent: 0.3,
    ),
    CryptoPlatform.dolarApp: DollarRate(
      type: DollarType.crypto,
      buy: 1472.0,
      sell: 1482.0,
      changePercent: 0.35,
    ),
  };
});

// Provider para el banco seleccionado (por defecto Banco Nación)
final selectedBankProvider =
    StateProvider<Bank>((ref) => Bank.nacion);

// Valores mockeados para cada banco
final bankRatesProvider = Provider<Map<Bank, DollarRate>>((ref) {
  return {
    Bank.nacion: DollarRate(
      type: DollarType.official,
      buy: 850.0,
      sell: 870.0,
      changePercent: -0.2,
    ),
    Bank.santander: DollarRate(
      type: DollarType.official,
      buy: 851.0,
      sell: 871.0,
      changePercent: -0.15,
    ),
    Bank.galicia: DollarRate(
      type: DollarType.official,
      buy: 849.5,
      sell: 869.5,
      changePercent: -0.25,
    ),
    Bank.bbva: DollarRate(
      type: DollarType.official,
      buy: 850.5,
      sell: 870.5,
      changePercent: -0.18,
    ),
    Bank.patagonia: DollarRate(
      type: DollarType.official,
      buy: 851.5,
      sell: 871.5,
      changePercent: -0.12,
    ),
    Bank.supervielle: DollarRate(
      type: DollarType.official,
      buy: 850.2,
      sell: 870.2,
      changePercent: -0.22,
    ),
    Bank.icbc: DollarRate(
      type: DollarType.official,
      buy: 849.8,
      sell: 869.8,
      changePercent: -0.28,
    ),
    Bank.ciudad: DollarRate(
      type: DollarType.official,
      buy: 850.8,
      sell: 870.8,
      changePercent: -0.16,
    ),
    Bank.bica: DollarRate(
      type: DollarType.official,
      buy: 851.2,
      sell: 871.2,
      changePercent: -0.14,
    ),
    Bank.mariva: DollarRate(
      type: DollarType.official,
      buy: 850.3,
      sell: 870.3,
      changePercent: -0.2,
    ),
    Bank.comafi: DollarRate(
      type: DollarType.official,
      buy: 849.9,
      sell: 869.9,
      changePercent: -0.26,
    ),
    Bank.credicoop: DollarRate(
      type: DollarType.official,
      buy: 850.6,
      sell: 870.6,
      changePercent: -0.17,
    ),
    Bank.hipotecario: DollarRate(
      type: DollarType.official,
      buy: 851.1,
      sell: 871.1,
      changePercent: -0.13,
    ),
  };
});

