# Push en iOS / TestFlight – Por qué no llegan las notificaciones

Si en Android te llegan las notis y en iOS (TestFlight) no, suele ser una de estas causas.

---

## 1. Capability Push Notifications en Xcode ✅ (ya agregada en el proyecto)

El provisioning profile debe incluir Push Notifications. En el proyecto ya está:

- **project.pbxproj**: `com.apple.Push = { enabled = 1; }`
- **Runner.entitlements**: `aps-environment = production`
- **Info.plist**: `UIBackgroundModes` → `remote-notification`

**Importante:** Después de agregar la capability, hay que **generar un nuevo build y subir de nuevo a TestFlight**. Los builds anteriores se generaron sin Push en el provisioning profile y no recibirán notificaciones.

```bash
cd ios
./build_archive.sh
# Subir el nuevo .ipa a App Store Connect y distribuir por TestFlight
```

---

## 2. Clave APNs (.p8) en Firebase (la causa más común)

Sin la clave APNs en Firebase, FCM no puede enviar a Apple.

### Pasos

1. **Crear clave APNs en Apple Developer** (si no tenés una):
   - https://developer.apple.com/account/resources/authkeys/list
   - Create a key → marcar **Apple Push Notifications service (APNs)** → Continue → Register → Descargar el `.p8` (solo se puede una vez; guardalo).
   - Anotar: **Key ID** y **Team ID**. El **Bundle ID** es tu app: `com.rgioia.dolarargentina`.

2. **Subir la clave en Firebase**:
   - Firebase Console → Tu proyecto → ⚙️ Configuración del proyecto
   - Pestaña **Cloud Messaging**
   - En **Configuración de apps de Apple**, elegir la app iOS (o agregarla con el Bundle ID)
   - Subir el archivo **.p8**, e indicar **Key ID**, **Team ID** y **Bundle ID**
   - Guardar

Si esto no está hecho, las notificaciones **no llegarán en iOS** aunque el resto esté bien.

---

## 3. App ID en Apple Developer con Push Notifications

En https://developer.apple.com/account/resources/identifiers/list :

- Entrá al App ID de tu app (`com.rgioia.dolarargentina`)
- En **Capabilities** debe estar marcado **Push Notifications**
- Si no está, activalo y guardá; después volvé a generar el provisioning profile (Xcode lo hace al hacer archive con automatic signing).

---

## 4. Cómo estás enviando la notificación

- Si enviás al **topic** `all_users`: el dispositivo iOS debe estar **suscrito** a ese topic. La app se suscribe al activar “Notificaciones” en Ajustes.
- Si enviás por **token FCM**: ese token tiene que ser el del iPhone en TestFlight (no el de otro dispositivo ni el de un emulador).

Para probar: en Firebase Console → Cloud Messaging → “Enviar mensaje de prueba” podés usar un token FCM. Para obtener el token del iPhone en TestFlight podés usar el diagnóstico en la app (si tenés la sección debug de notificaciones) o un `print` del token en el código.

---

## 5. Resumen rápido

| Qué revisar | Dónde |
|-------------|--------|
| Capability Push en el proyecto | Xcode / project.pbxproj ✅ |
| `aps-environment` = production | Runner.entitlements ✅ |
| Clave APNs (.p8) subida | Firebase Console → Cloud Messaging → Configuración de apps de Apple |
| App ID con Push Notifications | developer.apple.com → Identifiers |
| Nuevo build después de tocar capabilities | `./build_archive.sh` y nuevo .ipa a TestFlight |

Después de **subir la clave APNs en Firebase** y de **generar un nuevo build con la capability Push** y subirlo a TestFlight, las notificaciones deberían empezar a llegar en iOS.
