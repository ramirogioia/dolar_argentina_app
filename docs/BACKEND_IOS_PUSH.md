r# Notificaciones push iOS (backend)

La app ya está preparada para recibir push en iOS (token APNs se pasa a FCM en `AppDelegate.swift`, suscripción al topic `all_users`).

## ¿TestFlight vs producción?

**No cambia nada en la app ni en el backend** entre TestFlight y App Store:

- El mismo build que subís a TestFlight usa **APNs production** (está en `Runner.entitlements`: `aps-environment` = `production`). TestFlight y App Store usan el mismo entorno.
- El backend envía igual: por **topic** `all_users` (o por token FCM). No hay que usar otro topic ni otra config para TestFlight vs prod.

## Cómo probar en TestFlight

1. Subir el build a TestFlight e instalar la app en un iPhone.
2. Abrir la app, aceptar notificaciones cuando lo pida.
3. Desde el backend, **disparar la notificación** al topic `all_users` (igual que para Android). Si Firebase tiene configurada la clave APNs para iOS, el dispositivo recibirá la notificación.

## Requisito en Firebase (iOS)

Para que FCM pueda entregar en iOS hace falta:

- **Firebase Console** → Proyecto → Configuración (engranaje) → **Cloud Messaging** → pestaña **Configuración de apps de Apple**.
- Subir la **clave APNs (.p8)** de tu Apple Developer account (Keys → crear clave con “Apple Push Notifications service (APNs)”).
- Bundle ID debe coincidir con el de la app (ej. `com.tuempresa.dolar_argentina_app`).

Sin esa clave, FCM no puede hablar con APNs y las notificaciones no llegarán a iOS (Android seguirá funcionando).

## Payload recomendado (compatible iOS y Android)

- **title**: ej. `"Cierre del día"`
- **body**: texto del mensaje
- **topic**: `all_users`

Para contenido específico (ej. “Cierre del día” con datos), el backend puede enviar **data** y opcionalmente **notification**; la app ya maneja `onMessage` y `onMessageOpenedApp` en `FCMService`.
