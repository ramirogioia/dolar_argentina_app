# Backend: qué enviar para que iOS reciba las notificaciones

Si el backend dice "enviado OK" pero **no llega al iPhone**, suele ser por el **formato del mensaje**. En iOS, FCM reenvía a APNs y APNs es más estricto que Android.

---

## 1. Incluir siempre el bloque `notification` (título y cuerpo)

iOS necesita que el mensaje tenga **notification** con **title** y **body** para que el sistema muestre la notificación en la bandeja. Si solo envías `data`, en Android puede funcionar y en iOS no.

**Correcto:**
```python
message = messaging.Message(
    notification=messaging.Notification(
        title="Apertura del mercado",
        body="El dólar blue subió a $1.485,00",
    ),
    data={"tipo": "apertura", ...},
    topic="all_users",
    ...
)
```

**Incorrecto para iOS:** enviar solo `data` sin `notification`.

---

## 2. Incluir siempre el bloque `apns` (APNSConfig)

Para que FCM entregue bien a iOS, el mensaje debe llevar configuración APNs explícita.

**Ejemplo con Firebase Admin SDK (Python):**

```python
message = messaging.Message(
    notification=messaging.Notification(
        title=title,
        body=body,
    ),
    data=data or {},
    topic="all_users",
    android=messaging.AndroidConfig(
        priority="high",
        notification=messaging.AndroidNotification(
            sound="default",
            channel_id="dolar_argentina_channel",
        ),
    ),
    apns=messaging.APNSConfig(
        payload=messaging.APNSPayload(
            aps=messaging.Aps(
                sound="default",
                badge=1,
                content_available=True,  # Ayuda a entrega en background
            ),
        ),
        fcm_options=messaging.APNSFCMOptions(
            image=None,
        ),
    ),
)
response = messaging.send(message)
```

Puntos importantes para `apns`:
- **aps.sound**: `"default"` para que suene.
- **aps.badge**: opcional (ej. `1`).
- **aps.content_available**: `True` suele mejorar la entrega cuando la app está en background.

---

## 3. Resumen de chequeo en el backend

| Revisión | Qué verificar |
|----------|----------------|
| **notification** | Que el mensaje tenga `notification` con `title` y `body`. |
| **apns** | Que el mensaje tenga `apns=messaging.APNSConfig(...)` con al menos `aps=messaging.Aps(sound="default")`. |
| **topic** | Que se envíe al topic `all_users` (mismo al que se suscribe la app). |
| **data** | Opcional; si usas `data`, que las claves/valores sean string (APNs exige strings en `data`). |

---

## 4. Si el backend ya tiene todo eso

Entonces revisar:
- **Firebase:** que la clave APNs (.p8) esté subida en Firebase Console → Project settings → Cloud Messaging → Apple app configuration.
- **iPhone:** Ajustes → Notificaciones → Dólar ARG permitidas; abrir la app al menos una vez para registrar token y topic.
- **Tiempo:** a veces tarda unos minutos después de subir la clave o cambiar el backend.

Si querés, podés pegar aquí (o en el repo del backend) el código donde armas el `messaging.Message` y lo revisamos.
