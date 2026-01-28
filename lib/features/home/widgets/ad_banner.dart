import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Widget para mostrar un banner de AdMob
/// Usa IDs de prueba durante desarrollo
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    // IDs de prueba de AdMob (funcionan en iOS y Android)
    // Reemplazar con tus IDs reales cuando publiques la app
    final adUnitId = _getAdUnitId();

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.largeBanner, // Banner más grande (320x100) para más ingresos
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Error al cargar banner: $error');
          setState(() {
            _isAdLoaded = false;
            _errorMessage = error.message;
          });
          ad.dispose();
        },
        onAdOpened: (_) => print('✅ Banner abierto'),
        onAdClosed: (_) => print('✅ Banner cerrado'),
      ),
    );

    _bannerAd?.load();
  }

  String _getAdUnitId() {
    // IDs de AdMob
    // IMPORTANTE: Usar test IDs durante desarrollo
    // Los anuncios reales solo funcionan cuando la app está publicada en App Store/Play Store

    // Test IDs (funcionan siempre, no generan ingresos)
    // iOS Test: ca-app-pub-3940256099942544/2934735716
    // Android Test: ca-app-pub-3940256099942544/6300978111

    // IDs Reales (solo funcionan cuando la app está publicada)
    // iOS Real: ca-app-pub-6119092953994163/2879928015
    // Android Real: (configurar cuando crees la app en AdMob)

    // Detecta automáticamente la plataforma
    if (Platform.isAndroid) {
      return 'ca-app-pub-3940256099942544/6300978111'; // Test ID Android
    } else if (Platform.isIOS) {
      // Cambiar a test ID durante desarrollo, real cuando publiques
      return 'ca-app-pub-3940256099942544/2934735716'; // Test ID iOS (cambiar a real cuando publiques)
      // return 'ca-app-pub-6119092953994163/2879928015'; // Real ID iOS (descomentar cuando publiques)
    }

    // Fallback
    return 'ca-app-pub-3940256099942544/2934735716'; // Test ID iOS
  }

  @override
  void dispose() {
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
            'Error al cargar anuncio',
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
