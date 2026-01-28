# Guía de Testing - Notificaciones Push

Esta guía te ayudará a probar las notificaciones push sin esperar al scrapping real.

## 📋 Checklist Pre-Testing

Antes de probar, asegúrate de tener:

- [ ] **Archivos de Firebase configurados:**
  - `android/app/google-services.json` (descargado desde Firebase Console)
  - `ios/Runner/GoogleService-Info.plist` (descargado desde Firebase Console)

- [ ] **Backend configurado:**
  - Firebase Admin SDK instalado
  - Service account key configurado
  - Script de prueba disponible (o usar Firebase Console)

## 🚀 Paso 1: Verificar que la App se Suscribe Correctamente

### 1.1. Ejecutar la App

```bash
flutter run
```

### 1.2. Revisar los Logs

Busca estos logs en la consola (deben aparecer al iniciar la app):

```
✅ Firebase inicializado correctamente
✅ AdMob inicializado correctamente
📱 Estado de permisos: AuthorizationStatus.authorized
✅ Suscrito al topic: all_users
📱 Token FCM: [un token largo aquí]
✅ FCM Service inicializado correctamente
```

**Si ves estos logs → ✅ La app está lista para recibir notificaciones**

**Si NO ves estos logs:**
- ❌ `Error al inicializar Firebase` → Falta `google-services.json` o `GoogleService-Info.plist`
- ❌ `Permisos de notificaciones denegados` → El usuario debe aceptar permisos (iOS)
- ❌ `Error al suscribirse al topic` → Verifica conexión a internet

### 1.3. Verificar el Token FCM

Copia el token FCM que aparece en los logs. Lo necesitarás para pruebas avanzadas.

## 🧪 Paso 2: Enviar Notificación de Prueba

Tienes **3 opciones** para enviar notificaciones de prueba:

---

### **Opción A: Desde Firebase Console (MÁS FÁCIL) ⭐**

Esta es la forma más rápida de probar sin tocar el backend.

#### Pasos:

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto: **dolar-argentina-c7939**
3. Ve a **Cloud Messaging** (en el menú lateral)
4. Haz clic en **"Send your first message"** o **"New notification"**
5. Completa el formulario:
   - **Notification title**: `Apertura del mercado` (o `Cierre del día`)
   - **Notification text**: `El dólar blue subió a $1.485,00` (o cualquier mensaje de prueba)
   - **Target**: Selecciona **"Topic"** → Escribe: `all_users`
6. Haz clic en **"Review"** → **"Publish"**

#### ✅ Resultado Esperado:

- Si la app está en **foreground**: Verás una notificación local en la app
- Si la app está en **background**: Verás la notificación en el sistema operativo
- Si la app está **cerrada**: Verás la notificación en el sistema, y al tocarla se abre la app

---

### **Opción B: Script del Backend (Si existe)**

Si el backend tiene un script `test_push_notification.py`:

#### Pasos:

1. Ve al directorio del backend
2. Ejecuta el script:
   ```bash
   python test_push_notification.py
   ```

#### Script de Ejemplo (si no existe, créalo):

```python
# test_push_notification.py
import firebase_admin
from firebase_admin import credentials, messaging

# Inicializar Firebase
cred = credentials.Certificate("serviceAccountKey.json")
firebase_admin.initialize_app(cred)

# Enviar notificación de prueba
message = messaging.Message(
    notification=messaging.Notification(
        title="Apertura del mercado",
        body="El dólar blue subió a $1.485,00",
    ),
    data={
        "tipo": "apertura",
        "dolar": "blue",
        "precio": "1485.00"
    },
    topic="all_users",
    android=messaging.AndroidConfig(
        priority="high",
        notification=messaging.AndroidNotification(
            sound="default",
            channel_id="dolar_argentina_channel"
        )
    ),
    apns=messaging.APNSConfig(
        payload=messaging.APNSPayload(
            aps=messaging.Aps(
                sound="default",
                badge=1
            )
        )
    )
)

response = messaging.send(message)
print(f"✅ Notificación enviada: {response}")
```

---

### **Opción C: Esperar al Scrapping Real**

Si quieres probar con datos reales:

#### Para Notificación de Apertura:
- Espera a que el scrapping detecte la primera corrida entre **11:15 y 12:15**
- El backend debería enviar automáticamente la notificación

