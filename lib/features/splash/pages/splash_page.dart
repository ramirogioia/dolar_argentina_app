import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../settings/settings_service.dart';
import '../../../services/version_checker.dart';
import '../../../widgets/update_dialogs.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String _themeMode = 'light'; // Por defecto light
  bool _forceUpdateBlocking = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    // Modo inmersivo: oculta barras del sistema para screenshots limpios
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Verificar actualización en paralelo
    _verificarActualizacion();

    // Esperar exactamente 2 segundos antes de navegar al home (si no hay force update)
    Timer(const Duration(seconds: 2), () {
      if (mounted && !_forceUpdateBlocking) {
        _navegarAlHome();
      }
    });
  }

  Future<void> _verificarActualizacion() async {
    try {
      // Esperar un poco para que la UI se cargue
      await Future.delayed(const Duration(milliseconds: 500));

      final updateInfo = await VersionChecker.verificarActualizacion();

      if (mounted && updateInfo != null) {
        if (updateInfo.type == UpdateType.force) {
          // FORCE UPDATE: Bloquear la app
          setState(() {
            _forceUpdateBlocking = true;
          });
          mostrarDialogoForceUpdate(context, updateInfo);
        } else if (updateInfo.type == UpdateType.kind) {
          // KIND UPDATE: Mostrar opcionalmente (después de navegar)
          // Esperar a que navegue primero
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              mostrarDialogoKindUpdate(context, updateInfo);
            }
          });
        }
      }
    } catch (e) {
      print('❌ Error verificando actualización: $e');
      // En caso de error, NO bloquear la app
      // Continuar normalmente
    }
  }

  void _navegarAlHome() {
    if (mounted && !_forceUpdateBlocking) {
      // Usar replace para que no se pueda volver al splash
      context.go('/');
    }
  }

  Future<void> _loadTheme() async {
    final service = SettingsService();
    final theme = await service.getThemeMode();
    if (mounted) {
      setState(() {
        _themeMode = theme;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    // Usar el menor entre ancho y alto para asegurar que el logo se vea completo
    final logoSize =
        (screenWidth < screenHeight ? screenWidth : screenHeight) * 0.6;

    // Determinar el color de fondo según el tema guardado
    final backgroundColor = _themeMode == 'dark'
        ? const Color(0xFF121212) // Negro del tema oscuro
        : const Color(0xFFD9EDF7); // Celeste del tema claro

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SizedBox.expand(
        child: Center(
          child: Image.asset(
            'assets/icon/app_icon_final.png',
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
