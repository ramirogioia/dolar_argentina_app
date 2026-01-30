#!/usr/bin/env python3
"""
Envía una notificación de prueba a un token FCM (ej. token de iOS).
Útil para probar si las notificaciones llegan al iPhone sin depender del topic.

Uso:
  pip install firebase-admin
  python scripts/send_test_push_ios.py TU_TOKEN_FCM

  O con el JSON de cuenta de servicio en otra ruta:
  python scripts/send_test_push_ios.py TU_TOKEN_FCM --cred serviceAccountKey.json

El token FCM lo ves en los logs de la app al abrirla (buscar "Token FCM" o "Token completo").
"""
import argparse
import os
import sys

try:
    import firebase_admin
    from firebase_admin import credentials, messaging
except ImportError:
    print("Instalá firebase-admin: pip install firebase-admin")
    sys.exit(1)


# Buscar JSON de cuenta de servicio (mismo que usa el backend)
DEFAULT_CREDS = [
    "serviceAccountKey.json",
    "google-services.json",  # no sirve para Admin SDK, pero probamos
]
# Si tenés el JSON en el backend:
DEFAULT_CREDS.extend([
    "../dolar_argentina_back/serviceAccountKey.json",
    "backend/serviceAccountKey.json",
])


def find_creds(path_hint=None):
    if path_hint and os.path.isfile(path_hint):
        return path_hint
    for p in DEFAULT_CREDS:
        if os.path.isfile(p):
            return p
    return None


def main():
    parser = argparse.ArgumentParser(description="Envía notificación de prueba al token FCM (iOS/Android)")
    parser.add_argument("token", help="Token FCM del dispositivo (lo mostrá la app al abrirla)")
    parser.add_argument("--cred", "-c", help="Ruta al JSON de cuenta de servicio de Firebase")
    parser.add_argument("--title", "-t", default="Prueba iOS", help="Título de la notificación")
    parser.add_argument("--body", "-b", default="Si ves esto, las notificaciones funcionan en tu iPhone.", help="Cuerpo")
    args = parser.parse_args()

    token = args.token.strip()
    if not token or len(token) < 20:
        print("❌ Token FCM inválido o muy corto. Pasá el token completo que muestra la app.")
        sys.exit(1)

    cred_path = find_creds(args.cred)
    if not cred_path:
        print("❌ No se encontró el JSON de cuenta de servicio (serviceAccountKey.json).")
        print("   Descargalo desde Firebase Console → Configuración del proyecto → Cuentas de servicio.")
        print("   Ponelo en la raíz del proyecto o pasá la ruta con --cred /ruta/al/archivo.json")
        sys.exit(1)

    if not firebase_admin._apps:
        cred = credentials.Certificate(cred_path)
        firebase_admin.initialize_app(cred)
        print(f"✅ Firebase inicializado con {cred_path}")

    # Mensaje para TOKEN (no topic), con APNs para iOS
    message = messaging.Message(
        notification=messaging.Notification(
            title=args.title,
            body=args.body,
        ),
        data={
            "tipo": "prueba",
            "origen": "script_ios",
        },
        token=token,
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
                    content_available=True,
                ),
            ),
        ),
    )

    try:
        response = messaging.send(message)
        print(f"✅ Enviado correctamente. ID: {response}")
        print("   Revisá el iPhone (y que no esté en No molestar).")
    except Exception as e:
        print(f"❌ Error al enviar: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
