import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../settings/settings_service.dart';
import '../../../services/version_checker.dart';
import '../../../widgets/update_dialogs.dart';
import '../../../app/router/app_router.dart';

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

      print('🔍 [SPLASH] Iniciando verificación de actualización...');
      final updateInfo = await VersionChecker.verificarActualizacion();

      print(
          '🔍 [SPLASH] updateInfo recibido: ${updateInfo != null ? "NO NULL" : "NULL"}');
      if (updateInfo != null) {
        print('🔍 [SPLASH] Tipo de actualización: ${updateInfo.type}');
      }

      if (mounted && updateInfo != null) {
        if (updateInfo.type == UpdateType.force) {
          print('🔍 [SPLASH] Mostrando FORCE UPDATE');
          // FORCE UPDATE: Bloquear la app
          setState(() {
            _forceUpdateBlocking = true;
          });
          mostrarDialogoForceUpdate(context, updateInfo);
        } else if (updateInfo.type == UpdateType.kind) {
          print('🔍 [SPLASH] KIND UPDATE detectado, programando diálogo...');
          // KIND UPDATE: Mostrar opcionalmente (después de navegar)
          // Esperar a que navegue primero y usar navigatorKey para obtener contexto válido
          Future.delayed(const Duration(milliseconds: 2000), () {
            _mostrarDialogoKindUpdateConRetry(updateInfo, intento: 1);
          });
        } else {
          print(
              '🔍 [SPLASH] No hay actualización necesaria (tipo: ${updateInfo.type})');
        }
      } else {
        print('⚠️ [SPLASH] updateInfo es null o widget no está montado');
      }
    } catch (e, stackTrace) {
      print('❌ [SPLASH] Error verificando actualización: $e');
      print('❌ [SPLASH] Stack trace: $stackTrace');
      // En caso de error, NO bloquear la app
      // Continuar normalmente
    }
  }

  void _navegarAlHome() {
    if (mounted && !_forceUpdateBlocking) {
      // Usar replace para que no se pueda volver al splash
      context.go('/home');
    }
  }

  void _mostrarDialogoKindUpdateConRetry(UpdateInfo updateInfo,
      {int intento = 1}) {
    print(
        '🔍 [SPLASH] Intentando mostrar diálogo KIND UPDATE (intento $intento)...');

    // Usar WidgetsBinding para asegurar que el contexto esté listo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contextValido = navigatorKey.currentContext;
      print(
          '🔍 [SPLASH] Contexto válido (intento $intento): ${contextValido != null ? "SÍ" : "NO"}');

      if (contextValido != null) {
        print('🔍 [SPLASH] Llamando a mostrarDialogoKindUpdate...');
        try {
          mostrarDialogoKindUpdate(contextValido, updateInfo);
          print('✅ [SPLASH] Diálogo mostrado exitosamente');
        } catch (e) {
          print('❌ [SPLASH] Error al mostrar diálogo: $e');
          if (intento < 3) {
            Future.delayed(const Duration(milliseconds: 500), () {
              _mostrarDialogoKindUpdateConRetry(updateInfo,
                  intento: intento + 1);
            });
          }
        }
      } else {
        print(
            '⚠️ [SPLASH] No se pudo obtener contexto válido (intento $intento)');
        if (intento < 5) {
          // Intentar de nuevo con más tiempo
          Future.delayed(const Duration(milliseconds: 500), () {
            _mostrarDialogoKindUpdateConRetry(updateInfo, intento: intento + 1);
          });
        } else {
          print(
              '❌ [SPLASH] Máximo de intentos alcanzado, no se pudo mostrar el diálogo');
        }
      }
    });
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
