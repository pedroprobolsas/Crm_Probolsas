# Script para aplicar la migración que implementa la configuración del Asistente IA

# Ruta al archivo de migración
$MIGRATION_FILE = "supabase/migrations/20250417000000_add_ia_assistant_setting.sql"

# Verificar que el archivo existe
if (-not (Test-Path $MIGRATION_FILE)) {
    Write-Host "Error: No se encontró el archivo de migración: $MIGRATION_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "Aplicando la migración para implementar la configuración del Asistente IA..." -ForegroundColor Yellow

# Leer el contenido del archivo
$SQL_CONTENT = Get-Content -Path $MIGRATION_FILE -Raw

# Mostrar información sobre la migración
Write-Host "La migración realizará los siguientes cambios:" -ForegroundColor Yellow
Write-Host "1. Añadir un registro en app_settings para el estado del Asistente IA" -ForegroundColor Cyan
Write-Host "2. Crear una tabla de auditoría para registrar cambios en la configuración" -ForegroundColor Cyan
Write-Host "3. Implementar políticas RLS para controlar el acceso" -ForegroundColor Cyan
Write-Host "4. Crear funciones para actualizar y consultar el estado del Asistente IA" -ForegroundColor Cyan

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

# Mostrar el comando para aplicar la migración usando supabase CLI
Write-Host "Si está usando Supabase CLI, puede aplicar la migración con el siguiente comando:" -ForegroundColor Yellow
Write-Host "supabase db execute --file $MIGRATION_FILE" -ForegroundColor Cyan

# Preguntar al usuario si desea ver el contenido del archivo
$VIEW_CONTENT = Read-Host "¿Desea ver el contenido del archivo de migración? (S/N)"
if ($VIEW_CONTENT -eq "S" -or $VIEW_CONTENT -eq "s") {
    Write-Host "Contenido del archivo de migración:" -ForegroundColor Yellow
    Write-Host $SQL_CONTENT
}

Write-Host "Después de aplicar la migración, puede probar las funciones creadas con las siguientes consultas SQL:" -ForegroundColor Yellow
Write-Host "-- Consultar el estado actual del Asistente IA" -ForegroundColor Cyan
Write-Host "SELECT * FROM get_ia_assistant_state();" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "-- Actualizar el estado del Asistente IA" -ForegroundColor Cyan
Write-Host "SELECT * FROM update_ia_assistant_state(false, 'Prueba de desactivación');" -ForegroundColor Cyan
Write-Host "SELECT * FROM update_ia_assistant_state(true, 'Prueba de activación');" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "-- Verificar los registros de auditoría" -ForegroundColor Cyan
Write-Host "SELECT * FROM app_settings_audit WHERE key = 'ia_assistant_enabled' ORDER BY created_at DESC LIMIT 10;" -ForegroundColor Cyan

Write-Host "Para integrar con n8n, puede usar las funciones get_ia_assistant_state() y update_ia_assistant_state() a través de la API de Supabase." -ForegroundColor Yellow
