# Script para aplicar la corrección del webhook de IA
# Este script ejecuta el script SQL fix_ia_webhook.sql

Write-Host "Aplicando correcciones al webhook de IA..." -ForegroundColor Cyan

# Verificar si el archivo de corrección existe
if (-not (Test-Path "fix_ia_webhook.sql")) {
    Write-Host "Error: No se encontró el archivo fix_ia_webhook.sql" -ForegroundColor Red
    exit 1
}

# Leer el contenido del archivo SQL
$sqlContent = Get-Content -Path "fix_ia_webhook.sql" -Raw

Write-Host "Se ha leído el script de corrección" -ForegroundColor Green

# Verificar si existe el script apply_ia_webhook_migration.ps1
if (Test-Path "apply_ia_webhook_migration.ps1") {
    Write-Host "Encontrado script apply_ia_webhook_migration.ps1, intentando usarlo como referencia" -ForegroundColor Yellow
    
    # Leer el contenido del script de migración para entender cómo se conecta a Supabase
    $migrationScript = Get-Content -Path "apply_ia_webhook_migration.ps1" -Raw
    
    Write-Host "Por favor, revisa el script de migración para entender cómo conectarte a Supabase" -ForegroundColor Yellow
}

# Instrucciones para el usuario
Write-Host "`nPara aplicar las correcciones, sigue estos pasos:" -ForegroundColor Green
Write-Host "1. Accede a la consola SQL de Supabase" -ForegroundColor White
Write-Host "2. Copia y pega el contenido del archivo fix_ia_webhook.sql" -ForegroundColor White
Write-Host "3. Ejecuta el script y revisa los resultados" -ForegroundColor White
Write-Host "4. Verifica los logs de Supabase para confirmar que el webhook de IA está funcionando correctamente" -ForegroundColor White

# Mostrar un resumen de las correcciones que se aplicarán
Write-Host "`nResumen de las correcciones que se aplicarán:" -ForegroundColor Cyan
Write-Host "1. Actualizar el campo asistente_ia_activado para el mensaje 'Prueba 1500'" -ForegroundColor White
Write-Host "2. Verificar y activar el trigger message_webhook_trigger" -ForegroundColor White
Write-Host "3. Recrear la función notify_message_webhook con la lógica correcta" -ForegroundColor White
Write-Host "4. Recrear el trigger message_webhook_trigger" -ForegroundColor White
Write-Host "5. Verificar e instalar la extensión http si es necesario" -ForegroundColor White
Write-Host "6. Crear o actualizar la función http_post" -ForegroundColor White
Write-Host "7. Insertar un mensaje de prueba con asistente_ia_activado=true" -ForegroundColor White

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

Write-Host "`nRecuerda verificar los logs de Supabase después de aplicar las correcciones para confirmar que el webhook de IA está funcionando correctamente." -ForegroundColor Yellow
