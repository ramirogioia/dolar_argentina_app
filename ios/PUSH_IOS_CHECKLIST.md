# Push en iOS: qué revisar si "iOS entregó token APNs: no"

El **token FCM** en el dispositivo depende de que **Apple entregue primero el token APNs**. Si en Ajustes → Debug sale "iOS entregó token APNs: no", Apple no está llamando a nuestra app con el token. Esto **no** se arregla subiendo archivos a Firebase.

---

## 1. Archivo .p8 en Firebase (clave APNs)

- **¿Para qué sirve?** Para que **FCM pueda enviar** notificaciones al dispositivo. Es decir: **después** de que el dispositivo ya tenga token.
- **¿Arregla "token APNs: no"?** **No.** El mensaje "iOS entregó token APNs: no" significa que el **dispositivo** no recibe el token de Apple. Eso es independiente de Firebase.
- **¿Hay que subirlo igual?** Sí. Cuando el token APNs llegue, vas a necesitar la clave .p8 en Firebase para que las notificaciones se envíen.
- **Dónde:** Firebase Console → Configuración del proyecto → Cloud Messaging → "Configuración de apps de Apple" → Subir clave APNs (.p8).

---

## 2. Qué revisar cuando "iOS entregó token APNs: no"

### En el dispositivo

1. **Desinstalá la app por completo** (mantener apretado → quitar app).
2. **Reiniciá el iPhone** (a veces APNs queda en un estado raro).
3. **Instalá de nuevo desde TestFlight** (usá un build reciente generado con `./ios/build_archive.sh`).
4. Al abrir la app, **aceptá notificaciones** cuando aparezca el diálogo.
5. Si antes habías denegado: **Ajustes → Dólar ARG → Notificaciones** y activá "Permitir notificaciones".
6. **Red:** probá sin VPN; algunas VPNs bloquean APNs.

### En Ajustes → Debug (dentro de la app)

- Si aparece **"Error iOS: …"**, anotá el texto exacto. Errores típicos:
  - **"no se encontró ninguna cadena de autorización 'aps-environment' para la app" (code=3000)** → el dispositivo no ve el entitlement Push en la app instalada. Ver sección 4 más abajo (regenerar perfil de distribución).
  - "no valid 'aps-environment' entitlement" → mismo que arriba; el perfil con el que se firmó no incluye Push.
  - "remote notifications are not supported in the simulator" → estás en simulador; probá en dispositivo real.
  - Otros → buscá el mensaje en la documentación de Apple o compartilo para revisar.

### En Apple Developer (developer.apple.com)

1. **Identifiers** → `com.rgioia.dolarargentina` → **Push Notifications** debe estar **activado**.
2. **Profiles** → el perfil de **Distribution** que usa tu app debe incluir Push. Si el dispositivo sigue diciendo "no aps-environment" (code 3000), hay que **regenerar** ese perfil (ver sección 4).

---

## 4. Error 3000: "no aps-environment" → regenerar perfil de distribución

Si el Error iOS dice algo como **"no se encontró ninguna cadena de autorización 'aps-environment' para la app"** con **domain=NSCocoaErrorDomain code=3000**, el **perfil de aprovisionamiento** con el que se firmó el IPA no está llegando al dispositivo con Push, o Xcode está usando un perfil viejo al exportar.

**Pasos (sin abrir Xcode):**

1. **developer.apple.com** → **Identifiers** → `com.rgioia.dolarargentina` → confirmá que **Push Notifications** está activado. Si no, activalo y guardá.
2. **Profiles** → buscá el perfil de tipo **App Store** o **App Store Connect** para esta app (com.rgioia.dolarargentina).
3. **Edit** (o creá uno nuevo) → asegurate de que el perfil incluya **Push Notifications** (debería aparecer si el App ID lo tiene). **Regenerate** y **Download** el .mobileprovision.
4. En tu Mac: **doble clic** en el .mobileprovision descargado para instalarlo (o copialo a `~/Library/MobileDevice/Provisioning Profiles/`).
5. Volvé a generar el IPA: `./ios/build_archive.sh`. El export usará el perfil nuevo.
6. Subí el IPA a TestFlight, **desinstalá la app** en el iPhone, **reiniciá el iPhone**, instalá de nuevo desde TestFlight y aceptá notificaciones.

Si no tenés un perfil de Distribution en la lista, creá uno: Profiles → + → App Store → seleccioná el App ID com.rgioia.dolarargentina → elegí tu certificado de Distribution → nombre (ej. "Dólar ARG AppStore") → Generate → Download e instalalo.

### Build que subís a TestFlight

- Tiene que ser el que genera `./ios/build_archive.sh` (archive sin firma + export con firma de distribución).
- Después del build podés verificar: `./ios/verify_ipa_push.sh` → debe decir que el IPA incluye Push (aps-environment).

---

## 3. Resumen

| Problema | Dónde actúa | ¿Lo arregla la .p8 en Firebase? |
|----------|-------------|----------------------------------|
| "iOS entregó token APNs: no" | Dispositivo + perfil + permisos | **No** |
| "Token FCM no disponible" porque no hay token APNs | Mismo que arriba | **No** |
| Ya tengo token FCM pero no me llegan notificaciones | Servidor FCM → Apple → dispositivo | **Sí** (hace falta la .p8 en Firebase) |

Si seguís con "iOS entregó token APNs: no" después de desinstalar, reiniciar e instalar de nuevo desde TestFlight, el siguiente dato clave es el **texto exacto del "Error iOS:"** que muestra la pantalla de Debug (si aparece).
