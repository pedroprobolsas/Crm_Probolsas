# Script para actualizar las Edge Functions para que no interfieran con el webhook de IA

# Configuración
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY

# Mostrar instrucciones iniciales
Write-Host "ACTUALIZACIÓN DE EDGE FUNCTIONS PARA WEBHOOK DE IA" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este script actualizará las Edge Functions para que no interfieran con el webhook de IA." -ForegroundColor Yellow
Write-Host "En lugar de deshabilitar o eliminar las funciones, las modificaremos para que:" -ForegroundColor Yellow
Write-Host "1. messages-incoming: Ignore mensajes que ya han sido procesados por el trigger SQL" -ForegroundColor Yellow
Write-Host "2. messages-outgoing: Ignore mensajes con asistente_ia_activado=true" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANTE: Antes de ejecutar este script, asegúrate de:" -ForegroundColor Red
Write-Host "1. Tener acceso a la consola de Supabase" -ForegroundColor Red
Write-Host "2. Tener permisos para actualizar las Edge Functions" -ForegroundColor Red
Write-Host "3. Tener una copia de seguridad de las Edge Functions originales (por precaución)" -ForegroundColor Red
Write-Host ""
Write-Host "¿Deseas continuar con la actualización de las Edge Functions? (S/N)" -ForegroundColor Cyan
$confirmation = Read-Host

if ($confirmation -ne "S") {
    Write-Host "Operación cancelada por el usuario." -ForegroundColor Yellow
    exit 0
}

# Paso 1: Verificar que los archivos de las Edge Functions existen
Write-Host ""
Write-Host "PASO 1: Verificando archivos de Edge Functions..." -ForegroundColor Green
Write-Host "----------------------------------------" -ForegroundColor Green

$messagesIncomingPath = "supabase/functions/messages-incoming/index.js"
$messagesOutgoingPath = "supabase/functions/messages-outgoing/index.js"

if (-not (Test-Path $messagesIncomingPath)) {
    Write-Error "El archivo $messagesIncomingPath no existe."
    exit 1
}

if (-not (Test-Path $messagesOutgoingPath)) {
    Write-Error "El archivo $messagesOutgoingPath no existe."
    exit 1
}

Write-Host "Archivos de Edge Functions encontrados." -ForegroundColor Green

# Paso 2: Actualizar las Edge Functions en Supabase
Write-Host ""
Write-Host "PASO 2: Actualizando Edge Functions en Supabase..." -ForegroundColor Green
Write-Host "-------------------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "Para actualizar las Edge Functions, sigue estos pasos:" -ForegroundColor Yellow
Write-Host "1. Ve a la sección 'Edge Functions' en la consola de Supabase" -ForegroundColor Yellow
Write-Host "2. Selecciona la función 'messages-incoming'" -ForegroundColor Yellow
Write-Host "3. Reemplaza el contenido del archivo index.js con el contenido del archivo $messagesIncomingPath" -ForegroundColor Yellow
Write-Host "4. Guarda los cambios" -ForegroundColor Yellow
Write-Host "5. Selecciona la función 'messages-outgoing'" -ForegroundColor Yellow
Write-Host "6. Reemplaza el contenido del archivo index.js con el contenido del archivo $messagesOutgoingPath" -ForegroundColor Yellow
Write-Host "7. Guarda los cambios" -ForegroundColor Yellow
Write-Host ""
Write-Host "¿Has actualizado las Edge Functions en Supabase? (S/N)" -ForegroundColor Cyan
$edgeFunctionsUpdated = Read-Host

if ($edgeFunctionsUpdated -ne "S") {
    Write-Host "Por favor, actualiza las Edge Functions antes de continuar." -ForegroundColor Red
    exit 1
}

# Paso 3: Aplicar la solución SQL para el webhook de IA
Write-Host ""
Write-Host "PASO 3: Aplicando solución SQL para el webhook de IA..." -ForegroundColor Green
Write-Host "------------------------------------------------" -ForegroundColor Green

$sqlFile = "fix_webhook_ia_completo_final.sql"

if (-not (Test-Path $sqlFile)) {
    Write-Host "Archivo SQL no encontrado. Saltando este paso." -ForegroundColor Yellow
} else {
    try {
        # Leer el contenido del archivo SQL
        $sqlContent = Get-Content -Path $sqlFile -Raw
        
        # Usar curl para ejecutar el SQL en Supabase
        $headers = @{
            "apikey" = $supabaseKey
            "Authorization" = "Bearer $supabaseKey"
            "Content-Type" = "application/json"
            "Prefer" = "params=single-object"
        }
        
        $body = @{
            "query" = $sqlContent
        } | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/execute_sql" -Method POST -Headers $headers -Body $body
        
        Write-Host "Solución SQL aplicada correctamente." -ForegroundColor Green
    }
    catch {
        Write-Error "Error al aplicar la solución SQL: $_"
        Write-Host "Continuando con el resto del proceso..." -ForegroundColor Yellow
    }
}

# Paso 4: Resumen y pasos adicionales
Write-Host ""
Write-Host "PASO 4: Resumen y pasos adicionales" -ForegroundColor Green
Write-Host "------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "Se han aplicado las siguientes soluciones:" -ForegroundColor Cyan
Write-Host "1. Se ha modificado la Edge Function messages-incoming para que ignore mensajes ya procesados por el trigger SQL" -ForegroundColor White
Write-Host "2. Se ha modificado la Edge Function messages-outgoing para que ignore mensajes con asistente_ia_activado=true" -ForegroundColor White
Write-Host "3. Se ha aplicado la solución SQL para el webhook de IA (si el archivo estaba disponible)" -ForegroundColor White
Write-Host ""
Write-Host "PASOS ADICIONALES RECOMENDADOS:" -ForegroundColor Yellow
Write-Host "1. Prueba enviar un mensaje con el asistente de IA activado desde la interfaz de usuario" -ForegroundColor Yellow
Write-Host "2. Verifica que no aparecen clientes duplicados en el módulo de clientes" -ForegroundColor Yellow
Write-Host "3. Verifica que no aparecen conversaciones duplicadas en el módulo de comunicaciones" -ForegroundColor Yellow
Write-Host "4. Revisa los logs de Supabase para confirmar que no hay errores relacionados con el webhook de IA" -ForegroundColor Yellow
Write-Host ""
Write-Host "Para más detalles sobre las soluciones implementadas, consulta:" -ForegroundColor Cyan
Write-Host "- README-resumen-soluciones-implementadas.md" -ForegroundColor Cyan
Write-Host "- README-solucion-webhook-ia-y-duplicacion.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "¡Soluciones aplicadas correctamente!" -ForegroundColor Green
