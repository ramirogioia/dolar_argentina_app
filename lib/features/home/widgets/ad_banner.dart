import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Widget para mostrar un banner de AdMob
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  String? _errorMessage;
  Timer? _loadTimeout;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _errorMessage = null;
    _isAdLoaded = false;
    final adUnitId = _getAdUnitId();

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.largeBanner,
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
      });
    });
  }

  String _getAdUnitId() {
    // Debug = test IDs. Release (TestFlight, App Store) = IDs reales de producción.
    const testIos = 'ca-app-pub-3940256099942544/2934735716';
    const testAndroid = 'ca-app-pub-3940256099942544/6300978111';
    const realIos = 'ca-app-pub-6119092953994163/2879928015';
    // Crear unidad "Banner" para la app Android en AdMob y reemplazar el número por el ID que te den:
    const realAndroid = 'ca-app-pub-6119092953994163/2879928015'; // Reemplazar /2879928015 por tu Android banner unit ID

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
    // Si hay error, mostrar mensaje
    if (_errorMessage != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 100, // Altura de Large Banner (320x100)
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
        margin: const EdgeInsets.all(16),
        height: 100, // Altura de Large Banner (320x100)
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2C2C2C)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF3C3C3C)
                : Colors.grey[300]!,
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

    // El banner de AdMob Large Banner tiene un tamaño de 320x100
    // Usamos SizedBox con altura fija para evitar problemas de layout infinito
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
