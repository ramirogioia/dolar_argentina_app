# Notificaciones push en iOS: configuración en Firebase (paso a paso)

Para que tu app **Dólar ARG** reciba notificaciones en iPhone, Firebase tiene que poder hablar con Apple (APNs). Eso se hace subiendo una **clave APNs (.p8)** en Firebase. Sin este paso, las notificaciones **no llegan a iOS** (Android puede seguir funcionando bien).

---

## Parte 1: Crear la clave APNs en Apple Developer

1. Entrá a **[Apple Developer](https://developer.apple.com/account)** e iniciá sesión.
2. En el menú lateral: **Certificates, Identifiers & Profiles** → **Keys**.
3. Tocá el botón **+** (o "Create a key").
4. **Key Name:** poné algo como `APNs Dólar Argentina` (sirve solo para identificarla).
5. Activá **Apple Push Notifications service (APNs)** (checkbox).
6. Tocá **Continue** y luego **Register**.
7. En la pantalla siguiente:
   - **Key ID:** anotala (ej. `ABC123XYZ`). La vas a necesitar en Firebase.
   - Tocá **Download** y guardá el archivo **.p8** en un lugar seguro.  
     **Importante:** Apple solo te deja descargar el .p8 **una vez**. Si lo perdés, tenés que crear otra clave.
8. Opcional: en **Keys** podés ver tu **Key ID** si no la anotaste.

**Dónde ver el Team ID**

- En Apple Developer: menú lateral → **Membership** (o en la esquina superior derecha del sitio).  
- O en [App Store Connect](https://appstoreconnect.apple.com) → **Users and Access** → tu usuario → **Team ID**.  
- Para esta app suele ser: `93QAZPHZ99` (verificá en tu cuenta).

**Bundle ID de la app:** `com.rgioia.dolarargentina`

---

## Parte 2: Subir la clave APNs en Firebase

1. Entrá a **[Firebase Console](https://console.firebase.google.com)**.
2. Elegí el proyecto de **Dólar Argentina** (o el que use tu app).
3. Tocá el **engranaje** al lado de "Project Overview" → **Project settings** (Configuración del proyecto).
4. Arriba, abrí la pestaña **Cloud Messaging**.
5. Bajá hasta la sección **"Apple app configuration"** / **"Configuración de apps de Apple"**.
6. Ahí vas a ver si ya hay una app iOS vinculada. Si ya está tu app:
   - Buscá la opción para **APNs Authentication Key** / **Clave de autenticación APNs**.
   - Si dice "No APNs Authentication Key" o similar, tocá **Upload** / **Subir** (o "Add key").
7. En el formulario:
   - **Upload your .p8 file:** elegí el archivo .p8 que descargaste de Apple.
   - **Key ID:** pegá el **Key ID** que anotaste (ej. `ABC123XYZ`).
   - **Team ID:** tu Team ID de Apple (ej. `93QAZPHZ99`).
   - **Bundle ID:** `com.rgioia.dolarargentina` (debe coincidir con el Bundle ID de la app en Xcode).
8. Guardá (Save / Guardar).

Si Firebase te muestra un mensaje de éxito, la clave quedó configurada. **No hace falta cambiar el IPA ni el código**: con subir la clave alcanza para que FCM pueda enviar a iOS.

---

## Parte 3: Verificar en el iPhone

1. **Ajustes** → **Notificaciones** → buscá **Dólar ARG** y asegurate de que las notificaciones estén **permitidas**.
2. Abrí la app **al menos una vez** después de instalar (desde TestFlight o desde Xcode). Así se registra el token FCM y la suscripción al topic.
3. Volvé a enviar una notificación de prueba (por ejemplo desde tu GitHub Action o desde Firebase Console → Cloud Messaging → "Send your first message" / enviar a topic `all_users`).

---

## Resumen rápido

| Qué | Dónde |
|-----|--------|
| Crear clave APNs (.p8) | [Apple Developer](https://developer.apple.com/account) → Keys → + → APNs → Download |
| Key ID | Pantalla después de crear la clave (o en la lista de Keys) |
| Team ID | Apple Developer → Membership, o App Store Connect |
| Subir .p8 en Firebase | [Firebase Console](https://console.firebase.google.com) → tu proyecto → ⚙️ → Cloud Messaging → Apple app configuration → Upload |
| Bundle ID | `com.rgioia.dolarargentina` |

---

## Si todavía no llegan

- Revisá que en Xcode el target **Runner** tenga **Push Notifications** y **Background Modes → Remote notifications** (ver `docs/IOS_PUSH_CHECKLIST.md`).
- Esperá unos minutos después de subir la clave; a veces tarda un poco.
- Probá cerrar la app por completo, volver a abrirla y enviar otra notificación de prueba.

Cuando la clave APNs esté subida en Firebase y el iPhone tenga notificaciones permitidas para Dólar ARG, las notificaciones deberían empezar a llegar.
