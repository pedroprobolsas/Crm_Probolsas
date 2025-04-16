# Script para aplicar la corrección final de webhooks y Edge Functions
# Este script ejecuta el script SQL fix_webhook_edge_functions_final.sql

Write-Host "Aplicando correcciones finales a webhooks y Edge Functions..." -ForegroundColor Cyan

# Verificar si el archivo de corrección existe
if (-not (Test-Path "fix_webhook_edge_functions_final.sql")) {
    Write-Host "Error: No se encontró el archivo fix_webhook_edge_functions_final.sql" -ForegroundColor Red
    exit 1
}

# Verificar si el archivo de instrucciones para Edge Functions existe
if (-not (Test-Path "README-edge-functions.md")) {
    Write-Host "Error: No se encontró el archivo README-edge-functions.md" -ForegroundColor Red
    exit 1
}

# Leer el contenido del archivo SQL
$sqlContent = Get-Content -Path "fix_webhook_edge_functions_final.sql" -Raw

Write-Host "Se ha leído el script de corrección" -ForegroundColor Green

# Instrucciones para el usuario
Write-Host "`nPara aplicar las correcciones finales, sigue estos pasos:" -ForegroundColor Green
Write-Host "1. Accede a la consola SQL de Supabase" -ForegroundColor White
Write-Host "2. Copia y pega el contenido del archivo fix_webhook_edge_functions_final.sql" -ForegroundColor White
Write-Host "3. Ejecuta el script y revisa los resultados" -ForegroundColor White
Write-Host "4. Sigue las instrucciones en README-edge-functions.md para corregir las Edge Functions" -ForegroundColor White
Write-Host "5. Verifica los logs de Supabase para confirmar que todo funciona correctamente" -ForegroundColor White

# Mostrar un resumen de las correcciones que se aplicarán
Write-Host "`nResumen de las correcciones que se aplicarán:" -ForegroundColor Cyan
Write-Host "1. Modificar la función notify_message_webhook para incluir el contenido en el payload" -ForegroundColor White
Write-Host "2. Recrear el trigger message_webhook_trigger" -ForegroundColor White
Write-Host "3. Crear una función http_post segura para evitar errores de sintaxis" -ForegroundColor White
Write-Host "4. Verificar si hay mensajes de agentes que se están tratando como mensajes de clientes" -ForegroundColor White
Write-Host "5. Insertar un mensaje de prueba con asistente_ia_activado=true" -ForegroundColor White
Write-Host "6. Crear una tabla message_whatsapp_status para rastrear el estado de envío a WhatsApp" -ForegroundColor White
Write-Host "7. Actualizar la Edge Function messages-outgoing para evitar modificar mensajes existentes" -ForegroundColor White

# Preguntar al usuario si desea ver el contenido del script SQL
$showContent = Read-Host "`n¿Deseas ver el contenido del script SQL? (s/n)"
if ($showContent -eq "s") {
    Write-Host "`nContenido del script SQL:" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    Write-Host $sqlContent
    Write-Host "----------------------------------------"
}

# Preguntar al usuario si desea copiar el contenido al portapapeles
$copyContent = Read-Host "`n¿Deseas copiar el contenido del script SQL al portapapeles? (s/n)"
if ($copyContent -eq "s") {
    $sqlContent | Set-Clipboard
    Write-Host "El contenido del script SQL ha sido copiado al portapapeles" -ForegroundColor Green
}

# Preguntar al usuario si desea ver las instrucciones para corregir las Edge Functions
$showEdgeFunctions = Read-Host "`n¿Deseas ver las instrucciones para corregir las Edge Functions? (s/n)"
if ($showEdgeFunctions -eq "s") {
    $edgeFunctionsContent = Get-Content -Path "README-edge-functions.md" -Raw
    Write-Host "`nInstrucciones para corregir las Edge Functions:" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
    Write-Host $edgeFunctionsContent
    Write-Host "----------------------------------------"
}

Write-Host "`nRecuerda verificar los logs de Supabase después de aplicar las correcciones para confirmar que todo funciona correctamente." -ForegroundColor Yellow
