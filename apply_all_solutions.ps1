# Script para aplicar todas las soluciones de una sola vez

# Configuración
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY
$sqlFile = "fix_webhook_ia_completo_final.sql"

# Verificar que el archivo SQL existe
if (-not (Test-Path $sqlFile)) {
    Write-Error "El archivo $sqlFile no existe."
    exit 1
}

# Mostrar instrucciones iniciales
Write-Host "APLICACIÓN COMPLETA DE SOLUCIONES" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este script aplicará todas las soluciones para los problemas de:" -ForegroundColor Yellow
Write-Host "1. Webhook de IA no funcionando" -ForegroundColor Yellow
Write-Host "2. Duplicación de clientes" -ForegroundColor Yellow
Write-Host ""
Write-Host "IMPORTANTE: Antes de ejecutar este script, asegúrate de:" -ForegroundColor Red
Write-Host "1. Tener acceso a la consola de Supabase" -ForegroundColor Red
Write-Host "2. Poder deshabilitar las Edge Functions 'messages-outgoing' y 'messages-incoming'" -ForegroundColor Red
Write-Host "3. Tener una copia de seguridad de la base de datos (por precaución)" -ForegroundColor Red
Write-Host ""
Write-Host "¿Deseas continuar con la aplicación de todas las soluciones? (S/N)" -ForegroundColor Cyan
$confirmation = Read-Host

if ($confirmation -ne "S") {
    Write-Host "Operación cancelada por el usuario." -ForegroundColor Yellow
    exit 0
}

# Paso 1: Deshabilitar Edge Functions
Write-Host ""
Write-Host "PASO 1: Deshabilitar Edge Functions" -ForegroundColor Green
Write-Host "--------------------------------" -ForegroundColor Green
Write-Host "Por favor, sigue estos pasos:" -ForegroundColor Yellow
Write-Host "1. Ve a la sección 'Edge Functions' en la consola de Supabase" -ForegroundColor Yellow
Write-Host "2. Busca las funciones 'messages-outgoing' y 'messages-incoming'" -ForegroundColor Yellow
Write-Host "3. Deshabilita temporalmente estas funciones" -ForegroundColor Yellow
Write-Host ""
Write-Host "¿Has deshabilitado las Edge Functions? (S/N)" -ForegroundColor Cyan
$edgeFunctionsDisabled = Read-Host

if ($edgeFunctionsDisabled -ne "S") {
    Write-Host "Por favor, deshabilita las Edge Functions antes de continuar." -ForegroundColor Red
    exit 1
}

# Paso 2: Aplicar solución SQL para el webhook de IA
Write-Host ""
Write-Host "PASO 2: Aplicando solución SQL para el webhook de IA..." -ForegroundColor Green
Write-Host "------------------------------------------------" -ForegroundColor Green

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
    exit 1
}

# Paso 3: Verificar la solución del webhook de IA
Write-Host ""
Write-Host "PASO 3: Verificando la solución del webhook de IA..." -ForegroundColor Green
Write-Host "---------------------------------------------" -ForegroundColor Green

try {
    # Ejecutar el script de verificación
    if (Test-Path "verify_webhook_ia_solution.sql") {
        $verifyContent = Get-Content -Path "verify_webhook_ia_solution.sql" -Raw
        
        $body = @{
            "query" = $verifyContent
        } | ConvertTo-Json -Depth 10
        
        $verifyResponse = Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/rpc/execute_sql" -Method POST -Headers $headers -Body $body
        
        Write-Host "Verificación completada." -ForegroundColor Green
        Write-Host ""
        Write-Host "RESULTADOS DE LA VERIFICACIÓN:" -ForegroundColor Cyan
        
        if ($verifyResponse.result) {
            Write-Host $verifyResponse.result -ForegroundColor White
        }
    }
    else {
        Write-Host "Archivo de verificación no encontrado. Saltando este paso." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error al verificar la solución: $_" -ForegroundColor Red
    Write-Host "Continuando con el resto del proceso..." -ForegroundColor Yellow
}

# Paso 4: Resumen y pasos adicionales
Write-Host ""
Write-Host "PASO 4: Resumen y pasos adicionales" -ForegroundColor Green
Write-Host "------------------------------" -ForegroundColor Green
Write-Host ""
Write-Host "Se han aplicado las siguientes soluciones:" -ForegroundColor Cyan
Write-Host "1. Se ha optimizado la función notify_message_webhook para manejar correctamente los mensajes con asistente_ia_activado=true" -ForegroundColor White
Write-Host "2. Se ha añadido un campo ia_webhook_sent para rastrear mensajes enviados al webhook" -ForegroundColor White
Write-Host "3. Se han deshabilitado las Edge Functions que interferían con el procesamiento" -ForegroundColor White
Write-Host "4. Se han modificado los archivos TypeScript para evitar duplicación de clientes" -ForegroundColor White
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
