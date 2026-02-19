import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'fcm_background_handler.dart';
import '../utils/logger.dart';

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

  static final List<String> _diagnosticLogs = [];
  static const int _maxDiagnosticLogs = 50;

  static void _diagnosticLog(String msg) {
    final line =
        '${DateTime.now().toIso8601String().substring(11, 23)} $msg';
    _diagnosticLogs.add(line);
    if (_diagnosticLogs.length > _maxDiagnosticLogs) {
      _diagnosticLogs.removeAt(0);
    }
  }

  /// Logs de diagnóstico para Debug (iOS/notificaciones). Copiar y pegar si hay error.
  static List<String> getDiagnosticLogs() =>
      List<String>.from(_diagnosticLogs);

  /// Solo iOS: log nativo APNs (AppDelegate).
  static Future<List<String>> getAPNsLog() async {
    if (!Platform.isIOS) return [];
    try {
      final list = await const MethodChannel('com.rgioia.dolarargentina/fcm')
          .invokeMethod<List<dynamic>>('getAPNsLog');
      return (list ?? []).map((e) => e.toString()).toList();
    } catch (e) {
      return ['Error al leer log iOS: $e'];
    }
  }

  /// Inicializa el servicio FCM
  ///
  /// [navigatorKey] es opcional pero recomendado para navegación desde notificaciones
  /// [autoSubscribe] si es true, se suscribe automáticamente al topic (default: true)
  static Future<void> initialize({
    GlobalKey<NavigatorState>? navigatorKey,
    bool autoSubscribe = true,
  }) async {
    if (_initialized) {
      Logger.warning('FCM ya está inicializado');
      return;
    }

    _navigatorKey = navigatorKey;

    try {
      _diagnosticLog('FCM initialize started');
      // Asegurar que Firebase esté inicializado (p. ej. si se tocó "Reinicializar FCM" o falló el init en main)
      try {
        Firebase.app();
      } catch (_) {
        _diagnosticLog('Firebase no listo, llamando Firebase.initializeApp()');
        await Firebase.initializeApp();
        _diagnosticLog('Firebase.initializeApp() OK');
      }
      // iOS: avisar a nativo que Firebase está listo (por si el token APNs llegó antes)
      if (Platform.isIOS) {
        try {
          await const MethodChannel('com.rgioia.dolarargentina/fcm')
              .invokeMethod<void>('onFirebaseReady');
          _diagnosticLog('onFirebaseReady sent to native');
        } catch (e) {
          _diagnosticLog('onFirebaseReady error: $e');
        }
      }

      // 1. Inicializar notificaciones locales para Android
      await _initializeLocalNotifications();

      // 2. Solicitar permisos del sistema en Android 13+ (API 33+)
      if (Platform.isAndroid) {
        final androidPlugin =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestNotificationsPermission();
          if (granted != null) {
            Logger.fcm(
                'Permiso POST_NOTIFICATIONS (Android 13+): ${granted ? "Concedido" : "Denegado"}');
          }
        }
      }

      // 3. Solicitar permisos de Firebase (crítico para iOS y Android)
      _diagnosticLog('Calling requestPermission...');
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      _diagnosticLog(
          'requestPermission result: ${settings.authorizationStatus}');
      Logger.fcm(
          'Estado de permisos Firebase: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // iOS: dar tiempo al sistema para entregar el token APNs después del permiso
        if (Platform.isIOS) {
          print('🍎 [FCM] iOS: esperando 2s para que el sistema entregue el token APNs...');
          await Future.delayed(const Duration(seconds: 2));
        }
        // 3. Obtener token FCM PRIMERO (necesario para suscribirse)
        // Intentar con retry logic porque Google Play Services puede tardar en emuladores
        String? token;
        const maxTokenRetries = 3;

        for (int attempt = 1; attempt <= maxTokenRetries; attempt++) {
          try {
            _diagnosticLog('getToken attempt $attempt/$maxTokenRetries');
            print(
                '🔍 [FCM] Obteniendo token FCM (intento $attempt/$maxTokenRetries)...');
            Logger.fcm(
                'Obteniendo token FCM (intento $attempt/$maxTokenRetries)...');
            print(
                '   [FCM] Esperando respuesta de Google Play Services/Firebase...');
            Logger.debug(
                'Esperando respuesta de Google Play Services/Firebase...',
                tag: 'FCM');

            // Timeout progresivo: 30s, 45s, 60s (más tiempo en emuladores)
            final timeoutSeconds = 30 + (attempt * 15);
            print('   [FCM] Timeout configurado: ${timeoutSeconds}s');
            Logger.debug('Timeout configurado: ${timeoutSeconds}s', tag: 'FCM');

            token = await _messaging.getToken().timeout(
              Duration(seconds: timeoutSeconds),
              onTimeout: () {
                print('⏱️ [FCM] Timeout después de ${timeoutSeconds}s');
                Logger.warning('Timeout después de ${timeoutSeconds}s',
                    tag: 'FCM');
                throw TimeoutException(
                    'Timeout al obtener token FCM después de ${timeoutSeconds}s');
              },
            );

            print('✅ [FCM] Respuesta recibida de getToken()');
            Logger.debug('Respuesta recibida de getToken()', tag: 'FCM');

            if (token != null && token.isNotEmpty) {
              _diagnosticLog('getToken OK (len=${token.length})');
              print('✅ ✅ ✅ [FCM] TOKEN FCM OBTENIDO EXITOSAMENTE ✅ ✅ ✅');
              Logger.info('TOKEN FCM OBTENIDO EXITOSAMENTE');
              print(
                  '   [FCM] Primeros 30 caracteres: ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
              Logger.info(
                  'Primeros 30 caracteres: ${token.substring(0, token.length > 30 ? 30 : token.length)}...',
                  tag: 'FCM');
              print('📱 [FCM] Token completo (cópialo para debugging):');
              Logger.info('Token completo (cópialo para debugging):',
                  tag: 'FCM');
              print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              Logger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                  tag: 'FCM');
              print(token);
              Logger.info(token, tag: 'FCM');
              print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
              Logger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
                  tag: 'FCM');
              if (Platform.isIOS) {
                print(
                    '🍎 [FCM] iOS: Si no recibís notificaciones en el iPhone, subí la clave APNs (.p8) en Firebase:');
                Logger.info(
                    'iOS: Si no recibís notificaciones en el iPhone, subí la clave APNs (.p8) en Firebase:',
                    tag: 'FCM');
                print(
                    '   [FCM] Firebase Console → Configuración → Cloud Messaging → Configuración de apps de Apple.');
                Logger.info(
                    'Firebase Console → Configuración → Cloud Messaging → Configuración de apps de Apple.',
                    tag: 'FCM');
              }
              break; // Éxito, salir del loop
            } else {
              _diagnosticLog('getToken returned null/empty');
              print('⚠️ ⚠️ ⚠️ [FCM] Token FCM es null o vacío ⚠️ ⚠️ ⚠️');
              Logger.warning('Token FCM es null o vacío');
              print(
                  '   [FCM] Esto es inesperado. Revisar configuración de Firebase.');
              Logger.warning(
                  'Esto es inesperado. Revisar configuración de Firebase.',
                  tag: 'FCM');
              // iOS: el token APNs puede llegar un poco después; esperar y reintentar
              if (Platform.isIOS && attempt < maxTokenRetries) {
                const delaySec = 3;
                print('🍎 [FCM] iOS: esperando ${delaySec}s antes de reintentar getToken()...');
                await Future.delayed(const Duration(seconds: delaySec));
              }
            }
          } catch (e) {
            _diagnosticLog('getToken attempt $attempt error: $e');
            final errorMsg = e.toString().toLowerCase();
            print('❌ [FCM] Error en intento $attempt: $e');
            Logger.error('Error en intento $attempt', error: e, tag: 'FCM');

            // Manejar SERVICE_NOT_AVAILABLE específicamente (común en emuladores)
            if (errorMsg.contains('service_not_available') ||
                errorMsg.contains('service_not_availabl')) {
              print(
                  '⚠️ [FCM] Google Play Services no está disponible (común en emuladores)');
              Logger.warning(
                  'Google Play Services no está disponible (común en emuladores)',
                  tag: 'FCM');

              if (attempt < maxTokenRetries) {
                // Esperar más tiempo para SERVICE_NOT_AVAILABLE (10s, 20s, 30s)
                final waitSeconds = attempt * 10;
                print(
                    '   [FCM] Esperando $waitSeconds segundos antes de reintentar...');
                Logger.debug(
                    'Esperando $waitSeconds segundos antes de reintentar...',
                    tag: 'FCM');
                await Future.delayed(Duration(seconds: waitSeconds));
                continue;
              } else {
                print(
                    '⚠️ [FCM] No se pudo obtener token después de $maxTokenRetries intentos');
                print(
                    '   [FCM] Esto es común en emuladores. Intentando en background...');
                Logger.warning(
                    'No se pudo obtener token después de $maxTokenRetries intentos',
                    tag: 'FCM');
                Logger.info(
                    'Esto es común en emuladores. Intentando en background...',
                    tag: 'FCM');
                _diagnosticLog('No token after retries, calling _obtenerTokenEnBackground');

                // Intentar obtener el token en background inmediatamente
                _obtenerTokenEnBackground(autoSubscribe);
                break;
              }
            } else if (errorMsg.contains('timeout') || e is TimeoutException) {
              print(
                  '⏱️ [FCM] Timeout al obtener token (intento $attempt/$maxTokenRetries)');
              Logger.warning(
                  'Timeout al obtener token (intento $attempt/$maxTokenRetries)',
                  tag: 'FCM');
              Logger.debug(
                  'Google Play Services está tardando más de lo esperado...',
                  tag: 'FCM');
              if (attempt < maxTokenRetries) {
                final waitSeconds = attempt * 5;
                print(
                    '   [FCM] Esperando $waitSeconds segundos antes de reintentar...');
                Logger.debug(
                    'Esperando $waitSeconds segundos antes de reintentar...',
                    tag: 'FCM');
                await Future.delayed(Duration(seconds: waitSeconds));
                continue;
              } else {
                print(
                    '⚠️ [FCM] No se pudo obtener token después de $maxTokenRetries intentos');
                print('   [FCM] Intentando en background...');
                Logger.error(
                    'No se pudo obtener token después de $maxTokenRetries intentos',
                    tag: 'FCM');
                Logger.warning(
                    'Esto es común en emuladores. Google Play Services puede estar lento.',
                    tag: 'FCM');
                Logger.info(
                    'Solución: Prueba en un dispositivo físico o espera más tiempo.',
                    tag: 'FCM');

                // Intentar obtener el token en background después de un delay
                Logger.debug(
                    'Intentando obtener token en background (puede tardar más)...',
                    tag: 'FCM');
                _obtenerTokenEnBackground(autoSubscribe);
                break;
              }
            } else {
              print('❌ [FCM] Error desconocido al obtener token FCM');
              Logger.error('Error al obtener token FCM', error: e, tag: 'FCM');
              Logger.debug('Tipo de error: ${e.runtimeType}', tag: 'FCM');
              if (attempt < maxTokenRetries) {
                final waitSeconds = attempt * 3;
                print(
                    '   [FCM] Esperando $waitSeconds segundos antes de reintentar...');
                await Future.delayed(Duration(seconds: waitSeconds));
                continue;
              } else {
                print('⚠️ [FCM] Sin token, no se puede suscribir al topic');
                print('   [FCM] Intentando obtener token en background...');
                Logger.warning('Sin token, no se puede suscribir al topic',
                    tag: 'FCM');
                Logger.debug('Intentando obtener token en background...',
                    tag: 'FCM');
                _obtenerTokenEnBackground(autoSubscribe);
                break;
              }
            }
          }
        }

        // 4. Suscribirse al topic exacto "all_users" solo si autoSubscribe es true
        // Esperar a que se complete (no en background)
        print('🔍 Estado antes de suscribirse:');
        print('   - autoSubscribe: $autoSubscribe');
        print('   - token disponible: ${token != null}');
        print('   - token length: ${token?.length ?? 0}');

        if (autoSubscribe && token != null) {
          print('🔍 Intentando suscribirse al topic "all_users"...');
          try {
            await subscribeToTopic();
            print('✅ Suscripción al topic completada (o intentada)');
          } catch (e) {
            print('❌ Error al suscribirse al topic: $e');
            print(
                '⚠️ La app puede no recibir notificaciones hasta que se resuelva esto');
          }
        } else if (!autoSubscribe) {
          print(
              'ℹ️ Auto-suscripción deshabilitada (notificaciones desactivadas por el usuario)');
          print(
              '   El usuario debe activar notificaciones en Configuración para recibir notificaciones');
        } else if (token == null) {
          print('⚠️ No se puede suscribir ahora: token FCM no disponible');
          print(
              '   La suscripción se intentará automáticamente cuando el token esté disponible');
          // Crítico para iOS: si getToken() devolvió null (p. ej. APNs aún no listo), reintentar en background y suscribir cuando llegue
          _obtenerTokenEnBackground(autoSubscribe);
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
      _diagnosticLog('FCM initialize failed: $e');
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
    print('🔍 Configurando handlers de notificaciones...');

    // Handler para cuando la app está en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 📨 📨 NOTIFICACIÓN RECIBIDA EN FOREGROUND 📨 📨 📨');
      print('   Título: ${message.notification?.title}');
      print('   Cuerpo: ${message.notification?.body}');
      print('   Data: ${message.data}');
      print('   Message ID: ${message.messageId}');
      print('   From: ${message.from}');

      _handleForegroundMessage(message);
    });

    print('✅ Handler de foreground configurado');

    // Handler para cuando el usuario toca una notificación y la app está en background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📨 📨 📨 USUARIO TOCÓ NOTIFICACIÓN (APP EN BACKGROUND) 📨 📨 📨');
      print('   Título: ${message.notification?.title}');
      print('   Cuerpo: ${message.notification?.body}');
      print('   Data: ${message.data}');
      _handleNotificationTap(message);
    });

    print('✅ Handler de background configurado');

    // Handler para cuando el usuario toca una notificación y la app estaba cerrada
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print(
            '📨 📨 📨 USUARIO TOCÓ NOTIFICACIÓN (APP ESTABA CERRADA) 📨 📨 📨');
        print('   Título: ${message.notification?.title}');
        print('   Cuerpo: ${message.notification?.body}');
        print('   Data: ${message.data}');
        // Esperar un poco para que la app termine de inicializar
        Future.delayed(const Duration(seconds: 1), () {
          _handleNotificationTap(message);
        });
      } else {
        print('ℹ️ No hay notificación pendiente (app abierta normalmente)');
      }
    });

    print('✅ Handler de app cerrada configurado');
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
    print('🔄 [FCM] Programando obtención de token en background...');
    Logger.debug('Programando obtención de token en background...', tag: 'FCM');

    // Esperar más tiempo en background para darle chance a Google Play Services
    Future.delayed(const Duration(seconds: 15), () async {
      try {
        print('🔄 [FCM] Reintentando obtener token FCM en background...');
        print('   [FCM] Esto puede tardar hasta 90 segundos en emuladores...');
        Logger.debug('Reintentando obtener token FCM en background...',
            tag: 'FCM');
        Logger.debug('Esto puede tardar hasta 90 segundos en emuladores...',
            tag: 'FCM');

        final token = await _messaging.getToken().timeout(
          const Duration(seconds: 90),
          onTimeout: () {
            print('⏱️ [FCM] Timeout en background después de 90s');
            Logger.warning('Timeout en background después de 90s', tag: 'FCM');
            throw TimeoutException('Timeout al obtener token en background');
          },
        );

        if (token != null && token.isNotEmpty) {
          print('✅ ✅ ✅ [FCM] TOKEN FCM OBTENIDO EN BACKGROUND ✅ ✅ ✅');
          Logger.info('TOKEN FCM OBTENIDO EN BACKGROUND');
          print(
              '   [FCM] Primeros 30 caracteres: ${token.substring(0, token.length > 30 ? 30 : token.length)}...');
          Logger.info(
              'Primeros 30 caracteres: ${token.substring(0, token.length > 30 ? 30 : token.length)}...',
              tag: 'FCM');
          print('📱 [FCM] Token completo:');
          Logger.info('Token completo:', tag: 'FCM');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          Logger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', tag: 'FCM');
          print(token);
          Logger.info(token, tag: 'FCM');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          Logger.info('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', tag: 'FCM');

          // Intentar suscribirse ahora que tenemos el token
          if (autoSubscribe) {
            print(
                '🔍 [FCM] Intentando suscribirse al topic ahora que tenemos el token...');
            Logger.fcm(
                'Intentando suscribirse al topic ahora que tenemos el token...');
            try {
              await subscribeToTopic();
            } catch (e) {
              print(
                  '⚠️ [FCM] Error al suscribirse después de obtener token: $e');
              Logger.error('Error al suscribirse después de obtener token',
                  error: e, tag: 'FCM');
            }
          }
        } else {
          print('⚠️ [FCM] Token obtenido pero es null o vacío');
          Logger.warning('Token obtenido pero es null o vacío', tag: 'FCM');
        }
      } catch (e) {
        final errorMsg = e.toString().toLowerCase();
        print('❌ [FCM] No se pudo obtener token en background: $e');
        Logger.error('No se pudo obtener token en background',
            error: e, tag: 'FCM');

        if (errorMsg.contains('service_not_available')) {
          print('⚠️ [FCM] Google Play Services sigue no disponible');
          print(
              '   [FCM] Esto es común en emuladores sin Google Play Services actualizado');
          print('   [FCM] Recomendación: Prueba en un dispositivo físico');
          Logger.warning('Google Play Services sigue no disponible',
              tag: 'FCM');
          Logger.info(
              'Esto es común en emuladores sin Google Play Services actualizado',
              tag: 'FCM');
        } else {
          print('💡 [FCM] Recomendación: Prueba en un dispositivo físico');
          print(
              '   [FCM] O verifica que Google Play Services esté actualizado en el emulador');
          Logger.info('Recomendación: Prueba en un dispositivo físico',
              tag: 'FCM');
          Logger.info(
              'O verifica que Google Play Services esté actualizado en el emulador',
              tag: 'FCM');
        }
      }
    });

    // iOS: segundo reintento a los 30s (el token APNs a veces tarda más)
    if (Platform.isIOS) {
      Future.delayed(const Duration(seconds: 30), () async {
        try {
          final token = await _messaging.getToken().timeout(
            const Duration(seconds: 15),
            onTimeout: () => throw TimeoutException('Timeout'),
          );
          if (token != null && token.isNotEmpty && autoSubscribe) {
            print('🍎 [FCM] iOS: token obtenido en 2º reintento, suscribiendo...');
            await subscribeToTopic();
          }
        } catch (_) {}
      });
    }
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

  /// Estado actual del permiso de notificaciones (para mostrar "Abrir Ajustes" si está denegado).
  static Future<AuthorizationStatus> getNotificationPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  /// Solo iOS: indica si el sistema entregó el token APNs a la app (diagnóstico).
  /// Si [received] es false, el perfil de aprovisionamiento o los entitlements no incluyen Push.
  static Future<Map<String, dynamic>?> getAPNsDiagnostics() async {
    if (!Platform.isIOS) return null;
    try {
      final received = await const MethodChannel('com.rgioia.dolarargentina/fcm')
          .invokeMethod<bool>('hasAPNsToken');
      final error = await const MethodChannel('com.rgioia.dolarargentina/fcm')
          .invokeMethod<String>('getAPNsError');
      return {'received': received ?? false, 'error': error ?? ''};
    } catch (e) {
      return {'received': false, 'error': e.toString()};
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
        Logger.fcm('Intento $attempt: Suscribiéndose al topic "all_users"...');
        await _messaging
            .subscribeToTopic('all_users')
            .timeout(const Duration(seconds: 10));

        Logger.info('SUSCRITO AL TOPIC "all_users" EXITOSAMENTE');
        Logger.info('La app ahora puede recibir notificaciones push',
            tag: 'FCM');
        Logger.info(
            'Para verificar: Envía una notificación de prueba desde Firebase Console',
            tag: 'FCM');
        Logger.info('O desde el backend al topic "all_users"', tag: 'FCM');
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

    // 6. Verificación específica para iOS
    if (Platform.isIOS) {
      print('6️⃣ iOS - Verificaciones específicas:');

      // Verificar si el token APNs está configurado
      try {
        // En iOS, el token APNs se pasa automáticamente desde AppDelegate
        // No hay forma directa de verificarlo desde Dart, pero podemos verificar el token FCM
        final token = await getToken();
        if (token != null) {
          print('   ✅ Token FCM disponible (requiere token APNs configurado)');
          print(
              '   💡 Si el token FCM existe, el token APNs probablemente está configurado');
        } else {
          print(
              '   ⚠️ Token FCM no disponible - puede indicar problema con token APNs');
        }
      } catch (e) {
        print('   ❌ Error verificando token: $e');
      }

      print('   📋 Checklist para notificaciones iOS:');
      print('   1. ¿Clave APNs (.p8) subida en Firebase Console?');
      print(
          '      → Firebase Console → Configuración → Cloud Messaging → Configuración de apps de Apple');
      print('   2. ¿GoogleService-Info.plist actualizado?');
      print('   3. ¿Permisos de notificaciones concedidos? (ver arriba)');
      print('   4. ¿aps-environment en production? (ver Runner.entitlements)');
      print(
          '   5. ¿UIBackgroundModes con remote-notification? (ver Info.plist)');
      print('');
      print('   🔍 Para verificar en Firebase Console:');
      print(
          '   - Ve a: https://console.firebase.google.com/project/dolar-argentina-c7939/settings/cloudmessaging');
      print('   - Verifica que haya una clave APNs (.p8) configurada');
      print('   - Si no hay clave, descárgala desde Apple Developer y súbela');
    }

    print('🔍 ===== FIN DIAGNÓSTICO =====\n');
  }
}
