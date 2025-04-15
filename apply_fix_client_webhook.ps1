# Script para aplicar la migración que soluciona el problema del webhook para mensajes de clientes

# Ruta al archivo de migración
$MIGRATION_FILE = "supabase/migrations/20250415000000_fix_client_webhook_with_http.sql"

# Verificar que el archivo existe
if (-not (Test-Path $MIGRATION_FILE)) {
    Write-Host "Error: No se encontró el archivo de migración: $MIGRATION_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "Aplicando la migración para solucionar el problema del webhook para mensajes de clientes..." -ForegroundColor Yellow

# Leer el contenido del archivo
$SQL_CONTENT = Get-Content -Path $MIGRATION_FILE -Raw

# Mostrar información sobre la migración
Write-Host "La migración realizará los siguientes cambios:" -ForegroundColor Yellow
Write-Host "1. Creará una función http_post que usa la extensión HTTP" -ForegroundColor Cyan
Write-Host "2. Modificará la función notify_message_webhook para usar http_post en lugar de net.http_post" -ForegroundColor Cyan
Write-Host "3. Recreará el trigger message_webhook_trigger" -ForegroundColor Cyan
Write-Host "4. Agregará más logging para identificar problemas" -ForegroundColor Cyan

# Preguntar al usuario si desea continuar
$CONTINUE = Read-Host "¿Desea aplicar esta migración? (S/N)"
if ($CONTINUE -ne "S" -and $CONTINUE -ne "s") {
    Write-Host "Operación cancelada por el usuario." -ForegroundColor Yellow
    exit 0
}

# Instrucciones para aplicar la migración
Write-Host "Para aplicar esta migración, siga estos pasos:" -ForegroundColor Yellow
Write-Host "1. Conéctese a la base de datos de Supabase usando la consola SQL o psql" -ForegroundColor Cyan
Write-Host "2. Ejecute el contenido del archivo: $MIGRATION_FILE" -ForegroundColor Cyan
Write-Host "3. Verifique los logs de Supabase para ver si hay información adicional sobre el problema" -ForegroundColor Cyan
Write-Host "4. Pruebe con un mensaje de cliente para verificar si la solución funciona" -ForegroundColor Cyan

# Mostrar el comando para aplicar la migración usando supabase CLI
Write-Host "Si está usando Supabase CLI, puede aplicar la migración con el siguiente comando:" -ForegroundColor Yellow
Write-Host "supabase db execute --file $MIGRATION_FILE" -ForegroundColor Cyan

# Preguntar al usuario si desea ver el contenido del archivo
$VIEW_CONTENT = Read-Host "¿Desea ver el contenido del archivo de migración? (S/N)"
if ($VIEW_CONTENT -eq "S" -or $VIEW_CONTENT -eq "s") {
    Write-Host "Contenido del archivo de migración:" -ForegroundColor Yellow
    Write-Host $SQL_CONTENT
}

Write-Host "Después de aplicar la migración, pruebe con un mensaje de cliente para verificar si la solución funciona." -ForegroundColor Yellow
Write-Host "Si el problema persiste, revise los logs de Supabase para obtener más información." -ForegroundColor Yellow
