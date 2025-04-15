# Script para aplicar la migración que implementa la configuración del Asistente IA por conversación

# Ruta al archivo de migración
$MIGRATION_FILE = "supabase/migrations/20250418000000_conversation_ia_settings.sql"

# Verificar que el archivo existe
if (-not (Test-Path $MIGRATION_FILE)) {
    Write-Host "Error: No se encontró el archivo de migración: $MIGRATION_FILE" -ForegroundColor Red
    exit 1
}

Write-Host "Aplicando la migración para implementar la configuración del Asistente IA por conversación..." -ForegroundColor Yellow

# Leer el contenido del archivo
$SQL_CONTENT = Get-Content -Path $MIGRATION_FILE -Raw

# Mostrar información sobre la migración
Write-Host "La migración realizará los siguientes cambios:" -ForegroundColor Yellow
Write-Host "1. Crear una nueva tabla conversation_settings para almacenar la configuración por conversación" -ForegroundColor Cyan
Write-Host "2. Crear una tabla de auditoría para registrar cambios en la configuración" -ForegroundColor Cyan
Write-Host "3. Implementar políticas RLS para controlar el acceso" -ForegroundColor Cyan
Write-Host "4. Crear funciones para actualizar y consultar el estado del Asistente IA por conversación" -ForegroundColor Cyan
Write-Host "5. Migrar el estado global actual a la nueva estructura" -ForegroundColor Cyan

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
Write-Host "-- Consultar el estado del Asistente IA para una conversación específica" -ForegroundColor Cyan
Write-Host "SELECT * FROM get_conversation_ia_state('ID_DE_CONVERSACION_AQUÍ');" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "-- Actualizar el estado del Asistente IA para una conversación específica" -ForegroundColor Cyan
Write-Host "SELECT * FROM update_conversation_ia_state('ID_DE_CONVERSACION_AQUÍ', false, 'Prueba de desactivación');" -ForegroundColor Cyan
Write-Host "SELECT * FROM update_conversation_ia_state('ID_DE_CONVERSACION_AQUÍ', true, 'Prueba de activación');" -ForegroundColor Cyan
Write-Host "" -ForegroundColor Cyan
Write-Host "-- Verificar los registros de auditoría" -ForegroundColor Cyan
Write-Host "SELECT * FROM conversation_settings_audit WHERE conversation_id = 'ID_DE_CONVERSACION_AQUÍ' ORDER BY created_at DESC LIMIT 10;" -ForegroundColor Cyan

Write-Host "NOTA IMPORTANTE: Esta migración modifica la estructura de datos para que el estado del Asistente IA sea por conversación en lugar de global." -ForegroundColor Yellow
Write-Host "Después de aplicar esta migración, deberá actualizar el código frontend para usar las nuevas funciones." -ForegroundColor Yellow
