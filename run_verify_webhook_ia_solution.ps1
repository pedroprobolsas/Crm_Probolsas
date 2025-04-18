# Script para verificar la solución del webhook de IA

# Configuración
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY
$sqlFile = "verify_webhook_ia_solution.sql"

# Verificar que el archivo SQL existe
if (-not (Test-Path $sqlFile)) {
    Write-Error "El archivo $sqlFile no existe."
    exit 1
}

# Leer el contenido del archivo SQL
$sqlContent = Get-Content -Path $sqlFile -Raw

# Mostrar instrucciones
Write-Host "Verificando la solución del webhook de IA..." -ForegroundColor Green
Write-Host ""
Write-Host "Este script ejecutará consultas SQL para verificar que la solución" -ForegroundColor Yellow
Write-Host "del webhook de IA está funcionando correctamente." -ForegroundColor Yellow
Write-Host ""

# Ejecutar el script SQL
try {
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
    
    Write-Host "Verificación completada." -ForegroundColor Green
    Write-Host ""
    Write-Host "RESULTADOS DE LA VERIFICACIÓN:" -ForegroundColor Cyan
    Write-Host "------------------------------" -ForegroundColor Cyan
    
    # Mostrar los resultados de la verificación
    if ($response.result) {
        Write-Host $response.result -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "PASOS ADICIONALES DE VERIFICACIÓN:" -ForegroundColor Yellow
    Write-Host "1. Verifica los logs de Supabase para confirmar que no hay errores relacionados con el webhook de IA." -ForegroundColor Yellow
    Write-Host "2. Confirma que las Edge Functions 'messages-outgoing' y 'messages-incoming' están deshabilitadas." -ForegroundColor Yellow
    Write-Host "3. Prueba enviar un mensaje con el asistente de IA activado desde la interfaz de usuario." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Si todos los pasos anteriores son exitosos, la solución está funcionando correctamente." -ForegroundColor Green
}
catch {
    Write-Error "Error al ejecutar la verificación: $_"
    exit 1
}
