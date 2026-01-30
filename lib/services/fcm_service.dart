import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'fcm_background_handler.dart';

/// Servicio para manejar Firebase Cloud Messaging (FCM)
///
/// Responsabilidades:
/// - Inicializar Firebase Messaging
/// - Solicitar permisos de notificaciones
/// - Suscribirse al topic "all_users"
/// - Manejar notificaciones en foreground, background y cuando la app está cerrada
/// - Navegar según el tipo de notificación recibida
class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Inicializa el servicio FCM
  ///
  /// [navigatorKey] es opcional pero recomendado para navegación desde notificaciones
  /// [autoSubscribe] si es true, se suscribe automáticamente al topic (default: true)
  static Future<void> initialize({
    GlobalKey<NavigatorState>? navigatorKey,
    bool autoSubscribe = true,
  }) async {
    if (_initialized) {
      print('⚠️ FCM ya está inicializado');
      return;
    }

    _navigatorKey = navigatorKey;

    try {
      // 1. Inicializar notificaciones locales para Android
      await _initializeLocalNotifications();

      // 2. Solicitar permisos (crítico para iOS)
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('📱 Estado de permisos: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // 3. Obtener token FCM PRIMERO (necesario para suscribirse)
        // Intentar con retry logic porque Google Play Services puede tardar en emuladores
        String? token;
        const maxTokenRetries = 3;

        for (int attempt = 1; attempt <= maxTokenRetries; attempt++) {
          try {
            print(
                '🔍 Obteniendo token FCM (intento $attempt/$maxTokenRetries)...');
            // Timeout progresivo: 20s, 30s, 40s (más tiempo en emuladores)
            token = await _messaging.getToken().timeout(
                  Duration(seconds: 15 + (attempt * 5)),
                );

            if (token != null && token.isNotEmpty) {
              print(
                  '✅ Token FCM obtenido exitosamente: ${token.substring(0, 30)}...');
              print('📱 Token completo (cópialo para debugging):');
              print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              print(token);
              print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              if (Platform.isIOS) {
                print('🍎 iOS: Si no recibís notificaciones en el iPhone, subí la clave APNs (.p8) en Firebase:');
                print('   Firebase Console → Configuración → Cloud Messaging → Configuración de apps de Apple.');
                print('   Ver ios/IOS_PUSH_SETUP.md');
              }
              break; // Éxito, salir del loop
            } else {
              print('⚠️ Token FCM es null o vacío');
            }
          } catch (e) {
            final errorMsg = e.toString().toLowerCase();
            if (errorMsg.contains('timeout')) {
              print(
                  '⏱️ Timeout al obtener token (intento $attempt/$maxTokenRetries)');
              print(
                  '   Google Play Services está tardando más de lo esperado...');
              if (attempt < maxTokenRetries) {
                print(
                    '   Esperando ${attempt * 3} segundos antes de reintentar...');
                await Future.delayed(Duration(seconds: attempt * 3));
                continue;
              } else {
                print(
                    '❌ No se pudo obtener token después de $maxTokenRetries intentos');
                print(
                    '⚠️ Esto es común en emuladores. Google Play Services puede estar lento.');
                print(
                    '💡 Solución: Prueba en un dispositivo físico o espera más tiempo.');

                // Intentar obtener el token en background después de un delay
                print(
                    '🔄 Intentando obtener token en background (puede tardar más)...');
                _obtenerTokenEnBackground(autoSubscribe);
                break;
              }
            } else {
              print('❌ Error al obtener token FCM: $e');
              if (attempt < maxTokenRetries) {
                await Future.delayed(Duration(seconds: 2));
                continue;
              } else {
                print('⚠️ Sin token, no se puede suscribir al topic');
                break;
              }
            }
          }
        }

        // 4. Suscribirse al topic exacto "all_users" solo si autoSubscribe es true
        // Esperar a que se complete (no en background)
        if (autoSubscribe && token != null) {
          print('🔍 Intentando suscribirse al topic "all_users"...');
          await subscribeToTopic();
        } else if (!autoSubscribe) {
          print(
              'ℹ️ Auto-suscripción deshabilitada (notificaciones desactivadas por el usuario)');
        } else if (token == null) {
          print('⚠️ No se puede suscribir ahora: token FCM no disponible');
          print(
              '   La suscripción se intentará automáticamente cuando el token esté disponible');
        }

        // 5. Configurar handler para background (debe ser top-level function)
        FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler);

        // 6. Configurar handlers de notificaciones
        _setupMessageHandlers();

        _initialized = true;
        print('✅ FCM Service inicializado correctamente');

        // Ejecutar diagnóstico después de un delay para verificar todo
        Future.delayed(const Duration(seconds: 3), () {
          diagnosticar();
        });
      } else {
        print('⚠️ Permisos de notificaciones denegados');
        print(
            '   El usuario debe aceptar permisos para recibir notificaciones');
      }
    } catch (e) {
      print('❌ Error al inicializar FCM Service: $e');
      print('🔍 Ejecutando diagnóstico...');
      // Ejecutar diagnóstico incluso si falla la inicialización
      Future.delayed(const Duration(seconds: 2), () {
        diagnosticar();
      });
      // Continuar aunque falle para que la app arranque
    }
  }

  /// Inicializa las notificaciones locales (necesario para mostrar notificaciones en foreground en Android)
  static Future<void> _initializeLocalNotifications() async {
    // Configuración para Android (icono blanco/transparente para la barra de notificaciones)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

    // Configuración para iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Crear canal de notificaciones para Android (opcional, el backend ya lo especifica)
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'dolar_argentina_channel',
        'Dólar Argentina Notificaciones',
        description: 'Notificaciones sobre cotizaciones del dólar',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Configura los handlers para diferentes estados de la app
  static void _setupMessageHandlers() {
    // Handler para cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 Notificación recibida en foreground:');
      print('   Título: ${message.notification?.title}');
      print('   Cuerpo: ${message.notification?.body}');
      print('   Data: ${message.data}');

      _handleForegroundMessage(message);
    });

    // Handler para cuando el usuario toca una notificación y la app está en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 Usuario tocó notificación (app en background):');
      print('   Data: ${message.data}');
      _handleNotificationTap(message);
    });

    // Handler para cuando el usuario toca una notificación y la app estaba cerrada
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print('📨 Usuario tocó notificación (app estaba cerrada):');
        print('   Data: ${message.data}');
        // Esperar un poco para que la app termine de inicializar
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationTap(message);
        });
      }
    });
  }

  /// Maneja notificaciones cuando la app está en foreground
  /// Muestra una notificación local para que el usuario la vea
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // Mostrar notificación local (icono circular blanco para la barra)
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'dolar_argentina_channel',
      'Dólar Argentina Notificaciones',
      channelDescription: 'Notificaciones sobre cotizaciones del dólar',
      icon: 'ic_notification',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data
          .toString(), // Pasar data como payload para poder accederla al tocar
    );
  }

  /// Maneja cuando el usuario toca una notificación local (foreground)
  static void _onNotificationTapped(NotificationResponse response) {
    print('📨 Usuario tocó notificación local');
    print('   Payload: ${response.payload}');

    // Navegar a home cuando se toca la notificación local (evitar crash si context ya no está montado)
    final ctx = _navigatorKey?.currentContext;
    if (ctx != null && ctx.mounted) {
      ctx.go('/');
      print('✅ Navegado a home desde notificación local');
    } else {
      print('⚠️ NavigatorKey no disponible para navegación local');
      // Reintentar después de un delay
      Future.delayed(const Duration(seconds: 1), () {
        _onNotificationTapped(response);
      });
    }
  }

  /// Navega según el tipo de notificación recibida
  /// Ambos tipos ("apertura" y "cierre") navegan a home
  static void _handleNotificationTap(RemoteMessage message) {
    final tipo = message.data['tipo'] as String?;

    final ctx = _navigatorKey?.currentContext;
    if (ctx == null || !ctx.mounted) {
      print('⚠️ NavigatorKey no disponible, intentando navegar más tarde...');
      Future.delayed(const Duration(seconds: 2), () {
        _handleNotificationTap(message);
      });
      return;
    }

    print('🧭 Navegando según tipo: $tipo');

    // Ambos tipos navegan a home (donde se muestra el dólar blue por defecto)
    if (tipo == 'apertura' || tipo == 'cierre') {
      ctx.go('/');
      print('✅ Navegado a home');
    } else {
      print('⚠️ Tipo desconocido: $tipo, navegando a home');
      ctx.go('/');
    }
  }

  /// Obtiene el token FCM en background (para cuando falla en la inicialización)
  static Future<void> _obtenerTokenEnBackground(bool autoSubscribe) async {
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        print('🔄 Reintentando obtener token FCM en background...');
        final token =
            await _messaging.getToken().timeout(const Duration(seconds: 30));

        if (token != null && token.isNotEmpty) {
          print(
              '✅ Token FCM obtenido en background: ${token.substring(0, 30)}...');
          print('📱 Token completo:');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print(token);
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          // Intentar suscribirse ahora que tenemos el token
          if (autoSubscribe) {
            print(
                '🔍 Intentando suscribirse al topic ahora que tenemos el token...');
            await subscribeToTopic();
          }
        }
      } catch (e) {
        print('⚠️ No se pudo obtener token en background: $e');
        print('💡 Recomendación: Prueba en un dispositivo físico');
      }
    });
  }

  /// Obtiene el token FCM actual (útil para debugging)
  static Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('❌ Error al obtener token FCM: $e');
      return null;
    }
  }

  /// Suscribe al topic "all_users" (método público para usar desde settings)
  /// Con retry logic y manejo de errores mejorado
  static Future<void> subscribeToTopic() async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Esperar un poco antes de intentar (especialmente en el primer intento)
        if (attempt == 1) {
          await Future.delayed(const Duration(seconds: 1));
        }

        // Intentar suscribirse con timeout
        print('   Intento $attempt: Suscribiéndose al topic "all_users"...');
        await _messaging
            .subscribeToTopic('all_users')
            .timeout(const Duration(seconds: 10));

        print('✅ ✅ ✅ SUSCRITO AL TOPIC "all_users" EXITOSAMENTE ✅ ✅ ✅');
        print('   La app ahora puede recibir notificaciones push');
        return; // Éxito, salir del loop
      } catch (e) {
        final errorMessage = e.toString().toLowerCase();

        // Si es un error de servicio no disponible, esperar más antes de reintentar
        if (errorMessage.contains('service_not_available') ||
            errorMessage.contains('networkcapability')) {
          print(
              '⚠️ Google Play Services no disponible (intento $attempt/$maxRetries). Esperando...');

          if (attempt < maxRetries) {
            await Future.delayed(retryDelay * attempt); // Delay progresivo
            continue;
          } else {
            print(
                '❌ No se pudo suscribir después de $maxRetries intentos. Google Play Services puede no estar disponible.');
            // No rethrow para evitar que la app se bloquee
            return;
          }
        } else {
          // Otro tipo de error
          print(
              '❌ Error al suscribirse al topic (intento $attempt/$maxRetries): $e');
          if (attempt < maxRetries) {
            await Future.delayed(retryDelay);
            continue;
          } else {
            print(
                '⚠️ No se pudo suscribir después de $maxRetries intentos. La suscripción se intentará automáticamente cuando Google Play Services esté disponible.');
            // No rethrow para evitar que la app se bloquee
            return;
          }
        }
      }
    }
  }

  /// Cancela la suscripción al topic (útil para testing o si el usuario desactiva notificaciones)
  /// Con manejo de errores mejorado
  static Future<void> unsubscribeFromTopic() async {
    try {
      await _messaging
          .unsubscribeFromTopic('all_users')
          .timeout(const Duration(seconds: 10));
      print('✅ Desuscrito del topic: all_users');
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();

      // Si es un error de servicio no disponible, solo loguear sin rethrow
      if (errorMessage.contains('service_not_available') ||
          errorMessage.contains('networkcapability')) {
        print(
            '⚠️ Google Play Services no disponible. La desuscripción se intentará automáticamente cuando esté disponible.');
      } else {
        print('❌ Error al desuscribirse del topic: $e');
      }
      // No rethrow para evitar que la app se bloquee
    }
  }

  /// Muestra una notificación de prueba localmente (sin necesidad de Firebase)
  /// Útil para probar que las notificaciones funcionan correctamente
  static Future<void> showTestNotification({
    String title = 'Apertura del mercado',
    String body = 'El dólar blue subió a \$1.485,00',
    String tipo = 'apertura',
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'dolar_argentina_channel',
        'Dólar Argentina Notificaciones',
        channelDescription: 'Notificaciones sobre cotizaciones del dólar',
        icon: 'ic_notification',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        title,
        body,
        details,
        payload: 'tipo=$tipo',
      );

      print('✅ Notificación de prueba mostrada: $title');
    } catch (e) {
      print('❌ Error al mostrar notificación de prueba: $e');
    }
  }

  /// Obtiene el token FCM y lo imprime en consola (útil para debugging)
  /// También lo retorna para copiarlo si es necesario
  static Future<String?> printToken() async {
    try {
      final token = await getToken();
      if (token != null) {
        print('📱 Token FCM (cópialo para pruebas):');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print(token);
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return token;
      } else {
        print('⚠️ No se pudo obtener el token FCM');
        return null;
      }
    } catch (e) {
      print('❌ Error al obtener token FCM: $e');
      return null;
    }
  }

  /// Diagnóstico completo del estado de FCM
  /// Útil para debugging cuando las notificaciones no llegan
  static Future<void> diagnosticar() async {
    print('\n🔍 ===== DIAGNÓSTICO FCM =====');

    // 1. Verificar inicialización
    print(
        '1️⃣ Estado de inicialización: ${_initialized ? "✅ Inicializado" : "❌ No inicializado"}');

    // 2. Verificar permisos
    try {
      final settings = await _messaging.getNotificationSettings();
      print('2️⃣ Permisos: ${settings.authorizationStatus}');
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        print('   ⚠️ Los permisos NO están autorizados');
      }
    } catch (e) {
      print('2️⃣ Error al verificar permisos: $e');
    }

    // 3. Verificar token
    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        print('3️⃣ Token FCM: ✅ Disponible (${token.length} caracteres)');
        print(
            '   Primeros 30 caracteres: ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
      } else {
        print('3️⃣ Token FCM: ❌ No disponible');
      }
    } catch (e) {
      print('3️⃣ Token FCM: ❌ Error al obtener: $e');
    }

    // 4. Verificar suscripción al topic (no hay API directa, pero podemos intentar suscribirnos de nuevo)
    print('4️⃣ Suscripción al topic "all_users": Verificando...');
    try {
      // Intentar suscribirse de nuevo para verificar
      await _messaging
          .subscribeToTopic('all_users')
          .timeout(const Duration(seconds: 5));
      print('   ✅ Suscripción al topic verificada');
    } catch (e) {
      print('   ⚠️ No se pudo verificar suscripción: $e');
      print(
          '   Esto puede ser normal si Google Play Services no está disponible');
    }

    // 5. Verificar configuración de Firebase
    try {
      final app = Firebase.app();
      print('5️⃣ Firebase App: ✅ Configurado (${app.name})');
    } catch (e) {
      print('5️⃣ Firebase App: ❌ No configurado: $e');
    }

    // 6. Recordatorio iOS: APNs en Firebase (si no llegan notificaciones)
    if (Platform.isIOS) {
      print('6️⃣ iOS: Si no recibís notificaciones, subí la clave APNs (.p8) en Firebase:');
      print('   Firebase Console → Configuración → Cloud Messaging → Configuración de apps de Apple.');
      print('   Ver ios/IOS_PUSH_SETUP.md o docs/IOS_PUSH_CHECKLIST.md');
    }

    print('🔍 ===== FIN DIAGNÓSTICO =====\n');
  }
}
