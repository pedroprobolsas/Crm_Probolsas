# Script para aplicar la corrección de webhooks y Edge Functions
# Este script ejecuta el script SQL fix_webhook_edge_functions.sql

Write-Host "Aplicando correcciones a webhooks y Edge Functions..." -ForegroundColor Cyan

# Verificar si el archivo de corrección existe
if (-not (Test-Path "fix_webhook_edge_functions.sql")) {
    Write-Host "Error: No se encontró el archivo fix_webhook_edge_functions.sql" -ForegroundColor Red
    exit 1
}

# Leer el contenido del archivo SQL
$sqlContent = Get-Content -Path "fix_webhook_edge_functions.sql" -Raw

Write-Host "Se ha leído el script de corrección" -ForegroundColor Green

# Instrucciones para el usuario
Write-Host "`nPara aplicar las correcciones, sigue estos pasos:" -ForegroundColor Green
Write-Host "1. Accede a la consola SQL de Supabase" -ForegroundColor White
Write-Host "2. Copia y pega el contenido del archivo fix_webhook_edge_functions.sql" -ForegroundColor White
Write-Host "3. Ejecuta el script y revisa los resultados" -ForegroundColor White
Write-Host "4. Verifica los logs de Supabase para confirmar que el webhook de IA está funcionando correctamente" -ForegroundColor White
Write-Host "5. Verifica también las Edge Functions según las instrucciones en check_edge_functions.md" -ForegroundColor White

# Mostrar un resumen de las correcciones que se aplicarán
Write-Host "`nResumen de las correcciones que se aplicarán:" -ForegroundColor Cyan
Write-Host "1. Verificar y actualizar las URLs del webhook de IA en app_settings" -ForegroundColor White
Write-Host "2. Recrear la función notify_message_webhook con la lógica correcta" -ForegroundColor White
Write-Host "3. Recrear el trigger message_webhook_trigger" -ForegroundColor White
Write-Host "4. Verificar otros triggers que puedan estar interfiriendo" -ForegroundColor White
Write-Host "5. Verificar y crear la función http_post si es necesario" -ForegroundColor White
Write-Host "6. Verificar e instalar la extensión http si es necesario" -ForegroundColor White
Write-Host "7. Actualizar el mensaje 'Prueba 1500' para que tenga asistente_ia_activado=true" -ForegroundColor White
Write-Host "8. Insertar un mensaje de prueba con asistente_ia_activado=true" -ForegroundColor White

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

Write-Host "`nRecuerda verificar también las Edge Functions según las instrucciones en check_edge_functions.md" -ForegroundColor Yellow
Write-Host "Para ello, abre el archivo check_edge_functions.md y sigue las instrucciones" -ForegroundColor Yellow
