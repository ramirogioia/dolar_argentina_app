enum CryptoPlatform {
  binance,
  kucoin,
  bybit,
  okx,
  bitget,
  dolarapp,
  airtm,
  lemon,
  astropay,
  cocoscrypto,
  fiwind;

  String get displayName {
    switch (this) {
      case CryptoPlatform.binance:
        return 'Binance';
      case CryptoPlatform.kucoin:
        return 'KuCoin';
      case CryptoPlatform.bybit:
        return 'Bybit';
      case CryptoPlatform.okx:
        return 'OKX';
      case CryptoPlatform.bitget:
        return 'Bitget';
      case CryptoPlatform.dolarapp:
        return 'DolarApp';
      case CryptoPlatform.airtm:
        return 'Airtm';
      case CryptoPlatform.lemon:
        return 'Lemon';
      case CryptoPlatform.astropay:
        return 'AstroPay';
      case CryptoPlatform.cocoscrypto:
        return 'Cocos Crypto';
      case CryptoPlatform.fiwind:
        return 'Fiwind';
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
      case CryptoPlatform.dolarapp:
        return 'assets/platforms/dolarapp_logo.png';
      case CryptoPlatform.airtm:
        return 'assets/platforms/airtm_logo.png';
      case CryptoPlatform.lemon:
        return 'assets/platforms/lemon_logo.png';
      case CryptoPlatform.astropay:
        return 'assets/platforms/astropay_logo.png';
      case CryptoPlatform.cocoscrypto:
        return 'assets/platforms/cocoscrypto_logo.png';
      case CryptoPlatform.fiwind:
        return 'assets/platforms/fiwind_logo.png';
    }
  }
}
