# Script para aplicar todas las soluciones en un solo paso
# Este script ejecuta todos los scripts PowerShell para solucionar el problema del webhook de IA

# Mostrar información
Write-Host "Aplicando todas las soluciones para el problema del webhook de IA..." -ForegroundColor Cyan
Write-Host ""

# Ejecutar los scripts PowerShell
$scripts = @(
    "apply_create_message_whatsapp_status.ps1",
    "apply_fix_webhook_ia_completo.ps1",
    "test_webhook_ia.ps1",
    "run_verify_webhook_ia_status.ps1"
)

foreach ($script in $scripts) {
    if (-not (Test-Path $script)) {
        Write-Host "El archivo $script no existe en el directorio actual." -ForegroundColor Red
        exit 1
    }
}

foreach ($script in $scripts) {
    Write-Host "Ejecutando $script..." -ForegroundColor Cyan
    & ".\$script"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Error al ejecutar $script." -ForegroundColor Red
        exit 1
    }
    
    Write-Host "$script ejecutado correctamente." -ForegroundColor Green
    Write-Host ""
}

Write-Host "Todas las soluciones han sido aplicadas correctamente." -ForegroundColor Green
Write-Host ""
Write-Host "IMPORTANTE: Asegúrate de que los archivos de Edge Functions estén correctamente desplegados en Supabase:" -ForegroundColor Yellow
Write-Host "- supabase/functions/messages-outgoing/index.js" -ForegroundColor Yellow
Write-Host "- supabase/functions/messages-incoming/index.js" -ForegroundColor Yellow
Write-Host ""
Write-Host "Pasos para verificar:" -ForegroundColor Cyan
Write-Host "1. Accede a la consola de Supabase" -ForegroundColor Cyan
Write-Host "2. Ve a la sección de Logs" -ForegroundColor Cyan
Write-Host "3. Busca mensajes relacionados con 'IA webhook', como:" -ForegroundColor Cyan
Write-Host "   - 'Selected IA webhook URL: X (is_production=true/false)'" -ForegroundColor Cyan
Write-Host "   - 'IA webhook payload: {...}'" -ForegroundColor Cyan
Write-Host "   - 'IA webhook request succeeded for message ID: X'" -ForegroundColor Cyan
Write-Host ""
Write-Host "También puedes enviar un mensaje desde la interfaz de usuario con el asistente de IA activado para verificar que funciona correctamente." -ForegroundColor Cyan
