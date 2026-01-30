# Script para ejecutar Flutter con logs filtrados
# Uso: .\run_with_filtered_logs.ps1

Write-Host "🚀 Iniciando Flutter con logs filtrados..." -ForegroundColor Green
Write-Host ""
Write-Host "📱 Terminal 1: Ejecutando Flutter..." -ForegroundColor Cyan
Write-Host "📋 Terminal 2: Ejecuta esto para ver logs filtrados:" -ForegroundColor Yellow
Write-Host "   adb logcat -s DolarApp:* flutter:I *:S" -ForegroundColor White
Write-Host ""

# Ejecutar Flutter en background
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$PWD'; flutter run -d emulator-5554"

# Esperar un momento para que Flutter inicie
Start-Sleep -Seconds 3

# Ejecutar adb logcat filtrado en otra ventana
Write-Host "📋 Abriendo terminal con logs filtrados..." -ForegroundColor Cyan
Start-Process powershell -ArgumentList "-NoExit", "-Command", "adb logcat -c; adb logcat -s DolarApp:* flutter:I *:S"

Write-Host ""
Write-Host "✅ Listo! Tienes dos ventanas:" -ForegroundColor Green
Write-Host "   1. Flutter run (para ver el output de compilación)" -ForegroundColor White
Write-Host "   2. Logs filtrados (solo DolarApp y Flutter)" -ForegroundColor White
Write-Host ""

