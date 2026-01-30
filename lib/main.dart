import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/router/app_router.dart';
import 'app/theme/app_theme.dart';
import 'features/settings/providers/settings_providers.dart';
import 'services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Inicializar Firebase (debe ser antes de cualquier otro servicio de Firebase)
  try {
    await Firebase.initializeApp();
    print('✅ Firebase inicializado correctamente');
  } catch (e) {
    print('❌ Error al inicializar Firebase: $e');
    print('⚠️ Verifica que los archivos google-services.json (Android) y GoogleService-Info.plist (iOS) estén presentes');
  }

  // Crashlytics: habilitar y capturar crashes (solo si Firebase está inicializado)
  try {
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = (details) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (_) {}

  runZonedGuarded<Future<void>>(() async {
    runApp(
      const ProviderScope(
        child: DolarArgentinaApp(),
      ),
    );
  }, (error, stack) {
    try {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {}
  });

  // Inicializar servicios pesados DESPUÉS de que la app arranque (en background)
  _initializeHeavyServices();
}

/// Inicializa servicios pesados en background después de que la app arranque
/// Esto mejora la experiencia del usuario al reducir el tiempo en el splash screen
void _initializeHeavyServices() {
  // Ejecutar en background sin bloquear
  Future.microtask(() async {
    // Esperar un momento para que la app termine de renderizar
    await Future.delayed(const Duration(milliseconds: 300));

    // Inicializar AdMob en background (no bloquea la UI)
    _initializeAdMob();

    // Inicializar FCM en background (puede tardar mucho, especialmente en emuladores)
    _initializeFCM();
  });
}

/// Inicializa AdMob de forma asíncrona (fire and forget)
void _initializeAdMob() {
  MobileAds.instance.initialize().then((_) {
    print('✅ AdMob inicializado correctamente');
  }).catchError((e) {
    print('⚠️ Error al inicializar AdMob: $e');
  });
}

/// Inicializa FCM de forma asíncrona (fire and forget)
void _initializeFCM() {
  SharedPreferences.getInstance().then((prefs) {
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    
    FCMService.initialize(
      navigatorKey: navigatorKey,
      autoSubscribe: notificationsEnabled,
    ).catchError((e) {
      print('⚠️ Error al inicializar FCM Service: $e');
    });
  }).catchError((e) {
    print('⚠️ Error al obtener SharedPreferences: $e');
  });
}

class DolarArgentinaApp extends ConsumerWidget {
  const DolarArgentinaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == 'dark';

    return MaterialApp.router(
      title: 'Dólar Argentina',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
