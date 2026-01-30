import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // No llamar FirebaseApp.configure() aquí: Flutter lo hace desde Dart (Firebase.initializeApp).
    // Llamarlo aquí causaba crash al abrir en algunos dispositivos/versiones.
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      application.registerForRemoteNotifications()
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Pasar el token APNs a Firebase. Sin esto, FCM no puede entregar notificaciones en iOS.
  // Solo asignar si Firebase ya está configurado (p. ej. por Flutter); si no, evitar crash.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    if FirebaseApp.app() != nil {
      Messaging.messaging().apnsToken = deviceToken
    }
  }
}
