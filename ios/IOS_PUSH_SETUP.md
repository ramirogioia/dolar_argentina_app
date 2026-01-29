# Push en iOS: si Android recibe y iOS no

En el código ya está todo listo (entitlements, AppDelegate, Info.plist).  
**Lo que falta es configurar Firebase con la clave de APNs.**

## Paso obligatorio: subir clave APNs en Firebase

1. Entrá a **[Firebase Console](https://console.firebase.google.com)** → tu proyecto.
2. **Configuración del proyecto** (engranaje) → pestaña **Cloud Messaging**.
3. Bajá hasta **"Configuración de apps de Apple"** (o "Apple app configuration").
4. Si no hay ninguna clave APNs:
   - En **[Apple Developer](https://developer.apple.com/account)** → **Keys** → **+** (crear clave).
   - Nombre: ej. "APNs Dólar Argentina". Activá **Apple Push Notifications service (APNs)**.
   - Continuar → **Register** → **Download** el archivo **.p8** (solo se puede descargar una vez; guardalo).
   - En Firebase: **Upload** (o "Subir") → elegí el .p8, ingresá **Key ID**, **Team ID** (`93QAZPHZ99`) y **Bundle ID** (`com.rgioia.dolarargentina`).
5. Guardar.

Sin este paso, FCM no puede enviar notificaciones a ningún iPhone.  
Después de subir la clave, volvé a probar (no hace falta cambiar el IPA si ya tenés el build con push habilitado).

## Verificar en el iPhone

- **Ajustes → Notificaciones → Dólar ARG** → permitidas.
- Abrir la app al menos una vez después de instalar (para registrar el token FCM).

Más detalle: `docs/IOS_PUSH_CHECKLIST.md`.
