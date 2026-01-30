# Script para solo ver logs filtrados (sin ejecutar Flutter)
# Útil si ya tienes Flutter corriendo en otra terminal
# Uso: .\run_filtered_logs_only.ps1

Write-Host "📋 Limpiando logs anteriores..." -ForegroundColor Cyan
adb logcat -c

Write-Host "🔍 Mostrando solo logs de DolarApp y Flutter..." -ForegroundColor Green
Write-Host "   (Presiona Ctrl+C para salir)" -ForegroundColor Yellow
Write-Host ""

adb logcat -s DolarApp:* flutter:I *:S

