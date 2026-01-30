# iOS no recibe push (Android sí): qué revisar

Si la GitHub Action envía la notificación y **Android la recibe pero iOS no**, casi siempre es por **APNs** (Apple Push Notification service). FCM entrega a Android directo; para iOS FCM reenvía a Apple, y eso requiere configuración extra.

---

## 1. Subir clave APNs en Firebase (lo más habitual)

Sin esto, FCM **no puede** entregar a ningún iPhone.

1. Entrá a [Firebase Console](https://console.firebase.google.com) → tu proyecto.
2. **Configuración del proyecto** (engranaje) → pestaña **Cloud Messaging**.
3. Bajá hasta **Configuración de apps de Apple**.
4. Si no hay clave APNs:
   - En [Apple Developer](https://developer.apple.com/account) → **Certificates, Identifiers & Profiles** → **Keys**.
   - Creá una clave nueva, activá **Apple Push Notifications service (APNs)**.
   - Descargá el archivo **.p8** (solo se puede una vez; guardalo).
   - En Firebase: **Subir** ese .p8, poné el **Key ID** y tu **Team ID** (ej. `93QAZPHZ99`) y el **Bundle ID** (`com.rgioia.dolarargentina`).
5. Guardá los cambios.

---

## 2. Token APNs pasado a Firebase (AppDelegate)

En `ios/Runner/AppDelegate.swift` la app debe pasar el token APNs a Firebase en `didRegisterForRemoteNotificationsWithDeviceToken` (asignar `Messaging.messaging().apnsToken = deviceToken`). Sin esto, FCM no puede entregar en iOS. Ya está implementado en el proyecto.

## 3. Capacidad Push en Xcode

La app tiene que tener la capacidad **Push Notifications** y **Background Modes → Remote notifications**.

1. Abrí `ios/Runner.xcworkspace` en Xcode.
2. Target **Runner** → **Signing & Capabilities**.
3. Si no está:
   - **+ Capability** → **Push Notifications**.
   - **+ Capability** → **Background Modes** → marcar **Remote notifications**.

(En el repo ya está `UIBackgroundModes` con `remote-notification` en `Info.plist`; Push Notifications se agrega desde Xcode y crea el archivo de entitlements.)

---

## 4. Comprobar en el iPhone (TestFlight)

- Que **Notificaciones** estén permitidas para **Dólar Argentina** (Ajustes → Notificaciones).
- Que la app se haya abierto al menos una vez después de instalar desde TestFlight (para que se registre el token FCM y la suscripción al topic).

---

## 5. Resumen

| Revisión              | Dónde                          |
|-----------------------|---------------------------------|
| Clave APNs (.p8)      | Firebase → Cloud Messaging → iOS |
| Push Notifications    | Xcode → Runner → Capabilities   |
| Remote notifications | Xcode → Background Modes       |
| Permisos en el iPhone | Ajustes → Notificaciones        |

Después de subir la clave APNs y tener las capabilities en Xcode, volvé a generar el build (o al menos archivar de nuevo) y subir a TestFlight; luego probar de nuevo el envío desde la GitHub Action.
