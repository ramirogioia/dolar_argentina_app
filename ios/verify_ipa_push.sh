#!/bin/bash
# Verifica que el IPA generado sea apto para Push en iOS.
# Incluye: perfil, entitlements del binario firmado, versión.
# Uso: ./ios/verify_ipa_push.sh   o   ./ios/verify_ipa_push.sh build/ipa/mi_app.ipa

set -e
cd "$(dirname "$0")/.."
SCRIPT_DIR="$(pwd)"

IPA_PATH="${1:-}"
if [ -z "$IPA_PATH" ] || [ ! -f "$IPA_PATH" ]; then
  IPA_PATH=$(ls -1t build/ipa/*.ipa 2>/dev/null | head -1)
fi

if [ -z "$IPA_PATH" ] || [ ! -f "$IPA_PATH" ]; then
  echo "❌ No se encontró ningún .ipa"
  echo "   Ejecutá: ./ios/build_archive.sh"
  echo "   O: ./ios/verify_ipa_push.sh build/ipa/dolar_argentina_app.ipa"
  exit 1
fi

echo "🔍 Verificación exhaustiva del IPA: $IPA_PATH"
echo ""

UNZIP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t verify_ipa)
trap 'rm -rf "$UNZIP_DIR"' EXIT

if ! unzip -q -o "$IPA_PATH" -d "$UNZIP_DIR" 2>/dev/null; then
  echo "❌ No se pudo descomprimir el IPA"
  exit 1
fi

APP="$UNZIP_DIR/Payload/Runner.app"
PROV="$APP/embedded.mobileprovision"

# ----- 1. Versión / Build -----
echo "━━━ 1. Versión (Info.plist) ━━━"
if [ -f "$APP/Info.plist" ]; then
  VERSION=$(plutil -p "$APP/Info.plist" 2>/dev/null | grep -E "CFBundleShortVersionString|CFBundleVersion" | head -2)
  echo "$VERSION"
else
  echo "⚠️ No se encontró Info.plist"
fi
echo ""

# ----- 2. Perfil de aprovisionamiento (embedded.mobileprovision) -----
echo "━━━ 2. Perfil embebido (embedded.mobileprovision) ━━━"
if [ ! -f "$PROV" ]; then
  echo "❌ No hay embedded.mobileprovision → el IPA no es válido para instalación"
  exit 1
fi

PROV_PLIST=$(mktemp 2>/dev/null || mktemp -t prov)
security cms -D -i "$PROV" 2>/dev/null > "$PROV_PLIST" || true
if [ -f "$PROV_PLIST" ] && [ -s "$PROV_PLIST" ]; then
  PROV_NAME=$(plutil -p "$PROV_PLIST" 2>/dev/null | grep -A1 '"Name"' | tail -1 | sed 's/.*"\(.*\)".*/\1/')
  echo "   Nombre del perfil: $PROV_NAME"
  echo ""
  echo "   Entitlements del perfil:"
  plutil -p "$PROV_PLIST" 2>/dev/null | grep -A50 "Entitlements" | head -20 || true
  echo ""

  if grep -q "aps-environment" "$PROV_PLIST" 2>/dev/null; then
    APS_VAL=$(grep -A1 "aps-environment" "$PROV_PLIST" | tail -1 | sed 's/.*"\(.*\)".*/\1/')
    echo "   ✅ aps-environment en perfil: $APS_VAL (production = TestFlight/App Store)"
  else
    echo "   ❌ El perfil NO tiene aps-environment"
    echo "   → Xcode está usando un perfil sin Push. Regenerá el perfil en developer.apple.com"
    rm -f "$PROV_PLIST"
    exit 1
  fi
else
  echo "⚠️ No se pudo decodificar el perfil"
fi
rm -f "$PROV_PLIST" 2>/dev/null || true
echo ""

# ----- 3. Entitlements del binario firmado -----
echo "━━━ 3. Entitlements del binario (codesign) ━━━"
BINARY="$APP/Runner"
if [ -f "$BINARY" ]; then
  ENT_XML=$(codesign -d --entitlements :- "$BINARY" 2>/dev/null || true)
  if [ -n "$ENT_XML" ]; then
    if echo "$ENT_XML" | grep -q "aps-environment"; then
      APS_BIN=$(echo "$ENT_XML" | grep -A1 "aps-environment" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
      echo "   ✅ Binario firmado con aps-environment: $APS_BIN"
    else
      echo "   ❌ El binario NO tiene aps-environment en su firma"
      echo "   → El export no aplicó correctamente los entitlements."
      echo "   → Probar: ExportOptions con manual + provisioningProfiles explícito"
    fi
  else
    echo "   ⚠️ No se pudieron leer los entitlements del binario"
  fi
else
  echo "   ⚠️ No se encontró el binario Runner"
fi
echo ""

# ----- 4. GoogleService-Info.plist (Firebase) -----
echo "━━━ 4. Firebase (GoogleService-Info.plist) ━━━"
if [ -f "$APP/GoogleService-Info.plist" ]; then
  echo "   ✅ GoogleService-Info.plist presente en el bundle"
else
  echo "   ❌ Falta GoogleService-Info.plist → Firebase no inicia en iOS"
fi
echo ""

# ----- Resumen -----
echo "━━━ Resumen ━━━"
if security cms -D -i "$PROV" 2>/dev/null | grep -q "aps-environment"; then
  echo "✅ Perfil: incluye Push"
  HAS_BIN_APS=false
  if [ -f "$BINARY" ]; then
    if codesign -d --entitlements :- "$BINARY" 2>/dev/null | grep -q "aps-environment"; then
      HAS_BIN_APS=true
    fi
  fi
  if [ "$HAS_BIN_APS" = true ]; then
    echo "✅ Binario: firmado con aps-environment"
    echo ""
    echo "El IPA debería funcionar para Push en TestFlight."
  else
    echo "⚠️ Binario: revisar entitlements (ver arriba)"
    echo ""
    echo "Si el dispositivo sigue con error 3000, probá:"
    echo "  - ios/ExportOptions.plist con signingStyle: manual y provisioningProfiles explícito"
    echo "  - Ver: ios/PUSH_IOS_OPCIONES_RESTANTES.md"
  fi
else
  echo "❌ El perfil NO tiene Push. Regenerá el perfil en developer.apple.com con Push habilitado."
fi
echo ""
