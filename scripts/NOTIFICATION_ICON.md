# Icono de notificación Android (tu logo)

Por defecto la app usa una "D" (Dólar) en blanco como icono de notificación. Para que las notificaciones muestren **tu logo** (Benjamin Franklin, bandera, etc.) en blanco:

1. Instalá Pillow si no lo tenés: `pip3 install Pillow`
2. Ejecutá: `python3 scripts/generate_notification_icon.py`
3. Si el script guardó en `scripts/ic_notification.png`:
   - Copiá `scripts/ic_notification.png` a `android/app/src/main/res/drawable/ic_notification.png`
   - Borrá `android/app/src/main/res/drawable/ic_notification.xml`
4. Recompilá la app.

El script toma tu icono (`assets/icon/app_icon_final.png` o el de iOS) y lo convierte en silueta blanca sobre transparente, que es lo que Android exige para la barra de notificaciones.
