import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Ocultar el splash nativo inmediatamente para que solo se vea este (el grande)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // Esperar exactamente 2 segundos antes de navegar al home
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        // Usar replace para que no se pueda volver al splash
        context.go('/');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = screenWidth * 0.7; // Logo más grande (70% del ancho)

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Center(
          child: Image.asset(
            'assets/icon/app_icon.png',
            width: logoSize,
            height: logoSize,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
