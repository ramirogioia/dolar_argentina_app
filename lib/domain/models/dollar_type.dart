enum DollarType {
  blue,
  official,
  tarjeta,
  mep,
  ccl,
  crypto;

  String get displayName {
    switch (this) {
      case DollarType.blue:
        return 'Dólar Blue';
      case DollarType.official:
        return 'Dólar Oficial';
      case DollarType.tarjeta:
        return 'Dólar Tarjeta';
      case DollarType.mep:
        return 'Dólar MEP';
      case DollarType.ccl:
        return 'Dólar CCL';
      case DollarType.crypto:
        return 'Dólar Cripto';
    }
  }
}
