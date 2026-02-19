import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Widget para mostrar un banner de AdMob
class AdBanner extends StatefulWidget {
  /// Ad Unit ID personalizado (opcional). Si no se provee, usa el ID por defecto.
  final String? customAdUnitId;
  
  const AdBanner({super.key, this.customAdUnitId});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  String? _errorMessage;
  Timer? _loadTimeout;
  AdSize? _currentAdSize;

  @override
  void initState() {
    super.initState();
    // No podemos cargar aquí porque no tenemos contexto
    // Cargaremos en el primer build
  }

  // Detecta si es tablet (ancho >= 600px)
  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.shortestSide >= 600;
  }

  // Obtiene el tamaño de banner apropiado según el dispositivo
  AdSize _getAdSize(BuildContext context) {
    if (_isTablet(context)) {
      // Para tablets: Leaderboard (728x90) - ancho completo, mejor para tablets
      return AdSize.leaderboard;
    }
    // Para phones: Large Banner (320x100) - funciona bien en móviles
    return AdSize.largeBanner;
  }

  void _loadBannerAdWithContext(BuildContext context) {
    final newSize = _getAdSize(context);

    if (_bannerAd != null && _isAdLoaded) {
      // Si ya hay un banner cargado y el tamaño es correcto, no recargar
      if (_currentAdSize == newSize) {
        return;
      }
      // Si cambió el tamaño, limpiar el anterior
      _bannerAd?.dispose();
      _bannerAd = null;
      _isAdLoaded = false;
    }

    // Si ya hay una carga en curso, no reiniciar (evita resetear el timeout en cada rebuild)
    if (_bannerAd != null && !_isAdLoaded && _errorMessage == null) {
      return;
    }
    // Si ya falló o dio timeout, no reiniciar en cada rebuild (en TestFlight/Release el fill puede ser bajo)
    if (_errorMessage != null) {
      return;
    }

    _errorMessage = null;
    _isAdLoaded = false;
    final adUnitId = _getAdUnitId();
    _currentAdSize = _getAdSize(context);

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: _currentAdSize!,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _loadTimeout?.cancel();
          _loadTimeout = null;
          if (mounted) setState(() => _isAdLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          _loadTimeout?.cancel();
          _loadTimeout = null;
          print('❌ Error al cargar banner: $error');
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _errorMessage = error.message;
            });
          }
          ad.dispose();
        },
        onAdOpened: (_) => print('✅ Banner abierto'),
        onAdClosed: (_) => print('✅ Banner cerrado'),
      ),
    );

    _bannerAd?.load();

    // Si no carga en 12 s, mostrar "Anuncio no disponible" en lugar de quedar en "Cargando..."
    _loadTimeout = Timer(const Duration(seconds: 12), () {
      if (!mounted || _isAdLoaded || _errorMessage != null) return;
      _loadTimeout = null;
      setState(() {
        _errorMessage = 'Tiempo de espera agotado';
        _bannerAd?.dispose();
        _bannerAd = null;
        _currentAdSize = null;
      });
    });
  }

  String _getAdUnitId() {
    // Si se provee un customAdUnitId, usarlo (solo en release mode)
    if (widget.customAdUnitId != null && kReleaseMode) {
      return widget.customAdUnitId!;
    }
    
    // Debug = test IDs. Release (TestFlight, App Store) = IDs reales de producción.
    const testIos = 'ca-app-pub-3940256099942544/2934735716';
    const testAndroid = 'ca-app-pub-3940256099942544/6300978111';
    const realIos = 'ca-app-pub-6119092953994163/2879928015';
    // Banner home Android (AdMob - app Android)
    const realAndroid = 'ca-app-pub-6119092953994163/5181773243';

    final useReal = kReleaseMode;
    if (Platform.isAndroid) {
      return useReal ? realAndroid : testAndroid;
    }
    if (Platform.isIOS) {
      return useReal ? realIos : testIos;
    }
    return useReal ? realIos : testIos;
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cargar el banner en el primer build o si cambió el tamaño
    _loadBannerAdWithContext(context);

    final isTablet = _isTablet(context);
    final adSize = _getAdSize(context);
    final bannerHeight = adSize.height.toDouble();

    // Si hay error, mostrar mensaje
    if (_errorMessage != null) {
      return Container(
        margin: EdgeInsets.only(
          left: isTablet ? 0 : 16,
          right: isTablet ? 0 : 16,
          top: 8,
          bottom: 8,
        ),
        height: bannerHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2C)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            kReleaseMode ? 'Anuncio no disponible' : 'Error al cargar anuncio',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // Si no está cargado, mostrar placeholder
    if (!_isAdLoaded || _bannerAd == null) {
      return Container(
        margin: EdgeInsets.only(
          left: isTablet ? 0 : 16,
          right: isTablet ? 0 : 16,
          top: 8,
          bottom: 8,
        ),
        height: bannerHeight,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2C)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF3C3C3C)
                : (Colors.grey[300] ?? const Color(0xFFE0E0E0)),
          ),
        ),
        child: Center(
          child: Text(
            'Cargando anuncio...',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // Banner adaptativo según dispositivo
    return Container(
      margin: EdgeInsets.only(
        left: isTablet ? 0 : 16,
        right: isTablet ? 0 : 16,
        top: 8,
        bottom: 8,
      ),
      width: double.infinity,
      height: bannerHeight,
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
