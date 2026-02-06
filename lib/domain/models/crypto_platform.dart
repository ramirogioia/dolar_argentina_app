enum CryptoPlatform {
  binance,
  kucoin,
  bybit,
  okx,
  bitget;

  String get displayName {
    switch (this) {
      case CryptoPlatform.binance:
        return 'Binance P2P';
      case CryptoPlatform.kucoin:
        return 'KuCoin P2P';
      case CryptoPlatform.bybit:
        return 'Bybit P2P';
      case CryptoPlatform.okx:
        return 'OKX P2P';
      case CryptoPlatform.bitget:
        return 'Bitget P2P';
    }
  }

  // Rutas de los logos de cada plataforma
  String get logoPath {
    switch (this) {
      case CryptoPlatform.binance:
        return 'assets/platforms/binance_logo.png';
      case CryptoPlatform.kucoin:
        return 'assets/platforms/kucoin_logo.png';
      case CryptoPlatform.bybit:
        return 'assets/platforms/bybit_logo.png';
      case CryptoPlatform.okx:
        return 'assets/platforms/okx_logo.png';
      case CryptoPlatform.bitget:
        return 'assets/platforms/bitget_logo.png';
    }
  }
}
