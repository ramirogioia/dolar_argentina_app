# Notificaciones Push en iOS – Diagnóstico completo

Guía para encontrar por qué las notificaciones no llegan en iOS (TestFlight / App Store). Incluye **todos los puntos que pueden fallar** y **qué capturas enviar** para depurar.

---

## 1. Checklist de posibles causas

Revisá cada ítem en orden. Cualquiera que falle puede impedir que lleguen las notificaciones.

### A. Firebase Console

| # | Qué puede fallar | Dónde verificar |
|---|------------------|-----------------|
| A1 | **Clave APNs (.p8) no subida o incorrecta** | Firebase → Configuración del proyecto → pestaña **Cloud Messaging** → sección **Configuración de apps de Apple**. Debe haber una app iOS con Bundle ID `com.rgioia.dolarargentina` y una clave APNs cargada. |
| A2 | **Key ID / Team ID / Bundle ID mal cargados** | Misma pantalla: al subir el .p8 se pide Key ID, Team ID y Bundle ID. Si alguno no coincide con Apple Developer, FCM no puede hablar con APNs. |
| A3 | **Proyecto o app iOS equivocados** | Confirmar que el proyecto es `dolar-argentina-c7939` y que la app iOS en Firebase usa el mismo `GOOGLE_APP_ID` que en `GoogleService-Info.plist` (ej. `1:1027895605266:ios:65ccb9a2d147b3493300cb`). |

### B. Apple Developer

