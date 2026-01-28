# Cómo Triggerear Notificaciones desde el Backend

## 📍 Dónde se Triggeran las Notificaciones

### 1. **Notificación de Apertura** (11:15 - 12:15)

**Ubicación en el código del backend:**
- Se debe integrar en el proceso de **scraping** existente
- Cuando se detecta la **primera corrida del día** entre 11:15 y 12:15

**Lógica:**
```python
# En tu script de scraping (ej: scraper.py)
from notifications.apertura import enviar_notificacion_apertura
from notifications.apertura import ya_enviado_apertura_hoy, marcar_apertura_enviada_hoy

# Dentro del loop de scraping, cuando obtienes una nueva corrida:
hora_actual = datetime.now().time()

# Verificar si es la primera corrida del día entre 11:15 y 12:15
if datetime.now().hour == 11 and 15 <= datetime.now().minute <= 15:
    if not ya_enviado_apertura_hoy():
        # Obtener datos del dólar blue de la corrida actual
        precio_blue = ultima_corrida['dolar_blue']['venta']
        
        # Enviar notificación
        enviar_notificacion_apertura(precio_blue)
        
        # Marcar como enviada
        marcar_apertura_enviada_hoy()
```

**Archivo sugerido:** `backend/notifications/apertura.py`

---

### 2. **Notificación de Cierre** (19:00 diario)

**Ubicación en el código del backend:**
- Se programa con un **cron job** o **scheduler**
- Se ejecuta automáticamente todos los días a las **19:00** (hora Argentina)

**Lógica:**
```python
# En tu script de scheduler (ej: notifications/scheduler.py)
from apscheduler.schedulers.blocking import BlockingScheduler
from notifications.cierre import enviar_notificacion_cierre

scheduler = BlockingScheduler(timezone='America/Argentina/Buenos_Aires')

# Programar cierre diario a las 19:00
scheduler.add_job(
    enviar_notificacion_cierre,
    'cron',
    hour=19,
    minute=0,
    day_of_week='mon-sun'  # Todos los días
)

scheduler.start()
```

**Archivo sugerido:** `backend/notifications/scheduler.py`

---

## 🧪 Cómo Probar Notificaciones Manualmente

### Opción 1: Script de Prueba (Recomendado)

He creado un script `BACKEND_TEST_NOTIFICATION.py` que puedes usar:

```bash
# Desde el directorio del backend
python BACKEND_TEST_NOTIFICATION.py --tipo apertura
python BACKEND_TEST_NOTIFICATION.py --tipo cierre
python BACKEND_TEST_NOTIFICATION.py --tipo custom --titulo "Mi título" --cuerpo "Mi mensaje"
```

**Requisitos:**
- Tener `firebase-admin` instalado: `pip install firebase-admin`
- Tener el archivo `serviceAccountKey.json` en el mismo directorio
- Ajustar la ruta en el script si es necesario

---

### Opción 2: Desde Firebase Console (Más Fácil)

1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Cloud Messaging** → **"New notification"**
4. Completa:
   - **Title**: `Apertura del mercado`
   - **Text**: `El dólar blue subió a $1.485,00`
   - **Target**: Selecciona **"Topic"** → Escribe: `all_users`
5. Haz clic en **"Review"** → **"Publish"**

---

### Opción 3: Integrar en el Código del Backend

Si quieres triggerear manualmente desde tu código:

```python
from notifications.fcm_service import enviar_push_notification

# Notificación de apertura
enviar_push_notification(
    title="Apertura del mercado",
    body="El dólar blue subió a $1.485,00",
    data={"tipo": "apertura", "precio": "1485.00"},
    topic="all_users"
)

# Notificación de cierre
enviar_push_notification(
    title="Cierre del día",
    body="Dólar Blue bajó 0,34% y cerró el día a $1.485,00",
    data={"tipo": "cierre", "variacion": "-0.34"},
    topic="all_users"
)
```

---

## 📋 Checklist para el Backend

Asegúrate de tener:

- [ ] **Firebase Admin SDK instalado**: `pip install firebase-admin`
- [ ] **Service Account Key descargado**: Desde Firebase Console → Project Settings → Service Accounts
- [ ] **Archivo `notifications/fcm_service.py`** con la función `enviar_push_notification()`
- [ ] **Integración en el scraper** para detectar primera corrida del día (11:15-12:15)
- [ ] **Scheduler configurado** para cierre diario (19:00)
- [ ] **Sistema de persistencia** para evitar duplicados (archivo JSON o DB)

---

## 🔍 Verificar que Funciona

1. **Ejecuta la app móvil** y verifica que se suscriba al topic:
   ```
   ✅ Suscrito al topic: all_users
   📱 Token FCM: [token aquí]
   ```

2. **Ejecuta el script de prueba**:
   ```bash
   python BACKEND_TEST_NOTIFICATION.py --tipo apertura
   ```

3. **Verifica en la app móvil**:
   - Si está en **foreground**: Verás notificación local
   - Si está en **background/cerrada**: Verás notificación del sistema
   - Al tocar la notificación: La app navega a home

---

## ⚠️ Errores Comunes

### "Topic not found" o "No subscribers"
- **Causa**: La app móvil no está suscrita al topic `all_users`
- **Solución**: Ejecuta la app móvil y verifica los logs que digan "✅ Suscrito al topic: all_users"

### "Permission denied" o "Invalid credentials"
- **Causa**: El `serviceAccountKey.json` no tiene permisos o está mal configurado
- **Solución**: Descarga nuevamente el archivo desde Firebase Console

### "Service not available"
- **Causa**: Google Play Services no está disponible (normal en emuladores)
- **Solución**: Prueba en un dispositivo físico o espera a que Google Play Services se inicialice

---

## 📚 Archivos de Referencia

- `BACKEND_NOTIFICATIONS_PROMPT.md` - Especificación completa del sistema
- `BACKEND_TEST_NOTIFICATION.py` - Script de prueba
- `TESTING_NOTIFICATIONS.md` - Guía de testing completa

