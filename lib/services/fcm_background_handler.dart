import 'package:firebase_messaging/firebase_messaging.dart';

/// Handler para notificaciones cuando la app está en background
/// 
/// Este archivo debe ser un top-level function para que Flutter lo pueda llamar
/// desde el código nativo de Android/iOS.
/// 
/// IMPORTANTE: Este handler solo se ejecuta cuando la app está en background,
/// NO cuando está cerrada completamente.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📨 Notificación recibida en background:');
  print('   Título: ${message.notification?.title}');
  print('   Cuerpo: ${message.notification?.body}');
  print('   Data: ${message.data}');
  
  // Aquí podrías procesar la notificación, guardar datos, etc.
  // La navegación se maneja en FCMService cuando el usuario toca la notificación
}

