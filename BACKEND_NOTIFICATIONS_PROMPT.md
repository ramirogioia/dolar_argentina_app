# Prompt para Backend - Sistema de Notificaciones Push

## Contexto
Necesitamos implementar un sistema de notificaciones push para la app móvil "Dólar Argentina" que alerta a los usuarios sobre:
1. **Apertura del mercado**: Primera medición del día (entre 11:15 y 12:15)
2. **Cierre del día**: Resumen diario con variación y brecha (a las 19:00)

## Estructura Actual del Backend

El backend actualmente:
- Scrapea datos de dólares cada hora (9:00 a 19:00)
- Genera archivos JSON diarios: `cotizaciones_YYYY-MM-DD.json`
- Estructura del JSON:
```json
{
  "fecha": "2026-01-28",
  "ultima_actualizacion": "2026-01-28T16:53:32.423939-03:00",
  "corridas": [
    {
      "timestamp": "2026-01-28T16:34:49.968800",
      "hora": "16:34:49",
      "dolar_blue": { "compra": 1465.00, "venta": 1485.00 },
      "dolar_oficial": { ... },
      "dolar_cripto": { ... },
      "dolar_tarjeta": { "compra": null, "venta": 1904.50 },
      "dolar_mep": { "compra": 1460.40, "venta": 1462.20 },
      "dolar_ccl": { "compra": 1507.50, "venta": 1508.10 }
    }
  ],
  "ultima_corrida": { ... }
}
```

## Requerimientos Técnicos

### 1. Integración con Firebase Cloud Messaging (FCM)

