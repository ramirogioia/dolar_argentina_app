enum Bank {
  nacion,
  santander,
  galicia,
  bbva,
  patagonia,
  supervielle,
  icbc,
  ciudad,
  comafi,
  credicoop,
  hipotecario;

  String get displayName {
    switch (this) {
      case Bank.nacion:
        return 'Banco Nación';
      case Bank.santander:
        return 'Banco Santander';
      case Bank.galicia:
        return 'Banco Galicia';
      case Bank.bbva:
        return 'Banco BBVA';
      case Bank.patagonia:
        return 'Banco Patagonia';
      case Bank.supervielle:
        return 'Banco Supervielle';
      case Bank.icbc:
        return 'Banco ICBC';
      case Bank.ciudad:
        return 'Banco Ciudad';
      case Bank.comafi:
        return 'Banco Comafi';
      case Bank.credicoop:
        return 'Banco Credicoop';
      case Bank.hipotecario:
        return 'Banco Hipotecario';
    }
  }

  // Rutas de los logos de cada banco
  String get logoPath {
    switch (this) {
      case Bank.nacion:
        return 'assets/banks/banco_nacion_logo.png';
      case Bank.santander:
        return 'assets/banks/banco_santander_logo.png';
      case Bank.galicia:
        return 'assets/banks/banco_galicia_logo.png';
      case Bank.bbva:
        return 'assets/banks/banco_bbva_logo.png';
      case Bank.patagonia:
        return 'assets/banks/banco_patagonia_logo.png';
      case Bank.supervielle:
        return 'assets/banks/banco_supervielle_logo.png';
      case Bank.icbc:
        return 'assets/banks/banco_icbc_logo.png';
      case Bank.ciudad:
        return 'assets/banks/banco_ciudad_logo.png';
      case Bank.comafi:
        return 'assets/banks/banco_comafi_logo.png';
      case Bank.credicoop:
        return 'assets/banks/banco_credicoop_logo.png';
      case Bank.hipotecario:
        return 'assets/banks/banco_hipotecario_logo.png';
    }
  }
}
