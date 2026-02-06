import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  /// Token APNs recibido antes de que Firebase esté listo (p. ej. en release/TestFlight).
  /// Se asigna a FCM cuando Dart notifica por method channel que Firebase ya está inicializado.
  static var pendingAPNsToken: Data?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // No llamar FirebaseApp.configure() aquí: Flutter lo hace desde Dart (Firebase.initializeApp).
    // Llamarlo aquí causaba crash al abrir en algunos dispositivos/versiones.
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      application.registerForRemoteNotifications()
      // Pedir permiso de notificaciones en iOS para que la app aparezca en Ajustes → Notificaciones
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Registrar method channel cuando la ventana esté lista (Dart nos avisará "Firebase listo").
    DispatchQueue.main.async { [weak self] in
      self?.registerFCMMethodChannel()
    }
    return result
  }

  private func registerFCMMethodChannel() {
    guard let controller = window?.rootViewController as? FlutterViewController else { return }
    let channel = FlutterMethodChannel(
      name: "com.rgioia.dolarargentina/fcm",
      binaryMessenger: controller.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "onFirebaseReady" {
        if let token = AppDelegate.pendingAPNsToken {
          Messaging.messaging().apnsToken = token
          AppDelegate.pendingAPNsToken = nil
          print("[AppDelegate] APNs token asignado a FCM tras notificación de Dart")
        }
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // Pasar el token APNs a Firebase. Sin esto, FCM no puede entregar notificaciones en iOS.
  // Si Firebase aún no está configurado (común en release/TestFlight), guardar y asignar cuando Dart avise.
  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    if FirebaseApp.app() != nil {
      Messaging.messaging().apnsToken = deviceToken
    } else {
      AppDelegate.pendingAPNsToken = deviceToken
      print("[AppDelegate] Token APNs recibido; Firebase no listo aún, guardado para asignar después")
    }
  }
}
