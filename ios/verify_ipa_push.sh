#!/bin/bash
# Verifica que el IPA generado tenga Push Notifications en el perfil (sin usar Xcode).
# Uso: ./ios/verify_ipa_push.sh   o   ./ios/verify_ipa_push.sh build/ipa/mi_app.ipa

set -e
cd "$(dirname "$0")/.."
SCRIPT_DIR="$(pwd)"

# Buscar el IPA: argumento o el último en build/ipa/
if [ -n "$1" ] && [ -f "$1" ]; then
  IPA_PATH="$1"
else
  IPA_PATH=$(ls -1t build/ipa/*.ipa 2>/dev/null | head -1)
fi

if [ -z "$IPA_PATH" ] || [ ! -f "$IPA_PATH" ]; then
  echo "❌ No se encontró ningún .ipa"
  echo "   Ejecutá primero: ./ios/build_archive.sh"
  echo "   O pasá la ruta: ./ios/verify_ipa_push.sh build/ipa/dolar_argentina_app.ipa"
  exit 1
fi

echo "🔍 Verificando: $IPA_PATH"
echo ""

UNZIP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t verify_ipa)
trap 'rm -rf "$UNZIP_DIR"' EXIT

if ! unzip -q -o "$IPA_PATH" -d "$UNZIP_DIR" 2>/dev/null; then
  echo "❌ No se pudo descomprimir el IPA"
  exit 1
fi

PROV="$UNZIP_DIR/Payload/Runner.app/embedded.mobileprovision"
if [ ! -f "$PROV" ]; then
  echo "❌ No se encontró embedded.mobileprovision en el IPA"
  exit 1
fi

echo "Perfil embebido (entitlements relevantes):"
echo "----------------------------------------"
if security cms -D -i "$PROV" 2>/dev/null | grep -E "aps-environment|application-identifier" -A1; then
  echo "----------------------------------------"
  if security cms -D -i "$PROV" 2>/dev/null | grep -q "aps-environment"; then
    echo ""
    echo "✅ El IPA incluye Push (aps-environment). Listo para subir a TestFlight."
  else
    echo ""
    echo "⚠️ El perfil no tiene aps-environment. Las notificaciones pueden no funcionar en iOS."
  fi
else
  echo "⚠️ No se pudo decodificar el perfil (¿keychain bloqueado?). Revisá que el IPA sea el generado por build_archive.sh."
fi
echo ""
