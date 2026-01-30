# Análisis: notificaciones en Android sí, en iOS no (parte mobile)

## Resumen del análisis

Se revisó todo el flujo de push en el repo **mobile** (este repo). La causa más probable en iOS era el **orden de inicialización**: Firebase debe estar configurado **en native (AppDelegate)** antes de que Apple entregue el token APNs. Si no, FCM nunca recibe el token APNs y no puede entregar notificaciones en ese dispositivo.

---

## Qué se revisó (y está correcto)

| Revisión | Estado |
|----------|--------|
| **Runner.entitlements** | `aps-environment: production` ✅ |
| **Info.plist** | `UIBackgroundModes` → `remote-notification` ✅ |
| **Xcode** | `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` ✅ |
| **AppDelegate** | `registerForRemoteNotifications()` ✅ |
| **AppDelegate** | `didRegisterForRemoteNotificationsWithDeviceToken` → `Messaging.messaging().apnsToken = deviceToken` ✅ |
| **Flutter FCM** | `requestPermission()`, `getToken()`, `subscribeToTopic('all_users')` ✅ |
| **Background handler** | `firebaseMessagingBackgroundHandler` registrado ✅ |
| **Topic** | Mismo `all_users` que el backend ✅ |

---

## Problema detectado: orden de inicialización en iOS

En iOS el flujo es:

1. Se llama `application.registerForRemoteNotifications()` en el AppDelegate.
2. **Más tarde** (incluso antes de que arranque Flutter), el sistema llama `didRegisterForRemoteNotificationsWithDeviceToken` con el token APNs.
3. En ese momento hacemos `Messaging.messaging().apnsToken = deviceToken`.

Si **Firebase no está configurado todavía** (porque solo se llamaba `Firebase.initializeApp()` desde Flutter al arrancar el engine), cuando llega el token APNs **Messaging aún no está inicializado**. Asignar `apnsToken` en ese momento no sirve o no se envía a FCM, y el token FCM que luego obtiene la app en Dart puede quedar sin vincular a APNs → **las notificaciones no llegan en iOS**.

En Android no pasa: no hay este paso de “token APNs primero”; FCM funciona sin ese orden.

---

## Cambio aplicado en este repo (mobile)

En **`ios/Runner/AppDelegate.swift`** se volvió a llamar **`FirebaseApp.configure()`** al inicio de `application(_:didFinishLaunchingWithOptions:)`, **antes** de `GeneratedPluginRegistrant` y de `registerForRemoteNotifications()`.

Así:

1. Firebase (y Messaging) están listos en cuanto arranca la app.
2. Cuando el sistema llame `didRegisterForRemoteNotificationsWithDeviceToken`, `Messaging.messaging().apnsToken = deviceToken` se ejecuta con Messaging ya inicializado.
3. FCM recibe el token APNs y puede entregar notificaciones en ese iPhone.

`Firebase.initializeApp()` en Dart sigue siendo seguro: si Firebase ya fue configurado en native, es idempotente.

---

## Si el release llegó a crashear al abrir

En un release anterior se había quitado `FirebaseApp.configure()` del AppDelegate para evitar un crash al abrir. Si al **volver a ponerlo** el crash reaparece:

1. Con **Crashlytics** activo, el siguiente crash debería verse en Firebase Console (Build → Crashlytics) con el stack trace.
2. Posibles causas entonces: otro código en el AppDelegate, falta o error de `GoogleService-Info.plist` en el build, o conflicto con otra librería. El stack de Crashlytics indicará el siguiente paso.

---

## Checklist rápido (mobile)

- [x] `FirebaseApp.configure()` al inicio del AppDelegate (iOS).
- [x] `Messaging.messaging().apnsToken = deviceToken` en `didRegisterForRemoteNotificationsWithDeviceToken`.
- [x] Entitlements con `aps-environment`.
- [x] Background mode `remote-notification`.
- [x] Flutter: permisos, getToken, subscribeToTopic('all_users').

Lo que **no** se controla desde este repo: clave APNs (.p8) en Firebase Console y que el backend envíe el mensaje con `notification` + `apns` (ver `docs/BACKEND_IOS_PUSH.md`).
