#!/bin/bash
set -e

echo "📦 Preparando build de Flutter..."

# Ir a la raíz del proyecto
cd "$(dirname "$0")/.."

# Primero hacer el build de Flutter (esto ya funciona sin code signing)
flutter build ios --release --no-codesign

echo ""
echo "📦 Creando archive desde el build de Flutter..."

cd ios

# Limpiar archive anterior (el build de Flutter queda en ../build/)
rm -rf ../build/Runner.xcarchive ../build/ipa

# Crear el archive usando el app que Flutter ya compiló
# Deshabilitar code signing durante el archive - el export lo manejará
xcodebuild archive \
  -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath ../build/Runner.xcarchive \
  -destination "generic/platform=iOS" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO

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

# Exportar el IPA - especificando el certificado explícitamente
echo ""
echo "💡 Si falla con 'No Accounts' o 'Invalid trust settings':"
echo "   1. Abre Xcode brevemente: open -a Xcode ios/Runner.xcworkspace"
echo "   2. Xcode > Settings > Accounts"
echo "   3. Agrega tu Apple ID con Team 93QAZPHZ99"
echo "   4. Click en 'Download Manual Profiles'"
echo "   5. Cierra Xcode y vuelve a ejecutar este script"
echo ""

# Intentar exportar con automatic provisioning
echo "💡 Intentando exportar con automatic provisioning..."
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
      echo "🔴 Problema: No hay cuentas configuradas en Xcode"
      echo ""
      echo "Solución:"
      echo "  1. Abre Xcode:"
      echo "     open -a Xcode ios/Runner.xcworkspace"
      echo ""
      echo "  2. En Xcode:"
      echo "     - Xcode > Settings (⌘,) > Accounts"
      echo "     - Click en '+' > Apple ID"
      echo "     - Ingresa tu Apple ID (con acceso al Team 93QAZPHZ99)"
      echo "     - Selecciona el Team 93QAZPHZ99"
      echo "     - Click en 'Download Manual Profiles'"
      echo "     - Espera a que termine"
      echo ""
      echo "  3. Cierra Xcode y vuelve a ejecutar este script"
    elif echo "$EXPORT_ERROR" | grep -q "No valid.*certificates"; then
      echo "🔴 Problema: No hay certificados válidos"
      echo ""
      echo "Solución:"
      echo "  Ver: ios/SETUP_CERTIFICATES.md"
    elif echo "$EXPORT_ERROR" | grep -q "Invalid trust settings"; then
      echo "🔴 Problema: Certificados con configuración de confianza inválida"
      echo ""
      echo "✅ SOLUCIÓN RÁPIDA:"
      echo ""
      echo "   Manualmente:"
      echo "   1. Abre Keychain Access:"
      echo "      open -a 'Keychain Access'"
      echo ""
      echo "   2. Selecciona 'login' keychain (lado izquierdo)"
      echo "   3. Selecciona categoría 'My Certificates' (arriba)"
      echo "   4. Busca certificados 'Apple Distribution' o 'Apple Development'"
      echo "   5. Doble click en CADA certificado encontrado"
      echo "   6. Expande 'Trust' (Confianza)"
      echo "   7. En 'When using this certificate' selecciona: 'Use System Defaults'"
      echo "   8. Cierra la ventana (se guarda automáticamente)"
      echo "   9. Repite para el certificado 'Apple Worldwide Developer Relations' si existe"
      echo ""
      echo "   Luego vuelve a ejecutar: cd ios && ./build_archive.sh"
    else
      echo "🔴 Error desconocido. Detalles:"
      echo "$EXPORT_ERROR" | tail -20
      echo ""
      echo "💡 Intenta:"
      echo "  1. Ver: ios/SETUP_CERTIFICATES.md"
      echo "  2. Abrir Xcode y configurar la cuenta (ver arriba)"
    fi
    echo ""
    exit 1
  }

cd ..

echo ""
echo "✅ Build completado!"
echo "📱 IPA disponible en: build/ipa/Runner.ipa"
echo ""
echo "Para subir a App Store Connect:"
echo "1. Abre Transporter app (Mac App Store)"
echo "2. Arrastra: build/ipa/Runner.ipa"
echo ""
