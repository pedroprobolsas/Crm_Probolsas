# Script para ejecutar el diagnóstico de webhooks y triggers
# Este script ejecuta el script SQL diagnose_webhook_triggers.sql

Write-Host "Iniciando diagnóstico de webhooks y triggers..." -ForegroundColor Cyan

# Verificar si el archivo de diagnóstico existe
if (-not (Test-Path "diagnose_webhook_triggers.sql")) {
    Write-Host "Error: No se encontró el archivo diagnose_webhook_triggers.sql" -ForegroundColor Red
    exit 1
}

# Leer el contenido del archivo SQL
$sqlContent = Get-Content -Path "diagnose_webhook_triggers.sql" -Raw

Write-Host "Se ha leído el script de diagnóstico" -ForegroundColor Green

# Instrucciones para el usuario
Write-Host "`nPara ejecutar el diagnóstico, sigue estos pasos:" -ForegroundColor Green
Write-Host "1. Accede a la consola SQL de Supabase" -ForegroundColor White
Write-Host "2. Copia y pega el contenido del archivo diagnose_webhook_triggers.sql" -ForegroundColor White
Write-Host "3. Ejecuta el script y revisa los resultados" -ForegroundColor White
Write-Host "4. Verifica los logs de Supabase para obtener más información" -ForegroundColor White

# Mostrar un resumen de las consultas que se ejecutarán
Write-Host "`nResumen de las consultas que se ejecutarán:" -ForegroundColor Cyan
Write-Host "1. Listar todos los triggers en la tabla messages" -ForegroundColor White
Write-Host "2. Verificar todas las configuraciones de webhooks en app_settings" -ForegroundColor White
Write-Host "3. Verificar el entorno (producción o pruebas)" -ForegroundColor White
Write-Host "4. Verificar si la extensión http está instalada y disponible" -ForegroundColor White
Write-Host "5. Verificar si la función http_post existe y su definición" -ForegroundColor White
Write-Host "6. Verificar la definición de todas las funciones relacionadas con webhooks" -ForegroundColor White
Write-Host "7. Verificar mensajes recientes con asistente_ia_activado=true" -ForegroundColor White
Write-Host "8. Verificar mensajes recientes de agentes" -ForegroundColor White
Write-Host "9. Instrucciones para verificar los logs" -ForegroundColor White

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

Write-Host "`nRecuerda también verificar las Edge Functions según las instrucciones en check_edge_functions.md" -ForegroundColor Yellow