#### Para Notificación de Cierre:
- Espera a las **19:00** (hora Argentina)
- El scheduler del backend debería enviar automáticamente la notificación

---

## 🧪 Paso 3: Probar Diferentes Estados de la App

### 3.1. App en Foreground (Abierta y Visible)

**Qué hacer:**
1. Mantén la app abierta y visible
2. Envía una notificación (Opción A o B)

**Resultado esperado:**
- ✅ Deberías ver una notificación local dentro de la app
- ✅ Los logs mostrarán: `📨 Notificación recibida en foreground:`
- ✅ Al tocar la notificación, debería navegar a home

### 3.2. App en Background (Minimizada)

**Qué hacer:**
1. Minimiza la app (presiona Home)
2. Envía una notificación

**Resultado esperado:**
- ✅ Deberías ver la notificación en el sistema operativo (barra de notificaciones)
- ✅ Los logs mostrarán: `📨 Notificación recibida en background:`
- ✅ Al tocar la notificación, la app se abre y navega a home

### 3.3. App Cerrada Completamente

**Qué hacer:**
1. Cierra completamente la app (swipe away o Force Stop)
2. Envía una notificación
3. Espera unos segundos

**Resultado esperado:**
- ✅ Deberías ver la notificación en el sistema operativo
- ✅ Al tocar la notificación, la app se abre desde cero
- ✅ Los logs mostrarán: `📨 Usuario tocó notificación (app estaba cerrada):`
- ✅ La app navega automáticamente a home

---

## 🔍 Paso 4: Verificar Navegación

Cuando tocas una notificación, deberías ver estos logs:

```
📨 Usuario tocó notificación (app en background/cerrada):
   Data: {tipo: apertura, dolar: blue, precio: 1485.00}
🧭 Navegando según tipo: apertura
✅ Navegado a home
```

**Verifica que:**
- ✅ La app navega a la pantalla home
- ✅ Los datos de la notificación se muestran en los logs

---

## 🐛 Troubleshooting

### Problema: "No veo los logs de suscripción"

**Solución:**
- Verifica que los archivos de Firebase estén presentes
- Revisa que `flutter pub get` se haya ejecutado correctamente
- Limpia y reconstruye: `flutter clean && flutter pub get && flutter run`

### Problema: "La notificación no llega"

**Solución:**
- Verifica que el topic sea exactamente `"all_users"` (minúsculas, guión bajo)
- Revisa los logs del backend si usas Opción B
- Verifica que el dispositivo tenga conexión a internet
- En iOS, verifica que los permisos estén aceptados

### Problema: "La navegación no funciona"

**Solución:**
- Verifica que `navigatorKey` esté configurado en el router
- Revisa los logs para ver si hay errores de navegación
- Asegúrate de que la app haya terminado de inicializar antes de tocar la notificación

### Problema: "En iOS no funciona"

**Solución:**
- iOS requiere permisos explícitos (se solicitan automáticamente la primera vez)
- Si el usuario denegó permisos, debe ir a Configuración → [App] → Notificaciones
- Las notificaciones push en iOS solo funcionan en dispositivos físicos (no en simulador)
- Verifica que APNs esté configurado en Firebase Console

---

## 📊 Checklist de Testing Completo

- [ ] App se suscribe correctamente al topic `all_users`
- [ ] Token FCM se obtiene y muestra en logs
- [ ] Notificación llega cuando la app está en **foreground**
- [ ] Notificación llega cuando la app está en **background**
- [ ] Notificación llega cuando la app está **cerrada**
- [ ] Al tocar la notificación, la app navega a **home**
- [ ] Los logs muestran correctamente los datos de la notificación
- [ ] Funciona en **Android**
- [ ] Funciona en **iOS** (si aplica)

---

## 🎯 Próximos Pasos

Una vez que todo funcione:

1. **Probar con datos reales**: Espera al scrapping real para verificar que las notificaciones de apertura y cierre funcionen correctamente
2. **Monitorear logs del backend**: Verifica que el backend esté enviando notificaciones correctamente
3. **Probar en diferentes dispositivos**: Asegúrate de que funcione en diferentes modelos y versiones de Android/iOS

---

## 💡 Tips

- **Para desarrollo rápido**: Usa Firebase Console (Opción A) para enviar notificaciones de prueba sin tocar el backend
- **Para debugging**: Revisa siempre los logs tanto de la app como del backend
- **Para producción**: Asegúrate de probar todos los estados de la app antes de publicar

