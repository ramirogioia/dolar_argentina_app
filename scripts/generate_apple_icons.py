#!/usr/bin/env python3
"""
Genera el set de iconos iOS (AppIcon.appiconset) desde una imagen fuente.
La imagen se redimensiona a 1024x1024 y se exporta sin canal alpha (requisito de Apple).
Requiere: pip install Pillow
"""
import json
import os
import re
import sys

try:
    from PIL import Image
except ImportError:
    print("Necesitas Pillow: pip3 install Pillow")
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.join(SCRIPT_DIR, "..")
ICONSET = os.path.join(PROJECT_ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
CONTENTS_JSON = os.path.join(ICONSET, "Contents.json")


def parse_size(s: str) -> float:
    """'20x20' -> 20.0, '83.5x83.5' -> 83.5"""
    return float(s.split("x")[0])


def parse_scale(scale: str) -> int:
    """'1x' -> 1, '2x' -> 2, '3x' -> 3"""
    return int(scale.replace("x", ""))


def main():
    if len(sys.argv) < 2:
        print("Uso: python3 generate_apple_icons.py <imagen_fuente.png>")
        sys.exit(1)
    source_path = os.path.abspath(sys.argv[1])
    if not os.path.isfile(source_path):
        print(f"No se encuentra: {source_path}")
        sys.exit(1)
    if not os.path.isfile(CONTENTS_JSON):
        print(f"No encontrado: {CONTENTS_JSON}")
        sys.exit(1)

    with open(CONTENTS_JSON) as f:
        data = json.load(f)

    img = Image.open(source_path).convert("RGBA")
    w, h = img.size
    # Cuadrar y redimensionar a 1024
    size = 1024
    if w != h:
        side = min(w, h)
        left = (w - side) // 2
        top = (h - side) // 2
        img = img.crop((left, top, left + side, top + side))
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    # Sin alpha: aplanar sobre fondo por si acaso
    if img.mode == "RGBA":
        bg = Image.new("RGB", (size, size), (0xD9, 0xED, 0xF7))
        bg.paste(img, mask=img.split()[3])
        base = bg
    else:
        base = img.convert("RGB")

    entries = []
    for entry in data["images"]:
        filename = entry["filename"]
        sz = entry["size"]
        scale = entry.get("scale", "1x")
        px = int(round(parse_size(sz) * parse_scale(scale)))
        entries.append((filename, px))

    for filename, px in entries:
        out = base.resize((px, px), Image.Resampling.LANCZOS)
        out_path = os.path.join(ICONSET, filename)
        out.save(out_path)
        print(f"  {filename} ({px}x{px})")

    print("Listo. Iconos generados sin canal alpha (válidos para Apple).")


if __name__ == "__main__":
    main()
