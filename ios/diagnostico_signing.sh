#!/bin/bash
# Diagnóstico: certificados y perfiles para Push iOS.
# Ejecutá: ./ios/diagnostico_signing.sh

echo "━━━ CERTIFICADOS DE FIRMA ━━━"
CERTS=$(security find-identity -v -p codesigning 2>/dev/null)
echo "$CERTS"
DIST_COUNT=$(echo "$CERTS" | grep -ci "distribution" || echo "0")
echo ""
echo "Certificados 'Distribution': $DIST_COUNT"
if [ "$DIST_COUNT" = "0" ]; then
  echo "  → Sin certificado Distribution, el export va a fallar."
  echo "  → Descargá 'Apple Distribution' de developer.apple.com e instalalo."
fi
echo ""

echo "━━━ PERFILES PARA com.rgioia.dolarargentina ━━━"
for f in ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision; do
  [ -f "$f" ] || continue
  PROV_XML=$(security cms -D -i "$f" 2>/dev/null)
  if echo "$PROV_XML" | grep -q "com.rgioia.dolarargentina"; then
    NAME=$(echo "$PROV_XML" | grep -A1 "<key>Name</key>" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    APS=$(echo "$PROV_XML" | grep -A1 "aps-environment" | tail -1 | sed 's/.*<string>\(.*\)<\/string>.*/\1/')
    echo "  • $NAME"
    echo "    aps-environment: ${APS:-no}"
  fi
done
echo ""

echo "━━━ CONCLUSIÓN ━━━"
if [ "$DIST_COUNT" = "0" ]; then
  echo "Necesitás instalar el certificado Apple Distribution."
  echo "Ver: ios/SETUP_CERTIFICATES.md"
else
  echo "Tenés certificado(s). Para forzar el perfil con Push, usá manual en ExportOptions."
fi
