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
  /// True si iOS alguna vez llamó a didRegisterForRemoteNotificationsWithDeviceToken (diagnóstico).
  static var apnsTokenEverReceived = false
  /// Mensaje de error si iOS llamó a didFailToRegisterForRemoteNotifications (diagnóstico).
  static var apnsRegistrationError: String?
  /// Log de eventos APNs para mostrar en la app (Debug).
  static var apnsLogLines: [String] = []

  private static func apnsLog(_ msg: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    let line = "\(formatter.string(from: Date())) \(msg)"
    DispatchQueue.main.async {
      apnsLogLines.append(line)
      if apnsLogLines.count > 60 { apnsLogLines.removeFirst() }
    }
    print("[AppDelegate] \(msg)")
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    AppDelegate.apnsLog("App launch")
    // No llamar FirebaseApp.configure() aquí: Flutter lo hace desde Dart (Firebase.initializeApp).
    GeneratedPluginRegistrant.register(with: self)
    if #available(iOS 10.0, *) {
      AppDelegate.apnsLog("Llamando registerForRemoteNotifications() al inicio")
      application.registerForRemoteNotifications()
      UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
        AppDelegate.apnsLog("requestAuthorization callback: granted=\(granted)")
        if granted {
          DispatchQueue.main.async {
            application.registerForRemoteNotifications()
            AppDelegate.apnsLog("registerForRemoteNotifications() llamado de nuevo tras permiso")
          }
        }
      }
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
      } else if call.method == "hasAPNsToken" {
        result(AppDelegate.apnsTokenEverReceived)
      } else if call.method == "getAPNsError" {
        result(AppDelegate.apnsRegistrationError ?? "")
      } else if call.method == "getAPNsLog" {
        result(AppDelegate.apnsLogLines)
      } else if call.method == "getAppInfo" {
        var dict: [String: Any] = [:]
        if let bid = Bundle.main.bundleIdentifier { dict["bundleId"] = bid }
        if let info = Bundle.main.infoDictionary {
          if let v = info["CFBundleShortVersionString"] as? String { dict["version"] = v }
          if let b = info["CFBundleVersion"] as? String { dict["build"] = b }
        }
        #if targetEnvironment(simulator)
        dict["simulator"] = true
        #else
        dict["simulator"] = false
        #endif
        dict["apnsReceived"] = AppDelegate.apnsTokenEverReceived
        if let err = AppDelegate.apnsRegistrationError { dict["apnsError"] = err }
        result(dict)
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
    AppDelegate.apnsTokenEverReceived = true
    AppDelegate.apnsRegistrationError = nil
    let tokenHex = deviceToken.map { String(format: "%02x", $0) }.joined()
    AppDelegate.apnsLog("didRegister: token APNs recibido (len=\(deviceToken.count))")
    if FirebaseApp.app() != nil {
      Messaging.messaging().apnsToken = deviceToken
      AppDelegate.apnsLog("Token asignado a FCM")
    } else {
      AppDelegate.pendingAPNsToken = deviceToken
      AppDelegate.apnsLog("Token guardado (Firebase aún no listo)")
    }
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    let err = error as NSError
    let msg = "\(error.localizedDescription) [domain=\(err.domain) code=\(err.code)]"
    AppDelegate.apnsRegistrationError = msg
    AppDelegate.apnsLog("didFail: \(msg)")
  }
}
