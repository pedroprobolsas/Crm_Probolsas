# Script para aplicar la migración que implementa el webhook de IA

# Ruta al archivo de migración
$MIGRATION_FILE = "supabase/migrations/20250416000000_add_ia_webhook_support.sql"

# Verificar que el archivo existe
if (-not (Test-Path $MIGRATION_FILE)) {
    Write-Host "Error: No se encontró el archivo de migración: $MIGRATION_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "Aplicando la migración para implementar el webhook de IA..." -ForegroundColor Yellow

# Leer el contenido del archivo
$SQL_CONTENT = Get-Content -Path $MIGRATION_FILE -Raw

# Mostrar información sobre la migración
Write-Host "La migración realizará los siguientes cambios:" -ForegroundColor Yellow
Write-Host "1. Añadir el campo asistente_ia_activado a la tabla messages" -ForegroundColor Cyan
Write-Host "2. Configurar las URLs del webhook de IA en app_settings" -ForegroundColor Cyan
Write-Host "3. Modificar la función notify_message_webhook para enviar mensajes al webhook de IA" -ForegroundColor Cyan
Write-Host "4. Recrear el trigger message_webhook_trigger" -ForegroundColor Cyan

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
Write-Host "3. Verifique los logs de Supabase para ver si hay información adicional sobre el proceso" -ForegroundColor Cyan
Write-Host "4. Pruebe con un mensaje de cliente con asistente_ia_activado=true para verificar si la solución funciona" -ForegroundColor Cyan

# Mostrar el comando para aplicar la migración usando supabase CLI
Write-Host "Si está usando Supabase CLI, puede aplicar la migración con el siguiente comando:" -ForegroundColor Yellow
Write-Host "supabase db execute --file $MIGRATION_FILE" -ForegroundColor Cyan

# Preguntar al usuario si desea ver el contenido del archivo
$VIEW_CONTENT = Read-Host "¿Desea ver el contenido del archivo de migración? (S/N)"
if ($VIEW_CONTENT -eq "S" -or $VIEW_CONTENT -eq "s") {
    Write-Host "Contenido del archivo de migración:" -ForegroundColor Yellow
    Write-Host $SQL_CONTENT
}

Write-Host "Después de aplicar la migración, pruebe con un mensaje de cliente con asistente_ia_activado=true para verificar si la solución funciona." -ForegroundColor Yellow
Write-Host "Si el problema persiste, revise los logs de Supabase para obtener más información." -ForegroundColor Yellow