| # | Qué puede fallar | Dónde verificar |
|---|------------------|-----------------|
| B1 | **App ID sin Push Notifications** | [Identifiers](https://developer.apple.com/account/resources/identifiers/list) → abrir `com.rgioia.dolarargentina` → en **Capabilities** debe estar **Push Notifications** activado. |
| B2 | **Clave APNs no creada o sin permiso APNs** | [Keys](https://developer.apple.com/account/resources/authkeys/list) → la clave que usás en Firebase debe tener **Apple Push Notifications service (APNs)**. El .p8 solo se descarga una vez; si lo perdiste, hay que crear otra clave y actualizarla en Firebase. |
| B3 | **Provisioning profile sin Push** | Aunque en Xcode el proyecto tenga la capability, si el perfil se generó antes de agregarla, ese build no tendrá Push. Siempre hacer **nuevo archive** después de tocar capabilities y subir ese build a TestFlight. |

### C. Xcode / Proyecto iOS

| # | Qué puede fallar | Dónde verificar |
|---|------------------|-----------------|
| C1 | **Capability Push Notifications no en el target** | Xcode → abrir `ios/Runner.xcodeproj` → target **Runner** → pestaña **Signing & Capabilities**. Debe aparecer **Push Notifications**. (En el repo ya está en `project.pbxproj`: `com.apple.Push = { enabled = 1 }`.) |
| C2 | **Entitlements sin aps-environment** | Archivo `ios/Runner/Runner.entitlements` debe contener `aps-environment` = `production` (para release/TestFlight). En el repo ya está. |
| C3 | **Bundle ID distinto** | El Bundle ID en Xcode debe ser exactamente `com.rgioia.dolarargentina` (igual que en Firebase y en el App ID de Apple). |
| C4 | **Build antiguo** | Si en algún momento se agregó Push o la clave APNs después del último build, ese .ipa no tiene la configuración nueva. Hacé un build nuevo y subilo a TestFlight. |

### D. Info.plist y background

| # | Qué puede fallar | Dónde verificar |
|---|------------------|-----------------|
| D1 | **UIBackgroundModes sin remote-notification** | `ios/Runner/Info.plist` debe tener `UIBackgroundModes` con `remote-notification`. En el repo ya está. |

### E. Código / Flutter

| # | Qué puede fallar | Dónde verificar |
|---|------------------|-----------------|
| E1 | **Usuario tiene notificaciones desactivadas en la app** | La app guarda `notifications_enabled` en SharedPreferences. Si está en `false`, no se llama a `subscribeToTopic('all_users')`. El usuario debe tener el switch de notificaciones activado en Ajustes. |
| E2 | **Permisos del sistema denegados** | En el iPhone: Ajustes → Dólar ARG → Notificaciones deben estar permitidas. Si el usuario rechazó el permiso, no se obtiene token FCM o no se suscribe. |
| E3 | **Token FCM no se obtiene en iOS** | Si el token APNs no se asigna a Firebase (por orden de inicialización), FCM no puede registrar el dispositivo. La app intenta asignar el token pendiente cuando Dart avisa por method channel; si hay un error silencioso ahí, no habrá token. |
| E4 | **Envío al topic vs token** | Si las notificaciones se envían al topic `all_users`, el dispositivo debe estar suscrito a ese topic (eso pasa cuando `autoSubscribe: true` y hay token). Si enviás por token, tenés que usar el token FCM del iPhone de prueba (no de otro dispositivo). |

### F. Cómo enviás la notificación

| # | Qué puede fallar | Dónde verificar |
|---|------------------|-----------------|
| F1 | **Topic incorrecto** | La app se suscribe a `all_users`. El mensaje en Firebase (o en tu backend) debe enviarse a ese topic, o bien usar el token FCM del dispositivo. |
| F2 | **Mensaje solo por data (sin notification)** | En iOS, si el mensaje no incluye payload de notificación (title/body) y la app está en background/cerrada, puede no mostrarse en pantalla de bloqueo. Para prueba, usá “Enviar mensaje de prueba” en Firebase con título y cuerpo. |

---

## 2. Qué capturas necesitamos para ayudarte

Enviá capturas de pantalla (o exportación) de los siguientes lugares. Con eso se puede acotar el fallo.

### 2.1 Firebase Console

1. **Configuración de Cloud Messaging (Apple)**  
   - Ir a: [Firebase Console](https://console.firebase.google.com) → proyecto **dolar-argentina-c7939** → ⚙️ **Configuración del proyecto** → pestaña **Cloud Messaging**.  
   - Captura de la sección **“Configuración de apps de Apple”** (o “Apple app configuration”): debe verse la app iOS con Bundle ID `com.rgioia.dolarargentina` y si hay **clave APNs** cargada (por ejemplo “Clave APNs de Apple” o “Apple APNs key” con Key ID).

2. **Detalle de la app iOS en Firebase**  
   - Si al hacer clic en la app iOS se abre un detalle o formulario donde se subió el .p8, una captura de esa pantalla (sin mostrar el contenido secreto del .p8). Solo necesitamos ver que exista la clave y los campos Key ID / Team ID / Bundle ID (los valores pueden taparse si preferís).

### 2.2 Apple Developer

3. **App ID – Capabilities**  
   - [Identifiers](https://developer.apple.com/account/resources/identifiers/list) → abrir el App ID `com.rgioia.dolarargentina`.  
   - Captura donde se vean las **Capabilities** con **Push Notifications** marcado.

4. **Clave APNs (opcional pero útil)**  
   - [Keys](https://developer.apple.com/account/resources/authkeys/list).  
   - Captura de la lista de claves donde se vea la clave que usás para APNs (nombre y que esté habilitada “Apple Push Notifications service (APNs)”). No hace falta mostrar la clave en sí.

### 2.3 Xcode (en tu Mac)

5. **Signing & Capabilities del target Runner**  
   - Abrir `ios/Runner.xcodeproj` en Xcode → seleccionar target **Runner** → pestaña **Signing & Capabilities**.  
   - Captura donde se vea **Push Notifications** en la lista de capabilities.

6. **Runner.entitlements**  
   - En el mismo proyecto, abrir `Runner/Runner.entitlements`.  
   - Captura del contenido (debe verse `aps-environment` = `production`).

### 2.4 iPhone / TestFlight

7. **Permisos de la app en el dispositivo**  
   - iPhone: **Ajustes → Dólar ARG → Notificaciones**.  
   - Captura donde se vea que las notificaciones están **Permitir notificaciones** activado (y opcionalmente “Pantalla de bloqueo”, “Centro de notificaciones”, “Banner”).

8. **Dentro de la app – Ajustes**  
   - Abrir la app → Ajustes.  
   - Captura donde se vea el switch de **Notificaciones push** (o “Notificaciones”) en **ON**.

9. **Logs / diagnóstico (si podés)**  
   - Si tenés forma de ver logs del dispositivo (Xcode → Window → Devices and Simulators → seleccionar el iPhone → Open Console, o correción desde Xcode con el iPhone conectado), una vez abierta la app buscá líneas que contengan `[FCM]`, `[AppDelegate]`, `APNs`, `Token FCM`.  
   - Copiá y pegá esas líneas (o captura) para ver si el token FCM se obtiene y si aparece “APNs token asignado a FCM”.

---

## 3. Resumen: orden sugerido de revisión

1. **Firebase:** Clave APNs (.p8) subida y correcta para `com.rgioia.dolarargentina` (capturas 1 y 2).  
2. **Apple:** App ID con Push Notifications; clave con permiso APNs (capturas 3 y 4).  
3. **Xcode:** Push Notifications en el target; `aps-environment` = production (capturas 5 y 6).  
4. **Build:** Siempre un **nuevo archive** después de tocar capabilities o Firebase, y subir ese build a TestFlight.  
5. **Dispositivo:** Notificaciones permitidas en Ajustes del sistema y switch ON en Ajustes de la app (capturas 7 y 8).  
6. **Envío:** Mensaje al topic `all_users` o al token FCM del iPhone de prueba; idealmente con título y cuerpo para la primera prueba.

Con las capturas de las secciones 2.1 a 2.4 (y 2.4.9 si hay logs) se puede acotar si el fallo está en Firebase, Apple, Xcode o en el dispositivo/configuración de la app.
