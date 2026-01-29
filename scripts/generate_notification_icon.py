#!/usr/bin/env python3
"""
Genera el icono de notificación para Android a partir del icono de la app.
Android requiere un icono en blanco sobre transparente (silueta) para la barra de notificaciones.
Requiere: pip install Pillow
"""
import os
import sys

try:
    from PIL import Image
except ImportError:
    print("Necesitas Pillow: pip3 install Pillow")
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.join(SCRIPT_DIR, "..")

# Origen: icono de la app (mismo que usás en iOS/home)
SOURCE_ICONS = [
    os.path.join(PROJECT_ROOT, "assets", "icon", "app_icon_final.png"),
    os.path.join(PROJECT_ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset", "Icon-App-1024x1024@1x.png"),
    os.path.join(PROJECT_ROOT, "assets", "icon", "app_icon_apple.png"),
]

# Salida: primero en scripts/ por si drawable no es escribible; luego copiar a drawable
OUTPUT_DRAWABLE = os.path.join(PROJECT_ROOT, "android", "app", "src", "main", "res", "drawable")
OUTPUT_IN_SCRIPTS = os.path.join(SCRIPT_DIR, "ic_notification.png")
OUTPUT_PATH = os.path.join(OUTPUT_DRAWABLE, "ic_notification.png")
SIZE = 96  # Tamaño recomendado para icono de notificación (xxxhdpi 24dp)
ALPHA_THRESHOLD = 40  # Píxeles con alpha > esto se convierten en blanco


def find_source():
    for path in SOURCE_ICONS:
        if os.path.isfile(path):
            return path
    return None


def image_to_white_silhouette(img: Image.Image, alpha_threshold: int = ALPHA_THRESHOLD) -> Image.Image:
    """Convierte la imagen a silueta blanca sobre transparente."""
    img = img.convert("RGBA")
    w, h = img.size
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    out_px = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > alpha_threshold:
                out_px[x, y] = (255, 255, 255, 255)
            else:
                out_px[x, y] = (0, 0, 0, 0)
    return out


def main():
    src = find_source()
    if not src:
        print("No se encontró ningún icono fuente. Revisá que exista assets/icon/app_icon_final.png o el 1024 de iOS.")
        sys.exit(1)

    print(f"Usando icono: {src}")
    img = Image.open(src)
    img = image_to_white_silhouette(img)
    img = img.resize((SIZE, SIZE), Image.Resampling.LANCZOS)
    os.makedirs(OUTPUT_DRAWABLE, exist_ok=True)
    try:
        img.save(OUTPUT_PATH, "PNG")
        print(f"Guardado: {OUTPUT_PATH} ({SIZE}x{SIZE})")
    except PermissionError:
        img.save(OUTPUT_IN_SCRIPTS, "PNG")
        print(f"Guardado en: {OUTPUT_IN_SCRIPTS}")
        print("Pasos para usar tu logo en notificaciones:")
        print("  1. Copiá scripts/ic_notification.png a android/app/src/main/res/drawable/ic_notification.png")
        print("  2. Borrá android/app/src/main/res/drawable/ic_notification.xml")
        print("  3. Recompilá la app")

    # Quitar el XML si existe, para que Android use el PNG
    xml_path = os.path.join(OUTPUT_DRAWABLE, "ic_notification.xml")
    if os.path.isfile(xml_path):
        try:
            os.remove(xml_path)
            print("Eliminado ic_notification.xml para usar el PNG generado.")
        except PermissionError:
            print("Eliminá manualmente android/.../drawable/ic_notification.xml para usar el PNG.")


if __name__ == "__main__":
    main()
