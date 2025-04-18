# Script para aplicar la solución completa del webhook de IA

# Configuración
$supabaseUrl = $env:SUPABASE_URL
$supabaseKey = $env:SUPABASE_SERVICE_ROLE_KEY
$sqlFile = "fix_webhook_ia_completo_final.sql"

# Verificar que el archivo SQL existe
if (-not (Test-Path $sqlFile)) {
    Write-Error "El archivo $sqlFile no existe."
    exit 1
}

# Leer el contenido del archivo SQL
$sqlContent = Get-Content -Path $sqlFile -Raw

# Mostrar instrucciones
Write-Host "IMPORTANTE: Antes de ejecutar este script, asegúrate de:" -ForegroundColor Yellow
Write-Host "1. Tener acceso a la consola de Supabase" -ForegroundColor Yellow
Write-Host "2. Deshabilitar las Edge Functions 'messages-outgoing' y 'messages-incoming'" -ForegroundColor Yellow
Write-Host ""
Write-Host "¿Has deshabilitado las Edge Functions? (S/N)" -ForegroundColor Cyan
$confirmation = Read-Host

if ($confirmation -ne "S") {
    Write-Host "Por favor, deshabilita las Edge Functions antes de continuar." -ForegroundColor Red
    exit 1
}

# Ejecutar el script SQL
Write-Host "Aplicando la solución completa del webhook de IA..." -ForegroundColor Green

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
    
    Write-Host "Solución aplicada correctamente." -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANTE:" -ForegroundColor Yellow
    Write-Host "1. Verifica los logs de Supabase para confirmar que el webhook de IA está funcionando correctamente." -ForegroundColor Yellow
    Write-Host "2. Mantén las Edge Functions deshabilitadas para evitar conflictos." -ForegroundColor Yellow
    Write-Host "3. Si necesitas volver a habilitar las Edge Functions, asegúrate de modificarlas para que no interfieran con el webhook de IA." -ForegroundColor Yellow
}
catch {
    Write-Error "Error al aplicar la solución: $_"
    exit 1
}
