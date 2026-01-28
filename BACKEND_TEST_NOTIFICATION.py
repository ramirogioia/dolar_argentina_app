#!/usr/bin/env python3
"""
Script de prueba para enviar notificaciones push desde el backend.

Uso:
    python BACKEND_TEST_NOTIFICATION.py --tipo apertura
    python BACKEND_TEST_NOTIFICATION.py --tipo cierre
    python BACKEND_TEST_NOTIFICATION.py --tipo custom --titulo "Mi título" --cuerpo "Mi mensaje"
"""

import firebase_admin
from firebase_admin import credentials, messaging
import argparse
import sys
from datetime import datetime

# ⚠️ IMPORTANTE: Ajusta la ruta al archivo serviceAccountKey.json
SERVICE_ACCOUNT_KEY_PATH = "serviceAccountKey.json"

# Topic al que están suscritos todos los usuarios
TOPIC = "all_users"


def inicializar_firebase():
    """Inicializa Firebase Admin SDK."""
    try:
        # Verificar si ya está inicializado
        firebase_admin.get_app()
        print("✅ Firebase ya está inicializado")
    except ValueError:
        # Inicializar Firebase
        try:
            cred = credentials.Certificate(SERVICE_ACCOUNT_KEY_PATH)
            firebase_admin.initialize_app(cred)
            print("✅ Firebase inicializado correctamente")
        except FileNotFoundError:
            print(f"❌ Error: No se encontró el archivo {SERVICE_ACCOUNT_KEY_PATH}")
            print("   Descárgalo desde Firebase Console → Project Settings → Service Accounts")
            sys.exit(1)
        except Exception as e:
            print(f"❌ Error al inicializar Firebase: {e}")
            sys.exit(1)


def enviar_notificacion_apertura():
    """Envía notificación de apertura del mercado."""
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
        topic=TOPIC,
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
    
    return enviar_mensaje(message, "apertura")


def enviar_notificacion_cierre():
    """Envía notificación de cierre del día."""
    message = messaging.Message(
        notification=messaging.Notification(
            title="Cierre del día",
            body="Dólar Blue bajó 0,34% y cerró el día a $1.485,00. La brecha con el Dólar Oficial desciende al 1,4%",
        ),
        data={
            "tipo": "cierre",
            "variacion": "-0.34",
            "precio": "1485.00",
            "brecha": "1.4"
        },
        topic=TOPIC,
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
    
    return enviar_mensaje(message, "cierre")


def enviar_notificacion_custom(titulo, cuerpo, tipo="custom"):
    """Envía una notificación personalizada."""
    message = messaging.Message(
        notification=messaging.Notification(
            title=titulo,
            body=cuerpo,
        ),
        data={
            "tipo": tipo,
            "timestamp": datetime.now().isoformat()
        },
        topic=TOPIC,
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
    
    return enviar_mensaje(message, tipo)


def enviar_mensaje(message, tipo_notificacion):
    """Envía el mensaje y maneja errores."""
    try:
        response = messaging.send(message)
        print(f"✅ Notificación '{tipo_notificacion}' enviada exitosamente")
        print(f"   Message ID: {response}")
        print(f"   Topic: {TOPIC}")
        return True
    except messaging.UnregisteredError:
        print(f"❌ Error: El topic '{TOPIC}' no tiene suscriptores")
        print("   Asegúrate de que la app móvil esté corriendo y suscrita al topic")
        return False
    except Exception as e:
        print(f"❌ Error al enviar notificación: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Envía notificaciones push de prueba desde el backend"
    )
    parser.add_argument(
        "--tipo",
        choices=["apertura", "cierre", "custom"],
        required=True,
        help="Tipo de notificación a enviar"
    )
    parser.add_argument(
        "--titulo",
        help="Título de la notificación (solo para tipo 'custom')"
    )
    parser.add_argument(
        "--cuerpo",
        help="Cuerpo del mensaje (solo para tipo 'custom')"
    )
    
    args = parser.parse_args()
    
    # Inicializar Firebase
    inicializar_firebase()
    
    # Enviar notificación según el tipo
    if args.tipo == "apertura":
        enviar_notificacion_apertura()
    elif args.tipo == "cierre":
        enviar_notificacion_cierre()
    elif args.tipo == "custom":
        if not args.titulo or not args.cuerpo:
            print("❌ Error: --titulo y --cuerpo son requeridos para tipo 'custom'")
            sys.exit(1)
        enviar_notificacion_custom(args.titulo, args.cuerpo)
    
    print("\n📱 Verifica que la notificación llegue a la app móvil")
    print("   - Si la app está en foreground: verás notificación local")
    print("   - Si la app está en background/cerrada: verás notificación del sistema")


if __name__ == "__main__":
    main()

