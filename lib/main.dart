import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'services/review_service.dart';

/// True si Firebase se inicializó correctamente (evita crashes al usar Crashlytics/FCM).
bool _firebaseInitialized = false;

void main() {
  // Toda la inicialización y runApp deben ejecutarse en la MISMA Zone para evitar
  // "Zone mismatch" (crash en Android/Google devices). ensureInitialized + runApp
  // dentro del mismo runZonedGuarded.
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Modo captura para Store: pantalla limpia (sin barra de navegación ni estado).
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Inicializar Firebase (debe ser antes de cualquier otro servicio de Firebase)
    try {
      await Firebase.initializeApp();
      _firebaseInitialized = true;
      print('✅ Firebase inicializado correctamente');
      // iOS: avisar a nativo que Firebase está listo para asignar el token APNs si llegó antes
      if (Platform.isIOS) {
        try {
          await const MethodChannel('com.rgioia.dolarargentina/fcm')
              .invokeMethod<void>('onFirebaseReady');
        } catch (_) {}
      }
    } catch (e) {
      print('❌ Error al inicializar Firebase: $e');
      print(
          '⚠️ Verifica que los archivos google-services.json (Android) y GoogleService-Info.plist (iOS) estén presentes');
      FCMService.setFirebaseInitError(e.toString());
    }

    // Crashlytics: solo si Firebase está listo; handlers nunca deben lanzar (Apple castiga crashes)
    if (_firebaseInitialized) {
      try {
        FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
        FlutterError.onError = (details) {
          try {
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          } catch (_) {}
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          try {
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          } catch (_) {}
          return true;
        };
      } catch (_) {}
    }

    runApp(
      const ProviderScope(
        child: DolarArgentinaApp(),
      ),
    );

    // Registrar apertura para solicitud de reseña (tras engagement)
    unawaited(ReviewService.recordLaunch());

    // Inicializar servicios pesados DESPUÉS de que la app arranque (en background)
    _initializeHeavyServices();
  }, (error, stack) {
    try {
      if (_firebaseInitialized) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
    } catch (_) {}
  });
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

/// Inicializa FCM de forma asíncrona (fire and forget).
/// Solo se ejecuta si Firebase inicializó bien; si no, evitaríamos crash al tocar Messaging.
void _initializeFCM() {
  if (!_firebaseInitialized) return;
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
    final locale = ref.watch(appLocaleProvider);

    return MaterialApp.router(
      title: 'Dólar Argentina',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
