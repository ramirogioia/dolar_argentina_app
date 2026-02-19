#!/bin/bash
set -e

# Build iOS IPA para App Store Connect / TestFlight.
# Usa tu perfil: Team 93QAZPHZ99. El archive se crea sin firma; el export firma con
# perfil de distribución (incluye Push si está en el perfil de la cuenta).

echo "📦 Preparando build de Flutter..."
echo "   (Firma en export: tu cuenta, Team 93QAZPHZ99)"
echo ""

# Ir a la raíz del proyecto
cd "$(dirname "$0")/.."
SCRIPT_DIR="$(pwd)"
IOS_DIR="$SCRIPT_DIR/ios"

# ----- Checks previos: Push Notifications configurado -----
echo "🔍 Verificando configuración de Push Notifications..."

if [ ! -f "$IOS_DIR/Runner/Runner.entitlements" ]; then
  echo "❌ Falta ios/Runner/Runner.entitlements"
  exit 1
fi
if ! grep -q "aps-environment" "$IOS_DIR/Runner/Runner.entitlements"; then
  echo "❌ Runner.entitlements no contiene aps-environment (necesario para notis iOS)"
  exit 1
fi
echo "   ✅ Runner.entitlements tiene aps-environment"

if ! grep -q "com.apple.Push" "$IOS_DIR/Runner.xcodeproj/project.pbxproj"; then
  echo "❌ El proyecto Xcode no tiene la capability Push Notifications"
  exit 1
fi
echo "   ✅ Proyecto tiene capability Push Notifications"
echo ""

# Build de Flutter sin code signing
flutter build ios --release --no-codesign

echo ""
echo "📦 Creando archive desde el build de Flutter..."

cd ios

# Limpiar archive anterior
rm -rf ../build/Runner.xcarchive ../build/ipa

# Archive SIN firma (evita conflicto con Automatic signing). El export firmará con distribución.
xcodebuild archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath ../build/Runner.xcarchive \
  -destination "generic/platform=iOS" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  -allowProvisioningUpdates

echo ""
echo "📤 Exportando IPA para App Store Connect..."

# Verificar certificados disponibles
echo "🔍 Verificando certificados disponibles..."
CERT_COUNT=$(security find-identity -v -p codesigning | grep -c "Distribution" || echo "0")
if [ "$CERT_COUNT" = "0" ]; then
  echo "❌ No se encontraron certificados de Distribution"
  echo ""
  echo "📋 Para descargar certificados:"
  echo "   1. Ve a https://developer.apple.com/account"
  echo "   2. Certificates, Identifiers & Profiles > Certificates"
  echo "   3. Descarga un certificado 'Apple Distribution'"
  echo "   4. Doble click para instalarlo"
  echo ""
  echo "   O ver: ios/SETUP_CERTIFICATES.md para instrucciones detalladas"
  echo ""
  echo "⚠️  Continuando sin certificados (fallará el export)..."
else
  echo "✅ Encontrados $CERT_COUNT certificado(s) de Distribution"
fi

echo ""
echo "💡 Si falla con 'No Accounts' o 'Invalid trust settings':"
echo "   1. Abre Xcode brevemente: open -a Xcode ios/Runner.xcworkspace"
echo "   2. Xcode > Settings > Accounts"
echo "   3. Agrega tu Apple ID con Team 93QAZPHZ99"
echo "   4. Click en 'Download Manual Profiles'"
echo "   5. Cierra Xcode y vuelve a ejecutar este script"
echo ""

# Exportar el IPA (aquí se aplica la firma de distribución)
xcodebuild -exportArchive \
  -archivePath ../build/Runner.xcarchive \
  -exportPath ../build/ipa \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates 2>&1 | tee /tmp/xcode_export.log || {
    EXPORT_ERROR=$(cat /tmp/xcode_export.log)
    echo ""
    echo "❌ Export falló. Revisando el error..."
    echo ""

    if echo "$EXPORT_ERROR" | grep -q "No accounts"; then
      echo "🔴 No hay cuentas configuradas en Xcode"
      echo "   Abre Xcode → Settings → Accounts → Agrega tu Apple ID (Team 93QAZPHZ99)"
      echo "   Luego 'Download Manual Profiles' y vuelve a ejecutar este script."
    elif echo "$EXPORT_ERROR" | grep -q "No valid.*certificates"; then
      echo "🔴 No hay certificados válidos de Distribution"
      echo "   Descarga el certificado Apple Distribution desde developer.apple.com e instálalo."
    else
      echo "$EXPORT_ERROR" | tail -30
    fi
    exit 1
  }

cd ..

echo ""
echo "✅ Build completado!"
# El nombre del IPA puede ser Runner.ipa o el del scheme (ej. dolar_argentina_app.ipa)
IPA_NAME=$(ls -1 build/ipa/*.ipa 2>/dev/null | head -1)
if [ -n "$IPA_NAME" ]; then
  echo "📱 IPA disponible en: $IPA_NAME"
else
  echo "📱 IPA en: build/ipa/"
fi
echo ""

# ----- Check post-export: que el perfil del IPA incluya Push -----
echo "🔍 Verificando que el perfil del IPA incluya Push..."
IPA_PATH="${IPA_NAME:-$SCRIPT_DIR/build/ipa/Runner.ipa}"
if [ -z "$IPA_PATH" ] || [ ! -f "$IPA_PATH" ]; then
  IPA_PATH=$(ls -1 build/ipa/*.ipa 2>/dev/null | head -1)
fi
if [ -n "$IPA_PATH" ] && [ -f "$IPA_PATH" ]; then
  UNZIP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t build_archive)
  if unzip -q -o "$IPA_PATH" -d "$UNZIP_DIR" 2>/dev/null; then
    PROV="$UNZIP_DIR/Payload/Runner.app/embedded.mobileprovision"
    if [ -f "$PROV" ]; then
      if security cms -D -i "$PROV" 2>/dev/null | grep -q "aps-environment"; then
        echo "   ✅ Perfil del IPA incluye Push (aps-environment) → notis deberían funcionar en dispositivo"
      else
        echo "   ⚠️ El perfil del IPA no muestra aps-environment."
        echo "   En Apple Developer: App ID debe tener Push Notifications; perfil de distribución debe incluirlo."
        echo "   Desinstalá la app en el iPhone e instalá de nuevo desde TestFlight."
      fi
    else
      echo "   ⚠️ No se encontró embedded.mobileprovision en el IPA"
    fi
  fi
  rm -rf "$UNZIP_DIR" 2>/dev/null || true
else
  echo "   ⚠️ IPA no encontrado en build/ipa/, no se pudo verificar"
fi
echo ""
echo "Para subir a App Store Connect:"
echo "1. Abre Transporter (Mac App Store)"
echo "2. Arrastra el .ipa que está en: build/ipa/"
echo ""
echo "Si las notificaciones no funcionan en iOS:"
echo "- En Firebase Console: subí la clave APNs (.p8) en Cloud Messaging → Apple."
echo "- Desinstalá la app en el iPhone e instalá de nuevo desde TestFlight."
echo ""