**Pasos:**
1. Crear proyecto en [Firebase Console](https://console.firebase.google.com/)
2. Habilitar Cloud Messaging API
3. Obtener credenciales (service account JSON)
4. Instalar SDK de Firebase Admin (Python):
   ```bash
   pip install firebase-admin
   ```

**Código base para inicializar:**
```python
import firebase_admin
from firebase_admin import credentials, messaging

# Inicializar Firebase (solo una vez)
cred = credentials.Certificate("path/to/serviceAccountKey.json")
firebase_admin.initialize_app(cred)
```

### 2. Notificación de Apertura del Mercado

**Lógica:**
- **Trigger**: Cuando se detecta la primera corrida del día entre 11:15 y 12:15
- **Condición**: Solo enviar si es la primera vez que se detecta hoy (evitar duplicados)
- **Contenido**: 
  - Título: "Apertura del mercado"
  - Mensaje: "El dólar blue [subió/bajó] a $X.XXX" (usar precio de venta)
  - Comparar con el último precio del día anterior (si existe)

**Ejemplo de mensaje:**
```
"El dólar blue subió a $1.485,00"
```

**Implementación sugerida:**
```python
def enviar_notificacion_apertura(corrida_actual, precio_anterior=None):
    """
    Envía notificación cuando se detecta la apertura del mercado.
    
    Args:
        corrida_actual: Primera corrida del día (dict con datos de dólares)
        precio_anterior: Precio de cierre del día anterior (opcional)
    """
    hora_actual = datetime.now().time()
    
    # Verificar si está en el rango de apertura
    if not (time(11, 15) <= hora_actual <= time(12, 15)):
        return False
    
    # Verificar si ya se envió hoy (usar cache/DB)
    if ya_enviado_apertura_hoy():
        return False
    
    precio_blue = corrida_actual.get('dolar_blue', {}).get('venta')
    if not precio_blue:
        return False
    
    # Determinar si subió o bajó
    if precio_anterior:
        if precio_blue > precio_anterior:
            accion = "subió"
        elif precio_blue < precio_anterior:
            accion = "bajó"
        else:
            accion = "se mantiene en"
    else:
        accion = "abre en"
    
    mensaje = f"El dólar blue {accion} a ${precio_blue:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.')
    
    # Enviar notificación push
    enviar_push_notification(
        title="Apertura del mercado",
        body=mensaje,
        data={"tipo": "apertura", "dolar": "blue", "precio": precio_blue}
    )
    
    # Marcar como enviado
    marcar_apertura_enviada_hoy()
    return True
```

### 3. Notificación de Cierre del Día

**Lógica:**
- **Trigger**: Programar diariamente a las 19:00 (hora Argentina, UTC-3)
- **Cálculos necesarios**:
  1. Primera corrida del día (apertura)
  2. Última corrida del día (cierre)
  3. Variación porcentual: `((cierre - apertura) / apertura) * 100`
  4. Brecha con dólar oficial: `((blue_venta - oficial_venta) / oficial_venta) * 100`

**Contenido:**
- Título: "Cierre del día"
- Mensaje: "Dólar Blue [subió/bajó] X,XX% y cerró el día a $X.XXX,XX. La brecha con el Dólar Oficial [sube/baja] al X,X%"

**Ejemplo de mensaje:**
```
"Dólar Blue bajó 0,34% y cerró el día a $1.485,00. La brecha con el Dólar Oficial desciende al 1,4%"
```

**Implementación sugerida:**
```python
def enviar_notificacion_cierre(fecha):
    """
    Envía notificación de cierre del día con resumen.
    
    Args:
        fecha: Fecha del día a resumir (datetime.date)
    """
    # Cargar JSON del día
    json_data = cargar_json_del_dia(fecha)
    
    if not json_data or not json_data.get('corridas'):
        return False
    
    corridas = json_data['corridas']
    primera_corrida = corridas[0]
    ultima_corrida = corridas[-1]
    
    # Precios de apertura y cierre
    blue_apertura = primera_corrida.get('dolar_blue', {}).get('venta')
    blue_cierre = ultima_corrida.get('dolar_blue', {}).get('venta')
    oficial_cierre = ultima_corrida.get('dolar_oficial', {}).get('nacion', {}).get('venta')
    
    if not blue_apertura or not blue_cierre:
        return False
    
    # Calcular variación
    variacion = ((blue_cierre - blue_apertura) / blue_apertura) * 100
    
    # Determinar dirección
    if variacion > 0:
        direccion = "subió"
    elif variacion < 0:
        direccion = "bajó"
    else:
        direccion = "se mantuvo"
    
    # Calcular brecha con oficial
    brecha_texto = ""
    if oficial_cierre:
        brecha = ((blue_cierre - oficial_cierre) / oficial_cierre) * 100
        if brecha > 0:
            brecha_direccion = "sube"
        else:
            brecha_direccion = "desciende"
        brecha_texto = f" La brecha con el Dólar Oficial {brecha_direccion} al {abs(brecha):.1f}%."
    
    # Formatear mensaje
    precio_formateado = f"${blue_cierre:,.2f}".replace(',', 'X').replace('.', ',').replace('X', '.')
    variacion_formateada = f"{abs(variacion):.2f}".replace('.', ',')
    
    mensaje = f"Dólar Blue {direccion} {variacion_formateada}% y cerró el día a {precio_formateado}.{brecha_texto}"
    
    # Enviar notificación push
    enviar_push_notification(
        title="Cierre del día",
        body=mensaje,
        data={"tipo": "cierre", "dolar": "blue", "precio": blue_cierre, "variacion": variacion}
    )
    
    return True
```

### 4. Función para Enviar Push Notifications

```python
def enviar_push_notification(title, body, data=None, topic="all_users"):
    """
    Envía notificación push a todos los usuarios suscritos al topic.
    
    Args:
        title: Título de la notificación
        body: Cuerpo del mensaje
        data: Datos adicionales (dict)
        topic: Topic de FCM (default: "all_users")
    """
    message = messaging.Message(
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=data or {},
        topic=topic,  # Todos los usuarios suscritos al topic "all_users"
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
    
    try:
        response = messaging.send(message)
        print(f"✅ Notificación enviada: {response}")
        return True
    except Exception as e:
        print(f"❌ Error al enviar notificación: {e}")
        return False
```

### 5. Sistema de Programación (Cron Job)

**Para la notificación de cierre (19:00 diario):**
```python
# Usar cron o scheduler (ej: APScheduler)
from apscheduler.schedulers.blocking import BlockingScheduler

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

**Para la notificación de apertura:**
- Integrar en el proceso de scraping existente
- Cuando se detecta la primera corrida del día entre 11:15-12:15, llamar a `enviar_notificacion_apertura()`

### 6. Persistencia (Evitar Duplicados)

**Usar cache/DB para evitar enviar múltiples veces:**
```python
# Ejemplo con Redis o archivo JSON
import json
from datetime import date

def ya_enviado_apertura_hoy():
    """Verifica si ya se envió la notificación de apertura hoy."""
    hoy = date.today().isoformat()
    try:
        with open('notificaciones_enviadas.json', 'r') as f:
            data = json.load(f)
            return data.get('apertura') == hoy
    except:
        return False

def marcar_apertura_enviada_hoy():
    """Marca que se envió la notificación de apertura hoy."""
    hoy = date.today().isoformat()
    try:
        with open('notificaciones_enviadas.json', 'r') as f:
            data = json.load(f)
    except:
        data = {}
    
    data['apertura'] = hoy
    
    with open('notificaciones_enviadas.json', 'w') as f:
        json.dump(data, f)
```

## Estructura de Archivos Sugerida

```
backend/
├── notifications/
│   ├── __init__.py
│   ├── fcm_service.py      # Inicialización de Firebase
│   ├── apertura.py          # Lógica de notificación de apertura
│   ├── cierre.py             # Lógica de notificación de cierre
│   └── scheduler.py          # Programación de tareas
├── serviceAccountKey.json    # Credenciales de Firebase (NO commitear)
└── notificaciones_enviadas.json  # Cache de notificaciones enviadas
```

## Checklist de Implementación

- [ ] Crear proyecto en Firebase Console
- [ ] Obtener service account key
- [ ] Instalar `firebase-admin` en Python
- [ ] Implementar función de envío de push notifications
- [ ] Integrar lógica de apertura en el proceso de scraping
- [ ] Implementar scheduler para cierre diario (19:00)
- [ ] Implementar sistema de persistencia para evitar duplicados
- [ ] Probar con topic de test antes de producción
- [ ] Documentar cómo los usuarios se suscriben al topic (se hará desde la app móvil)

## Notas Importantes

1. **Zona horaria**: Usar `America/Argentina/Buenos_Aires` (UTC-3)
2. **Formato de números**: Usar formato argentino (punto para miles, coma para decimales)
3. **Manejo de errores**: Implementar logging y manejo de excepciones
4. **Testing**: Probar primero con un topic de test antes de enviar a producción
5. **Rate limiting**: FCM tiene límites, pero para este caso no debería ser problema

## Próximos Pasos (App Móvil)

La app móvil necesitará:
1. Integrar Firebase Cloud Messaging SDK
2. Suscribir usuarios al topic "all_users" al iniciar la app
3. Manejar notificaciones cuando la app está en foreground/background
4. Navegar a la pantalla correcta cuando se toca la notificación

---

**¿Preguntas o dudas sobre la implementación?** Este prompt cubre toda la lógica necesaria para el backend.

