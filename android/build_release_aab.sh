#!/bin/bash
set -e

echo "📦 Build AAB para Google Play Store"
echo ""

# Ir a la raíz del proyecto
cd "$(dirname "$0")/.."

# Verificar que exista key.properties (firma de release)
if [ ! -f "android/key.properties" ]; then
  echo "❌ No existe android/key.properties"
  echo ""
  echo "Para subir al Play Store necesitás firmar el AAB con un keystore de release."
  echo "Pasos (solo una vez):"
  echo ""
  echo "  1. Crear el keystore:"
  echo "     cd android"
  echo "     keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload"
  echo ""
  echo "  2. Crear android/key.properties con:"
  echo "     storePassword=TU_PASSWORD"
  echo "     keyPassword=TU_PASSWORD"
  echo "     keyAlias=upload"
  echo "     storeFile=../upload-keystore.jks"
  echo ""
  echo "  (Guardá el keystore y las contraseñas en un lugar seguro; sin ellos no podés actualizar la app.)"
  echo ""
  echo "  Ver docs/ANDROID_RELEASE.md para más detalle."
  echo ""
  exit 1
fi

echo "✅ key.properties encontrado"
echo ""

flutter build appbundle --release

echo ""
echo "✅ AAB generado:"
echo "   build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "Para subir al Play Store:"
echo "  1. https://play.google.com/console → Tu app → Producción (o Prueba interna)"
echo "  2. Crear nueva versión → Subir el archivo app-release.aab"
echo ""
