enum CryptoPlatform {
  binance,
  prex,
  dolarApp;

  String get displayName {
    switch (this) {
      case CryptoPlatform.binance:
        return 'Binance P2P';
      case CryptoPlatform.prex:
        return 'Prex P2P';
      case CryptoPlatform.dolarApp:
        return 'Dolar App P2P';
    }
  }

  // Rutas de los logos de cada plataforma
  String get logoPath {
    switch (this) {
      case CryptoPlatform.binance:
        return 'assets/platforms/binance_logo.png';
      case CryptoPlatform.prex:
        return 'assets/platforms/prex_logo.png';
      case CryptoPlatform.dolarApp:
        return 'assets/platforms/dolarapp_logo.png';
    }
  }
}
