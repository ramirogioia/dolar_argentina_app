#!/bin/bash
# Empaqueta los dSYM del archive para subirlos a Firebase Crashlytics.
# Ejecutar DESPUÉS de: ./ios/build_archive.sh  o  flutter build ipa --release
#
# Uso: chmod +x ios/zip_dsyms_for_firebase.sh && ./ios/zip_dsyms_for_firebase.sh

set -e
cd "$(dirname "$0")/.."

DSYM_REL=""
if [ -d "build/Runner.xcarchive/dSYMs" ]; then
  DSYM_REL="build/Runner.xcarchive/dSYMs"
elif [ -d "build/ios/archive/Runner.xcarchive/dSYMs" ]; then
  DSYM_REL="build/ios/archive/Runner.xcarchive/dSYMs"
else
  echo "❌ No se encontró dSYMs. Generá primero el IPA:"
  echo "     ./ios/build_archive.sh"
  echo "   o:"
  echo "     flutter build ipa --release"
  exit 1
fi

OUT="build/dsyms_for_firebase.zip"
mkdir -p build
rm -f "$OUT"
zip -r -q "$OUT" "$DSYM_REL"

echo "✅ Listo: $OUT"
echo "   Subilo en Firebase Console → Crashlytics → dSYM faltante (acepta .zip)."
echo "   Coincide con la versión del IPA (pubspec: version en la raíz del proyecto)."
